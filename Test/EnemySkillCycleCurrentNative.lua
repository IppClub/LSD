-- Verify the public arena's automatic controller selects all five Taotie skills.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=D.Path(root,"Test","enemy-skill-cycle-current-result.json")
local runId=tostring(os.time())
D.Content:save(out,D.json.encode({status="RUNNING",runId=runId}))
D.thread(function()
 local ok,result=xpcall(function()
  local a=require("Training.Arena").createAsync({scene="VRTraining"})
  a:beginDemo(180)
  assert(a.student.playable.current==a.student.data.combatRest,"Repeated round reset lost active rest track")
  -- A stationary high-health observer lets the normal AI finish a whole cycle.
  -- It does not select skills or substitute attack events or animations.
  a.studentHP=1000
  local deadline=D.App.runningTime+50
  while #a.enemyAttacks<5 or not a.enemyAttacks[5].completedAt do
   assert(D.App.runningTime<deadline,"Automatic five-skill cycle stalled")
   D.sleep(0.01)
  end
  local rows={}
  for i,kind in ipairs({"blow","swing","butt","roll","bomb"}) do
   local s=a.enemyAttacks[i]
   assert(s.kind==kind and s.attackAt and s.completedAt,"Automatic skill missing: "..kind)
   assert(s.attackAt>s.startedAt and s.completedAt>s.attackAt,"Automatic windup/recovery order: "..kind)
   if i>1 then assert(s.startedAt>a.enemyAttacks[i-1].completedAt,"Automatic attacks overlapped") end
   rows[i]={kind=kind,event=s.attackAt-s.startedAt,completed=s.completedAt-s.startedAt}
  end
  -- All five normal selections are already measured. Keep the next attack
  -- outside this observation window while the last bomb/hit and rest resolve.
  a.nextEnemy=D.App.runningTime+10
  local idleLoops=0;a.enemy.playable:slot("AnimationEnd",function(name)if name=="idle"then idleLoops=idleLoops+1 end end)
  local atEnd={current=a.student.playable.current,completed=a.student.data.combatCompletedName,blocked=require('Combat.Displacement').blocked(a.student),hp=a.studentHP}
  local restDeadline=D.App.runningTime+8
  while a.student.data.combatCompletedName~=a.student.data.combatRest or require('Combat.Displacement').blocked(a.student)do
   assert(D.App.runningTime<restDeadline,"Observer rest did not recover: "..D.json.encode(atEnd,false,true));D.sleep(.02)
  end
  while idleLoops<2 do
   assert(D.App.runningTime<restDeadline,"Enemy idle did not complete two natural loops");D.sleep(.02)
  end
  assert(a.enemy.data.combatCompletedName=="idle" and a.enemy.data.combatCompletedAt>a.enemyAttacks[5].completedAt and math.abs(a.enemy.playable.recovery-0.2)<0.001,"Automatic cycle did not restore idle")
  -- Spine clears current on every loop Complete; the completed event proves
  -- the stationary observer kept its rest loop throughout the measured round.
  assert(a.student.data.combatCompletedName==a.student.data.combatRest and a.student.data.combatCompletedAt>a.roundStarted,"Observer rest loop did not complete after reactions")
  a.mode="review"
  return "PASS automaticSelection=true attacks=5 noManualStart=true orderedWindupImpactEnd=true noOverlap=true recoveryIdle=true restAfterReaction=true enemyIdleLoops=2 timings="..D.json.encode(rows,false,true)
 end,debug.traceback)
 local report={status=ok and "PASS"or"FAIL",error=not ok and tostring(result)or nil,summary=ok and result or nil,runId=runId,scope="Normal public arena demo controller selects five skills; stationary observer HP1000. Not normal HP survival, formal mission or natural win"}
 D.Content:save(out,D.json.encode(report,false,true))
end)
