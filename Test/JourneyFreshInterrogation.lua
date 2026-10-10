-- Command-driven native public-route QA, using a copy of an earned capture save.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/fresh-interrogation-route-result.json')
local function save()D.Content:save(out,D.json.encode(report))end
save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-researcher-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fresh%-researcher%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fresh-interrogation-route-qa-'..run..'.db')
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Interrogation route stalled');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local world=D.Platformer.Data.store.world;local route=world.infiltration
  local service=assert(require('Story.Service').open());assert(route.capture.caught and not service:summary().completed['researcher-interrogation'])
  local accepted,why=service:completeAsync('researcher-interrogation','Factory',false,{})
  assert(not accepted and why=='INTERROGATION_PRESENTATION_REQUIRED')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_interrogation BEFORE INSERT ON Game0StoryNodes WHEN NEW.id='researcher-interrogation' BEGIN SELECT RAISE(ABORT,'QA interrogation');END")>=0)
  route.menu:emit('Tapped',1)
  wait(function()return world.storyFlow and world.storyFlow.id=='researcher-interrogation'end)
  local actors=world.interrogation.actors;assert(actors.fox.motionVariant=='spine-corrected')
  local warningChecked=false
  local flow=world.storyFlow;local deadline=D.App.runningTime+100
  while flow.phase~='save-error' and flow.phase~='complete' do
   assert(D.App.runningTime<deadline,'Dialogue or command stalled')
   if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit('Tapped')end
   if actors.threat.active and actors.threat.frames>2 then
    assert(actors.threat.patch.visible and actors.fox.speed==1)
    local anchor=actors.fox:getKey('mouthCenter/mouthCenter')
    assert((actors.threat.patch.position-anchor).length<3,'Fang patch detached from animated mouth')
    if not warningChecked then D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/fresh-interrogation-fox-warning.tga'));warningChecked=true end
   end
   D.sleep(.09)
  end
  assert(warningChecked and not actors.threat.active,'Fox warning did not finish')
  report.correctedFox=true;report.animatedFangAnchor=true
  assert(flow.phase=='save-error','Save failure was not shown')
  assert(#flow.view._reviews==12,'Original twelve rows not shown')
  assert(not service:summary().completed['researcher-interrogation'])
  assert(#D.DB:query("SELECT node FROM lsd.Game0StoryPerformances WHERE node='researcher-interrogation'")==0)
  report.proof=world.interrogation.report;assert(require('Story.InterrogationProof').validate(report.proof))
  assert(D.DB:exec('DROP TRIGGER lsd.fail_interrogation')>=0);flow.retryButton:emit('Tapped');wait(function()return flow.phase=='complete'end)
  assert(service:summary().completed['researcher-interrogation']);assert(route.researcher.current=='unconscious')
  local records=D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='researcher-interrogation'");assert(#records==1)
  assert(service:summary().objective:find('第七层'))
  assert(require('Story.SecondPatrolStore').open(),'Second patrol unavailable after interrogation')
  for name,value in pairs(snapshot)do if name~='Game0StoryNodes' and name~='Game0StoryUnlocks' and name~='Game0StoryPerformances'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  D.Content:save(D.Path(root,'Test/fresh-interrogation-resume-fixture.txt'),db)
  report.database=db;report.rows=12;report.saveFailureRetry=true;report.atomicProof=true;report.priorTablesPreserved=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 save();print(D.json.encode(report))
end)
