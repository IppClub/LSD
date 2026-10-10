local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-save-lifecycle-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local Store=require('Training.DisarmStore');local original=Store.saveAsync
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-performance-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/lsd%-disarm%-practice%-qa%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-save-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn)local deadline=D.App.runningTime+18;while not fn()do assert(D.App.runningTime<deadline,'Save lifecycle timeout');D.sleep(.02)end end
  local function count()return D.DB:query('SELECT COUNT(*) FROM lsd.Game0DisarmObservations')[1][1]end
  local models=assert(require('Training.FlowerPractice').models())
  local initial=count();local mode='slow';local calls=0
  Store.saveAsync=function(trace)calls=calls+1;D.sleep(mode=='slow'and .7 or .1);if mode=='fail'then return false,'WRITE_FAILED'end;return original(trace)end
  local function open()
   require('Training.DisarmPractice').openAsync(nil,'ninilite',models,nil,'ninilite')
   D.Director.ui3D:getChildByTag('disarm-supply-loadout').saveButton:emit('Tapped')
   wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.patrolLevel and D.Platformer.Data.store.world.patrolLevel.phase=='ready'end)
   local c=D.Platformer.Data.store.world.patrolLevel;c.start:emit('Tapped');wait(function()return c.battle.phase=='playing'and c.battle.arena.student.onSurface end)
   c.hud.move:emit('Right',true);D.sleep(.2);c.hud.move:emit('Right',false);c.withdraw:emit('Tapped');return c
  end
  local c=open();wait(function()return c.phase=='saving-result'and c.battle.disarmTrace.sourceSaveState=='saving'end);assert(c.result==nil);D.sleep(.2);assert(c.result==nil,'Result navigation appeared before save')
  wait(function()return c.phase=='result'end);assert(count()==initial+1 and c.battle.disarmTrace.sourceSaveState=='saved');r.delayedSaveWaited=true
  c.result.baseButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  mode='fail';c=open();wait(function()return c.phase=='save-error'end);assert(c.error=='WRITE_FAILED'and count()==initial+1 and c.result.resultLayout=='MissionFail')
  r.failureScreenshot=D.Content.writablePath..'/disarm-save-failure.tga';D.App:saveScreenshot(r.failureScreenshot);D.sleep(.2)
  mode='slow';local before=calls;c.result.againButton:emit('Tapped');c.result.againButton:emit('Tapped');c.result.baseButton:emit('Tapped')
  assert(c.phase=='saving-result'and not c.leaving,'Navigation allowed while retry was running')
  wait(function()return c.phase=='result'end);assert(calls==before+1 and count()==initial+2 and c.battle.disarmTrace.sourceSaveState=='saved');r.retrySavedOnce=true
  local source=assert(Store.loadLatestAsync());assert(source.source.trace.demonstrator=='ninilite');assert(#source.source.trace.executions>0)
  c.result.baseButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  mode='fail';c=open();wait(function()return c.phase=='save-error'end);c.result.baseButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end);assert(count()==initial+2);r.explicitDiscardReturned=true
 end,debug.traceback)
 Store.saveAsync=original;r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
