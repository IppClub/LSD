local Proof={}
local function number(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
local function positive(v)return number(v)and v>0 end
function Proof.validate(p,model)
 if type(p)~='table'or p.encounter~='twins-evacuation'or p.status~='won'or not positive(p.seconds)then return false,'RESCUE_VICTORY_REQUIRED'end
 if not positive(p.mentorHP)or type(p.learner)~='table'or not positive(p.learner.hp)or not positive(p.learner.modelActions)or type(model)~='table'or not require("Training.Summary").matches(p.learner,model) then return false,'RESCUE_PARTY_REQUIRED'end
 if not number(p.mentorHits)or not number(p.learner.hits)or not number(p.fireHits)or p.mentorHits+p.learner.hits+p.fireHits<=0 then return false,'RESCUE_COMBAT_REQUIRED'end
 if type(p.twins)~='table'or #p.twins~=2 then return false,'BOTH_TWINS_REQUIRED'end
 for i,t in ipairs(p.twins)do
  local start=i==1 and 4150 or 4350;local goal=i==1 and 5400 or 5560
  if type(t)~='table'or t.role~=(i==1 and 'vika'or'vivi')or not positive(t.hp)or t.hp>100 or t.startX~=start or not number(t.x)or t.x<goal-1 or t.x>goal+1 or not positive(t.distance)or t.distance<goal-start-1 or not positive(t.walkSeconds)or t.distance/t.walkSeconds>85.1 or type(t.loops)~='table'or not positive(t.loops.fmove)then return false,'PHYSICAL_TWINS_ESCORT_REQUIRED'end
 end
 if type(p.stages)~='table'or #p.stages~=2 then return false,'TWO_RESCUE_ZONES_REQUIRED'end
 local stops={{4800,4960},{5400,5560}}
 for i,s in ipairs(p.stages)do
  if type(s)~='table'or s.stage~=i or not positive(s.seconds)or type(s.positions)~='table'or #s.positions~=2 or type(s.guards)~='table'or #s.guards~=2 then return false,'INVALID_RESCUE_ZONE'end
  for j,x in ipairs(s.positions)do if not number(x)or math.abs(x-stops[i][j])>1 then return false,'SAFE_POINT_REQUIRED'end end
  for _,g in ipairs(s.guards)do
   if type(g)~='table'or g.hp~=0 or not number(g.loseStarted)or not number(g.loseEnded)or not positive(g.loseDuration)or g.loseEnded-g.loseStarted<g.loseDuration-.04 or type(g.strikes)~='table'then return false,'FULL_DEFEAT_REQUIRED'end
   for _,s in ipairs(g.strikes)do
    if type(s)~='table'or not require('Training.EnemyCombat').specs[s.kind]or not positive(s.duration)or not number(s.startedAt)or not number(s.completedAt)or s.completedAt-s.startedAt<s.duration-.05 then return false,'FULL_ATTACK_REQUIRED'end
    if s.hit and (not number(s.attackAt)or s.attackAt<=s.startedAt or s.attackAt>s.completedAt)then return false,'AUTHORED_ATTACK_POINT_REQUIRED'end
   end
  end
 end
 local w=p.ward
 if type(w)~='table'or w.x~=4700 or w.y~=150 or w.radius~=440 or w.capacity~=160 or not number(w.absorbed)or not number(w.remaining)or w.absorbed<0 or w.remaining<0 or math.abs(w.absorbed+w.remaining-160)>.01 or type(p.contacts)~='table'then return false,'FINITE_WARD_REQUIRED'end
 local absorbed=0;local damage={vika=0,vivi=0}
 for _,hit in ipairs(p.contacts)do
  if type(hit)~='table'or damage[hit.role]==nil or not number(hit.x)or not number(hit.y)or not number(hit.absorbed)or not number(hit.dealt)or not positive(hit.amount)or hit.absorbed<0 or hit.dealt<0 or math.abs(hit.amount-hit.absorbed-hit.dealt)>.01 then return false,'INVALID_RESCUE_CONTACT'end
  if hit.absorbed>0 and (hit.x-w.x)^2+(hit.y-w.y)^2>w.radius^2 then return false,'WARD_RANGE_REQUIRED'end
  absorbed=absorbed+hit.absorbed;damage[hit.role]=damage[hit.role]+hit.dealt
 end
 if math.abs(absorbed-w.absorbed)>.01 then return false,'WARD_CONTACT_REQUIRED'end
 for _,t in ipairs(p.twins)do if math.abs(t.hp-(100-damage[t.role]))>.01 then return false,'TWIN_HEALTH_REQUIRED'end end
 return true
end
return Proof
