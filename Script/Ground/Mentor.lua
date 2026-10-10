local K=require('Combat.Displacement')
local D=require("Dora")
local P=D.Platformer
local Animation=require("CombatAnimation")
local Visuals=require('Combat.FirearmVisuals')
local Mentor={}
function Mentor.createAsync(self,mentorName)
	mentorName=mentorName=="charF" and "charF" or "charM"
	D.Cache:loadAsync("spine:"..mentorName)
 require("Combat.Movement").register("groundMentorMove",270)
	-- Global action definitions must not retain a closed battle.
	local battleRef=setmetatable({self},{__mode="v"})
	P.UnitAction:add("groundMentorShot",{priority=3,reaction=0,recovery=0.15,
		available=function(owner) local battle=battleRef[1]; return battle~=nil and battle.phase=="playing" and (not battle.supplies or battle.supplies:canSpend("mentor","kinetic")) and not owner.data.weaponDisarmed and not K.blocked(owner) and owner.onSurface and D.App.runningTime>=battle.nextMentorShot end,
		create=function(owner)
			local self=battleRef[1]; if not self or self.phase~="playing" then return function()return true end end
			local weaponRevision=owner.data.weaponRevision or 0
   local combatStep=self.arena.beginCombatAction and self.arena.beginCombatAction(owner,"mentor")
   self.nextMentorShot=D.App.runningTime+1
			owner.velocityX=0
   -- Turn before the authored firing animation updates the gun transform.
   local initialRedirect=self.effects and self.effects:redirect(owner)
   if initialRedirect then owner.faceRight=initialRedirect.unit.x>=owner.x end
			owner.playable:slot("attack"):set(function()
				local targetEnemy
    if self.mentorTarget then targetEnemy=self.mentorTarget() else targetEnemy=self.arena.enemy end
				if owner.data.weaponDisarmed or (owner.data.weaponRevision or 0)~=weaponRevision or self.phase~="playing" or not targetEnemy or (not self.mentorTarget and self.arena.enemyHP<=0) then return end
    local redirected=self.effects and self.effects:redirect(owner)
    if redirected then owner.faceRight=redirected.unit.x>=owner.x end
				local gun=owner.playable:getSlot("pistol")
    local position=gun and self.arena.world:convertToNodeSpace(gun:convertToWorldSpace(D.Vec2(300,0))) or owner.position+D.Vec2(owner.faceRight and 65 or -65,-20)
    local shotAngle=self.mentorAim and self.mentorAim.angle or 0
    if not redirected and self.arena.prepareMentorShot then
     local shot=self.arena.prepareMentorShot(owner,combatStep,{x=position.x,y=position.y},shotAngle)
     if not shot then return end
     position=D.Vec2(shot.origin.x,shot.origin.y);shotAngle=shot.angle
    end
    if self.supplies then
     local ok,why=self.supplies:emit('mentor','kinetic',1,'mentor',combatStep)
     if not ok then self.supplyFailure=why;return end
    end
    -- A nearby redirected ally can stand between the character and the authored
    -- muzzle. Start just before the first obstruction so normal bullet physics
    -- resolves contact, rather than spawning beyond the ally (or a wall).
    if redirected then
     local muzzle=position;local origin=D.Vec2(owner.x,muzzle.y)
     local nearest,point,blocked;local dx=muzzle.x-origin.x
     if math.abs(dx)>1e-6 then
      self.arena.world:raycast(origin,muzzle,false,function(body,hit)
       if body==redirected.unit or body.group==P.Data.groupTerrain then
        local t=(hit.x-origin.x)/dx
        if t>=0 and t<=1 and (not nearest or t<nearest)then nearest=t;point=hit;blocked=body.group==P.Data.groupTerrain end
       end
       return false
      end)
      if blocked then
       if gun then Visuals.casing(owner,gun,self.arena.world,self.mentorCasings)end
       return
      end
      if point then position=D.Vec2(point.x-(dx>0 and 12 or -12),point.y)end
     end
    end
    -- BulletDef retains its face factory after the bullet leaves the world.
    -- Capture shot values only, never the battle or emitting unit.
    local shotRight=owner.faceRight
    local def=P.BulletDef(); def.lifeTime=require('Combat.FirearmRules').lifeTime; def.highSpeedFix=true; def.gravity=D.Vec2.zero
				def:setAsCircle(10); def:setVelocity(-shotAngle,require('Combat.FirearmRules').speed)
				def.face=P.Face(function()return Visuals.bulletFace(shotAngle,shotRight)end)
				local bullet=P.Bullet(def,owner)
				local allow=P.TargetAllow(); allow:allow("Enemy",true); if redirected then allow:allow("Friend",true) end; allow.terrainAllowed=true
				bullet.targetAllow=allow:toValue()
				bullet:slot("HitTarget",function(projectile,target)
     if redirected and target==redirected.unit and self.phase=="playing" then redirected.damage(15,{kind="virus-friendly-fire"}); self.friendlyHits=(self.friendlyHits or 0)+1
     elseif target==targetEnemy and self.phase=="playing" then
						if self.damageMentorTarget then self.damageMentorTarget(target,5) else self.arena.enemyHP=math.max(0,self.arena.enemyHP-5) end; self.mentorHits=self.mentorHits+1
					end
					projectile.hitStop=true
				end)
    bullet.position=position
    bullet:addTo(self.arena.world)
    require('Tutorial.LightStrip').LightStrip(bullet.position,bullet,0xccffffff)
    if gun then Visuals.casing(owner,gun,self.arena.world,self.mentorCasings)end
				self.arena.projectiles[#self.arena.projectiles+1]=bullet
    if redirected and self.arena.observeRedirectedProjectile then self.arena.observeRedirectedProjectile(bullet,"mentor",combatStep)end
    if self.arena.observeProjectile and not redirected then self.arena.observeProjectile(bullet,"mentor",combatStep)end
			end)
			return D.once(function() local _,completed=Animation.playOnceAsync(owner,"pistol");if self.arena.finishCombatAction then self.arena.finishCombatAction(combatStep,owner,"mentor",completed and 'completed' or 'interrupted')end; Animation.rest(owner); return true end)
		end})
	self.mentor=self.arena.spawnUnit(mentorName,1,520,{"groundMentorMove","groundMentorShot"})
	self.mentor.data.supplyActorId='mentor'
 self.mentor.data.mentorMuzzleProfile=mentorName
	self.mentorCasings={}
 require("Combat.Movement").attach(self.mentor,self,"groundMentorMove",270)
 self.mentor.faceRight=true; Animation.rest(self.mentor)
	self.arena.extraEnemyTargets={{unit=self.mentor,damage=function(n) self.mentorHP=math.max(0,self.mentorHP-n) end}}
	local gun=D.Spine("kineticgun"); gun.look="PT"; gun.scaleX=0.3; gun.scaleY=0.3
	self.mentor.playable:setSlot("pistol",gun)
 self.mentor.data.combatWeaponAsset='kineticgun';self.mentor.data.combatWeaponLook='PT'
 self.mentorAim=require('Combat.Aim').new(self.mentor,function()
  return (not self.supplies or self.supplies:canSpend('mentor','kinetic')) and not self.mentor.data.weaponDisarmed and not K.blocked(self.mentor) and self.phase=='playing' and self.mentorHP>0 and (not self.effects or not self.effects:blocked(self.mentor,'shoot')) and self.mentor.onSurface and not self.mentor:isDoing('groundMentorShot') and D.App.runningTime>=self.nextMentorShot
 end,function()return self:command('shoot')end)
 return self.mentor
end
function Mentor.bindAim(hud,battle)
 require('UI.AimHint').attach(hud,function()
  return battle.mentorAim.held,battle.mentorAim.precision,battle.phase=='ready'or battle.mentorAim.canStart()
 end)
 hud:gslot('Skill.Began',function()battle.mentorAim:begin()end)
 hud:gslot('Skill.Ended',function(cancelled)
  if cancelled then battle.mentorAim:cancel();return end
  -- Mark only this HUD release. Automated assistance and direct commands keep
  -- their own provenance, including after a rejected or duplicate release.
  local origin=battle.mentorActionOrigin
  battle.mentorActionOrigin='player'
  battle.mentorAim:release()
  battle.mentorActionOrigin=origin
 end)
 hud:slot('Cleanup',function()battle.mentorAim:cancel()end)
end
return Mentor
