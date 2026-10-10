local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/optional-formal-mission-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/optional-formal-mission-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local model=assert(require('Training.FlowerQStore').loadAsync()).source.baseModels.ninilite
  local service=assert(require('Mission.Service').open());assert(service:recoverAsync());assert(service:saveFormationAsync({mentor=true,learner='ninilite'}))
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available;local L=require('Economy.Loadout')
  for _,quantity in ipairs({0,8})do
   local values=L.defaults();values['mentor:kinetic']=40;values['ninilite:emp']=quantity;values['wuyun:emp']=0;values['wuyun:blade']=0;assert(L.saveAsync(values))
   local c,attempt
   local panel=assert(require('Economy.Preparation').openAsync('c0-m01',model,nil,function(s,a)attempt=a;c=require('Mission.Level').openAsync(s,a,'charF')end))
   assert(panel.quote.total==(quantity==0 and 82 or 117));local before=E.wallet().available;local reserved=panel.quote.total
   panel.saveButton:emit('Tapped');local deadline=D.App.totalTime+90
   while not c do assert(D.App.totalTime<deadline);D.sleep(.02)end
   local b=c.battle;assert(b.supplies and not b.supplies.isVirtual and E.wallet().available==before-reserved)
   while b.phase=='playing' or b.phase=='saving'do assert(D.App.totalTime<deadline,b.saveError);b:command('shoot');b:command('repair');D.sleep(.1)end
   while not c.result do assert(D.App.totalTime<deadline,b.saveError);D.sleep(.02)end
   local ledger=assert(E.load(attempt.supplyAttempt));local bill=assert(ledger.result)
   assert(E.wallet().available==before+bill.net and not E.active())
   assert(bill.reserved==reserved and bill.refund==reserved-bill.cost)
   if quantity==0 then
    assert(b.phase=='failed' and b.reason:find('检查补给',1,true),b.reason)
    assert(not ledger.stock['ninilite:emp']and #bill.lines==1 and bill.income==0 and bill.net<0 and c.result.resultLayout=='MissionFail')
   else
    assert(b.phase=='won',b.reason);assert(c.result.resultLayout=='Settlement'and bill.income==100 and #bill.lines==2)
    assert(ledger.stock['ninilite:emp'].used>=4 and ledger.stock['ninilite:emp'].used<=8)
   end
   local balance=E.wallet().available;assert(service:finishAsync(attempt,b.phase,b.report));assert(E.wallet().available==balance)
   r.cases[#r.cases+1]={emp=quantity,status=b.phase,reason=b.reason,seconds=b.report.seconds,bill=bill,attempt=attempt.id,supplyAttempt=attempt.supplyAttempt,layout=c.result.resultLayout,balance=balance};save()
   D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/optional-formal-'..quantity..'.tga');D.sleep(.1)
   b.arena.closed=true;b.arena.world:removeFromParent();c.result:removeFromParent()
  end
  r.balanceAfter=E.wallet().available;r.checks={'real budget confirmation reserves supplies','unprovisioned learner fails with supply guidance','failure has no reward and negative return','lean ammunition completes both waves','dedicated success and failure pages','refund and wallet match bills','duplicate settlement does not pay twice'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
