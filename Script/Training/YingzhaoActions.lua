-- Aim intent is committed before an authored shot, never a promised hit.
local D=require('Dora');local A={version=1}
local parts={};for _,id in ipairs(require('Training.YingzhaoFeatures').parts)do parts[id]=true end
-- Native float positions can differ by subpixels at a shared arena clamp.
-- Preserve the existing exact-overlap convention (face right) in that tie.
function A.movementFaceRight(owner,target)return target.x-owner.x>=-.01 end
function A.decode(label,version)
 version=version or 1
 if version~=1 and version~=2 then return end
 if version==2 and type(label)=='string'then
  local skill,side=label:match('^(%a+)@(%a+)$')
  if (skill=='fire'or skill=='wind')and(side=='left'or side=='right')then return skill,nil,side=='right'end
 end
 if label=='idle'or label=='fmove'or label=='bmove'or label=='melee'then return label end
 local part=type(label)=='string'and label:match('^shoot@([%w]+)$')
 if part and (parts[part]or part=='summon')then return 'laser',part end
end
function A.plan(b,arena,part,manualPreview)
 local p=b.bossCombat;local owner=arena.student
 if b.phase~='playing'or p.closed then return nil,'NOT_PLAYING'end
 local target,regions
 if part=='summon'then
  local distance
  for _,e in ipairs(b.enemies)do if e~=p.boss and e.enemyHP>0 and e.enemy.visible and e.enemy.opacity>.1 then
   local d=math.abs(e.enemy.x-owner.x);if not distance or d<distance then target=e;distance=d end
  end end
  if not target then return nil,'NO_VISIBLE_SUMMON'end
  local u=target.enemy;local w,h=u.unitDef.size.width/2,u.unitDef.size.height/2
  regions={{id='body',vertices={{x=u.x-w,y=u.y-h},{x=u.x+w,y=u.y-h},{x=u.x+w,y=u.y+h},{x=u.x-w,y=u.y+h}}}}
 elseif parts[part]then
  if not p.armor:available()then return nil,'BOSS_HIDDEN'end
  p:sample();target=p.boss;regions=p.armor.target.regions
 else return nil,'UNKNOWN_PART'end
 local face=target.enemy.x>=owner.x
 local Muzzle=require('Combat.Muzzle')
 local learnerOrigin=not manualPreview and Muzzle.learnerPreview(b.world,owner,0,face)or nil
 local origin=manualPreview and Muzzle.manualPreview(b.world,owner,0,face)or learnerOrigin or Muzzle.preview(b.world,owner,face)
 local originAtAngle=manualPreview and function(angle)return Muzzle.manualPreview(b.world,owner,angle,face)end
  or learnerOrigin and function(angle)return Muzzle.learnerPreview(b.world,owner,angle,face)end or nil
 -- A summoned body strictly before the requested part's padded bounding box
 -- cannot be bypassed by the exact polygon test. Reject these rays cheaply.
 local blockers={}
 if target==p.boss then for _,e in ipairs(b.enemies)do
  local u=e.enemy
  if e~=p.boss and e.enemyHP>0 and u.visible and u.opacity>.1 then
   local w,h=u.unitDef.size.width/2,u.unitDef.size.height/2
   blockers[#blockers+1]={id='body',vertices={{x=u.x-w,y=u.y-h},{x=u.x+w,y=u.y-h},{x=u.x+w,y=u.y+h},{x=u.x-w,y=u.y+h}}}
  end
 end end
 local function preblocked(from,to,region)
  local box=region.bounds;if not box or #blockers==0 then return false end
  local lo,hi=0,1
  for _,axis in ipairs({'x','y'})do
   local start=from[axis];local delta=to[axis]-start
   local lower=box[axis=='x'and'minX'or'minY'];local upper=box[axis=='x'and'maxX'or'maxY']
   local pad=1e-8*(1+math.abs(delta)+upper-lower);lower=lower-pad;upper=upper+pad
   if math.abs(delta)<1e-30 then if start<lower or start>upper then return false end
   else
    local first,last=(lower-start)/delta,(upper-start)/delta;if first>last then first,last=last,first end
    lo=math.max(lo,first);hi=math.min(hi,last);if lo>hi then return false end
   end
  end
  local hit=require('Combat.HitGeometry').nearest(from,to,blockers)
  return hit and hit.t<lo-1e-8 or false
 end
 local ray,why=require('Combat.PartAim').solve(origin,face,part=='summon'and'body'or part,regions,function(from,to)
  local hit,terrain=p:contact(from,to)
  return terrain or not hit or (target==p.boss and (hit.enemy~=nil or hit.part~=part))or(target~=p.boss and hit.enemy~=target)
 end,true,preblocked,originAtAngle)
 -- Projectile emission sweeps from the owner's x to the muzzle, so a close
 -- summoned body can be hit before the muzzle. Preserve that same first-contact
 -- and terrain rule instead of rejecting every ray whose muzzle is inside it.
 if not ray and part=='summon' then
  local point={x=origin.x+(face and 1 or -1),y=origin.y}
  local hit,terrain=p:contact({x=owner.x,y=origin.y},point)
  if not terrain and hit and hit.enemy==target then
   ray={angle=0,origin=origin,point=point,intendedPart='body',distance=1}
  end
 end
 if not ray then return nil,why end
 ray.faceRight=face;ray.intent=part;ray.committedAt=D.App.runningTime;ray.muzzleMode=not manualPreview and 'committed-point-v1' or nil
 ray.manualPreview=manualPreview or nil
 return ray
end
-- The chosen world point is frozen before the authored animation. At release,
-- compensate only for the real gun's pose, never for a target's newer position.
function A.emission(aim,muzzle)
 if aim.muzzleMode~='committed-point-v1' then return {angle=aim.angle,origin=muzzle} end
 local dx=(aim.point.x-muzzle.x)*(aim.faceRight and 1 or -1)
 local dy=aim.point.y-muzzle.y
 local distance=math.sqrt(dx*dx+dy*dy)
 if dx<=0 or math.abs(dy)>dx or distance>require('Combat.FirearmRules').travel then return nil,'COMMITTED_POINT_UNREACHABLE' end
 return {angle=-math.deg(math.atan(dy,dx)),origin={x=muzzle.x,y=muzzle.y}}
end
-- Validate committed intent independently of the eventual contact: a miss or a
-- different first body is legitimate after the scene moves.
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
local function point(v)return type(v)=='table'and finite(v.x)and finite(v.y)end
function A.validateStep(step)
 local aim=step.aim;if aim==nil then return true end
 if step.action~='shoot'or not ({mentor=true,ninilite=true,wuyun=true})[step.actor]or type(aim)~='table'or not (parts[aim.intent]or aim.intent=='summon')then return false,'INVALID_BOSS_AIM'end
 if aim.intendedPart~=(aim.intent=='summon'and'body'or aim.intent)or type(aim.faceRight)~='boolean'or not finite(aim.angle)or math.abs(aim.angle)>45 or not point(aim.origin)or not point(aim.point)or not finite(aim.distance)or not finite(aim.committedAt)or not finite(step.started)or aim.committedAt>step.started or step.started-aim.committedAt>.1 then return false,'INVALID_BOSS_AIM'end
 local dx=(aim.point.x-aim.origin.x)*(aim.faceRight and 1 or -1);local dy=aim.point.y-aim.origin.y
 local distance=math.sqrt(dx*dx+dy*dy)
 if dx<=0 or distance>require('Combat.FirearmRules').travel or math.abs(distance-aim.distance)>1e-4 or math.abs(-math.deg(math.atan(dy,dx))-aim.angle)>1e-4 then return false,'INVALID_BOSS_AIM_GEOMETRY'end
 if aim.muzzleMode~=nil and aim.muzzleMode~='committed-point-v1' then return false,'INVALID_BOSS_AIM_MODE'end
 if step.emitted~=nil then
  if step.emitted~=1 or not point(step.muzzle)or not point(step.velocity)or step.velocity.x*(aim.faceRight and 1 or -1)<=0 then return false,'BOSS_AIM_EMISSION_MISMATCH'end
  local expected=aim.angle
  if aim.muzzleMode then
   local shot=A.emission(aim,step.muzzle);local emission=step.aimEmission
   if not shot or type(emission)~='table'or not finite(emission.angle)or not point(emission.origin)or not finite(emission.at)or emission.at<step.started or step.ended and emission.at>step.ended or math.abs(emission.origin.x-step.muzzle.x)>1e-4 or math.abs(emission.origin.y-step.muzzle.y)>1e-4 or math.abs(emission.angle-shot.angle)>1e-4 then return false,'BOSS_POINT_EMISSION_MISMATCH'end
   expected=shot.angle
   if math.abs(math.sqrt(step.velocity.x^2+step.velocity.y^2)-require('Combat.FirearmRules').speed)>.02 then return false,'BOSS_POINT_SPEED_MISMATCH'end
  elseif step.aimEmission~=nil then return false,'INVALID_BOSS_AIM_MODE'end
  if math.abs(-math.deg(math.atan(step.velocity.y,math.abs(step.velocity.x)))-expected)>.02 then return false,'BOSS_AIM_EMISSION_MISMATCH'end
 elseif step.velocity~=nil or step.muzzle~=nil or step.aimEmission~=nil then return false,'BOSS_AIM_EMISSION_MISMATCH'end
 return true
end
function A.legal(actor,label,version)
 local action=A.decode(label,version)
 return action~=nil and (action~='melee'or actor=='wuyun')and(action~='wind'or actor=='wuyun')and(action~='fire'or actor=='ninilite')
end
function A.available(b,arena,label,version)
 local action,part=A.decode(label,version)
 if not action then return false,'UNKNOWN_YINGZHAO_ACTION'end
 if not A.legal(arena.character.id,label,version)then return false,'WRONG_SKILL_ACTOR'end
 if action=='wind'or action=='fire'then
  if not b.magic or b.magic.roles[action]~=arena then return false,'ROLE_ABSENT'end
  return b.magic:available(action)
 end
 local ok,why=arena:available(action);if not ok then return false,why end
 if action=='fmove'or action=='bmove'then
  local u=arena.student;local face=arena.targetFacingForAction and arena.targetFacingForAction(action)
  if face==nil then face=u.faceRight end
  local direction=(face and 1 or -1)*(action=='bmove'and -1 or 1)
  if (direction<0 and u.x<=arena.minX+.01)or(direction>0 and u.x>=arena.maxX-.01)then return false,'ARENA_BOUNDARY'end
 end
 if part then local aim,reason=A.plan(b,arena,part);if not aim then return false,reason end end
 return true
end
function A.request(b,arena,label,source,version)
 local action,part,face=A.decode(label,version);if not action then return false,'UNKNOWN_YINGZHAO_ACTION'end
 if not A.legal(arena.character.id,label,version)then return false,'WRONG_SKILL_ACTOR'end
 if action=='wind'or action=='fire'then
  local ok,why=A.available(b,arena,label,version);if not ok then return false,why end
  return b.magic:request(action,{source=source or 'scripted',faceRight=face,noQueue=true})
 end
 if action=='fmove'or action=='bmove'then local ok,why=A.available(b,arena,label,version);if not ok then return false,why end end
 local ray,why
 if part then ray,why=A.plan(b,arena,part);if not ray then return false,why end end
 arena.yingzhaoAim=ray
 local ok,reason=arena:request(action,source or 'scripted')
 arena.yingzhaoAim=nil
 return ok,reason
end
return A
