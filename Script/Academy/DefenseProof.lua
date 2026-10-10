local Proof={}
local function number(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function positive(n)return number(n)and n>0 end
function Proof.validate(p,model)
 if type(p)~='table'or p.encounter~='academy-defense'or p.status~='won'or not positive(p.seconds)then return false,'DEFENSE_VICTORY_REQUIRED'end
 if not positive(p.mentorHP)or not positive(p.powerHP)or not positive(p.beaconHP)then return false,'PROTECTED_TARGET_REQUIRED'end
 local ni=p.learner
 if type(ni)~='table'or not positive(ni.hp)or not positive(ni.modelActions)or type(model)~='table'or not require("Training.Summary").matches(ni,model) then return false,'ADOPTED_LEARNER_REQUIRED'end
 if not number(p.mentorHits)or not number(ni.hits)or not number(p.fireHits)or p.mentorHits+ni.hits+p.fireHits<=0 then return false,'COMBAT_DAMAGE_REQUIRED'end
 if type(p.stages)~='table'or #p.stages~=3 then return false,'THREE_STAGES_REQUIRED'end
 for i,stage in ipairs(p.stages)do
  if type(stage)~='table'or stage.stage~=i or not positive(stage.seconds)or not positive(stage.powerHP)or not positive(stage.beaconHP)or type(stage.guards)~='table'or #stage.guards~=2 then return false,'INVALID_DEFENSE_STAGE'end
  for _,g in ipairs(stage.guards)do
   if type(g)~='table'or g.hp~=0 or not number(g.loseStarted)or not number(g.loseEnded)or not positive(g.loseDuration)or g.loseEnded-g.loseStarted<g.loseDuration-.04 then return false,'FULL_DEFEAT_REQUIRED'end
   if type(g.strikes)~='table'then return false,'ATTACK_RECORD_REQUIRED'end
   for _,s in ipairs(g.strikes)do
    if type(s)~='table'or not require('Training.EnemyCombat').specs[s.kind]or not positive(s.duration)or not number(s.startedAt)or not number(s.completedAt)or s.completedAt-s.startedAt<s.duration-.05 then return false,'FULL_ATTACK_REQUIRED'end
    if s.hit and (not number(s.attackAt)or s.attackAt<=s.startedAt or s.attackAt>s.completedAt)then return false,'AUTHORED_ATTACK_POINT_REQUIRED'end
   end
  end
 end
 if not number(p.beaconX)or p.exitX~=2094 or p.beaconX<p.exitX or p.beaconStartX~=1300 or not number(p.escortDistance)or p.escortDistance<p.exitX-p.beaconStartX-.1 or not positive(p.escortSeconds)or p.escortDistance/p.escortSeconds>85.1 then return false,'PHYSICAL_ESCORT_REQUIRED'end
 return true
end
return Proof
