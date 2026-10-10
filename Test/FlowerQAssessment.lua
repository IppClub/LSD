local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-assessment-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-telemetry-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-telemetry%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-assessment-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync());local A=require('Training.FlowerQAssessment')
  local bundle,why=A.captureAsync(saved.source.baseModels);assert(bundle,why);assert(A.verifyAsync(bundle,saved.source.baseModels));r.exactReview=true
  assert(#bundle.trials==11 and #bundle.sources==2 and not bundle.assessment.readyForDecision)
  assert(bundle.assessment.profiles.near.training=='trained');for _,id in ipairs({'far','reproduction','field'})do assert(bundle.assessment.profiles[id].training=='unknown')end;r.noFalseHeldout=true
  local forged=D.json.decode(D.json.encode(bundle,false,true),32);forged.assessment.readyForDecision=true;local yes,why=A.verifyAsync(forged,saved.source.baseModels);assert(not yes and why=='REVIEW_STALE');r.forgedReviewRejected=true
  local row=bundle.trials[#bundle.trials];assert(D.DB:exec('DELETE FROM lsd.Game0FlowerQTrials WHERE id=?',{row[1]})>=0)
  yes,why=A.verifyAsync(bundle,saved.source.baseModels);assert(not yes and why=='REVIEW_STALE');r.changedTrialsRejected=true
  assert(D.DB:exec('INSERT INTO lsd.Game0FlowerQTrials(id,candidate,episode,payload) VALUES(?,?,?,?)',row)>=0)
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQDraft SET current=1 WHERE singleton=1')>=0);yes,why=A.verifyAsync(bundle,saved.source.baseModels);assert(not yes);r.changedCandidateRejected=true
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQDraft SET current=2 WHERE singleton=1')>=0);assert(A.verifyAsync(bundle,saved.source.baseModels))
  local panel=require('Training.FlowerQPanel').openAsync(function()end,saved.source.baseModels);panel.reviewButton:emit('Tapped');panel.scenario:emit('Tapped');assert(panel.profile=='far' and panel.label.text:find('不能认定为未见场景',1,true) and panel.label.text:find('次数未采集',1,true))
  D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-q-assessment.tga');D.sleep(.2);r.publicWarning=true
  r.blocked=bundle.assessment.blocked;r.warnings=bundle.assessment.warnings
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
