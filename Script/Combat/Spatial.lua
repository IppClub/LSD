-- Decision-time positions are world-space body centers, not armor-edge distances.
local S={version=2}
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
function S.capture(battle,owner)
 local K=require('Combat.Displacement');local control=K.snapshot(owner)
 local s={version=2,x=owner.x,y=owner.y,velocityX=owner.velocityX,velocityY=owner.velocityY,grounded=owner.onSurface,control=control}
 local function relative(unit)return {dx=unit.x-owner.x,dy=unit.y-owner.y,distance=math.sqrt((unit.x-owner.x)^2+(unit.y-owner.y)^2)}end
 local nearest
 for _,enemy in ipairs(battle.enemies or {})do if enemy.enemyHP>0 then
  local p=relative(enemy.enemy);if not nearest or p.distance<nearest.distance then
   p.source=enemy.combatSource or enemy.enemyAsset or 'unknown';p.phase=enemy.enemyPhase or 'unknown';p.skill=enemy.enemyPhase=='attack' and enemy.enemyStrike and enemy.enemyStrike.kind or nil;nearest=p
  end
 end end
 s.threat=nearest
 local ally
 local function consider(unit,hp)
  if unit~=owner and hp>0 then local p=relative(unit);if not ally or p.distance<ally.distance then p.actor=unit==battle.mentor and 'mentor' or unit.entity.name;ally=p end end
 end
 consider(battle.mentor,battle.mentorHP)
 for _,a in ipairs(battle.learners)do consider(a.student,a.studentHP)end
 s.ally=ally;s.boss=relative(battle.roots[3].enemy)
 local status=battle.effects.states[owner]or {};local now=require('Dora').App.runningTime
 s.dragged=now<(status.dragUntil or 0);s.exhausted=now<(status.exhaustedUntil or 0)
 local parts=battle.partCombat
 if parts and not parts.closed and battle.roots[3].enemyHP>0 then
  parts:sample()
  s.bossHull=require('Combat.HitGeometry').distance({x=owner.x,y=owner.y},parts.target.regions)
  local muzzle=parts:muzzle(owner)
  local closest=require('Combat.HitGeometry').distance(muzzle,parts.target.regions)
  if closest then s.firearm={muzzle=muzzle,travel=require('Combat.FirearmRules').travel,hullDistance=closest.distance,withinTravel=closest.distance<=require('Combat.FirearmRules').travel}end
 end
 return s
end
function S.validate(s)
 if type(s)~='table' or (s.version~=1 and s.version~=2) or type(s.grounded)~='boolean' or type(s.dragged)~='boolean' or type(s.exhausted)~='boolean'then return false end
 for _,k in ipairs({'x','y','velocityX','velocityY'})do if not finite(s[k])then return false end end
 if type(s.control)~='table' or type(s.control.blocked)~='boolean' or not ({free=true,hit=true,fall=true,standUp=true,idle=true,prepare=true})[s.control.phase]then return false end
 for _,key in ipairs({'boss','ally','threat'})do local v=s[key];if v then
  if type(v)~='table' or not finite(v.dx)or not finite(v.dy)or not finite(v.distance)or v.distance<0 or math.abs(v.distance-math.sqrt(v.dx*v.dx+v.dy*v.dy))>.01 then return false end
 elseif key=='boss'then return false end end
 if s.version==2 then
  local h=s.bossHull
  if h and (type(h)~='table' or not finite(h.distance) or h.distance<0 or type(h.position)~='table' or not finite(h.position.x) or not finite(h.position.y) or type(h.part)~='string' or type(h.inside)~='boolean')then return false end
  local f=s.firearm
  if f and (type(f)~='table' or not finite(f.travel) or f.travel<=0 or not finite(f.hullDistance) or f.hullDistance<0 or type(f.muzzle)~='table' or not finite(f.muzzle.x) or not finite(f.muzzle.y) or f.withinTravel~=(f.hullDistance<=f.travel))then return false end
 end
 return true
end
function S.eventValid(e)
 if type(e)~='table' or not ({mentor=true,ninilite=true,wuyun=true})[e.actor] or e.origin~='forced' or not ({hit=true,pull=true,fall=true,standUp=true})[e.kind] or type(e.source)~='string' or type(e.skill)~='string'then return false end
 for _,k in ipairs({'at','x','y','velocityX','velocityY'})do if not finite(e[k])then return false end end
 return e.at>=0
end
return S
