local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/pursuit-supply-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/pursuit-supply-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local service=assert(require('Mission.Service').open());assert(service:recoverAsync());assert(require('Story.Service').open())
  assert(D.DB:exec("INSERT OR IGNORE INTO lsd.Game0StoryNodes(id,completedAt) VALUES('ruins-ambush',0),('ayan-recovery',0)")>=0)
  assert(service:saveFormationAsync({mentor=true,learner='ninilite',wuyun=true}))
  local L=require('Economy.Loadout');local values=L.defaults();values['mentor:kinetic']=2;values['mentor:smoke']=0;values['mentor:flare']=0;assert(L.saveAsync(values))
  local E=require('Economy.Store');assert(E.open());local balance=E.wallet().available
  local c,attempt;local panel=assert(require('Economy.Preparation').openAsync('c0-m06',nil,nil,function(s,a)attempt=a;c=require('Ruins.PursuitLevel').openAsync(s,a)end))
  assert(#panel.quote.lines==1 and panel.quote.total==6,'Noncombat companions charged')
  panel.saveButton:emit('Tapped');local deadline=D.App.totalTime+30
  while not c do assert(D.App.totalTime<deadline);D.sleep(.05)end
  local b=c.battle;assert(b.supplies)
  while b.supplies.ledger.stock['mentor:kinetic'].remaining>0 do
   assert(b.phase=='playing' and D.App.totalTime<deadline);b:command('shoot');D.sleep(.1)
  end
  assert(not b:command('shoot'));c.withdraw:emit('Tapped')
  while not c.result do assert(D.App.totalTime<deadline,b.saveError);D.sleep(.05)end
  assert(c.result.resultLayout=='MissionFail' and b.report.economy.cost==6 and E.wallet().available==balance-6)
  c.result.againButton:emit('Tapped');while not c.supplyPanel do assert(D.App.totalTime<deadline);D.sleep(.05)end
  assert(not E.active(),'Retry bypassed budget confirmation');c.supplyPanel.closeButton:emit('Tapped');assert(c.supplyPanel==nil and E.wallet().available==balance-6)
  assert(service:finishAsync(attempt,'aborted',b.report));assert(E.wallet().available==balance-6)
  require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=8500,energySquad=true,ruinsSearch=true})
  local world=D.Platformer.Data.store.world;local entry=assert(require('Ruins.Return').openAsync(world))
  deadline=D.App.totalTime+15;while not entry.supplyPanel do assert(D.App.totalTime<deadline,entry.error);D.sleep(.05)end
  assert(world.data.storyBusy and not E.active());entry.supplyPanel.closeButton:emit('Tapped')
  assert(entry.phase=='ready' and not world.data.storyBusy and not entry.supplyPanel)
  r.cost=b.report.economy.cost;r.checks={'mentor-only quote despite saved full formation','two actual shots and empty gate','dedicated failure ledger','retry requires budget','cancel no reserve','idempotent settlement','return-route budget cancellation restores exploration'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
