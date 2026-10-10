-- Verify the public arena's automatic controller selects all five Taotie skills.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,"Test","enemy-skill-cycle-result.txt")
local runId=tostring(os.time())
D.Content:save(out,"LSD_ENEMY_SKILL_CYCLE_RUNNING runId="..runId.."\n")
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
  D.sleep(0.1)
  assert(a.enemy.playable.current=="idle" and math.abs(a.enemy.playable.recovery-0.2)<0.001,"Automatic cycle did not restore idle")
  -- Spine clears current on every loop Complete; the completed event proves
  -- the stationary observer kept its rest loop throughout the measured round.
  assert(a.student.data.combatCompletedName==a.student.data.combatRest and a.student.data.combatCompletedAt>a.roundStarted,"Observer rest loop did not complete")
  a.mode="review"
  return "PASS automaticSelection=true attacks=5 noManualStart=true orderedWindupImpactEnd=true noOverlap=true recoveryIdle=true timings="..D.json.encode(rows,false,true)
 end,debug.traceback)
 local report="LSD_ENEMY_SKILL_CYCLE_"..(ok and result or "FAIL "..tostring(result)).." runId="..runId
 print(report); D.Content:save(out,report.."\n")
end)
