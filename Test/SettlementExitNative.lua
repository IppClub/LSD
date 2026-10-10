local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/settlement-exit-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local db=D.Content.writablePath..'/settlement-exit-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local models=assert(require('Training.FlowerQStore').loadAsync()).source.baseModels
  local service=assert(require('Mission.Service').open());assert(service:recoverAsync());assert(require('Story.Service').open())
  assert(D.DB:exec("INSERT OR IGNORE INTO lsd.Game0StoryNodes(id,completedAt) VALUES('ground-contact',0),('energy-plan',0)")>=0)
  local E=require('Economy.Store');assert(E.open());local L=require('Economy.Loadout');local values=L.defaults();for k in pairs(values)do values[k]=1 end;assert(L.saveAsync(values))
  local function wait(f)local deadline=D.App.runningTime+30;while not f()do assert(D.App.runningTime<deadline,'Settlement exit timed out');D.sleep(.05)end end
  for _,case in ipairs({{id='c0-m01',module='Mission.Level',withdraw='mission-withdraw',room='OperationRoom',text='返回指挥室',again='重新配装'},
   {id='c0-m02',module='Ground.Level',withdraw='ground-battle-withdraw',room='TrainA',text='返回列车',again='返回调查点'},
   {id='c0-m03',module='Ground.EnergyLevel',room='TrainA',text='返回列车'},
   {id='c0-m03',module='Ground.EnergyLevel',room='TrainA',text='返回列车',lethal=true}})do
   assert(service:saveFormationAsync({mentor=true,learner='ninilite',wuyun=case.id=='c0-m03'and true or nil}))
   local c;local before=E.wallet().available
   local support=require('Ground.LifeSupport').new(65,'defence');support.hp={100,100,100}
   local panel=assert(require('Economy.Preparation').openAsync(case.id,case.id=='c0-m03'and models or models.ninilite,nil,function(s,a)
    c=require(case.module).openAsync(s,a,case.id=='c0-m01'and 'charF'or support)
   end));panel.saveButton:emit('Tapped');wait(function()return c end)
   local b=c.battle;local oldWorld=b.arena.world
   if case.lethal then
    -- Controlled low-health fixture; damage still comes from the real attack.
    b.mentorHP=1;b.mentor.position=D.Vec2(b.central.enemy.x-120,b.arena.world.offset+155)
    b.central.studentHP=1;assert(b.central.enemyCombat:start('blow'))
   else local withdraw=c.withdraw or assert(D.Director.ui3D:getChildByTag(case.withdraw));withdraw:emit('Tapped')end
   wait(function()return c.result end)
   if b.partCombat and b.partCombat.view then
    assert(not b.partCombat.view.node.parent,'Boss combat HUD remains attached over settlement')
    assert(b.partCombat.view.closed and #b.partCombat.view.effects==0,'Boss HUD effects were not closed')
   end
   local v=c.result;assert(v.resultLayout=='MissionFail'and v.baseButton.children.last.text==case.text)
   assert(v.reportLabel.text:find(b.reason,1,true),'Missing outcome reason')
   if case.again then assert(v.againButton.visible and v.againButton.children.last.text==case.again)
   else assert(not v.againButton.visible and not v.againButton.touchEnabled)end
   assert(b.phase==(case.lethal and 'failed'or'aborted')and b.report.economy.income==0 and E.wallet().available==before-b.report.economy.cost and not E.active())
   if case.lethal then assert(b.mentorHP==0);r.failureScreenshot=D.Content.writablePath..'/energy-defeat-exit.tga';D.App:saveScreenshot(r.failureScreenshot);D.sleep(.2)end
   local balance=E.wallet().available;v.baseButton:emit('Tapped');v.baseButton:emit('Tapped')
   wait(function()local w=D.Platformer.Data.store.world;return w~=oldWorld and w.tag==case.room end)
   wait(function()return b.arena.closed end)
   assert(E.wallet().available==balance and not E.active());r.cases[#r.cases+1]={mission=case.id,outcome=b.phase,reason=b.reason,room=case.room,cost=b.report.economy.cost,button=case.text};save()
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
