local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/fresh-wuyun-departure-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-roof-exit-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fresh%-roof%-aftermath%-exit%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fresh-wuyun-departure-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Resume timeout');D.sleep(.03)end end
  local availability=require('Story.Availability');local allowed,reason=availability.canDeploy('wuyun');assert(not allowed and reason=='CHARACTER_DEPARTED')
  local service=assert(require('Mission.Service').open());assert(not assert(service:formation()).wuyun)
  local formation={mentor=true,learner='ninilite',wuyun=true}
  local saved,why=service:saveFormationAsync(formation);assert(not saved and why=='CHARACTER_DEPARTED')
  local attempt,e=service:beginAsync('c0-m03',{},formation);assert(not attempt and e=='CHARACTER_DEPARTED');report.deploymentRejected=true
  local progress=require('Training.Progress').forCharacter('wuyun');assert(progress.load());assert(progress.adopted and progress.adopted.sampleCount>0);report.samples=progress.adopted.sampleCount
  report.scenes={}
  local nav=require('Academy.Navigation')
  for _,name in ipairs({'RestRoom','Station','Factory','AbandonedCity'})do
   local w=nav.returnToRoomAsync(name,{energySquad=true});D.sleep(.6)
   assert(not D.Group({'name','unit'}):find(function(e)return e.name=='wuyun'and e.unit.world==w end),'Departed Wuyun spawned in '..name)
   report.scenes[#report.scenes+1]=name
  end
  local w=nav.returnToRoomAsync('TrainA');local deployment=assert(require('Ground.Deployment').openAsync(w,'Ruins'));assert(not deployment.formation.wuyun)
  deployment.view.secondCard:emit('Tapped');D.sleep(.2);assert(not deployment.formation.wuyun)
  deployment.view.startButton:emit('Tapped');D.sleep(.2);assert(deployment.phase=='briefing'and D.Platformer.Data.store.world==w)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/fresh-wuyun-departure-formation.tga'));report.publicDeploymentBlocked=true
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Departure changed '..name)end
  report.allTablesPreserved=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
