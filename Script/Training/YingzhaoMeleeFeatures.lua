-- Current visible body contact, not a prediction of the later attack frame.
local M={version=1,names={'meleeReach'},categories={meleeReach='unknown reachable blocked distant'}}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function M.capture(b,owner,target)
 if b.phase~='playing'or not target then return {schemaVersion=1,present=false}end
 local face=require('Training.YingzhaoActions').movementFaceRight(owner,target.enemy)
 local hit,terrain=b.bossCombat:probeMelee(owner,face)
 return {schemaVersion=1,present=true,ownX=owner.x,ownY=owner.y,faceRight=face,
  targetX=target.enemy.x,segmentLength=300,terrain=terrain~=nil and terrain~=false,
  contact=not hit and'none'or ((target==b.bossCombat.boss and not hit.enemy)or hit.enemy==target)and'target'or'other',
  fraction=hit and hit.t or nil}
end
function M.project(raw)
 if type(raw)~='table'or raw.schemaVersion~=1 or type(raw.present)~='boolean'then return end
 if not raw.present then return {meleeReach='unknown'}end
 if not finite(raw.ownX)or not finite(raw.ownY)or not finite(raw.targetX)or type(raw.faceRight)~='boolean'or raw.faceRight~=(raw.targetX-raw.ownX>=-.01)or raw.segmentLength~=300 or type(raw.terrain)~='boolean'then return end
 if raw.contact~='none'and raw.contact~='target'and raw.contact~='other'then return end
 if raw.contact=='none'then if raw.fraction~=nil then return end
 elseif not finite(raw.fraction)or raw.fraction<0 or raw.fraction>1 then return end
 return {meleeReach=raw.terrain and'blocked'or raw.contact=='target'and'reachable'or raw.contact=='other'and'blocked'or'distant'}
end
function M.validate(s)
 local raw=s.meleeProbe;local state=M.project(raw)
 if not state or state.meleeReach~=s.meleeReach then return false end
 if raw.present and(s.target=='none'or raw.ownX~=s.ownX or raw.targetX~=s.targetX)then return false end
 return true
end
return M
