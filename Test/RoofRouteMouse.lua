-- Observe genuine OS input through the normal control-pod entry and roof HUD.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=true};local out=D.Path(root,'Test/roof-route-mouse-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/control-pod-dialogue-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-control%-pod%-dialogue%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-roof-mouse-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  require('Start');local deadline=D.App.runningTime+900;local seenPod=false;local roof
  while true do
   assert(D.App.runningTime<deadline,'OS route observation timed out');local w=D.Platformer.Data.store.world
   if w and w.controlPod then seenPod=true end
   if w and w.roof then roof=w.roof;if roof.stage==2 and roof.phase=='ready' then break end end
   D.sleep(.1)
  end
  assert(seenPod and roof.lastStairs and roof.lastClimb and #roof.lastClimb.actors==2,'Route was not earned through current session')
  D.sleep(1);assert(roof:landingCollision(roof.player) and roof:landingCollision(roof.nini))
  for name,value in pairs(snapshot)do if name~='Game0ControlPod'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  report.status='PASS';report.controlPodEntry=true;report.stage=2;report.stairs=roof.lastStairs;report.climb=roof.lastClimb;report.priorTablesPreserved=true
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-route-os-landed.tga'))
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
