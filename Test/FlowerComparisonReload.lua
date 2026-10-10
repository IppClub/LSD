local script,source=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script));local out=root..'/Test/flower-comparison-reload-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
 assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-comparison%-%d+%.db$'))
 local dest=D.Content.writablePath..'/flower-reload-'..os.time()..'.db';assert(D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
 local P=require('Training.FlowerPractice');local c=P.openAsync(nil,'ninilite')
 r.error=c.comparisonError;r.candidateError=c.candidateError;r.lastError=c.lastTrialError
 local rows,why=require('Training.FlowerTrialStore').history('ninilite');r.historyError=why;r.recordCount=rows and #rows;r.comparison=c.comparison
 assert(c.comparison,'Missing comparison: '..tostring(c.comparisonError))
 local C=require('Training.FlowerComparison');local I=require('Training.FlowerIdentity');local basic,candidate
 for _,row in ipairs(rows)do if row.episode.episode==c.comparison.basicEpisode then basic=row elseif row.episode.episode==c.comparison.candidateEpisode then candidate=row end end
 assert(basic and candidate and basic.status~='aborted' and candidate.status~='aborted')
 local function clone(v)return D.json.decode(D.json.encode(v),32)end
 local aborted=clone(basic);aborted.status='aborted';local no,why=C.build(aborted,candidate);assert(not no and why=='ABORTED_TRIAL')
 local mismatch=clone(candidate);mismatch.setup.models.wuyun.trainingAccuracy=.123;local no,why=C.build(basic,mismatch);assert(not no and why=='SETUP_MISMATCH')
 assert(not C.latest('ninilite',{},assert(P.models())),'Stale policy accepted')
 assert(I.equal({a=1,b={c=2}},{b={c=2},a=1}) and not I.equal({a=1},{a=2}))
 assert(require('Training.FlowerTrialStore').saveAsync(candidate),'Reloaded trial was not idempotent')
 assert(c.comparison.adoptionEligible==false)
 local Review=require('Training.FlowerReview')
 local realReview=assert(Review.latest('ninilite',c.candidate,assert(P.models())))
 assert(#realReview.pairs==1 and realReview.verdict=='collect-more' and not realReview.adoptionEligible)
 r.realReview=realReview
 -- Synthetic repeated records exercise selection/gates only. They are never
 -- saved as played rounds and never count as runtime performance evidence.
 local sequence={};local function duplicate(record,id)local item=clone(record);item.episode.episode='synthetic-review-'..id;return item end
 for i=1,3 do sequence[#sequence+1]=duplicate(candidate,'candidate-'..i);sequence[#sequence+1]=duplicate(basic,'basic-'..i)end
 local review=assert(Review.build(sequence,'ninilite',c.candidate,assert(P.models())))
 assert(#review.pairs==3 and review.verdict=='candidate-regressed' and review.candidateWins==0 and review.durationPairs==0 and review.winningDurationDelta==0 and not review.adoptionEligible)
 local used={};for _,pair in ipairs(review.pairs)do assert(not used[pair.basicEpisode] and not used[pair.candidateEpisode]);used[pair.basicEpisode]=true;used[pair.candidateEpisode]=true end
 local duplicateHistory={sequence[1],sequence[1]};local no,why=Review.build(duplicateHistory,'ninilite',c.candidate,assert(P.models()));assert(not no and why=='DUPLICATE_EPISODE')
 local oneBaseline={sequence[1],sequence[3],sequence[5],sequence[2]};local once=assert(Review.build(oneBaseline,'ninilite',c.candidate,assert(P.models())));assert(#once.pairs==1 and once.missingBaseline==2)
 local olderWin=duplicate(basic,'older-candidate-win');olderWin.controller='candidate';olderWin.policy=clone(candidate.policy)
 sequence[#sequence+1]=olderWin;sequence[#sequence+1]=duplicate(basic,'older-basic')
 local recent=assert(Review.build(sequence,'ninilite',c.candidate,assert(P.models())));assert(recent.candidateWins==0 and #recent.pairs==3,'Older good result displaced recent failure')
 local sameWins={}
 for i=1,3 do local win=duplicate(olderWin,'win-'..i);sameWins[#sameWins+1]=win;sameWins[#sameWins+1]=duplicate(basic,'win-baseline-'..i)end
 local coverage=assert(Review.build(sameWins,'ninilite',c.candidate,assert(P.models())))
 assert(coverage.verdict=='needs-held-out-evaluation' and not coverage.adoptionEligible,'Repeated scenario passed held-out gate')
 r.syntheticSelectionChecks=true;r.boundaries=true;r.semanticIdentity=true;r.reloadedIdempotent=true
 D.App.winSize=D.Size(683,384);D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-comparison.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.failure=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
