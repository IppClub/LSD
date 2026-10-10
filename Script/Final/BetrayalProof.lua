local P={}
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
function P.validate(p)
 if type(p)~='table'or p.version~=1 or p.rows~=15 then return false,'FINAL_DIALOGUE_REQUIRED'end
 if not finite(p.clockBefore)or p.clockBefore<=0 or p.clockBefore~=p.clockAfter or not finite(p.freezeStarted)or not finite(p.freezeObserved)or p.freezeObserved-p.freezeStarted<.65 then return false,'FROZEN_COMMUNICATION_REQUIRED'end
 local a=p.action
 if type(a)~='table'or (a.mentor~='charF'and a.mentor~='charM')then return false,'BETRAYAL_ACTION_REQUIRED'end
 for _,k in ipairs({'attackStarted','attackEnded','attackDuration','impactAt','hitStarted','hitEnded','hitDuration','fallStarted','fallEnded','fallDuration','impactDistance'})do if not finite(a[k])then return false,'BETRAYAL_TIMING_REQUIRED'end end
 if a.attackDuration<.99 or a.attackEnded-a.attackStarted<a.attackDuration-.04 or a.impactAt<=a.attackStarted or a.impactAt>=a.attackEnded or a.impactDistance>170 or a.impactDistance<100 then return false,'NATIVE_BETRAYAL_IMPACT_REQUIRED'end
 if a.hitDuration<.59 or math.abs(a.hitStarted-a.impactAt)>.03 or a.hitEnded-a.hitStarted<a.hitDuration-.04 then return false,'NATIVE_MENTOR_HIT_REQUIRED'end
 if a.fallDuration<1.1 or a.fallStarted<a.attackEnded or a.fallStarted<a.hitEnded or a.fallEnded-a.fallStarted<a.fallDuration-.04 or not a.held then return false,'COMPLETE_MENTOR_FALL_REQUIRED'end
 if type(a.approach)~='table'or not finite(a.approach.distance)or a.approach.distance<300 or not finite(a.approach.seconds)or a.approach.seconds<2 then return false,'LIN_APPROACH_REQUIRED'end
 return true
end
return P
