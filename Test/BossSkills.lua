-- Real Big Taotie timelines, calibrated impacts, physics and bullet collisions.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,"Test","boss-skills-result.txt"); D.Content:save(out,"LSD_BOSS_SKILLS_RUNNING\n")
D.thread(function()
 local ok,result=xpcall(function()
  local a=require("Training.Arena").createAsync({scene="AbandonedCity",enemyAsset="dataotie",enemyMaxHP=320})
  D.Cache:loadAsync("spine:charM")
  local extra=a.spawnUnit("charM",1,710,{}); local hp=100
  local rows={}
  for _,kind in ipairs({"trample","swing","pounce","shot","rush"}) do
   require('Combat.Displacement').clear(extra)
   extra.visible=kind=="swing" or kind=="pounce"
   extra.group=extra.visible and 1 or 3
   a.extraEnemyTargets={}; hp=100
   a:beginDemo(kind=="shot" and 650 or kind=="pounce" and 480 or kind=="rush" and 450 or 180)
   D.sleep(0.2)
   assert(a.enemyHP==320 and not a.enemy.faceRight)
   assert(a.enemyCombat:start(kind)); local s=a.enemyStrike
   if kind=="swing" then
    a.student.position=D.Vec2(a.enemy.x+200,a.student.y); extra.position=D.Vec2(a.enemy.x+260,a.student.y)
    a.extraEnemyTargets={{unit=extra,damage=function(n) hp=hp-n end}}
   elseif kind=="pounce" then
    extra.position=D.Vec2(740,a.student.y); a.extraEnemyTargets={{unit=extra,damage=function(n) hp=hp-n end}}
   end
   local x=a.student.x; local y=a.student.y; local ex=a.enemy.x; local moved=false; local maxY=a.student.y
   local endAt=D.App.runningTime+13
   while not s.completedAt do
    assert(D.App.runningTime<endAt,"Boss didn't finish "..kind)
    if not s.attackAt then assert(a.studentHP==100 and hp==100,"Windup caused damage "..kind) end
    if kind~="rush" then assert(a.enemy.playable.current==kind,"Boss animation truncated "..kind) end
    moved=moved or math.abs(a.enemy.x-ex)>5; maxY=math.max(maxY,a.student.y)
    if kind=='trample' and s.attackAt and not s.captured and a.student.y>y+250 then
     s.captured=true;D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/boss-launch-native.tga')
    end
    D.sleep(0.01)
   end
   a.nextEnemy=D.App.runningTime+20
   if kind=="shot" then D.sleep(0.5) end
   assert(s.attackAt and a.studentHP<100,"Boss skill missed "..kind)
   if kind~="rush" then assert(s.completedAt-s.startedAt>=s.duration-0.04,"Short animation "..kind) end
   if kind=="trample" then assert(a.studentHP==80 and math.abs(a.student.x-x)>200 and maxY>y+250,"Trample did not visibly launch "..D.json.encode({hp=a.studentHP,dx=a.student.x-x,lift=maxY-y,displacements=s.displacements})) end
   if kind=="swing" then assert(hp==80 and a.studentHP==80 and a.student.x>x,"Rear multi-target knock missing") end
   if kind=="pounce" then assert(hp==80 and a.studentHP==80 and moved and maxY>y+5,"Pounce displacement/group/upward hit missing "..D.json.encode({extra=hp,student=a.studentHP,moved=moved,maxY=maxY,offset=a.world.offset,enemy=a.enemy.x,studentX=a.student.x})) end
   if kind=="shot" then assert(s.shots==3 and (s.projectileHits or 0)>=1,"No physical burst hits") end
   if kind=="rush" then
    assert(moved and s.rushLoops==3 and a.studentHP==76,"Rush displacement, single hit or full loops missing")
    assert(#s.stages==4 and s.stages[1].name=="rush" and s.stages[2].name=="rush1" and s.stages[3].name=="rush2" and s.stages[4].name=="rush3")
    for _,i in ipairs({1,2,4}) do local r=s.stages[i]; assert(r.completedAt and r.completedAt-r.startedAt>=r.duration-0.04,"Rush segment truncated") end
   end
   D.sleep(0.1)
   assert(a.enemy.playable.current=="idle" and math.abs(a.enemy.playable.recovery-0.2)<0.001,"Boss did not recover to idle")
   rows[#rows+1]={kind=kind,damage=100-a.studentHP,extraDamage=100-hp,impact=s.attackAt-s.startedAt,complete=s.completedAt-s.startedAt,shots=s.shots,projectileHits=s.projectileHits,rushLoops=s.rushLoops,learnerDisplacementX=a.student.x-x,learnerMaxLift=maxY-y,displacements=s.displacements}
  end
  -- A second impact still damages, but cannot chain-launch the same actor.
  a:beginDemo(180);D.sleep(.2)
  local K=require('Combat.Displacement');local target={unit=a.student};local strike={};local order=a.student.order
  assert(K.apply(target,-360,520,strike));assert(K.blocked(a.student) and not a:available('laser'))
  local vx,vy=a.student.velocityX,a.student.velocityY
  local applied,why=K.apply(target,900,900,strike)
  assert(not applied and why=='DISPLACEMENT_IMMUNITY' and #strike.displacements==1)
  assert(a.student.velocityX==vx and a.student.velocityY==vy)
  local deadline=D.App.runningTime+2.5
  a.nextEnemy=deadline+5
  while not a.student.onSurface or K.blocked(a.student)do assert(D.App.runningTime<deadline,'Landing control did not recover');D.sleep(.02)end
  D.sleep(.05);assert(a:available('laser') and a.student.playable.current==a.student.data.combatRest and a.student.order==order,'Landing did not restore idle/order');K.clear(a.student)
  -- Locked direction: trample misses behind; tail swipe misses the front.
  for _,kind in ipairs({"trample","swing"}) do
   a.extraEnemyTargets={}; a:beginDemo(180); assert(a.enemyCombat:start(kind)); local s=a.enemyStrike
   if kind=="trample" then a.student.position=D.Vec2(a.enemy.x+200,a.student.y) end
   local deadline=D.App.runningTime+5
   while not s.completedAt do assert(D.App.runningTime<deadline,"Boss miss test stalled"); D.sleep(0.01) end
   assert(a.studentHP==100,"Facing/range rule ignored "..kind)
  end
  return "PASS skills=5 calibratedWindup=true fullAnimations=true rearGroupHit=true singleTrample=true physicalPounce=true physicalBurst=true rushFourStages=true rushThreeFullLoops=true perTargetRushOnce=true lockedDirection=true recoveryIdle=true timings="..D.json.encode(rows)
 end,debug.traceback)
 local report="LSD_BOSS_SKILLS_"..(ok and result or "FAIL "..tostring(result)); print(report); D.Content:save(out,report.."\n")
end)
