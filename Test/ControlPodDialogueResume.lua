-- Loads the last earned control-pod checkpoint in a QA copy without replaying travel or audio.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/control-pod-dialogue-resume-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/control-pod-dialogue-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and (D.Path:getFilename(source):match('^lsd%-control%-pod%-dialogue%-qa%-%d+%.db$')or D.Path:getFilename(source):match('^lsd%-control%-pod%-mouse%-qa%-%d+%.db$')))
  local db=D.Path(D.Content.writablePath,'lsd-control-pod-dialogue-resume-qa-'..run..'.db');report.database=db;report.source=source
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local store=assert(require('Story.ControlPodStore').open());local before=assert(store:load());assert(before.active)
  require('Start');local deadline=D.App.runningTime+40
  while not(D.Platformer.Data.store.world and D.Platformer.Data.store.world.controlPod and D.Platformer.Data.store.world.controlPod.phase=='ready')do assert(D.App.runningTime<deadline,'Control pod resume stalled');D.sleep(.03)end
  local c=D.Platformer.Data.store.world.controlPod
  assert(c.floor==before.floor and c.state.doorOpen==before.doorOpen and not c.sound and not c.lastTraversal and not c.lastDoor)
  if before.doorOpen then assert(not c.barrier and math.abs(c.art.door.angleY+105)<.1)else assert(c.barrier)end
  D.sleep(.05) -- The native broadphase updates after scene construction.
  assert(c.dialogueComplete and #c.researchers==3 and not c.world.storyFlow)
  local hit=false;local y=require('Factory.ControlPodGeometry').floorY(c.floor)
  c.world:raycast(D.Vec2(500,y+20),D.Vec2(500,y-40),false,function(body)if body==c.art.floorBody then hit=true;return true end;return false end);assert(hit,'Landing has no native collision')
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  report.status='PASS';report.floor=c.floor;report.doorOpen=c.state.doorOpen;report.noReplay=true;report.landingCollision=true;report.allTablesPreserved=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
