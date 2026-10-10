-- Actual authored flower actions, live bodies/projectiles, and complete chant recovery.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=D.Path(root,"Test","flower-skills-current-result.json"); local id=tostring(os.time()); D.Content:save(out,D.json.encode({status="RUNNING",runId=id}))
D.thread(function()
 local ok,result=xpcall(function()
  local Arena=require("Training.Arena"); local records={}
  local function wait(f,time,label) local deadline=D.App.runningTime+(time or 12); while not f() do assert(D.App.runningTime<deadline,label or "Flower wait stalled"); D.sleep(0.01) end end
  local function target(arena,extra,health)
   return {{unit=arena.student,alive=function() return arena.studentHP>0 end,isAttacking=function() return arena:isAttacking() end,damage=function(n) local dealt=math.min(n,arena.studentHP); arena.studentHP=arena.studentHP-dealt; arena.metrics.damageTaken=arena.metrics.damageTaken+dealt; return dealt end},
    {unit=extra,alive=function() return health.hp>0 end,damage=function(n) local dealt=math.min(n,health.hp); health.hp=health.hp-dealt; return dealt end}}
  end
  local function finish(arena,strike)
   wait(function()
    if not strike.attackAt then assert(arena.studentHP==100,"Flower windup damage "..strike.kind) end
    if not strike.completedAt then assert(arena.enemy.playable.current==arena.enemyCombat.stage or (arena.enemyCombat.stageDone and arena.enemy.playable.lastCompleted==arena.enemyCombat.stage),"Flower animation truncated "..strike.kind) end
    return strike.completedAt
   end,15,"Flower action did not end "..strike.kind)
   for _,part in ipairs(strike.segments) do assert(part.completedAt and part.completedAt-part.startedAt>=part.duration-0.10,"Short flower segment "..part.name) end
   if strike.kind=='leech' or strike.kind=='attack' or strike.kind=='twine'then
    local reactions=assert(strike.displacements,'Missing flower hit response')
    assert(#reactions>0)
    for _,hit in ipairs(reactions)do
     local phase=hit.reactions[1];assert(phase.name=='hit' and phase.completed and phase.completed-phase.started>=phase.duration-.04,'Flower hit truncated by status or AI')
    end
   end
   D.sleep(0.1)
   assert(arena.enemy.playable.current=="idle" and math.abs(arena.enemy.playable.recovery-0.2)<0.001,"Flower recovery missing")
   records[#records+1]={kind=strike.kind,impact=strike.attackAt-strike.startedAt,completed=strike.completedAt-strike.startedAt,targets=strike.targets,segments=strike.segments}
  end
  local a=Arena.createAsync({scene="Factory",enemyAsset="xiaohuayao"})
  D.Cache:loadAsync("spine:charM"); local extra=a.spawnUnit("charM",1,570,{})
  local health={hp=100}; a.enemyTargets=function() return target(a,extra,health) end
  a:beginDemo(180); a.enemyHP=50; assert(a.enemyCombat:start("leech")); local strike=a.enemyStrike
  local studentX=a.student.x; local extraX=extra.x; finish(a,strike)
  assert(a.studentHP==88 and health.hp==88 and a.enemyHP==74 and strike.targets==2,"Leech damage/healing mismatch")
  assert(math.abs(a.student.x-studentX)<4 and math.abs(extra.x-extraX)<4,"Leech must not knock back")
  a:beginDemo(550); health.hp=100; extra.position=D.Vec2(570,a.world.offset+155); extra.velocity=D.Vec2.zero
  studentX=a.student.x; extraX=extra.x; assert(a.enemyCombat:start("pull")); strike=a.enemyStrike
  wait(function() return strike.attackAt end); assert(not a:available("laser"),"Drag did not suppress new commands")
  finish(a,strike)
  assert(a.studentHP==100 and health.hp==100 and a.student.x>studentX+200 and extra.x>extraX+200,"Pull lacks physical displacement or inflicted HP damage")
  assert(a.enemyCombat.effects.states[a.student].stamina==75 and a.enemyCombat.effects.states[extra].stamina==75,"Pull stamina mismatch")
  -- Big flower has opposite-facing art and a taller physical body, not a Taotie placeholder.
  a=Arena.createAsync({scene="Factory",enemyAsset="dahuayao",characterId="wuyun"})
  extra=a.spawnUnit("charM",1,560,{}); health={hp=100}; a.enemyTargets=function() return target(a,extra,health) end
  local song=require("Factory.Song").new(a,a.enemyCombat.effects)
  a:beginDemo(350); assert(a.enemyCombat:start("attack")); strike=a.enemyStrike; finish(a,strike)
  assert(a.studentHP==82 and health.hp==100 and strike.targets==1,"Big flower basic attack must hit one target")
  a:beginDemo(350); health.hp=100; extra.position=D.Vec2(430,a.world.offset+155); extra.velocity=D.Vec2.zero
  assert(a.enemyCombat:start("twine")); strike=a.enemyStrike; finish(a,strike)
  assert(strike.waves==5 and strike.targets==2 and a.studentHP<=92 and health.hp<=92,"Ground vines did not reach two live bodies")
  local effects=a.enemyCombat.effects
  assert(a.student.group==2 and extra.group==2 and effects:blocked(a.student,"laser"),"Confusion did not change allegiance/control")
  assert(song:request()); local cast=song.logs[1]; local poisonedBefore=a.studentHP
  wait(function() return cast.completedAt end,5,"Full chant missing")
  assert(cast.releaseAt and cast.releaseAt-cast.startedAt>=cast.duration-0.05 and not cast.unexpectedAttackEvent and cast.cleared==2,"Chant release occurred before full gesture")
  assert(a.student.group==1 and extra.group==1 and a.studentHP<poisonedBefore,"Chant must clear confusion without healing poison")
  assert(not effects:apply(target(a,extra,health)[1],"confuse",6,{kind="twine"}),"Chant protective interval missing")
  D.sleep(0.15); assert(a.student.playable.current=="prepare" and math.abs(a.student.playable.recovery-0.2)<0.001,"Chant prepare recovery missing")
  local requested,why=song:request(); assert(not requested and why=="COOLDOWN","Chant cooldown missing")
  a:beginDemo(350); a.nextEnemy=math.huge; D.sleep(math.max(0,song.ready-D.App.runningTime+0.05)); health.hp=100; extra.position=D.Vec2(890,a.world.offset+155); extra.velocity=D.Vec2.zero
  assert(a.enemyCombat:start("transv")); strike=a.enemyStrike
  wait(function() return strike.attackAt end)
  assert(not a:available("fmove") and not a:available("bmove"),"Virus failed to stop exoskeleton commands")
  requested,why=song:request(); assert(not requested and why=="EQUIPMENT_DISABLED","Virus must disable chant equipment")
  assert(a:request("laser","demo"),"Infected firearm did not fire")
  wait(function() return (a.metrics.friendlyHits or 0)>0 end,5,"Virus did not redirect a real projectile to a teammate")
  assert(health.hp==80,"Virus projectile failed to damage teammate")
  finish(a,strike); assert(#strike.segments==3,"Virus three-part motion truncated")
  wait(function() return not effects:blocked(a.student,"fmove") end,6,"Virus equipment never recovered")
  a:beginDemo(180); a.nextEnemy=math.huge
  wait(function() return a.student.onSurface end)
  assert(a:request("melee","demo"))
  local previousCasts=#song.logs; requested,why=song:request()
  assert(requested and why=="QUEUED_AFTER_ATTACK","Chant cut off an existing melee action")
  local meleeCompleted
  wait(function()
   if not a:isAttacking() and not meleeCompleted then meleeCompleted=a.student.data.combatCompletedAt end
   song:update(); return #song.logs>previousCasts
  end,5,"Queued chant never started")
  local queued=song.logs[#song.logs]
  assert(meleeCompleted and queued.startedAt>=meleeCompleted,"Queued chant started before melee AnimationEnd")
  wait(function() return queued.releaseAt end,5,"Queued chant did not complete")
  assert(queued.releaseAt-queued.startedAt>=queued.duration-0.05,"Queued chant was truncated")
  a:beginDemo(350); health.hp=100; assert(a.enemyCombat:start("seed")); strike=a.enemyStrike; finish(a,strike)
  assert(#strike.segments==3 and strike.spawned==3 and #a.seededEnemies==3,"Seed dance failed to spawn three real buds")
  for _,child in ipairs(a.seededEnemies) do assert(child.enemy.world==a.world and child.enemyCombat.budding and child.bud.visible and not child.enemy.playable.visible and child.bud.current=="bud","Seed is not a dormant original bud") end
  a:beginDemo(350); assert(#a.seededEnemies==0,"Reset left stale buds")
  -- An actual projectile starts the complete five-second accumulated-damage window.
  a=Arena.createAsync({scene="Factory",enemyAsset="xiaohuayao",enemyBud=true})
  a:beginDemo(400); assert(a.enemyCombat.budding and a.enemyCombat.bud.visible)
  wait(function() return a.student.onSurface end); assert(a:request("laser","demo")); wait(function() return a.enemyCombat.firstBudHit end)
  local first=a.enemyCombat.firstBudHit; D.sleep(3.6)
  assert(a.enemyCombat.budding and not a.enemyCombat.opening and not a.enemyCombat.openedAt,"Bud opened before five seconds")
  assert(a:request("laser","demo")); wait(function() return a.metrics.hits==2 end)
  wait(function() return a.enemyCombat.opening end,5,"Damaged bud never blossomed")
  assert(a.enemyCombat.budOpenedAt-first>=5 and a.enemyCombat.damageInBud==40 and math.abs(a.enemyCombat.budCoefficient-0.8)<0.001,"Bud damage coefficient/window mismatch")
  local began=a.enemyCombat.budOpenedAt; local duration=a.enemyCombat.budDuration
  wait(function() return a.enemyCombat.openedAt end,8,"Full bud blossom never ended")
  assert(a.enemyCombat.openedAt-began>=duration-0.05 and a.enemyHP==80 and a.enemy.playable.visible and not a.enemyCombat.bud.visible,"Blossom visibility/derived health wrong")
  D.sleep(0.1); assert(a.enemy.playable.current=="idle" and math.abs(a.enemy.playable.recovery-0.2)<0.001,"Blossom recovery missing current="..a.enemy.playable.current.." recovery="..a.enemy.playable.recovery.." phase="..a.enemyPhase)
  return "PASS authoredSkills=6 noWindupDamage=true fullSegments=true leechGroupHealing=true noLeechKnock=true physicalGroupPull=true staminaConsumed=true singleBasicAttack=true progressiveGroundVines=true actualConfusedAllegiance=true poisonContinues=true completeWuyunChant=true noFakeChantEvent=true chantProtectsSixSeconds=true chantCooldown=true chantQueuedAfterFullMelee=true virusBlocksMovement=true virusRealFriendlyProjectile=true virusRecovers=true seedThreeOriginalBuds=true resetRemovesBuds=true actualProjectileBudWindow=true accumulatedDamageCoefficient=true fullBlossom=true recoveryIdleAndPrepare=true timings="..D.json.encode(records,false,true)
 end,debug.traceback)
 local report={status=ok and "PASS"or"FAIL",error=not ok and tostring(result)or nil,summary=ok and result or nil,runId=id,scope="Controlled native flower skills, actual projectiles, statuses, original buds and Wuyun chant; not automatic selection or original mission/natural victory"};D.Content:save(out,D.json.encode(report,false,true))
end)
