-- Public withdrawal/result buttons on an isolated QA database. Navigation is
-- intercepted before loading a room; this checks routing, not a full journey.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/factory-result-navigation-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local source=prior.database
  local dest=D.Content.writablePath..'/factory-result-navigation-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(dest) and D.Content:copyAsync(source,dest))
  assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  require('Data.Config'):loadAsync()
  local function model(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  local resultView=require('Factory.ResultView');local create=resultView.create;r.createSeconds={}
  resultView.create=function(...)local start=D.App.elapsedTime;local view=create(...);r.createSeconds[#r.createSeconds+1]=D.App.elapsedTime-start;return view end
  local saveCalls=0
  local c=require('Factory.Level').openAsync({finishAsync=function()saveCalls=saveCalls+1;return true end},{mission='c0-m05',models={ninilite=model('ninilite','laser'),wuyun=model('wuyun','melee')}})
  D.sleep(.1);c.start:emit('Tapped');D.sleep(.2);c.withdraw:emit('Tapped')
  local deadline=D.App.totalTime+5;while not c.result do assert(D.App.totalTime<deadline,'Missing settlement');D.sleep(.05)end
  assert(c.battle.phase=='aborted' and saveCalls==1)
  assert(c.result.resultLayout=='MissionFail');r.withdrawLayout=c.result.resultLayout
  local navigation=require('Academy.Navigation');local original=navigation.returnToRoomAsync;local calls=0
  navigation.returnToRoomAsync=function(room,options)calls=calls+1;r.room=room;r.hasOptions=options~=nil end
  c.result.baseButton:emit('Tapped');c.result.againButton:emit('Tapped');D.sleep(.1)
  navigation.returnToRoomAsync=original
  assert(calls==1 and r.room=='TrainA' and not r.hasOptions,'Result routing or double-tap guard changed')
  r.saveCalls=saveCalls;r.navigationCalls=calls;r.withdrawal=true
  -- Win is a display-only fixture, not an earned gameplay result or saved reward.
  local view=require('Factory.ResultView').create({phase='won',reason=require('Factory.BattleText').victory,report=c.battle.report})
  c.result:removeFromParent();view:addTo(D.Director.ui3D);D.sleep(.1)
  assert(view.againButton and view.baseButton and view.resultLayout=='Settlement');r.winView=true
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/factory-result-win-fixture.tga');D.sleep(.1)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
