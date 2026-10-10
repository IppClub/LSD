local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/pursuit-consumable-fault-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/pursuit-supply-victory-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/pursuit%-supply%-%d+%.db$'))
  local dest=D.Content.writablePath..'/pursuit-consumable-fault-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local L=require('Economy.Loadout');local values=L.defaults();values['mentor:smoke']=nil;values['mentor:flare']=nil
  assert(L.saveAsync(values));local loaded=assert(L.load());assert(loaded['mentor:smoke']==2 and loaded['mentor:flare']==2)
  assert(L.quote(loaded,{learner='ninilite',wuyun=true}).total==293)
  loaded['mentor:kinetic']=1;loaded['mentor:smoke']=1;loaded['mentor:flare']=0;assert(L.saveAsync(loaded))
  local c;local panel=assert(require('Economy.Preparation').openAsync('c0-m06',nil,nil,function(s,a)c=require('Ruins.PursuitLevel').openAsync(s,a)end))
  assert(#panel.buttons==3 and #panel.quote.lines==2 and panel.quote.total==10)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/pursuit-consumable-budget.tga');D.sleep(.2)
  panel.saveButton:emit('Tapped');local deadline=D.App.totalTime+30
  while not c do assert(D.App.totalTime<deadline);D.sleep(.05)end
  local b=c.battle;assert(not b:command('flare'))
  assert(D.DB:exec("CREATE TRIGGER lsd.FailTool BEFORE UPDATE ON Game0SupplyAttempts BEGIN SELECT RAISE(ABORT,'tool fault'); END")>=0)
  while not b:command('smoke')do assert(D.App.totalTime<deadline);D.sleep(.05)end
  while not (b.lastTool and b.lastTool.completed)do assert(D.App.totalTime<deadline);D.sleep(.05)end
  assert(b.lastTool.attempted and not b.lastTool.released and b.toolUses.smoke==0 and #b.smoke==0 and b.supplies.ledger.spent==2)
  assert(D.DB:exec('DROP TRIGGER lsd.FailTool')>=0)
  while not b:command('smoke')do assert(D.App.totalTime<deadline);D.sleep(.05)end
  while b.toolUses.smoke==0 do assert(D.App.totalTime<deadline);D.sleep(.05)end
  assert(b.supplies.ledger.spent==8 and b.supplies.ledger.stock['mentor:smoke'].remaining==0 and not b:command('smoke'))
  c.withdraw:emit('Tapped');while not c.result do assert(D.App.totalTime<deadline,b.saveError);D.sleep(.05)end
  assert(b.report.economy.cost==8 and b.report.economy.refund==2 and #b.report.economy.lines==2)
  r.checks={'legacy four-slot config readable','factory budget unchanged','zero tool quantity omitted','three-slot mission UI','save failure prevents smoke effect','retry consumes one unit','empty tool refused','unused bullet refunded'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
