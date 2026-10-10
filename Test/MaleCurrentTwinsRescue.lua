-- Native battle integration against an earned model; no story victory is inserted.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/male-current-twins-evacuation-route-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/male-current-jade-arrival-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-male%-current%-jade%-arrival%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-male-current-twins-evacuation-route-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true)end
  require('Data.Config'):loadAsync();local progress=require('Training.Progress');assert(progress.load()and progress.adopted)
  local beforeMedicine=assert(require('Story.Supplies').count('mentor','first-aid-water'))
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Defense route stalled');D.sleep(.02)end end
  local service=assert(require('Mission.Service').open());assert(service:recoverAsync())
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='RDRoom' and w.rescueGate end,40)
  local world=D.Platformer.Data.store.world;wait(function()return world.rescueGate~=nil end,20);local gate=assert(world.rescueGate)
  local rejected,why=gate:request();assert(not rejected and why=='DISCOVERY_LOCATION_REQUIRED')
  local function approach(w)
   local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end))
   local hud=D.Director.ui3D.children.first
   -- Find the original HUD by its movement component, not by a test control.
   for i=1,D.Director.ui3D.children.count do local n=D.Director.ui3D.children:get(i);if n.move then hud=n;break end end
   assert(hud.move);hud.move:emit('Right',true);wait(function()return p.unit.x>w.rescueGate.marker.x-120 end,10);hud.move:emit('Right',false);D.sleep(.1)
  end
  approach(world)
  local formation=assert(service:formation())
  local level,why=gate:request();assert(level,why);local b=level.battle;local attempt=assert(level.attempt)
  local bad,why=service:finishAsync(attempt,'won',{});assert(not bad and why=='RESCUE_VICTORY_REQUIRED')
  local duplicate,why=service:beginAsync('c0-m08',progress.adopted,formation);assert(not duplicate and why=='MISSION_ALREADY_ACTIVE')
  local jade=require('Story.Service').open();assert(jade:summary().completed['jade-arrival'])
  D.sleep(.8);level.start:emit('Tapped');local deadline=D.App.runningTime+260
  while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Defense battle stalled')
   if b.phase=='playing'then
    if b.jadeCarrier.robot.state=='guard' and b.jadeCarrier.phase=='riding' and not result.buddhaGuardVisible then
     assert(b.jadeCarrier.robot.opacity>.99);result.buddhaGuardVisible=true
     D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/buddha-v6-rescue-battle.tga'))
    end
    result.minimumTwinSpacing=math.min(result.minimumTwinSpacing or math.huge,b.twins[2].unit.x-b.twins[1].unit.x)
    local target=b:target(b.mentor);local lead=b.twins[1].unit.x+180
    local delta=target and target.enemy.x-b.mentor.x or lead-b.mentor.x
    local retreat=target and target.enemyPhase=='attack'and math.abs(delta)<240
    local moving=retreat or math.abs(delta)>(target and 300 or 50)
    local moveDelta=retreat and -delta or delta
    level.hud.move:emit('Left',moving and moveDelta<0);level.hud.move:emit('Right',moving and moveDelta>0)
    if not moving and target then D.emit('Skill.Began');D.emit('Skill.Ended');level.fire:emit('TapBegan')end
    if b.mentorHP<=65 then level.medicine:emit('TapBegan')end
   end
   D.sleep(.04)
  end
  assert(result.minimumTwinSpacing>=158,'Twins overlapped during escort')
  result.combat=b.report;assert(b.phase=='won',b.reason)
  assert(result.buddhaGuardVisible and b.jadeWardPulses==b.ward.hits and b.ward.hits>0)
  result.buddhaHitPulses=b.jadeWardPulses
  assert(b.jadeCarrier.phase=='ground' and #b.jadeCarrier.events==2 and b.jadeCarrier.weight==0)
  for _,event in ipairs(b.jadeCarrier.events)do assert(event.ended-event.started>=event.duration)end
  result.carrierCompleted=true
  assert(#b.completedStages==2 and b.twins[1].actor.hp>0 and b.twins[2].actor.hp>0)
  assert(b.mentorHits>0 and b.arena.metrics.modelActions>0 and b.arena.metrics.hits>0 and b.magic.fireHits>0,'Missing actual combat contribution')
  for _,stage in ipairs(b.completedStages)do
   assert(#stage.guards==2)
   for _,guard in ipairs(stage.guards)do
    assert(guard.hp==0 and guard.loseEnded-guard.loseStarted>=guard.loseDuration-.04)
    for _,strike in ipairs(guard.strikes)do assert(strike.completedAt and strike.completedAt-strike.startedAt>=strike.duration-.05,'Attack cut short')end
   end
  end
  assert(beforeMedicine-require('Story.Supplies').count('mentor','first-aid-water')==b.medicineUses,'Medicine inventory mismatch')
  assert(require('Rescue.Proof').validate(b.report,progress.adopted))
  local function clone()return D.json.decode(D.json.encode(b.report),32)end
  for _,corrupt in ipairs({function(p)p.stages[2]=nil end,function(p)p.twins[1].hp=0 end,function(p)p.twins[2].distance=0 end,function(p)p.twins[2].x=5100 end,function(p)p.ward.remaining=160 end,function(p)p.stages[1].guards[1].loseEnded=p.stages[1].guards[1].loseStarted end})do
   local p=clone();corrupt(p);assert(not require('Rescue.Proof').validate(p,progress.adopted),'Invalid proof accepted')
  end
  wait(function()return level.phase=='result'end,5)
  assert(service:summary().unlocks['twins-rescued'])
  local saved=D.DB:query('SELECT report FROM lsd.Game0MissionAttempts WHERE id=?',{attempt.id})[1][1]
  assert(service:finishAsync(attempt,'won',{}));assert(saved==D.DB:query('SELECT report FROM lsd.Game0MissionAttempts WHERE id=?',{attempt.id})[1][1])
  duplicate,why=service:beginAsync('c0-m08',progress.adopted,formation);assert(not duplicate and why=='ALREADY_WON')
  level.result.againButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world and D.Platformer.Data.store.world.rescueGate end,15)
  world=D.Platformer.Data.store.world;approach(world);local record=assert(world.rescueGate:request());assert(world.rescueGate.phase=='record')
  record.againButton:emit('Tapped');assert(world.rescueGate.phase=='ready')
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='twins-rescued'")==1)
  local changed={Game0MissionAttempts=true,Game0MissionMeta=true,Game0MissionUnlocks=true,Game0StorySupplies=true}
  for name,snapshot in pairs(snapshots)do if not changed[name]then assert(snapshot==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  local roster=assert(require('Story.AcademyLossRecords').current());for _,r in ipairs(roster)do if r.role=='vika'or r.role=='vivi'then assert(r.status=='rescued')end end
  local loss=assert(require('Story.AcademyLossRecords').saved());for _,r in ipairs(loss)do if r.role=='vika'or r.role=='vivi'then assert(r.status=='awaiting-rescue')end end
  assert(not world.jadeArrival.ward.active and world.jadeArrival.twins[1].model.x==5400 and world.jadeArrival.twins[2].model.x==5560)
  D.sleep(.5);assert(world.jadeArrival.carrier.phase=='ground' and world.jadeArrival.carrier.robot.opacity==0)
  result.buddhaHiddenAfterRescue=true
  result.rosterUpdatedWithoutChangingLoss=true;result.saveFaultInjected=false;result.idempotent=true;result.physicalGate=true;result.savedRecord=true;result.invalidProofRejected=true
  D.Content:save(D.Path(root,'Test/male-current-twins-evacuation-resume-fixture.txt'),db)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-twins-evacuation-route.tga'));result.status='PASS';result.priorTablesPreserved=true
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
