local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/optional-formal-cold-read-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/optional-formal-mission-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/optional%-formal%-mission%-%d+%.db$'))
  local dest=D.Content.writablePath..'/optional-formal-cold-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local service=assert(require('Mission.Service').open());assert(service:recoverAsync())
  assert(E.wallet().available==prior.balanceAfter and not E.active())
  local equal=require('Training.FlowerIdentity').equal;local values=assert(require('Economy.Loadout').load());assert(values['ninilite:emp']==8 and values['wuyun:emp']==0 and values['wuyun:blade']==0)
  for _,case in ipairs(prior.cases)do
   local ledger=assert(E.load(case.supplyAttempt));assert(ledger.status==case.status and equal(ledger.result,case.bill))
   local rows=assert(D.DB:query('SELECT status,report FROM lsd.Game0MissionAttempts WHERE id=?',{case.attempt}));assert(#rows==1 and rows[1][1]==case.status)
   local report=D.json.decode(rows[1][2],32);assert(equal(report.economy,case.bill)and report.reason==case.reason)
   local page=require('UI.Settlement')({missionMode=true,resultStatus=case.status=='won'and 'Complete'or'Failed',economy=report.economy,reportText=report.reason,missionTitle='警戒行动'})
   page:addTo(D.Director.ui3D);page:alignLayout();D.sleep(.1);assert(page.resultLayout==case.layout)
   if case.status=='failed'then assert(page.reportLabel.text:sub(1,#case.reason)==case.reason);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/optional-formal-failure-reason-first.tga');D.sleep(.15)end
   page:removeFromParent()
   assert(service:finishAsync({mission='c0-m01',id=case.attempt},case.status,report));assert(E.wallet().available==prior.balanceAfter)
  end
  r.balance=prior.balanceAfter;r.checks={'new process reloads zero quantities','both formal reports and bills preserved','no active reservation after recovery','dedicated results reconstruct from saved reports','repeated finish after restart cannot duplicate reward'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
