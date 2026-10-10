-- Real muzzle-driven projectiles. A released weapon invalidates preparation,
-- while an already emitted round remains in flight until contact/end of battle.
local D=require('Dora');local P=D.Platformer
local V=require('Combat.FirearmVisuals');local R=require('Combat.FirearmRules')
local Profiles=require('Combat.WeaponProfiles');local F={}
function F.profile(asset)
 if asset=='kineticgun' then return Profiles.mentor end
 if asset=='empgun' then return Profiles.laser end
end
function F.canFire(controller)
 local lease=controller.lease
 if not lease or not lease.active or not F.profile(lease.asset)then return false end
 local supplies=controller.battle.supplies
 if not supplies then return true end
 local owner=lease.owner.data.supplyActorId
 local item=({kineticgun='kinetic',empgun='emp'})[lease.asset]
 return owner~=nil and item~=nil and supplies:canSpend(owner,item)
end
function F.aim(controller)
 local shot=controller.shotAim
 if not shot or shot.fired or not shot.lease.active then return end
 local gun=shot.lease.borrowed;local world=controller.battle.world
 local p=world:convertToNodeSpace(gun:convertToWorldSpace(D.Vec2.zero))
 local q=world:convertToNodeSpace(gun:convertToWorldSpace(D.Vec2(300,0)))
 local desired=math.deg(math.atan(shot.target.y-p.y,shot.target.x-p.x))
 local actual=math.deg(math.atan(q.y-p.y,q.x-p.x));local delta=(desired-actual+180)%360-180
 shot.rotation=math.max(-45,math.min(45,shot.rotation+delta*(controller.unit.faceRight and -1 or 1)*.5))
 controller.unit.playable:setBoneRotation('weapon-aim',shot.rotation)
end
function F.fire(c)
 local s=c.shotAim;local u,b=c.unit,c.battle
 if not s or s.fired or not s.lease.active or c.lease~=s.lease or b.phase~='playing' or c.record.enemyHP<=0 then return false end
 s.fired=true
 local gun=s.lease.borrowed;local world=b.world;local profile=assert(F.profile(s.lease.asset))
 local origin=world:convertToNodeSpace(gun:convertToWorldSpace(D.Vec2.zero))
 local muzzle=world:convertToNodeSpace(gun:convertToWorldSpace(D.Vec2(300,0)))
 local dx,dy=muzzle.x-origin.x,muzzle.y-origin.y;local length=math.sqrt(dx*dx+dy*dy)
 if length<1 or dx*(u.faceRight and 1 or -1)<=0 then return false end
 if b.supplies then
  local ok,why=b.supplies:emitStolen(s.lease)
  if not ok then c.supplyFailure=why;return false end
 end
 local vx,vy=dx/length,dy/length
 local strike=c.strike;local event={clip='shoot',at=D.App.runningTime,weapon=profile.id,x=muzzle.x,y=muzzle.y,dx=vx,dy=vy};strike.impacts[#strike.impacts+1]=event
 local targets={};for _,t in ipairs(b:targets())do if t.hp()>0 then targets[t.unit]=t end end
 -- The visible barrel must not spawn the round beyond a nearby body or wall.
 local nearest,point,terrain
 world:raycast(origin,muzzle,false,function(body,hit)
  if body.group==P.Data.groupTerrain or targets[body] then
   local t=((hit.x-origin.x)*dx+(hit.y-origin.y)*dy)/(length*length)
   if t>=0 and t<=1 and (not nearest or t<nearest)then nearest=t;point=hit;terrain=body.group==P.Data.groupTerrain end
  end;return false
 end)
 c.casings=c.casings or {};c.projectiles=c.projectiles or {}
 if profile.id=='kinetic' then V.casing(u,gun,world,c.casings)end
 if terrain then event.blocked='BARREL_TERRAIN';return false end
 local position=point and D.Vec2(point.x-vx*12,point.y-vy*12) or muzzle
 local angle=math.deg(math.atan(vy,math.abs(vx)));local faceRight=u.faceRight
 local def=P.BulletDef();def.lifeTime=R.lifeTime;def.highSpeedFix=true;def.gravity=D.Vec2.zero;def:setAsCircle(10);def:setVelocity(angle,R.speed)
 def.face=P.Face(function()
  if profile.id=='kinetic' then return V.bulletFace(-angle,faceRight)end
  local dot=D.DrawNode();dot:drawDot(D.Vec2.zero,8,D.Color(0xff8dbef3));return dot
 end)
 local bullet=P.Bullet(def,u);local allow=P.TargetAllow();allow:allow('Enemy',true);allow.terrainAllowed=true;bullet.targetAllow=allow:toValue()
 bullet:slot('HitTarget',function(projectile,target)
  event.contactAt=D.App.runningTime;event.contactGroup=target.group;event.contactX=target.x;event.contactY=target.y
  if b.phase=='playing' then
   local t=targets[target]
   if t and t.hp()>0 then
    if t.hitWeapon then t.hitWeapon(profile,event)
    elseif profile.healthDamage>0 then t.damage(profile.healthDamage,{kind='stolen-firearm',attacker=u,weapon=profile.id,weaponOwner=s.lease.owner.data.supplyActorId,shotAt=event.at,strikeStarted=strike.started})
    elseif t.damageArmor then t.damageArmor(profile.armorDamage)end
    strike.hits=strike.hits+1;event.hitAt=D.App.runningTime;event.hit=true
   end
  end
  projectile.hitStop=true
 end)
 bullet.position=position;bullet:addTo(world);c.projectiles[#c.projectiles+1]=bullet
 require('Tutorial.LightStrip').LightStrip(bullet.position,bullet,profile.id=='kinetic' and 0xccffffff or 3431841523)
 event.emitted=true;return true
end
local function prune(list,clear)
 if not list then return end
 for i=#list,1,-1 do
  if clear and list[i].parent then list[i]:removeFromParent()end
  if not list[i].parent then table.remove(list,i)end
 end
end
function F.clear(c)
 prune(c.projectiles,true);prune(c.casings,true)
end
function F.update(c,now)
 local dt=math.max(0,math.min(.1,now-(c.aimUpdated or now)));c.aimUpdated=now
 local clear=c.battle.phase~='playing'
 prune(c.projectiles,clear);prune(c.casings,clear)
 if c.busy and c.strike.skill=='shoot' then F.aim(c)
 elseif c.shotAim then
  local s=c.shotAim;s.rotation=s.rotation*(1-math.min(1,dt/.08))
  if math.abs(s.rotation)<.05 then s.rotation=0 end
  c.unit.playable:setBoneRotation('weapon-aim',s.rotation)
  if s.rotation==0 then c.shotAim=nil end
 end
end
return F
