local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/final-supply-entry-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local source=D.Content:load(root..'/Test/jade-distance-resume-fixture.txt');assert(source:match('^/Users/Jin/Workspace/Dora/lsd%-jade%-distance%-qa%-%d+%.db$'))
  local dest=D.Content.writablePath..'/final-supply-entry-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local service=assert(require('Mission.Service').open());assert(service:recoverAsync());assert(require('Story.Service').open())
  assert(D.DB:exec("INSERT OR IGNORE INTO lsd.Game0StoryNodes(id,completedAt) VALUES('jade-distance',0)")>=0)
  local progress=require('Training.Progress');assert(progress.load()and progress.adopted)
  assert(service:saveFormationAsync({mentor=true,learner='ninilite'}))
  local L=require('Economy.Loadout');local values=L.defaults();values['mentor:kinetic']=2;values['ninilite:emp']=2;assert(L.saveAsync(values))
  local E=require('Economy.Store');assert(E.open());local balance=E.wallet().available
  local world=require('Academy.Navigation').returnToRoomAsync('RDRoom')
  D.sleep(.5)
  local gate=assert(world.finalGate,'Missing gate: '..D.json.encode(require('Story.Service').open():summary()));local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end),'Missing player')
  local deadline=D.App.totalTime+60;D.sleep(.5)
  local hud;for i=1,D.Director.ui3D.children.count do local n=D.Director.ui3D.children:get(i);if n.move then hud=n;break end end
  assert(hud);hud.move:emit('Right',true);while p.unit.x<gate.marker.x-120 do assert(D.App.totalTime<deadline);D.sleep(.03)end;hud.move:emit('Right',false);D.sleep(.1)
  assert(gate:request());gate.buttons.mobility:emit('Tapped');gate.view.startButton:emit('Tapped');while not gate.supplyPanel do assert(D.App.totalTime<deadline);D.sleep(.05)end
  local panel=gate.supplyPanel;assert(p.busy and world.data.journalOpen and panel.quote.total==17)
  panel.closeButton:emit('Tapped');D.sleep(.1)
  assert(gate.phase=='briefing' and gate.view.visible and not gate.supplyPanel and E.wallet().available==balance and not E.active())
  gate.view.backButton:emit('Tapped');assert(gate.phase=='ready'and not world.data.journalOpen)
  assert(gate:request());gate.view.startButton:emit('Tapped');while not gate.supplyPanel do assert(D.App.totalTime<deadline);D.sleep(.05)end;panel=gate.supplyPanel;panel.saveButton:emit('Tapped');while not gate.level do assert(D.App.totalTime<deadline);D.sleep(.05)end
  local c=gate.level;local b=c.battle;c.start:emit('Tapped')
  while b.supplies.ledger.stock['mentor:kinetic'].remaining>0 do assert(D.App.totalTime<deadline);b:command('shoot');D.sleep(.1)end
  assert(not b:command('shoot'));c.withdraw:emit('Tapped');while not c.result do assert(D.App.totalTime<deadline);D.sleep(.05)end
  assert(c.result.resultLayout=='MissionFail' and c.result.economy==b.report.economy and b.report.economy.income==0)
  local after=E.wallet().available;assert(after==balance-b.report.economy.cost)
  assert(service:finishAsync(c.attempt,'aborted',b.report));assert(E.wallet().available==after)
  c.result.againButton:emit('Tapped');while not c.supplyPanel do assert(D.App.totalTime<deadline);D.sleep(.05)end
  assert(not E.active());c.supplyPanel.closeButton:emit('Tapped');D.sleep(.1);assert(not c.leaving and not c.supplyPanel and not E.active()and E.wallet().available==after)
  r.cost=b.report.economy.cost;r.checks={'real corridor budget','cancel restores movement and no reservation','real emission and empty gate','dedicated failure bill','idempotent settlement','retry budget and cancellation'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
