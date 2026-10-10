-- Native authored animation timing + actual physical outcomes on an earned copy.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','pursuit-outcomes-result.txt');D.Content:save(out,'LSD_PURSUIT_OUTCOMES_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','ruins-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-ruins%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-pursuit-outcomes-qa-'..id..'.db')
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  require('Data.Config'):loadAsync();local story=assert(require('Story.Service').open());local service=assert(require('Mission.Service').open())
  -- Explicit service fixture: original five-line dialogue is independently public-route tested.
  assert(story:completeAsync('ruins-ambush','AbandonedCity'))
  local wp=require('Training.Progress').forCharacter('wuyun');assert(require('Training.Progress').load() and wp.load())
  local models=D.json.encode({require('Training.Progress').adopted,wp.adopted},false,true)
  local function wait(f,t) local untilTime=D.App.runningTime+(t or 12);while not f() do assert(D.App.runningTime<untilTime,'Pursuit outcomes stalled');D.sleep(.01) end end
  local B=require('Ruins.Pursuit');local b=B.createAsync(service,assert(service:beginAsync('c0-m06',nil,{mentor=true})))
  wait(function() return b.mentor.onSurface end)
  for _,e in ipairs(b.enemies) do e.nextAttack=math.huge;e.hp=0 end
  -- Stop automated acquisition with explicit per-enemy eligibility fixtures,
  -- then exercise the actual production attack specs and full native tracks.
  local timings={};b.mentorHP=10000
  for _,e in ipairs({b.enemies[1],b.enemies[2]}) do
   e.hp=100
   for _,spec in ipairs(B.attackSpecs[e.asset]) do
    e.nextAttack=math.huge;e.unit:stop();e.unit.velocityX=0;e.unit.position=D.Vec2(7500,b.world.offset+155)
    b.mentor.position=D.Vec2(spec.rush and 7280 or 7400,b.world.offset+155);b.mentor.velocityX=0
    local hp=b.mentorHP;local projectiles=#b.hostileProjectiles;local startX=e.unit.x
    assert(b:enemyStrike(e,spec));local strike=e.strikes[#e.strikes]
    wait(function() return strike.duration end)
    assert(not b:enemyStrike(e,spec),'Same enemy overlapped its attack')
    while not strike.completed do
     assert(e.unit.playable.current==spec.name or (e.unit.data.combatCompletedName==spec.name and (e.unit.data.combatCompletedAt or -1)>=strike.started),'Attack track truncated '..spec.name)
     if D.App.runningTime-strike.started<(spec.at[1] or (spec.rush and .6 or .45))-.03 then assert(b.mentorHP==hp and #b.hostileProjectiles==projectiles,'Windup caused damage/projectile') end
     assert(D.App.runningTime-strike.started<6,'Attack did not complete');D.sleep(.01)
    end
    e.nextAttack=D.App.runningTime+.5
    assert(strike.completed-strike.started>=strike.duration-.05,'Attack ended before full length')
    assert(#strike.impacts==(spec.rush and 1 or #spec.at),'Attack windows missing')
    for i,t in ipairs(strike.impacts) do if spec.rush then assert(t>=.6 and t<=1.5) else assert(t>=spec.at[i]-.01 and t<=spec.at[i]+.08)end end
    D.sleep(.15);if spec.evade then assert(strike.hits==0 and math.abs(e.unit.x-startX)>80,'Evade did not retreat') else assert(strike.hits>0,'Actual attack missed timing fixture '..spec.name)end
    assert(e.unit.playable.current==e.unit.data.combatRest and math.abs(e.unit.playable.recovery-.2)<.001,'Rest did not recover')
    timings[#timings+1]={asset=e.asset,name=spec.name,duration=strike.duration,completed=strike.completed-strike.started,impacts=strike.impacts,hits=strike.hits}
   end
   e.hp=0
  end
  -- Use actual combat medicine command; a failed durable write cannot heal.
  b.mentorHP=70;assert(D.DB:exec("CREATE TRIGGER lsd.fail_medicine_combat BEFORE UPDATE ON Game0StorySupplies BEGIN SELECT RAISE(ABORT,'QA combat medicine fault'); END")>=0)
  assert(b:command('medicine'));wait(function() return not b.medicineBusy end)
  assert(b.mentorHP==70 and b.medicineUses==0 and require('Story.Supplies').count('mentor','first-aid-water')==1)
  D.DB:exec('DROP TRIGGER lsd.fail_medicine_combat');assert(b:command('medicine'));wait(function() return not b.medicineBusy end)
  assert(b.mentorHP==95 and b.medicineUses==1 and require('Story.Supplies').count('mentor','first-aid-water')==0)
  assert(b:command('medicine'));wait(function() return not b.medicineBusy end);assert(b.mentorHP==95 and b.medicineUses==1)
  b:finish('aborted','Timing fixture finished');wait(function() return b.phase=='aborted' end)
  local Level=require('Ruins.PursuitLevel')
  local c=Level.openAsync(service,assert(service:beginAsync('c0-m06',nil,{mentor=true})));b=c.battle
  -- Low-health fixture; actual hostile projectile must produce the failed result.
  wait(function() return b.mentor.onSurface end);b.mentorHP=9
  wait(function() return b.phase=='failed' and c.result end,20)
  local actualHits=0;for _,e in ipairs(b.enemies) do for _,s in ipairs(e.strikes) do actualHits=actualHits+s.hits end end
  assert(actualHits>0 and not service:summary().unlocks['ruins-diversion-complete'])
  c.result.againButton:emit('Tapped');wait(function() local w=D.Platformer.Data.store.world;return w and w.pursuitLevel and w.pursuitLevel~=c end,20)
  c=D.Platformer.Data.store.world.pursuitLevel;b=c.battle
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_pursuit_withdraw BEFORE UPDATE ON Game0MissionAttempts WHEN NEW.mission='c0-m06' BEGIN SELECT RAISE(ABORT,'QA pursuit withdraw fault'); END")>=0)
  c.withdraw:emit('Tapped');wait(function() return b.phase=='save-error' end)
  assert(service:summary().last.status=='active' and not service:summary().unlocks['ruins-diversion-complete'])
  D.DB:exec('DROP TRIGGER lsd.fail_pursuit_withdraw');c.withdraw:emit('Tapped');wait(function() return b.phase=='aborted' and c.result end)
  local interrupted=assert(service:beginAsync('c0-m06',nil,{mentor=true}));assert(service:recoverAsync())
  assert(service:summary().last.id==interrupted.id and service:summary().last.status=='aborted')
  c=Level.openAsync(service,assert(service:beginAsync('c0-m06',nil,{mentor=true})));b=c.battle
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_pursuit_reward BEFORE INSERT ON Game0MissionUnlocks WHEN NEW.id='ruins-diversion-complete' BEGIN SELECT RAISE(ABORT,'QA pursuit reward fault'); END")>=0)
  wait(function() return b.mentor.onSurface end);local hud=assert(D.Director.ui3D:getChildByTag('pursuit-hud'))
  hud.weapon:emit('TapBegan');D.sleep(.04);assert(b.mentorAim.held and not b.mentor:isDoing('groundMentorShot'),'Press fired before release');hud.weapon:emit('TapEnded');wait(function() return b.mentorHits>0 and not b.mentor:isDoing('groundMentorShot') end)
  c.toolButtons.flare:emit('TapBegan');wait(function() return b.toolAnimations.flare==1 and b.flareHits>0 and not b.mentor:isDoing('pursuitTool') end)
  c.toolButtons.smoke:emit('TapBegan');wait(function() return b.toolAnimations.smoke==1 and not b.mentor:isDoing('pursuitTool') end)
  hud.move.onMove('keyRight',true);wait(function() return b.phase=='save-error' end,40)
  assert(b.pendingStatus=='won' and service:summary().last.status=='active' and not service:summary().unlocks['ruins-diversion-complete'])
  D.DB:exec('DROP TRIGGER lsd.fail_pursuit_reward');c.withdraw:emit('Tapped');wait(function() return b.phase=='won' and c.result end)
  assert(service:finishAsync(b.attempt,'won',b.report))
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='ruins-diversion-complete'")==1)
  assert(require('Training.Progress').load() and wp.load() and D.json.encode({require('Training.Progress').adopted,wp.adopted},false,true)==models)
  c.result.againButton:emit('Tapped');wait(function() local w=D.Platformer.Data.store.world;return w.tag=='OuterHeaven' and w.valleyEncounter and w.valleyEncounter.phase=='ready' end,30)
  return 'PASS sixActualFullAttacks=true noWindupDamage=true noOverlap=true recovery=.2 actualMedicineHeal=true medicineFaultNoHeal=true emptyNoHeal=true physicalFailure=true publicRetry=true publicWithdrawalRetry=true interruptionSafe=true actualWinRollbackRetry=true rewardOnce=true settlementContinuesValley=true modelsPreserved=true timings='..D.json.encode(timings,false,true)
 end,debug.traceback)
 local report='LSD_PURSUIT_OUTCOMES_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
