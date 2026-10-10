-- Native battle integration against an earned model; no story victory is inserted.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/fresh-academy-defense-retry-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-reconnection-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fresh%-reconnection%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fresh-academy-defense-retry-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true)end
  require('Data.Config'):loadAsync();local progress=require('Training.Progress');assert(progress.load()and progress.adopted)
  local beforeMedicine=assert(require('Story.Supplies').count('mentor','first-aid-water'))
  local level=require('Academy.DefenseLevel').openAsync({ninilite=progress.adopted});local b=level.battle
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Defense retry stalled');D.sleep(.02)end end
  D.sleep(.8);level.start:emit('Tapped');wait(function()return b.phase=='playing'end,5)
  wait(function()return b.enemies[1].enemyPhase=='attack'end,8)
  local strike=b.enemies[1].enemyStrike
  level.withdraw:emit('Tapped');wait(function()return level.phase=='result'end,15)
  assert(b.phase=='aborted'and strike.completedAt and strike.completedAt-strike.startedAt>=strike.duration-.05)
  result.withdrawFullAttack=true
  level.result.againButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w~=b.world and w.patrolLevel and w.patrolLevel.phase=='ready'end,20)
  local nextLevel=D.Platformer.Data.store.world.patrolLevel
  assert(nextLevel.medicine and nextLevel.medicine.parent and nextLevel.fire and nextLevel.fire.parent and nextLevel.hud.parent,'Retry lost controls')
  assert(nextLevel.battle.stage==0 and #nextLevel.battle.completedStages==0 and nextLevel.battle.mentorHP==100)
  nextLevel.start:emit('Tapped');wait(function()return nextLevel.battle.phase=='playing'end,5)
  nextLevel.withdraw:emit('Tapped');wait(function()return nextLevel.phase=='result'end,15)
  assert(nextLevel.battle.phase=='aborted'and #nextLevel.battle.completedStages==0)
  assert(beforeMedicine==require('Story.Supplies').count('mentor','first-aid-water'))
  result.retryControls=true;result.noUnearnedVictory=true
  for name,snapshot in pairs(snapshots)do if name~='Game0StorySupplies'then assert(snapshot==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  result.status='PASS';result.priorTablesPreserved=true
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
