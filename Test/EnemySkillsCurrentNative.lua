-- Five authored small-Taotie attacks: real animations, projectiles and physics.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=D.Path(root,"Test","enemy-skills-current-result.json")
local runId=tostring(os.time())
D.Content:save(out,D.json.encode({status="RUNNING",runId=runId}))
D.thread(function()
 local ok,result=xpcall(function()
  local arena=require("Training.Arena").createAsync({scene="VRTraining"})
  local rows={}
  assert(arena.enemyCombat.rollSprite.width==249 and arena.enemyCombat.rollSprite.height==249,"Rolling art size mismatch")
  for _,kind in ipairs({"blow","swing","butt","roll","bomb"}) do
   arena:beginDemo(kind=="bomb" and 500 or 180)
   -- suppress automatic next attacks while each measured skill and bomb resolves
   assert(arena.enemyCombat:start(kind))
   local strike=arena.enemyStrike; local startX=arena.student.x; local maxY=arena.student.y; local knocked=false
   local deadline=D.App.runningTime+10
   while not strike.completedAt or (kind=="bomb" and not strike.explodedAt) do
    assert(D.App.runningTime<deadline,"Skill did not complete or hit: "..kind)
    maxY=math.max(maxY,arena.student.y); knocked=knocked or arena.student.x<startX-5
    if not strike.attackAt then assert(arena.studentHP==100,"Damage during windup: "..kind) end
    if kind=="roll" and arena.enemyCombat.stage=="rolling" then assert(arena.enemyCombat.rollSprite.visible and not arena.enemy.playable.visible,"Rolling sprite missing") end
    if kind~="roll" and not strike.completedAt then assert(arena.enemy.playable.current==kind,"Truncated "..kind) end
    D.sleep(0.01)
   end
   assert(strike.attackAt and arena.studentHP<100,"No attack event damage: "..kind)
   if kind=="blow" or kind=="roll" then assert(knocked,"Missing horizontal knockback: "..kind) end
   if kind=="butt" then assert(maxY>arena.world.offset+180,"Missing upward knockback") end
   if kind=="swing" then assert(math.abs(arena.student.x-startX)<3,"Normal attack knocked back") end
   if kind=="bomb" then assert(strike.explodedAt>strike.attackAt and strike.projectile and strike.blastTargets==1,"Bomb did not fly then explode") end
   local reactions=assert(strike.displacements and strike.displacements[1],"Missing hit response: "..kind).reactions
   assert(reactions[1].name=="hit","Missing authored hit: "..kind)
   local recoverDeadline=D.App.totalTime+4
   while require('Combat.Displacement').blocked(arena.student)do assert(D.App.totalTime<recoverDeadline,"Hit did not recover: "..kind);D.sleep(.02)end
   assert(reactions[1].completed and reactions[1].completed-reactions[1].started>=reactions[1].duration-.04,"Truncated hit: "..kind)
   D.sleep(0.1)
   assert(not arena.enemyCombat.rollSprite.visible and arena.enemy.playable.visible,"Rolling art did not restore")
   assert(arena.enemy.playable.current=="idle" and math.abs(arena.enemy.playable.recovery-0.2)<0.001,"Missing recovery loop")
   assert(strike.completedAt-strike.startedAt>=strike.duration-.04,"Authored clip ended early: "..kind)
   rows[#rows+1]={kind=kind,damage=100-arena.studentHP,duration=strike.duration,event=strike.attackAt-strike.startedAt,completed=strike.completedAt-strike.startedAt}
  end
  -- A real bomb splash must damage two bodies, without pushing either.
  arena:beginDemo(500)
  local extra=arena.spawnUnit("charM",1,770); local hp=100
  arena.extraEnemyTargets={{unit=extra,damage=function(n) hp=hp-n end}}
  assert(arena.enemyCombat:start("bomb")); local strike=arena.enemyStrike; local deadline=D.App.runningTime+8
  while not strike.explodedAt do assert(D.App.runningTime<deadline,"Splash did not resolve"); D.sleep(0.01) end
  assert(hp==82 and arena.studentHP==82 and strike.blastTargets==2,"Bomb splash: mentorHP="..hp.." learnerHP="..arena.studentHP.." targets="..strike.blastTargets)
  assert(math.abs(extra.velocityX)<1 and math.abs(arena.student.velocityX)<1,"Bomb unexpectedly knocked targets back")
  require('Combat.Displacement').clear(extra) -- Independent next scenario.
  -- Rolling is a group attack; each contacted body receives exactly one strike.
  arena:beginDemo(180); hp=100
  extra.position=D.Vec2(arena.student.x+70,arena.world.offset+155); extra.velocity=D.Vec2.zero
  assert(arena.enemyCombat:start("roll")); strike=arena.enemyStrike
  local extraX=extra.x; deadline=D.App.runningTime+8
  while not strike.completedAt do
   assert(D.App.runningTime<deadline,"Group rolling did not complete")
   if not strike.attackAt then assert(hp==100 and arena.studentHP==100,"Rolling windup dealt damage") end
   D.sleep(0.01)
  end
  assert(hp==84 and arena.studentHP==84 and strike.damage==32,"Rolling must hit each body once")
  assert(extra.x<extraX-5 and arena.enemyCombat.rollHits[extra] and arena.enemyCombat.rollHits[arena.student],"Rolling group knock missing")
  D.sleep(0.1)
  assert(arena.enemy.playable.current=="idle" and not arena.enemyCombat.rollSprite.visible,"Group rolling recovery missing")
  -- City coordinates must not trip the VR-only boundary on the first rolling tick.
  local city=require("Training.Arena").createAsync({scene="AbandonedCity",origin=5920,minX=4800,maxX=6900})
  city:beginDemo(180); assert(city.enemyCombat:start("roll")); local cityStrike=city.enemyStrike
  deadline=D.App.runningTime+8
  while not cityStrike.completedAt do assert(D.App.runningTime<deadline,"City roll stalled"); D.sleep(0.01) end
  assert(cityStrike.completedAt-cityStrike.attackAt>=1.95,"City roll was truncated by training bounds")
  assert(city.studentHP==84,"City roll failed to hit physical learner")
  return "PASS attacks=5 rollingArt=true noWindupDamage=true completeAnimations=true horizontalKnock=true verticalKnock=true normalNoKnock=true bombProjectile=true bombNoKnock=true splashTargets=2 rollingTargets=2 rollingHitOnce=true cityRollingFullLength=true timings="..D.json.encode(rows,false,true)
 end,debug.traceback)
 local report={status=ok and "PASS"or"FAIL",error=not ok and tostring(result)or nil,summary=ok and result or nil,runId=runId,scope="Controlled native forced-skill physics and full animation; not autonomous selection, original mission reachability or natural win"}
 D.Content:save(out,D.json.encode(report,false,true))
end)
