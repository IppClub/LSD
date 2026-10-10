-- Native battle integration against an earned model; no story victory is inserted.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/academy-defense-interrupted-resume-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/academy-defense-interrupt-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-academy%-defense%-interrupt%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-academy-defense-interrupted-resume-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true)end
  local before=assert(D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE mission='c0-m07'AND status='active'")[1]);require('Start')
  local deadline=D.App.runningTime+35
  while not(D.Platformer.Data.store.world and D.Platformer.Data.store.world.tag=='PassageA'and D.Platformer.Data.store.world.defenseGate)do assert(D.App.runningTime<deadline,'Interrupted resume stalled');D.sleep(.02)end
  local world=D.Platformer.Data.store.world;assert(not world.defenseBattle and not world.patrolLevel)
  assert(D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=?',{before[1]})[1][1]=='aborted')
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='academy-defense-complete'")==0)
  for name,snapshot in pairs(snapshots)do if name~='Game0MissionAttempts'then assert(snapshot==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  result.status='PASS';result.attempt=before[1];result.recoveredToGate=true;result.noFalseVictory=true;result.priorTablesPreserved=true
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
