-- Loads the last earned control-pod checkpoint in a QA copy without replaying travel or audio.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/fresh-control-pod-dialogue-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-control-pod-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and (D.Path:getFilename(source):match('^lsd%-fresh%-control%-pod%-route%-qa%-%d+%.db$')or D.Path:getFilename(source):match('^lsd%-fresh%-control%-pod%-mouse%-qa%-%d+%.db$')))
  local db=D.Path(D.Content.writablePath,'lsd-fresh-control-pod-dialogue-qa-'..run..'.db');report.database=db;report.source=source
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local store=assert(require('Story.ControlPodStore').open());local before=assert(store:load());assert(before.active)
  require('Start');local deadline=D.App.runningTime+40
  while not(D.Platformer.Data.store.world and D.Platformer.Data.store.world.controlPod and D.Platformer.Data.store.world.controlPod.phase=='ready')do assert(D.App.runningTime<deadline,'Control pod resume stalled');D.sleep(.03)end
  local c=D.Platformer.Data.store.world.controlPod
  assert(c.floor==before.floor and c.state.doorOpen==before.doorOpen and not c.sound and not c.lastTraversal and not c.lastDoor)
  if before.doorOpen then assert(not c.barrier and math.abs(c.art.door.angleY+105)<.1)else assert(c.barrier)end
  assert(c.state.doorOpen and #c.researchers==3)
  local story=assert(require('Story.Service').open())
  local rejected,why=story:completeAsync('control-pod-researchers','ControlPod',false,{})
  assert(not rejected and why=='CONTROL_POD_DIALOGUE_REQUIRED')
  local function wait(f,t)local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Control pod dialogue stalled');D.sleep(.02)end end
  c.hud.move:emit('Right',true);wait(function()return c.player.unit.x>=2190 end,12);c.hud.move:emit('Right',false)
  wait(function()return c.fox.animation=='idle'end,8)
  local moved=c.player.unit.x;assert(moved>=2150)
  local captured=false;local observer=D.Node();observer:addTo(c.world);observer:schedule(function()local stage=c.world.controlPodDialogue;if stage and stage.threat and stage.threat.active and stage.threat.frames>10 and not captured then captured=true;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/fresh-control-pod-fox-warning.tga'))end;return captured end)
  assert(c:openDoor());wait(function()return c.world.storyFlow and c.world.storyFlow.view.visible end)
  local flow=c.world.storyFlow;local view=flow.view
  assert(flow.id=='control-pod-researchers' and c.phase=='dialogue')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_control_dialogue BEFORE INSERT ON Game0StoryNodes WHEN NEW.id='control-pod-researchers' BEGIN SELECT RAISE(FAIL,'qa injected save failure'); END")>=0)
  local dialogueDeadline=D.App.runningTime+90
  while flow.phase=='dialogue' do
   assert(D.App.runningTime<dialogueDeadline,'Dialogue did not advance')
   if not view._advancing then view.confirm:emit('Tapped')end
   D.sleep(.05)
  end
  wait(function()return flow.phase=='save-error'end)
  assert(#view._reviews==29 and not story:summary().completed['control-pod-researchers'])
  assert(#D.DB:query("SELECT * FROM lsd.Game0StoryPerformances WHERE node='control-pod-researchers'")==0)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_control_dialogue')>=0);flow.retryButton:emit('Tapped');wait(function()return flow.phase=='complete'end)
  assert(c.dialogueComplete and c.phase=='ready')
  local proof=assert(D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='control-pod-researchers'"))[1][1]
  assert(require('Story.ControlPodDialogueProof').validate(D.json.decode(proof)))
  local again,why=story:completeAsync('control-pod-researchers','ControlPod',true);assert(again,why)
  assert(D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='control-pod-researchers'")[1][1]==proof)
  local replay=assert(require('Story.Flow').openAsync('control-pod-researchers',c.world,nil,true))
  local replayDeadline=D.App.runningTime+90
  while replay.phase=='dialogue' or replay.phase=='saving' do
   assert(D.App.runningTime<replayDeadline,'Replay stalled')
   if replay.phase=='dialogue' and not replay.view._advancing then replay.view.confirm:emit('Tapped')end;D.sleep(.05)
  end
  assert(replay.phase=='complete' and #replay.view._reviews==29)
  assert(D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='control-pod-researchers'")[1][1]==proof)
  assert(captured,'Animated fox warning was not observed')
  report.originalUIReplay=true
  for name,value in pairs(snapshot)do
   if name~='Game0StoryNodes' and name~='Game0StoryUnlocks' and name~='Game0StoryPerformances' then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  end
  report.status='PASS';report.rows=#view._reviews;report.threeResearchers=true;report.physicalApproach=moved;report.saveFailureRetry=true;report.idempotentProof=true;report.priorTablesPreserved=true;report.proof=D.json.decode(proof)
  D.Content:save(D.Path(root,'Test/fresh-control-pod-dialogue-resume-fixture.txt'),db)
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
