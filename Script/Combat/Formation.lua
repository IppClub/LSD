-- Freeze distinct regroup destinations at command time. Prefer the mentor's
-- side away from the threat; use the other side when the arena edge is close.
local F={spacing=180,recoverySpacing=100,tolerance=18}
function F.recoveryNeeded(health,ceilings,powered)
 if not powered then return false end
 for i,hp in ipairs(health)do
  if hp>0 and hp<(ceilings and ceilings[i]or 100)then return true end
 end
 return false
end
-- A prior arrival may belong to an older moving plan. Report the actual
-- latest-slot positions at expiry, without changing the finite order lifetime.
function F.deadlineFeedback(learners,plan,mode,health,ceilings,powered)
 if not plan then return nil end
 for _,arena in ipairs(learners)do
  local x=plan[arena.character.id]
  if arena.studentHP>0 and type(x)=='number'and math.abs(arena.student.x-x)>F.tolerance then
   return '集合未到齐\n再按 G 重整'
  end
 end
 if mode=='recover'and F.recoveryNeeded(health or {},ceilings,powered)then
  return '恢复已到期\n长按 G 继续'
 end
end
function F.plan(anchor,threat,ids,minX,maxX,options)
 local away=threat>=anchor and -1 or 1
 local requestedSpacing=options and options.spacing or F.spacing
 assert(type(requestedSpacing)=='number'and requestedSpacing>0 and requestedSpacing<=F.spacing,'Invalid formation spacing')
 local slots={};local result={_away=away}
 if options and options.keepAway then
  -- An arena edge is not permission to regroup inside the visible attack lane.
  -- Compress the rear slots instead; preserve normal spacing when room exists.
  local edge=away<0 and math.min(anchor,minX+25)or math.max(anchor,maxX-25)
  local room=math.max(0,(edge-anchor)*away)
  local spacing=#ids>0 and math.min(requestedSpacing,room/#ids)or 0
  result._compressed=spacing<requestedSpacing;result._spacing=spacing
  for i,id in ipairs(ids)do result[id]=anchor+away*spacing*i end
  return result
 end
 for _,direction in ipairs({away,-away})do
  for i=1,#ids do
   local x=anchor+direction*requestedSpacing*i
   if x>=minX+25 and x<=maxX-25 then slots[#slots+1]=x end
  end
 end
 -- Caller lists closer roles first, ranged roles later.
 for i,id in ipairs(ids)do result[id]=slots[i]end
 return result
end
-- Recovery tracks visible threat-side changes as well as mentor movement.
-- A Boss at the anchor is ambiguous; keep the prior side within tolerance.
function F.needsRecoveryReplan(plan,anchor,threat)
 if math.abs(anchor-plan._anchor)>F.tolerance then return true end
 if math.abs(threat-anchor)<=F.tolerance then return false end
 return plan._away~=(threat>anchor and -1 or 1)
end
-- Manual orders remain bounded, but a distant half-speed backstep needs more
-- than the old fixed three seconds. Arrival still releases each actor early.
function F.duration(plan,learners)
 local duration=3
 for _,arena in ipairs(learners)do
  local x=plan[arena.character.id]
  if x and arena.studentHP>0 then
   duration=math.max(duration,math.max(0,math.abs(x-arena.student.x)-F.tolerance)/120+.5)
  end
 end
 return math.min(12,duration)
end
function F.recoveryDuration(plan,learners,health,ceilings,rate)
 assert(type(rate)=='number'and rate>0,'Invalid healing rate')
 local missing=0
 for i,hp in ipairs(health)do if hp>0 then missing=math.max(missing,(ceilings and ceilings[i]or 100)-hp)end end
 return math.min(12,F.duration(plan,learners)+missing/rate)
end
-- The manual order owns each actor until that actor arrives. Recovery keeps
-- the whole living formation waiting only while its real benefit is active.
function F.owns(arena,battle,now)
 if battle.phase~='playing'or not battle.gatherPlan or now>=(battle.gatherUntil or 0)or arena.studentHP<=0 then return false end
 if battle.gatherMode=='recover'then return battle:gatherActive()end
 return arena.regroupPlan~=battle.gatherPlan or not arena.regroupComplete
end
-- Recovery owns locomotion, not a stationary learned attack. Revoke the
-- decision window immediately when the mentor moves or this actor is displaced
-- from its slot; the inner update will then replan/regroup without exploration.
function F.stationaryRecovery(arena,battle,now)
 local plan=battle.gatherPlan
 return battle.gatherMode=='recover'and F.owns(arena,battle,now)
  and arena.regroupPlan==plan and arena.regroupComplete==true
  and type(plan._anchor)=='number'and math.abs(battle.mentor.x-plan._anchor)<=F.tolerance
  and (not battle.gatherThreat or not F.needsRecoveryReplan(plan,battle.mentor.x,battle:gatherThreat()))
  and type(plan[arena.character.id])=='number'
  and math.abs(arena.student.x-plan[arena.character.id])<=F.tolerance
end
function F.stop(arena)
 if not arena.regroupMoving then return end
 arena.regroupMoving=nil
 if arena.student:isDoing(arena.physical.fmove)or arena.student:isDoing(arena.physical.bmove)then
  arena.student:stop();arena.student.velocityX=0
  require('CombatAnimation').rest(arena.student)
 end
end
function F.step(arena,x,battle)
 local u=arena.student
 -- Regroup can bypass Arena:update; preserve the same physical arena bounds.
 if arena.minX and arena.maxX and (u.x<arena.minX or u.x>arena.maxX)then
  local old,vx=u.x,u.velocityX;u.x=math.max(arena.minX,math.min(arena.maxX,old))
  if (old<arena.minX and vx<0)or(old>arena.maxX and vx>0)then u.velocityX=0 end
 end
 if require('Combat.Displacement').blocked(u) or not u.onSurface or arena:isAttacking() or (arena.studentEffects and arena.studentEffects:blocked(u,'gather'))then return false end
 if not x or math.abs(x-u.x)<=F.tolerance then
  if u:isDoing(arena.physical.fmove)or u:isDoing(arena.physical.bmove)then arena.regroupMoving=true end
  F.stop(arena);return true
 end
 local direction=x>=u.x and 1 or -1
 local enemy=battle and require('Combat.Movement').target(u,battle)
 local face=enemy and enemy.x>=u.x or not enemy and direction>0
 local action=enemy and ((direction>0)~=face)and arena.physical.bmove or arena.physical.fmove
 -- Close the old movement interval before changing its facing or action.
 if u.faceRight~=face and (u:isDoing(arena.physical.fmove)or u:isDoing(arena.physical.bmove))then u:stop()end
 u.faceRight=face
 if u:isDoing(action)and not arena.regroupMoving and arena.beginMovementAction and arena.finishMovementAction then
  -- Preserve the running walk animation, but close the model-owned decision
  -- interval when the player's order takes over the same physical action.
  local label=action==arena.physical.bmove and 'bmove'or'fmove'
  arena.finishMovementAction(arena.movementStep,u,label)
  arena.movementStep=arena.beginMovementAction(u,label,'command-gather')
 end
 if not u:isDoing(action)then u:start(action)end
 arena.regroupMoving=true
 return false
end
return F
