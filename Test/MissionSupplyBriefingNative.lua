local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/mission-supply-briefing-result.json';local r={status='RUNNING',osInput=false}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-single-package-opening-scripted-20261007/result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+%.db$'))
  local dest=D.Content.writablePath..'/mission-supply-briefing-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local balance=E.wallet().available
  local c=assert(require('Mission.Briefing').openAsync());assert(c.mission=='c0-m01')
  c.view.startButton:emit('Tapped');local deadline=D.App.totalTime+20
  while not c.supplyPanel do assert(D.App.totalTime<deadline);D.sleep(.02)end
  c.supplyPanel.closeButton:emit('Tapped');D.sleep(.1);assert(c.phase=='briefing' and c.view.visible and not E.active() and E.wallet().available==balance)
  assert(c.supplyPanel==nil);c.view.startButton:emit('Tapped')
  while not c.supplyPanel do assert(D.App.totalTime<deadline);D.sleep(.02)end
  c.supplyPanel.saveButton:emit('Tapped')
  while not c.level do assert(D.App.totalTime<deadline);D.sleep(.02)end
  assert(c.phase=='battle' and c.level.battle.supplies)
  local b=c.level.battle;b:finish('aborted','Briefing entry QA')
  while not c.level.result do assert(D.App.totalTime<deadline,b.saveError);D.sleep(.02)end
  assert(c.level.result.resultLayout=='MissionFail' and b.report.economy.cost==5 and E.wallet().available==balance-5)
  local level=c.level;local result=level.result;local after=E.wallet().available;local originalReport=result.reportLabel.text
  -- Real read failure from an incompatible schema in this isolated database.
  assert(D.DB:exec('UPDATE lsd.Game0MissionMeta SET schemaVersion=2 WHERE id=1')>=0)
  result.againButton:emit('Tapped');result.againButton:emit('Tapped');deadline=D.App.totalTime+30
  while not level.retryError do assert(D.App.totalTime<deadline);D.sleep(.02)end
  assert(level.retryError=='INCOMPATIBLE_MISSION_SAVE'and result.parent and result.reportLabel.text:find('请重试',1,true))
  assert(result.reportLabel.text:find(originalReport,1,true),'Retry error discarded the settled report')
  result.reportButton:emit('Tapped');D.sleep(.2);assert(result.reportPanel.label==result.reportLabel and result.reportLabel.text:find('请重试',1,true));result.reportPanel.backButton:emit('Tapped');assert(result.visible and not result.reportPanel)
  assert(E.wallet().available==after and not E.active())
  assert(D.DB:exec('UPDATE lsd.Game0MissionMeta SET schemaVersion=1 WHERE id=1')>=0)
  result.againButton:emit('Tapped');result.againButton:emit('Tapped')
  local briefing
  while not briefing do briefing=D.Director.ui3D:getChildByTag('mission-briefing');assert(D.App.totalTime<deadline);D.sleep(.02)end
  local nextRun=assert(briefing.controller);assert(not level.retryError and nextRun.phase=='briefing')
  nextRun.view.startButton:emit('Tapped')
  while not nextRun.supplyPanel do assert(D.App.totalTime<deadline);D.sleep(.02)end
  assert(E.wallet().available==after and not E.active())
  nextRun.supplyPanel.saveButton:emit('Tapped')
  while not nextRun.level do assert(D.App.totalTime<deadline);D.sleep(.02)end
  assert(E.active()and nextRun.level.battle.attempt.id~=b.attempt.id)
  D.Director.ui3D:getChildByTag('mission-withdraw'):emit('Tapped')
  while not nextRun.level.result do assert(D.App.totalTime<deadline);D.sleep(.02)end
  assert(not E.active()and E.wallet().available==after-nextRun.level.battle.report.economy.cost)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/mission-supply-briefing.tga');D.sleep(.2)
  r.checks={'formation start opens real budget','cancel restores formation without reservation','confirmation launches charged mission','withdrawal uses dedicated failure result','failed reconfiguration remains retryable','reconfiguration after recovery launches a distinct paid attempt','duplicate clicks do not duplicate charge'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
