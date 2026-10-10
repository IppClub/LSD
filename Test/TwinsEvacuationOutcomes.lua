local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/twins-evacuation-outcomes-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/jade-arrival-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-jade%-arrival%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-twins-evacuation-outcomes-qa-'..run..'.db');result.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Rescue outcome timeout');D.sleep(.02)end end
  require('Data.Config'):loadAsync();local progress=require('Training.Progress');assert(progress.load()and progress.adopted)
  local service=assert(require('Mission.Service').open());local formation=assert(service:formation())
  local saved=assert(D.DB:query("SELECT completedAt FROM lsd.Game0StoryNodes WHERE id='jade-arrival'")[1])
  assert(D.DB:exec("DELETE FROM lsd.Game0StoryNodes WHERE id='jade-arrival'")>=0)
  local bad,err=service:beginAsync('c0-m08',progress.adopted,formation);assert(not bad and err=='STORY_LOCKED')
  local w=require('Academy.Navigation').returnToRoomAsync('RDRoom');wait(function()return w.jadeArrival and w.jadeArrival.phase=='ready'end,20);assert(not w.rescueGate)
  assert(D.DB:exec("INSERT INTO lsd.Game0StoryNodes VALUES('jade-arrival',?)",{saved[1]})>=0);result.prerequisiteLocked=true
  w=require('Academy.Navigation').returnToRoomAsync('RDRoom');wait(function()return w.rescueGate end,20)
  local player=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end));local hud
  D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
  hud.move:emit('Right',true);wait(function()return player.unit.x>4290 end,10);hud.move:emit('Right',false);D.sleep(.2)
  local level=assert(w.rescueGate:request());local b=level.battle;level.start:emit('Tapped')
  local active;wait(function()for _,e in ipairs(b.enemies)do if e.enemyPhase=='attack'then active=e;return true end end end,12)
  local strike=active.enemyStrike;local hp={b.twins[1].actor.hp,b.twins[2].actor.hp,b.mentorHP,b.arena.studentHP}
  level.withdraw:emit('Tapped');wait(function()return level.phase=='result'end,15)
  assert(b.phase=='aborted'and strike.completedAt and strike.completedAt-strike.startedAt>=strike.duration-.05)
  assert(b.twins[1].actor.hp==hp[1]and b.twins[2].actor.hp==hp[2]and b.mentorHP==hp[3]and b.arena.studentHP==hp[4])
  assert(not service:summary().unlocks['twins-rescued']);result.drainedAttack={kind=strike.kind,duration=strike.duration,elapsed=strike.completedAt-strike.startedAt};result.noDamageAfterWithdraw=true
  level.result.againButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world and D.Platformer.Data.store.world.patrolLevel end,20)
  local retry=D.Platformer.Data.store.world.patrolLevel;local nextBattle=retry.battle
  assert(nextBattle.phase=='ready'and retry.attempt.id~=level.attempt.id and nextBattle.twins[1].actor.hp==100 and nextBattle.twins[2].actor.hp==100 and nextBattle.ward.remaining==160)
  assert(nextBattle.medicineRemaining==b.medicineRemaining);retry.withdraw:emit('Tapped');wait(function()return retry.phase=='result'end,10)
  assert(D.DB:query("SELECT COUNT(*) FROM lsd.Game0MissionAttempts WHERE mission='c0-m08' AND status='aborted'")[1][1]==2)
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0 and not service:summary().unlocks['twins-rescued'])
  local allowed={Game0MissionAttempts=true,Game0MissionMeta=true};for name,value in pairs(snapshots)do if not allowed[name]then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  result.freshRetry=true;result.priorTablesPreserved=true;result.status='PASS'
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
