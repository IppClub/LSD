local D=require('Dora')
return function(root,actor,filename,repetitions,failSave)
local out=root..'/Test/'..filename;local r={status='RUNNING',actor=actor,rounds={}}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-demonstration-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-demo%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-comparison-ui-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn,seconds)local untilAt=D.App.runningTime+(seconds or 20);while not fn()do assert(D.App.runningTime<untilAt,'Comparison UI timeout');D.sleep(.05)end end
  local function models()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0DisarmCandidates'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=models();require('Training.Level')(nil,actor);wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local function open()
   D.Director.ui3D:getChildByTag('training-controls'):getChildByTag('training-menu'):getChildByTag('缴械对照'):emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('disarm-comparison-budget')end)
   return D.Director.ui3D:getChildByTag('disarm-comparison-budget')
  end
  open().closeButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end);r.budgetCancelled=true
  local Store=require('Training.DisarmComparisonStore');local saved
  for round=1,repetitions or 1 do
  r.round=round;r.currentRun=0
  if failSave then assert(Store.list());assert(D.DB:exec("CREATE TRIGGER lsd.reject_comparison BEFORE INSERT ON Game0DisarmComparisons BEGIN SELECT RAISE(ABORT,'test write failure'); END")>=0)end
  local budget=open();assert(budget.noteLabel.text:find('6场',1,true));budget.saveButton:emit('Tapped')
  wait(function()
   local progress=D.Director.ui3D:getChildByTag('disarm-comparison-progress')
   if progress then
    collectgarbage('collect');assert(progress.state and progress.cancelButton,'Progress controls lost after garbage collection')
    if r.currentRun~=progress.state.index then r.currentRun=progress.state.index;D.Content:save(out,D.json.encode(r,false,true))end
   end
   return D.Director.ui3D:getChildByTag('disarm-comparison-result')
  end,650)
  local view=D.Director.ui3D:getChildByTag('disarm-comparison-result')
  if failSave then
   assert(not view.state.saved and view.state.error=='WRITE_FAILED');assert(view.retryButton.visible and view.discardButton.visible and not view.backButton.visible)
   assert(#Store.list()==round-1)
   D.sleep(.2);r.failureScreenshot=D.Content.writablePath..'/comparison-save-failure.tga';D.App:saveScreenshot(r.failureScreenshot);D.sleep(.2)
   if round==2 then
    view.discardButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
    assert(#Store.list()==1 and Store.loadLatest().id==saved.id and models()==before);r.discarded=true;r.modelsUnchanged=true;return
   end
   local original=Store.saveAsync;local calls=0
   Store.saveAsync=function(record)calls=calls+1;D.sleep(.4);return original(record)end
   local function retry()
    view.retryButton:emit('Tapped');wait(function()return view.state.saving end)
    view.retryButton:emit('Tapped');view.backButton:emit('Tapped');view.discardButton:emit('Tapped');D.sleep(.1)
    assert(view.state.saving and not view.backButton.visible and not view.discardButton.visible and not view.retryButton.visible)
    assert(D.Director.ui3D:getChildByTag('disarm-comparison-result')==view)
    wait(function()return not view.state.saving end)
   end
   retry();assert(calls==1 and not view.state.saved and view.retryButton.visible and view.discardButton.visible)
   assert(D.DB:exec('DROP TRIGGER lsd.reject_comparison')>=0)
   retry();assert(calls==2 and view.state.saved and view.backButton.visible and not view.discardButton.visible and not view.retryButton.visible)
   view.retryButton:emit('Tapped');D.sleep(.1);assert(calls==2);Store.saveAsync=original;r.saveRetry=true;r.navigationGuarded=true
  end
  assert(view.state.saved and not view.state.error);assert(view.label.text:find('未自动采用',1,true))
  saved=assert(Store.loadLatest());assert(saved.record.setup.candidate.model.characterId==actor);if r.rounds[round-1]then assert(saved.id~=r.rounds[round-1].archive,'Repeated comparison must have a new identity')end;assert(saved.id==view.state.saved);assert(Store.saveAsync(view.state.record)==saved.id)
  local recomputed=assert(require('Training.DisarmCompare').review(saved.record));assert(require('Training.FlowerIdentity').equal(recomputed,saved.review));assert(require('Training.FlowerIdentity').equal(recomputed,saved.record.review));r.review=recomputed;r.archive=saved.id;r.rounds[round]={archive=saved.id,review=recomputed}
  local copy=D.json.decode(D.json.encode(saved.record),32);copy.runs[2].trace.comparisonSetup.mentor='human';assert(not require('Training.DisarmCompare').review(copy))
  copy=D.json.decode(D.json.encode(saved.record),32);copy.runs[2].seconds=999;assert(not require('Training.DisarmCompare').review(copy));r.mismatchRejected=true
  D.sleep(.2);r.screenshot=D.Content.writablePath..'/comparison-result.tga';D.App:saveScreenshot(r.screenshot);D.sleep(.2)
  view.backButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  end
  open().saveButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('disarm-comparison-progress')end);D.Director.ui3D:getChildByTag('disarm-comparison-progress').cancelButton:emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('disarm-comparison-result')end)
  local cancelled=D.Director.ui3D:getChildByTag('disarm-comparison-result');assert(cancelled.state.error=='CANCELLED'and not cancelled.state.saved);assert(Store.loadLatest().id==saved.id);r.cancelled=true
  cancelled.backButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end);assert(models()==before);r.modelsUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
end
