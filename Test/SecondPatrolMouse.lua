-- Real OS input only: prepares an earned interrogation copy and observes completion.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=true};local out=D.Path(root,'Test/second-patrol-mouse-result.json')
local function save()D.Content:save(out,D.json.encode(report))end
save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/interrogation-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-interrogation%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-second-patrol-mouse-qa-'..run..'.db')
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Interrogation route stalled');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local world=D.Platformer.Data.store.world;local route=world.infiltration
  assert(route.interrogated and not route.second.completed)
  report.database=db;report.status='READY';save()
  wait(function()return route.battleLevel end,240)
  local level=route.battleLevel;local b=level.battle
  assert(not b.wuyun and #b.learners==1 and not level.wind.visible)
  wait(function()return level.phase=='result' or level.phase=='save-error'end,240)
  report.battle=b.report;save();assert(b.phase=='won',b.reason)
  assert(level.phase=='result' and level.checkpointSaved)
  assert(assert(route.secondStore:load()).completed)
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  report.wuyunAbsent=true;report.priorTablesPreserved=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 save();print(D.json.encode(report))
end)
