local Proof={}
local function number(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
local function positive(v)return number(v)and v>0 end
function Proof.validate(p,model,variant)
 if type(p)~='table'or p.encounter~='last-promise'or p.status~='won'or not positive(p.seconds)then return false,'EVACUATION_VICTORY_REQUIRED'end
 if not positive(p.mentorHP)or not number(p.mentorX)or p.mentorX<1900 or type(p.learner)~='table'or not positive(p.learner.hp)or not number(p.learner.x)or p.learner.x<1900 or not positive(p.learner.modelActions)or type(model)~='table'or not require("Training.Summary").matches(p.learner,model) then return false,'EVACUATION_PARTY_REQUIRED'end
 if not number(p.mentorHits)or not number(p.learner.hits)or not number(p.fireHits)or p.mentorHits+p.learner.hits+p.fireHits<=0 then return false,'EVACUATION_COMBAT_REQUIRED'end
 local a=p.auxiliary
 if type(a)~='table'or a.variant~=variant or not ({defence=true,cargo=true,mobility=true})[variant]or not positive(a.hp)or a.hp>100 or a.startX~=350 or not number(a.x)or math.abs(a.x-2090)>.01 or not number(a.distance)or math.abs(a.distance-1740)>1 or not positive(a.seconds)or a.distance/a.seconds>100.1 or type(a.loops)~='table'or not positive(a.loops.deploy)or not positive(a.loops.shield)or not positive(a.loops.move)then return false,'PHYSICAL_RECORD_CARRIER_REQUIRED'end
 if type(p.stages)~='table'or #p.stages~=3 then return false,'THREE_EVACUATION_ZONES_REQUIRED'end
 for i,s in ipairs(p.stages)do
  if type(s)~='table'or s.stage~=i or not positive(s.seconds)or s.x~=({800,1450,2090})[i]or not positive(s.hp)or type(s.guards)~='table'or #s.guards~=2 then return false,'INVALID_EVACUATION_ZONE'end
  for _,g in ipairs(s.guards)do
   if type(g)~='table'or g.hp~=0 or not number(g.loseStarted)or not number(g.loseEnded)or not positive(g.loseDuration)or g.loseEnded-g.loseStarted<g.loseDuration-.04 or type(g.strikes)~='table'then return false,'FULL_DEFEAT_REQUIRED'end
   for _,s in ipairs(g.strikes)do
    if type(s)~='table'or not require('Training.EnemyCombat').specs[s.kind]or not positive(s.duration)or not number(s.startedAt)or not number(s.completedAt)or s.completedAt-s.startedAt<s.duration-.05 then return false,'FULL_ATTACK_REQUIRED'end
    if s.hit and (not number(s.attackAt)or s.attackAt<=s.startedAt or s.attackAt>s.completedAt)then return false,'AUTHORED_ATTACK_POINT_REQUIRED'end
   end
  end
 end
 local s=p.support
 if type(s)~='table'or s.initialGold~=45 or s.radius~=360 or not number(s.gold)or s.gold<0 or s.gold>90 or not positive(s.spent)or not number(s.collected)or s.collected<0 or s.collected>30 or math.abs(45+s.collected-s.spent-s.gold)>.02 or not number(s.healed)or s.healed<0 or not number(s.hazardDamage)or s.hazardDamage<0 then return false,'FINITE_LIFE_SUPPORT_REQUIRED'end
 if not number(p.coverBlocks)or type(p.coverEvents)~='table'or p.coverBlocks~=#p.coverEvents then return false,'INVALID_COVER_RECORD'end
 for _,c in ipairs(p.coverEvents)do
  if type(c)~='table'or (c.x~=1080 and c.x~=1730)or not number(c.targetX)or not number(c.sourceX)or math.abs(c.targetX-c.x)>120 or (c.sourceX-c.x)*(c.targetX-c.x)>=0 or not number(c.sourceY)or not number(c.targetY)or not number(c.base)or not number(c.impactY)then return false,'SPATIAL_COVER_REQUIRED'end
  local blocked,y=require('Final.Cover').intersection(c.x,c.base,c.sourceX,c.sourceY,c.targetX,c.targetY)
  if not blocked or math.abs(y-c.impactY)>.01 then return false,'SPATIAL_COVER_REQUIRED'end
 end
 if (p.emergencyGranted~=0 and p.emergencyGranted~=1)or not number(p.emergencyUsed)or p.emergencyUsed<0 or p.emergencyUsed>p.emergencyGranted or p.emergencyUsed%1~=0 then return false,'TASK_SUPPLY_REQUIRED'end
 return true
end
return Proof
