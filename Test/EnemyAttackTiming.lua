-- Actual Spine events and physics, without touching any player database.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local output=D.Path(root,"Test","enemy-attack-timing-result.txt")
local runId=tostring(os.time())
D.Content:save(output,"LSD_ENEMY_TIMING_RUNNING runId="..runId.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local arena=require("Training.Arena").createAsync({scene="VRTraining",distance=250,enemySkills={"blow"}})
  local deadline=D.App.runningTime+25
  while #arena.enemyAttacks<2 or not arena.enemyAttacks[2].completedAt do
   assert(D.App.runningTime<deadline,"Attack animation never completed")
   local strike=arena.enemyStrike
   if #arena.enemyAttacks==1 and strike and strike.completedAt then arena.student.position=D.Vec2(arena.enemy.x-250,arena.world.offset+155); arena.student.velocity=D.Vec2.zero end
   if strike and not strike.completedAt then
    assert(arena.enemyPhase=="attack" and arena.enemy.playable.current=="blow","Attack truncated before completion")
    if not strike.attackAt then assert(arena.studentHP==100-20*(#arena.enemyAttacks-1),"Damage applied in windup") end
   end
   D.sleep(0.01)
  end
  local timings={}
  for i=1,2 do
   local s=arena.enemyAttacks[i]
   assert(s.attackAt and s.attackAt>s.startedAt and s.attackAt<s.completedAt,"Missing authored attack frame")
   assert(s.completedAt-s.startedAt>=s.duration-0.05 and s.completedAt-s.startedAt<=s.duration+0.35,"Playback length differs from actual animation")
   assert(s.damage==20,"Expected one strike damage")
   timings[i]={duration=s.duration,attack=s.attackAt-s.startedAt,completed=s.completedAt-s.startedAt}
  end
  assert(arena.studentHP==60 and arena.metrics.damageTaken==40,"Duplicate attack damage")
  D.sleep(0.1)
  assert(math.abs(arena.enemy.playable.recovery-0.2)<0.001 and arena.enemy.playable.current==arena.enemy.data.combatRest,"Monster rest: current="..arena.enemy.playable.current.." expected="..arena.enemy.data.combatRest.." recovery="..arena.enemy.playable.recovery)
  -- Out of range and behind must miss at the animation event.
  arena:resetRound(500); arena.mode="demo"
  while not arena.enemyStrike or not arena.enemyStrike.attackAt do D.sleep(0.01) end
  assert(arena.studentHP==100 and arena.enemyStrike.damage==0,"Out-of-range hit")
  while not arena.enemyStrike.completedAt do D.sleep(0.01) end
  arena:resetRound(250); arena.mode="demo"
  while not arena.enemyStrike do D.sleep(0.01) end
  arena.student.x=arena.enemy.x+250
  while not arena.enemyStrike.attackAt do D.sleep(0.01) end
  assert(arena.studentHP==100 and arena.enemyStrike.damage==0,"Attack turned or hit behind during windup")
  arena:resetRound(500); arena.mode="demo"
  local shotEnded=false
  arena.student.playable:slot("AnimationEnd",function(name) if name=="pistol" then shotEnded=true end end)
  assert(arena:request("laser","demo"))
  local shotDeadline=D.App.runningTime+6
  while not shotEnded do assert(D.App.runningTime<shotDeadline,"Learner shot did not complete"); D.sleep(0.01) end
  D.sleep(0.1)
  assert(math.abs(arena.student.playable.recovery-0.2)<0.001 and arena.student.playable.current=="prepare","Learner did not mix back to prepare")
  return "PASS restMix=true learnerPrepare=true cycles=2 noWindupDamage=true noTruncation=true singleHit=true rangeAndFacing=true timing="..D.json.encode(timings,false,true)
 end,debug.traceback)
 local report="LSD_ENEMY_TIMING_"..(ok and result or "FAIL "..tostring(result)).." runId="..runId
 print(report); D.Content:save(output,report.."\n")
end)
