-- Real OS input only: prepares an earned capture copy and observes completion.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=true};local out=D.Path(root,'Test/interrogation-mouse-result.json')
local function save()D.Content:save(out,D.json.encode(report))end
save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/researcher-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-researcher%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-interrogation-mouse-qa-'..run..'.db')
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Interrogation route stalled');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local world=D.Platformer.Data.store.world;local route=world.infiltration
  local service=assert(require('Story.Service').open());assert(route.capture.caught and not service:summary().completed['researcher-interrogation'])
  report.status='READY';save()
  wait(function()return service:summary().completed['researcher-interrogation'] and world.storyFlow and world.storyFlow.phase=='complete'end,240)
  local flow=world.storyFlow;assert(flow and flow.id=='researcher-interrogation' and flow.phase=='complete')
  assert(#flow.view._reviews==12)
  report.proof=world.interrogation.report;assert(require('Story.InterrogationProof').validate(report.proof))
  assert((route.researcher.current=='unconscious' or route.researcher.lastCompleted=='unconscious'));assert(math.abs(route.fox.x-route.researcher.x)>350)
  for name,value in pairs(snapshot)do if name~='Game0StoryNodes' and name~='Game0StoryUnlocks' and name~='Game0StoryPerformances'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  report.database=db;report.rows=12;report.atomicProof=true;report.priorTablesPreserved=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 save();print(D.json.encode(report))
end)
