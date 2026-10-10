-- Public UI events and isolated saved models; not OS input acceptance.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-entry-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-entry-'..os.time()..'.db';r.database=db;assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function saved()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')})end
  local before=saved();local E=require('Economy.Store');assert(E.open());local balance=E.wallet().available
  local function wait(fn)local stop=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<stop,'Entry timeout');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'ninilite');wait(controls)
  controls():getChildByTag('training-menu'):getChildByTag('大英招示范'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout')end)
  D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout').closeButton:emit('Tapped');wait(controls);assert(E.wallet().available==balance)
  controls():getChildByTag('training-menu'):getChildByTag('大英招示范'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout')end)
  D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout').saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoDemonstration end)
  local c=D.Platformer.Data.store.world.patrolLevel;c.withdraw:emit('Tapped');wait(function()return c.phase=='result'end)
  assert(c.result.resultLayout=='MissionFail'and c.battle.demonstrationSourceId)
  c.result.baseButton:emit('Tapped');wait(controls)
  controls():getChildByTag('training-menu'):getChildByTag('学习部位'):emit('Tapped');wait(function()return controls().arena.mode~='building'end)
  assert(controls().arena.message:find('不足6条',1,true))
  local source=D.json.decode(D.Content:load(root..'/Test/yingzhao-policy-result.json'),32);assert(source.status=='PASS');assert(require('Training.YingzhaoStore').saveAsync(source.source))
  controls():getChildByTag('training-menu'):getChildByTag('学习部位'):emit('Tapped');wait(function()return controls().arena.mode~='building'end)
  assert(controls().arena.message:find('已保存',1,true),controls().arena.message)
  assert(require('Training.YingzhaoPolicyStore').loadLatestAsync('ninilite'));assert(saved()==before and E.wallet().available==balance)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/yingzhao-public-training.tga');D.sleep(.2)
  local observations=D.DB:query('SELECT COUNT(*) FROM lsd.Game0YingzhaoObservations')[1][1]
  controls():getChildByTag('training-menu'):getChildByTag('部位试战'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-trial-budget')end)
  D.Director.ui3D:getChildByTag('yingzhao-trial-budget').saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoCandidateId end)
  c=D.Platformer.Data.store.world.patrolLevel;assert(not c.battle.demonstrator and c.gather);c.start:emit('Tapped')
  wait(function()for _,step in ipairs(c.battle.bossTrace.steps)do if step.origin=='candidate'and step.emitted==1 then return true end end end)
  c.withdraw:emit('Tapped');wait(function()return c.phase=='result'end)
  assert(c.result.resultLayout=='MissionFail'and #c.battle.arena.recorder.samples==0)
  assert(D.DB:query('SELECT COUNT(*) FROM lsd.Game0YingzhaoObservations')[1][1]==observations)
  c.result.baseButton:emit('Tapped');wait(controls);assert(saved()==before and E.wallet().available==balance)
  r.candidateTrial=true
  r.cancelled=true;r.virtualResult=true;r.learned=true;r.walletUnchanged=true;r.adoptionUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
