-- Evaluate the actually learned positioning model; never force a successful result.
local script,source=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script));local out=root..'/Test/flower-position-generalization-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={status='RUNNING',trials={}};local function save()D.Content:save(out,D.json.encode(r))end
 local ok,err=xpcall(function()
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-position%-learning%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-position-generalization-'..os.time()..'.db';assert(D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local P=require('Training.FlowerPractice');local T=require('Training.FlowerTrialStore')
  for _,id in ipairs(require('Training.FlowerScenarios').ids)do
   local c=P.openAsync(nil,'ninilite',nil,nil,nil,id);D.sleep(.2);c.trialButton:emit('Tapped');local began=D.App.totalTime
   while c.battle.phase=='playing' or c.battle.phase=='saving'do
    assert(D.App.totalTime-began<135,'Positioning evaluation stalled');r.profile=id;r.elapsed=D.App.totalTime-began;save();D.sleep(.5)
   end
   assert(c.result and c.result.trialSaved);local record=assert(T.latest('ninilite'));assert(record.status~='aborted')
   r.trials[#r.trials+1]={profile=id,status=record.status,seconds=record.seconds,evaluation=record.evaluation};save()
  end
  local source=assert(require('Training.FlowerPolicyStore').evidence('ninilite'));local rows=assert(T.history('ninilite'));local R=require('Training.FlowerAdoptionReview')
  local bundle,review=R.make(source,rows[1].setup.models,rows);assert(bundle,review);assert(bundle.fieldTrials and review.required==4 and R.verifyAsync(bundle))
  r.review=review;r.samples=source.policy.sampleCount;r.allProfilesRecorded=true
  if review.readyForDecision then
   local S=require('Training.FlowerAdoptionStore');local ok,why=S.adoptAsync(bundle,{accepted=true,review=review});assert(ok,why)
   local saved=assert(S.load('ninilite'));assert(saved.bundle.fieldTrials and saved.review.required==4)
   r.qaAdoption=saved.id;assert(S.rollbackAsync('ninilite'));r.qaRollback=true
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
