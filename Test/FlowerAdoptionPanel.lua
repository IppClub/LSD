-- Native player review/rollback workflow, using disposable real QA archives.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-adoption-panel-result.json'
D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-target-demo-result.json'),32))
  assert(prior.status=='PASS' and D.Path:getFilename(prior.database):match('^flower%-target%-demo%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-adoption-panel-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local Store=require('Training.FlowerAdoptionStore');local Practice=require('Training.FlowerPractice')
  local function unchanged()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0FlowerCandidates'),D.DB:query('SELECT * FROM lsd.Game0FlowerPractice'),D.DB:query('SELECT * FROM lsd.Game0FlowerTrials'),D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=unchanged();D.App.winSize=D.Size(1000,750)
  local c=Practice.openAsync(nil,'ninilite');D.sleep(.4);assert(c.adoptionButton.visible)
  c.adoptionButton:emit('Tapped');D.sleep(.1);local panel=assert(c.adoptionView)
  assert(not panel.ready and not panel.adopt.visible and not c.hud.visible)
  assert(not c:start() and not c:learnAsync('latest'))
  panel.adopt:emit('Tapped');assert(not Store.inspect('ninilite'))
  for i=1,4 do panel.next:emit('Tapped')end
  assert(panel.page==4 and panel.label.text:find('候选：失败') and not panel.adopt.visible)
  assert(panel.label.text:find('队伍承伤') and panel.label.text:find('破甲协作') and panel.label.text:find('误伤'))
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-adoption-panel-field.tga');D.sleep(.2)
  panel.back:emit('Tapped');D.sleep(.1);assert(panel.closed and not c.adoptionView and c.hud.visible)
  assert(unchanged()==before);r.failedCandidateBlocked=true;r.navigationReadOnly=true;r.backgroundInputBlocked=true
  -- Import an actual old adoption only to verify recovery, never to claim a
  -- valid current-rule adoption. The previous 1:2 boss evaluation cannot deploy.
  assert(load(D.Content:load(root..'/Test/Fixtures/FlowerLegacyAdoption.lua')))()('/private/tmp/lsd-shan-1791135078/save/flower-adoption-store-1791155684.db')
  local archived=assert(Store.inspect('ninilite'));assert(archived.id==1 and archived.parent==0)
  local ok,why=Store.rollbackAsync('ninilite',999);assert(not ok and why=='ADOPTION_STATE_CHANGED' and Store.inspect('ninilite').id==1)
  c.adoptionButton:emit('Tapped');panel=assert(c.adoptionView)
  assert(panel.current.id==1 and panel.deploymentError=='ENCOUNTER_CHANGED' and panel.rollback.visible)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-adoption-panel-legacy.tga');D.sleep(.2)
  panel.rollback:emit('Tapped');assert(panel.rollbackPending and panel.confirmRollback.visible and Store.inspect('ninilite').id==1)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_panel_rollback BEFORE UPDATE ON Game0FlowerAdoptionState BEGIN SELECT RAISE(ABORT,'QA rollback'); END")>=0)
  local function wait(fn)local untilAt=D.App.totalTime+10;while not fn()do assert(D.App.totalTime<untilAt,'Panel wait timeout');D.sleep(.02)end end
  panel.confirmRollback:emit('Tapped');panel.back:emit('Tapped');assert(not panel.closed)
  wait(function()return not panel.busy end);assert(panel.error=='WRITE_FAILED' and panel.current.id==1 and panel.confirmRollback.visible)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_panel_rollback')>=0)
  panel.confirmRollback:emit('Tapped');wait(function()return not panel.busy end)
  assert(panel.message=='已恢复基础成果。' and not panel.current and not panel.rollback.visible)
  panel.back:emit('Tapped');c.adoptionButton:emit('Tapped');panel=assert(c.adoptionView)
  assert(not panel.current and panel.currentError=='NOT_ADOPTED' and not panel.rollback.visible)
  panel.back:emit('Tapped');assert(unchanged()==before)
  assert(#D.DB:query('SELECT id FROM lsd.Game0FlowerAdoptions')==1,'Rollback erased history')
  r.rollbackAtomic=true;r.staleRollbackRejected=true;r.legacyRecovery=true;r.reopened=true;r.historyPreserved=true
  -- The second learner has an independent review even without a candidate.
  c=Practice.openAsync(nil,'wuyun');D.sleep(.3);c.adoptionButton:emit('Tapped');panel=assert(c.adoptionView)
  assert(not panel.ready and not panel.current and not panel.adopt.visible and panel.label.text:find('乌云'))
  panel.back:emit('Tapped');r.characterIsolation=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
