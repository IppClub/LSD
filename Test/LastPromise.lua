-- Native battle integration against an earned model; no story victory is inserted.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/last-promise-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/jade-distance-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-jade%-distance%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-last-promise-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true)end
  require('Data.Config'):loadAsync();local progress=require('Training.Progress');assert(progress.load()and progress.adopted)
  local beforeMedicine=assert(require('Story.Supplies').count('mentor','first-aid-water'))
  local level=require('Final.Level').openAsync({ninilite=progress.adopted},'mobility');local b=level.battle
  D.sleep(.8);level.start:emit('Tapped');local deadline=D.App.runningTime+260
  while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Defense battle stalled')
   if b.phase=='playing'then
    local target=b:target(b.mentor);local lead=b.objective.x+170
    local delta=target and target.enemy.x-b.mentor.x or lead-b.mentor.x
    local retreat=target and target.enemyPhase=='attack'and math.abs(delta)<240
    local moving=retreat or math.abs(delta)>(target and 300 or 50)
    local moveDelta=retreat and -delta or delta
    level.hud.move:emit('Left',moving and moveDelta<0);level.hud.move:emit('Right',moving and moveDelta>0)
    if not moving and target then D.emit('Skill.Began');D.emit('Skill.Ended');level.fire:emit('TapBegan')end
    if not result.stageOneScreen and b.stage==1 and b.objective.x>600 then result.stageOneScreen=true;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/last-promise-stage-one.tga'))end
    if b.mentorHP<=65 then level.medicine:emit('TapBegan')end
   end
   D.sleep(.04)
  end
  result.combat=b.report;assert(b.phase=='won',b.reason)
  assert(require('Final.Proof').validate(b.report,progress.adopted,'mobility'))
  assert(#b.completedStages==3 and b.objective.x>=2090 and b.support.machineHP>0)
  assert(b.escortDistance>=1740 and b.escortSeconds>17 and b.actor.completed.deploy and b.actor.completed.shield)
  assert(b.mentorHits>0 and b.arena.metrics.modelActions>0 and b.arena.metrics.hits>0 and b.magic.fireHits>0,'Missing actual combat contribution')
  for _,stage in ipairs(b.completedStages)do
   assert(#stage.guards==2)
   for _,guard in ipairs(stage.guards)do
    assert(guard.hp==0 and guard.loseEnded-guard.loseStarted>=guard.loseDuration-.04)
    for _,strike in ipairs(guard.strikes)do assert(strike.completedAt and strike.completedAt-strike.startedAt>=strike.duration-.05,'Attack cut short')end
   end
  end
  assert(beforeMedicine-require('Story.Supplies').count('mentor','first-aid-water')==b.medicineUses,'Medicine inventory mismatch')
  for name,snapshot in pairs(snapshots)do if name~='Game0StorySupplies'then assert(snapshot==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/last-promise-native.tga'));result.status='PASS';result.priorTablesPreserved=true
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
