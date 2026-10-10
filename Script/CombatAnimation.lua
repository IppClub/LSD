-- Explicit pose mixing shared by the training learner, monster and mission mentor.
local D=require("Dora")
local Animation={recovery=0.2}
function Animation.play(unit,name,loop)
 unit.playable.recovery=Animation.recovery
 return unit.playable:play(name,loop or false)
end
function Animation.rest(unit)
 local name=unit.data.combatRest or "idle"
 unit.playable.recovery=Animation.recovery
 -- Re-entering the same rest loop needlessly mixes the old track with itself.
 -- Its interrupt/end callback can clear the newly started same-name track.
 if unit.playable.current==name then return 0 end
 return Animation.play(unit,name,true)
end
function Animation.playOnceAsync(unit,name)
 unit.data.combatCompletedName=""; unit.data.combatCompletedAt=-1
 local started=D.App.runningTime
 local duration=Animation.play(unit,name,false)
 local function failed(reason)
  unit.data.combatAnimationFailure=reason
  unit.data.combatAnimationFailureName=name
  unit.data.combatAnimationFailureAt=D.App.runningTime
  unit.data.combatAnimationFailures=(unit.data.combatAnimationFailures or 0)+1
  print("CombatAnimation: "..reason.." "..name)
  return duration,false
 end
 if duration<=0 then return failed('MISSING_ANIMATION')end
 local deadline=started+duration+2
 while unit.data.combatCompletedName~=name or (unit.data.combatCompletedAt or -1)<started do
  -- Release the caller without fabricating a successful completion event.
  if D.App.runningTime>=deadline then
   return failed('ANIMATION_END_TIMEOUT')
  end
  D.sleep(0.01)
 end
 return duration,true
end
function Animation.configure(unit,asset)
 unit.data.combatRest="idle"
 unit.data.combatHasHit=false;unit.data.combatHasFall=false;unit.data.combatHasStandUp=false
 for _,name in ipairs(D.Spine:getAnimations(asset)) do
  if name=="prepare" then unit.data.combatRest="prepare"end
  if name=='hit'then unit.data.combatHasHit=true end
  if name=='fall'then unit.data.combatHasFall=true end
  if name=='standUp'then unit.data.combatHasStandUp=true end
 end
 unit.playable.recovery=Animation.recovery
 unit.playable:slot("AnimationEnd",function(name)
  unit.data.combatCompletedName=name; unit.data.combatCompletedAt=D.App.runningTime
 end)
end
return Animation
