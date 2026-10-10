-- Projectile positions live in world coordinates; roads only affect display transforms.
local D=require('Dora');local M={}
local profiles
-- Authored firing-pose samples, independent of enemies and targeting. Keep
-- uncalibrated weapons/characters on their existing preview convention.
function M.manualLocal(owner,angle,faceRight)
 local id=owner.data.mentorMuzzleProfile
 if not id or owner.data.combatWeaponAsset~='kineticgun' or owner.data.combatWeaponLook~='PT' then return end
 if not profiles then profiles=D.json.decode(assert(D.Content:load('Data/Combat/mentor-muzzle-preview.json')),32).profiles end
 local profile=profiles[id];if not profile then return end
 local points=profile.points;angle=math.max(-45,math.min(45,angle or 0))
 local index=#points-1;for i=1,#points-1 do if angle<=points[i+1].angle then index=i;break end end
 local a,b=points[index],points[index+1];local t=(angle-a.angle)/(b.angle-a.angle)
 if faceRight==nil then faceRight=owner.faceRight end
 return D.Vec2((a.x+(b.x-a.x)*t)*(faceRight and 1 or -1),a.y+(b.y-a.y)*t)
end
function M.manualPreview(world,owner,angle,faceRight)
 local localPoint=M.manualLocal(owner,angle,faceRight)
 if not localPoint then return M.preview(world,owner,faceRight) end
 local point=world:convertToNodeSpace(owner:convertToWorldSpace(localPoint))
 return {x=point.x,y=point.y}
end
function M.preview(world,owner,faceRight)
 if faceRight==nil then faceRight=owner.faceRight end
 local point=world:convertToNodeSpace(owner:convertToWorldSpace(D.Vec2(faceRight and 65 or -65,-20)))
 return {x=point.x,y=point.y}
end
-- Learner EMP firing poses differ from idle poses and from the mentor gun.
-- This predicts an authored origin only; actual emission/contact stay authoritative.
local learnerProfiles
function M.learnerLocal(owner,angle,faceRight)
 local id=owner.data.supplyActorId
 if owner.data.combatWeaponAsset~='empgun' or owner.data.combatWeaponLook~='PT' then return end
 local gun=owner.playable:getSlot('pistol')
 if not gun or math.abs(gun.scaleX-.2)>1e-5 or math.abs(gun.scaleY-.2)>1e-5 then return end
 if not learnerProfiles then learnerProfiles=D.json.decode(assert(D.Content:load('Data/Combat/learner-muzzle-preview.json')),32).profiles end
 local profile=learnerProfiles[id];if not profile then return end
 local points=profile.points;angle=math.max(-45,math.min(45,angle or 0))
 local index=#points-1;for i=1,#points-1 do if angle<=points[i+1].angle then index=i;break end end
 local a,b=points[index],points[index+1];local t=(angle-a.angle)/(b.angle-a.angle)
 if faceRight==nil then faceRight=owner.faceRight end
 return D.Vec2((a.x+(b.x-a.x)*t)*(faceRight and 1 or -1),a.y+(b.y-a.y)*t)
end
function M.learnerPreview(world,owner,angle,faceRight)
 local localPoint=M.learnerLocal(owner,angle,faceRight);if not localPoint then return end
 local point=world:convertToNodeSpace(owner:convertToWorldSpace(localPoint))
 return {x=point.x,y=point.y}
end
function M.actual(world,owner)
 local gun=owner.playable:getSlot('pistol')
 if not gun then return M.preview(world,owner)end
 local point=world:convertToNodeSpace(gun:convertToWorldSpace(D.Vec2(300,0)))
 return {x=point.x,y=point.y}
end
return M
