local script,source=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script));local out=root..'/Test/flower-adoption-review-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-evidence%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-adoption-review-'..os.time()..'.db';assert(not D.Content:exist(dest) and D.Content:copyAsync(source,dest))
  assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local R=require('Training.FlowerAdoptionReview');local S=require('Training.FlowerPolicyStore')
  local source=assert(S.evidence('ninilite'));local rows=assert(require('Training.FlowerTrialStore').history('ninilite'))
  assert(#require('Training.FlowerPracticeStore').history('ninilite')==0,'Use evicted rolling history fixture')
  local bundle,review=R.make(source,rows[1].setup.models,rows);assert(bundle,review)
  assert(review.readyForDecision and not review.adoptionEligible and review.candidateWins==3 and #bundle.trials==6)
  local frozen=D.json.decode(D.json.encode(bundle),32);assert(R.verifyAsync(frozen))
  local tradeoffs={};for _,e in ipairs(review.tradeoffs)do tradeoffs[e.profile..':'..e.metric]=e.delta end
  assert(tradeoffs['near:seconds']>20 and tradeoffs['far:teamDamage']==18,'Actual adverse results hidden')
  local function clone(x)return D.json.decode(D.json.encode(x),32)end
  local wrong=clone(frozen);wrong.trials[6]=wrong.trials[5];local bad,why=R.assess(wrong);assert(not bad and why=='REUSED_EPISODE')
  wrong=clone(frozen);wrong.trials[6]=nil;assert(not R.assess(wrong))
  wrong=clone(frozen);wrong.learner='wuyun';assert(not R.assess(wrong))
  wrong=clone(frozen);wrong.models.ninilite.sampleCount=wrong.models.ninilite.sampleCount+1;assert(not R.assess(wrong))
  -- A newer adverse test fixture must not fall back to an older winning row.
  local failed=clone(bundle.trials[2]);failed.status='failed';failed.episode.episode=failed.episode.episode..'-negative-review-fixture'
  local latest={failed};for _,row in ipairs(rows)do latest[#latest+1]=row end
  local adverse,review=R.make(source,rows[1].setup.models,latest);assert(adverse and not review.readyForDecision and review.candidateWins==2 and #review.blockers==1)
  local partial={};for _,row in ipairs(rows)do if not row.setup.profile or row.setup.profile.id~='far'then partial[#partial+1]=row end end
  local absent,why=R.make(source,rows[1].setup.models,partial);assert(not absent and why=='MISSING_PROFILE_PAIR')
  -- Freeze is independent of caller arrays and rolling trial retention.
  source.policy.rules[1].action='bmove';rows[1].seconds=999;assert(R.verifyAsync(bundle) and R.verifyAsync(frozen))
  r.sourceEpisodes=#source.episodes;r.samples=source.policy.sampleCount;r.trials=#frozen.trials;r.tradeoffs=tradeoffs;r.nativeRebuild=true;r.latestFailureBlocks=true;r.wrongSetupRejected=true;r.independentEvidence=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
