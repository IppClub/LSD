local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/mission-supply-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/mission-supply-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local model=assert(require('Training.FlowerQStore').loadAsync()).source.baseModels.ninilite
  local service=assert(require('Mission.Service').open());assert(service:recoverAsync());assert(service:saveFormationAsync({mentor=true,learner='ninilite'}))
  local E=require('Economy.Store');assert(E.open());local before=E.wallet().available
  local cancelled=false;local panel=assert(require('Economy.Preparation').openAsync('c0-m01',model,function()cancelled=true end,function()error('Cancelled panel launched')end))
  assert(#panel.quote.lines==2);panel.closeButton:emit('Tapped');assert(cancelled and E.wallet().available==before and not E.active())
  local config=assert(require('Economy.Loadout').load());config['mentor:kinetic']=2;assert(require('Economy.Loadout').saveAsync(config))
  local c,attempt
  panel=assert(require('Economy.Preparation').openAsync('c0-m01',model,nil,function(s,a)attempt=a;c=require('Mission.Level').openAsync(s,a,'charF')end))
  panel.saveButton:emit('Tapped');local deadline=D.App.totalTime+25
  while not c do assert(D.App.totalTime<deadline);D.sleep(.05)end
  local b=c.battle;assert(b.supplies and b.arena.supplies==b.supplies and not b.supplies.isVirtual)
  while b.supplies:observation('mentor').ammo.kinetic>0 do
   assert(b.phase=='playing' and D.App.totalTime<deadline);b:command('shoot');D.sleep(.1)
  end
  assert(not b:command('shoot'));assert(b.supplies.ledger.stock['mentor:kinetic'].used==2)
  while b.supplies.ledger.stock['ninilite:emp'].used==0 do assert(b.phase=='playing' and D.App.totalTime<deadline);D.sleep(.1)end
  b:finish('aborted','QA withdrawal');while not c.result do assert(D.App.totalTime<deadline,b.saveError);D.sleep(.05)end
  assert(c.result.resultLayout=='MissionFail' and c.result.economy==b.report.economy)
  assert(b.report.economy.income==0 and b.report.economy.cost>=13 and E.wallet().available==before-b.report.economy.cost)
  local balance=E.wallet().available;assert(service:finishAsync(attempt,'aborted',b.report));assert(E.wallet().available==balance)
  r.withdrawal={cost=b.report.economy.cost,balance=balance,layout=c.result.resultLayout}
  -- Full two-wave run, without forced damage or overriding learner decisions.
  assert(require('Economy.Loadout').saveAsync(require('Economy.Loadout').defaults()));c=nil
  panel=assert(require('Economy.Preparation').openAsync('c0-m01',model,nil,function(s,a)attempt=a;c=require('Mission.Level').openAsync(s,a,'charF')end))
  panel.saveButton:emit('Tapped');deadline=D.App.totalTime+80
  while not c do assert(D.App.totalTime<deadline);D.sleep(.05)end
  local b=c.battle
  while b.phase=='playing' or b.phase=='saving'do
   assert(D.App.totalTime<deadline);b:command('shoot');b:command('repair');D.sleep(.1)
  end
  assert(b.phase=='won' or b.phase=='failed',b.saveError)
  while not c.result do assert(D.App.totalTime<deadline);D.sleep(.05)end
  local ledger=assert(E.load(attempt.supplyAttempt));assert(ledger.status==b.phase and b.arena.supplies==b.supplies)
  assert(E.wallet().available==balance+b.report.economy.net)
  r.natural={status=b.phase,wave=b.wave,seconds=b.report.seconds,cost=b.report.economy.cost,income=b.report.economy.income,net=b.report.economy.net,balance=E.wallet().available,layout=c.result.resultLayout}
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/mission-supply-result.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
