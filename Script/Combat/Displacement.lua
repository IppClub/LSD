-- Shared physical hit response. Immunity suppresses repeated displacement,
-- never damage, and a deadline prevents a stuck airborne control lock.
local D=require('Dora');local Animation=require('CombatAnimation');local K={}
local states=setmetatable({},{__mode='k'})
function K.blocked(unit)
 local s=states[unit]
 if not s then return false end
 local now=D.App.runningTime
 return s.active and now<s.deadline
end
function K.snapshot(unit)
 local s=states[unit];local active=K.blocked(unit)
 return {blocked=active,phase=active and s.phase or 'free'}
end
function K.clear(unit)
 local s=states[unit]
 if s and s.monitor then s.monitor:removeFromParent()end
 states[unit]=nil
end
function K.apply(target,x,y,strike)
 local u=target.unit;local now=D.App.runningTime
 if target.immovable or (target.alive and not target.alive())then return false,'IMMOVABLE_OR_FALLEN'end
 local scale=target.displacementScale or 1
 assert(type(scale)=='number'and scale==scale and scale>=0 and scale<=1,'Invalid physical protection')
 if scale==0 then return false,'PHYSICAL_SHIELD'end
 x=x*scale;if y then y=y*scale end
 local old=states[u]
 if old and (now<old.immuneUntil or K.blocked(u))then return false,'DISPLACEMENT_IMMUNITY'end
 K.clear(u);u:stop()
 local s={active=true,minimum=now+.3,deadline=now+8,airDeadline=now+2.2,immuneUntil=now+2.5}
 -- PlatformWorld order selects a path with a vertical layer offset.
 -- Hit reactions must preserve this lane; physical Y already expresses lift.
 states[u]=s;u.velocity=D.Vec2(x,y or u.velocityY)
 s.knockdown=((y or 0)>=600 or math.abs(x)>=900) and u.data.combatHasFall and u.data.combatHasStandUp
 local function play(name)
  s.phase=name;s.started=D.App.runningTime
  u.data.combatCompletedName='';u.data.combatCompletedAt=-1
  s.duration=Animation.play(u,name,false)
  s.phases[#s.phases+1]={name=name,started=s.started,duration=s.duration}
  if target.onForcedMovement then target.onForcedMovement({origin='forced',kind=name=='fall' and 'fall' or name=='standUp' and 'standUp' or 'hit',source=strike and strike.source or 'unknown',skill=strike and strike.kind or 'unknown',at=D.App.totalTime,x=u.x,y=u.y,velocityX=u.velocityX,velocityY=u.velocityY})end
 end
 s.phases={};play(u.data.combatHasHit and 'hit' or u.data.combatRest or 'idle')
 if strike then
  strike.displacements=strike.displacements or {}
  strike.displacements[#strike.displacements+1]={actor=u.entity.name,at=now,x=u.x,y=u.y,velocityX=x,velocityY=y or u.velocityY,reactions=s.phases}
 end
 s.monitor=D.Node();s.monitor:addTo(u)
 s.monitor:schedule(function()
  local at=D.App.runningTime
  if target.alive and not target.alive()then K.clear(u);return true end
  local ended=u.data.combatCompletedName==s.phase and (u.data.combatCompletedAt or -1)>=s.started
  ended=ended or s.duration<=0
  if ended and not s.phases[#s.phases].completed then s.phases[#s.phases].completed=at end
  if at<s.deadline then
   if not ended then return false end
   if s.phase~='fall' and s.phase~='standUp' and s.knockdown then play('fall');return false end
   -- A knocked-down actor must land before getting up, even after a long fall.
   if not u.onSurface and (s.knockdown or at<s.airDeadline) then return false end
   if s.phase=='fall' and u.onSurface then
    u.velocityX=0;play('standUp');return false
   end
   if at<s.minimum then return false end
  end
  s.active=false;s.immuneUntil=math.max(s.immuneUntil,at+.4)
  Animation.rest(u)
  if u.onSurface then u.velocityX=0 end
  s.monitor:removeFromParent();s.monitor=nil
  return true
 end)
 return true
end
return K
