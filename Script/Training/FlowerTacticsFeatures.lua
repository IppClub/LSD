-- Version 7 classifier inputs are derived only from contemporaneous spatial v2.
local T={version=7,names={'bossGap','allySpacing','threatDistance','threatActivity','shotReach','control'}}
T.categories={bossGap='unknown contact near mid far',allySpacing='alone crowded supported isolated',threatDistance='none near mid far',threatActivity='none attacking other',shotReach='unknown within outside',control='free airborne hit fall standUp dragged exhausted'}
function T.project(state)
 if not require('Training.FlowerFeatures').validate(state) or not state.spatial or state.spatial.version~=2 then return nil,'SPATIAL_EVIDENCE_REQUIRED'end
 local s=state.spatial;local out={};for k,v in pairs(state)do out[k]=v end
 local function distance(n)return n<=300 and 'near' or n<=650 and 'mid' or 'far'end
 out.bossGap=not s.bossHull and 'unknown' or s.bossHull.distance<=80 and 'contact' or distance(s.bossHull.distance)
 out.allySpacing=not s.ally and 'alone' or s.ally.distance<160 and 'crowded' or s.ally.distance<=360 and 'supported' or 'isolated'
 out.threatDistance=s.threat and distance(s.threat.distance)or'none'
 out.threatActivity=not s.threat and 'none' or s.threat.phase=='attack' and 'attacking' or 'other'
 out.shotReach=not s.firearm and 'unknown' or s.firearm.withinTravel and 'within' or 'outside'
 out.control=s.control.blocked and (s.control.phase=='fall'and'fall'or s.control.phase=='standUp'and'standUp'or'hit')or s.dragged and'dragged'or s.exhausted and'exhausted'or not s.grounded and'airborne'or'free'
 return out
end
return T
