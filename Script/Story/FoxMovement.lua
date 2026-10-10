-- Keep explicit gait cadence independent of displacement, without restarting loops.
local D=require('Dora')
local Movement={recoverySeconds=.2}
function Movement.setVelocity(model,velocity)
 local moving=math.abs(velocity)>.001
 local speed=1
 if moving and model.walkAnimationSpeed then
  speed=model.walkAnimationSpeed
 elseif moving and model.strideDistance then
  speed=math.abs(velocity)/(model.strideDistance*math.abs(model.scaleX)/model.stanceSeconds)
 end
 model.speed=speed;model.recovery=Movement.recoverySeconds*speed
 model.travelVelocity=velocity
 if moving then
  -- Original Q fox and its atlas face left. Keep art direction explicit.
  local artFacesRight=model.artFacesRight==true
  model.fliped=(velocity>0)~=artFacesRight
 end
 local name=moving and (model.moveAnimation or 'move')or'idle'
 -- Spine clears current on loop completion and during recovery. Track the
 -- requested loop explicitly so those events never restart its recovery each frame.
 local current=model.moveAnimation and model.movementState or model.current
 if current~=name then
  model.movementState=name
  model.travelReadyAt=moving and (D.App.runningTime+(model.anticipationSeconds or 0)) or nil
  model:play(name,true)
 end
 return name
end
-- The authored first pose lifts one foot while the supporting foot stays put.
-- Begin actual travel when native recovery finishes, preserving that planted foot.
function Movement.step(model,velocity,dt)
 Movement.setVelocity(model,velocity)
 local activeDt=dt
 if velocity~=0 and model.travelReadyAt then activeDt=math.min(dt,math.max(0,D.App.runningTime-model.travelReadyAt))end
 local distance=velocity*activeDt
 model.x=model.x+distance;model.actualTravelVelocity=activeDt>0 and velocity or 0
 return distance
end
return Movement
