-- Real OS input only: prepares an earned interrogation copy and observes completion.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=true};local out=D.Path(root,'Test/fresh-control-pod-key-result.json')
local function save()D.Content:save(out,D.json.encode(report))end
save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-second-patrol-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fresh%-second%-patrol%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fresh-control-pod-key-qa-'..run..'.db')
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Control pod observation timed out');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local world=D.Platformer.Data.store.world;local route=world.infiltration
  assert(route.second.completed)
  report.database=db;report.status='READY';save()
  wait(function()local w=D.Platformer.Data.store.world;return w and w.controlPod and w.controlPod.phase=='ready'end,240)
  local c=D.Platformer.Data.store.world.controlPod
  wait(function()return c.floor==2 and c.phase=='ready'end,120)
  report.up=true;save()
  wait(function()return c.floor==1 and c.phase=='ready'end,120)
  report.down=true;report.status='PASS';report.shortKeyEvents=true

 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 save();print(D.json.encode(report))
end)
