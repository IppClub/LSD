-- Native battle integration against an earned model; no story victory is inserted.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/academy-defense-interrupt-prepare-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/reconnection-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-reconnection%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-academy-defense-interrupt-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true)end
  require('Data.Config'):loadAsync()
  local world=require('Academy.Navigation').returnToRoomAsync('PassageA');local gate=assert(world.defenseGate)
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Prepare interrupt stalled');D.sleep(.02)end end
  local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end))
  local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
  hud.move:emit('Left',true);wait(function()return p.unit.x<1260 end,5);hud.move:emit('Left',false);D.sleep(.1)
  local level=assert(gate:request());level.start:emit('Tapped');wait(function()return level.battle.phase=='playing'and level.battle.enemies[1].enemyPhase=='attack'end,8)
  assert(D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=?',{level.attempt.id})[1][1]=='active')
  D.Content:save(D.Path(root,'Test/academy-defense-interrupt-fixture.txt'),db)
  result.status='PREPARED';result.attempt=level.attempt.id;result.phase=level.battle.phase;result.enemyPhase=level.battle.enemies[1].enemyPhase
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
