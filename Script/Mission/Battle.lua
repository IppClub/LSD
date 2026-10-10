local K=require('Combat.Displacement')
local D=require("Dora")
local P=D.Platformer
local Arena=require("Training.Arena")
local Catalog=require("Mission.Catalog")
local Animation=require("CombatAnimation")
local Visuals=require("Combat.FirearmVisuals")
local Firearm=require("Combat.FirearmRules")
local Battle={}
Battle.__index=Battle
function Battle:command(action)
	if self.phase~="playing" then return false,"NOT_PLAYING" end
	local u=self.mentor
 if K.blocked(u)then return false,"DISPLACED"end
	if action=="repair" then
		if self.repairs<=0 then self.message="修复包已用尽。"; return false,"NO_REPAIRS" end
		if math.abs(u.x-self.relayX)>180 then self.message="靠近蓝色通讯节点再修复。"; return false,"OUT_OF_RANGE" end
		if D.App.runningTime<self.nextRepair then return false,"COOLDOWN" end
		if self.relayHP>=self.config.relayHP then self.message="通讯节点完好，先保留修复包。"; return false,"FULL_HEALTH" end
		self.repairs=self.repairs-1; self.nextRepair=D.App.runningTime+self.config.repairCooldown
		self.relayHP=math.min(self.config.relayHP,self.relayHP+self.config.repairAmount)
		self.message="通讯节点已修复。"; return true
	elseif action=="shoot" then
  if self.supplies and not self.supplies:canSpend('mentor','kinetic')then return false,'NO_AMMO'end
		if D.App.runningTime<self.nextMentorShot or not u.onSurface then return false,"COOLDOWN" end
		u.faceRight=self.arena.enemy.x>=u.x
		return u:start("missionMentorShot")
	elseif action=="left" or action=="right" then
		if u:isDoing("missionMentorShot") then return false,"ACTION_BUSY" end
		return require("Combat.Movement").command(u,action)
	elseif action=="stop" then
		if u:isDoing("missionMentorShot") then return false,"ACTION_BUSY" end
		u:stop(); u.velocityX=0; Animation.rest(u); return true
	end
	return false,"UNKNOWN_COMMAND"
end
function Battle:finish(status,reason)
	if self.phase~="playing" then return false end
	K.clear(self.mentor);K.clear(self.arena.student)
 self.phase="saving"; self.reason=reason
	self.arena.mode="review"; self.arena.student:stop(); self.arena.student.velocityX=0
	self.arena.enemy:stop(); self.arena.enemy.velocityX=0
	self.mentor:stop(); self.mentor.velocityX=0
	self.report={reason=reason,waves=self.rounds,mentorHP=self.mentorHP,relayHP=self.relayHP,repairsUsed=self.config.repairs-self.repairs,
		seconds=D.App.runningTime-self.started,mentorHits=self.mentorHits,modelSamples=self.attempt.model.sampleCount,training=require("Training.Summary").record(self.attempt.model)}
	self.pendingStatus=status
	self:saveResult()
	return true
end
function Battle:saveResult()
	if self.saving then return end
	self.saving=true
	D.thread(function()
		local ok,err=self.service:finishAsync(self.attempt,self.pendingStatus,self.report)
		self.saving=false
		if ok then self.phase=self.pendingStatus; self.message=self.reason
		else self.phase="save-error"; self.message="结算尚未保存，点击重试保存。"; self.saveError=err end
	end)
end
function Battle:update()
	if self.arena.closed then return true end
	if self.phase~="playing" then return false end
	local now=D.App.runningTime
	self.arena:update()
	self.mentor.x=math.max(350,math.min(1500,self.mentor.x))
	self.arena.world.camera.position=D.Vec2((math.min(self.mentor.x,self.arena.student.x)+math.max(self.relayX,self.arena.enemy.x))/2,300)
	if now>=self.nextRelayDamage then
		self.nextRelayDamage=self.nextRelayDamage+self.config.relayInterval
		self.relayHP=math.max(0,self.relayHP-self.config.relayDamage)
		self.message="入侵冲击了通讯节点，导师可在蓝色节点旁修复。"
	end
	if self.mentorHP<=0 then self:finish("failed","导师失去战斗能力。")
	elseif self.relayHP<=0 then self:finish("failed","通讯节点失守。")
	elseif now-self.started>=self.config.deadline then self:finish("failed","警戒行动超时。")
	elseif self.arena.mode=="review" and self.arena.result then
		local result=self.arena.result
		self.rounds[#self.rounds+1]=result
		if not result.won then self:finish("failed",result.studentHP<=0 and "妮妮莉特失去战斗能力。" or "本波未能及时击退。")
		elseif result.metrics.hits<self.config.learnerHitsPerWave then
   local empty=self.supplies and not self.supplies:canSpend("ninilite","emp")
   self:finish("failed",empty and "学员有效命中不足，且EMP已耗尽或未携带；请先检查补给，再调整战术。" or "学员尚未发挥训练成果：返回训练，补充接近与射击示范。")
		elseif self.wave==#self.config.waves then self:finish("won","两次入侵均已击退，通讯节点仍在运行。")
		else
			self.wave=self.wave+1
			local health=result.studentHP
			self.arena:beginTrial(self.config.waves[self.wave],self.attempt.model)
			self.arena.studentHP=health
			self.message="第二次入侵：保持警戒，训练成果继续生效。"
		end
	end
	return false
end
function Battle.createAsync(service,attempt,mentorName)
	local config=assert(Catalog[attempt.mission])
	local self=setmetatable({service=service,attempt=attempt,config=config,phase="loading",wave=1,rounds={},
		mentorHP=100,relayHP=config.relayHP,repairs=config.repairs,relayX=650,nextRepair=0,nextMentorShot=0,mentorHits=0},Battle)
	self.arena=Arena.createAsync({manualUpdate=true,enemySpeed=config.enemySpeed,roundLimit=35})
 if attempt.supplyAttempt then self.supplies=assert(require('Economy.CombatSession').open(attempt.supplyAttempt));self.arena.supplies=self.supplies end
	mentorName=mentorName=="charF" and "charF" or "charM"
	D.Cache:loadAsync("spine:"..mentorName)
 local battleRef=setmetatable({self},{__mode="v"})
 require("Combat.Movement").register("missionMentorMove",270)
	P.UnitAction:add("missionMentorShot",{priority=3,reaction=0,recovery=0.15,
		available=function(owner) local self=battleRef[1];return self~=nil and not self.arena.closed and self.phase=='playing' and (not self.supplies or self.supplies:canSpend('mentor','kinetic')) and not K.blocked(owner) and owner.onSurface and D.App.runningTime>=self.nextMentorShot end,
		create=function(owner)
			local self=battleRef[1];if not self or self.arena.closed then return function()return true end end
			self.nextMentorShot=D.App.runningTime+1
			owner.velocityX=0
			owner.playable:slot("attack"):set(function()
				if self.phase~="playing" or self.arena.enemyHP<=0 then return end
                if self.supplies then local ok,why=self.supplies:emit('mentor','kinetic',1,'mentor');if not ok then self.message='射击取消：'..tostring(why);return end end
				local def=P.BulletDef(); def.lifeTime=Firearm.lifeTime; def.highSpeedFix=true; def.gravity=D.Vec2.zero
				def:setAsCircle(10); def:setVelocity(-(self.mentorAim and self.mentorAim.angle or 0),Firearm.speed)
				def.face=P.Face(function()return Visuals.bulletFace(self.mentorAim and self.mentorAim.angle or 0,owner.faceRight)end)
				local bullet=P.Bullet(def,owner)
				local allow=P.TargetAllow(); allow:allow("Enemy",true); allow.terrainAllowed=true
				bullet.targetAllow=allow:toValue()
				bullet:slot("HitTarget",function(projectile,target)
					if target==self.arena.enemy and self.phase=="playing" then
						self.arena.enemyHP=math.max(0,self.arena.enemyHP-5); self.mentorHits=self.mentorHits+1
					end
					projectile.hitStop=true
				end)
				local gun=owner.playable:getSlot("pistol")
                bullet.position=gun and self.arena.world:convertToNodeSpace(gun:convertToWorldSpace(D.Vec2(300,0))) or owner.position+D.Vec2(owner.faceRight and 65 or -65,-20);bullet:addTo(self.arena.world)
                require('Tutorial.LightStrip').LightStrip(bullet.position,bullet,0xccffffff)
                if gun then Visuals.casing(owner,gun,self.arena.world,self.mentorCasings)end
				self.arena.projectiles[#self.arena.projectiles+1]=bullet
			end)
			return D.once(function() Animation.playOnceAsync(owner,"pistol"); Animation.rest(owner); return true end)
		end})
	self.mentor=self.arena.spawnUnit(mentorName,1,520,{"missionMentorMove","missionMentorShot"})
	require("Combat.Movement").attach(self.mentor,self,"missionMentorMove",270)
 self.mentor.faceRight=true; Animation.rest(self.mentor)
	self.arena.extraEnemyTargets={{unit=self.mentor,alive=function()return self.phase=="playing" and self.mentorHP>0 end,damage=function(n) self.mentorHP=math.max(0,self.mentorHP-n) end}}
	local gun=D.Spine("kineticgun"); gun.look="PT"; gun.scaleX=0.3; gun.scaleY=0.3
	self.mentor.playable:setSlot("pistol",gun)
 self.mentorCasings={}
 self.mentorAim=require('Combat.Aim').new(self.mentor,function()
  return (not self.supplies or self.supplies:canSpend('mentor','kinetic')) and self.phase=='playing' and self.mentorHP>0 and not K.blocked(self.mentor) and self.mentor.onSurface and not self.mentor:isDoing('missionMentorShot') and D.App.runningTime>=self.nextMentorShot
 end,function()return self:command('shoot')end,'missionMentorShot')
	local relay=D.DrawNode(); relay:drawDot(D.Vec2.zero,30,D.Color(0xff4ce6ed)); relay.position=D.Vec2(self.relayX,self.arena.world.offset+70); relay:addTo(self.arena.world)
	local marker=D.Label("SourceHanSansCN-Regular",28); marker.text="通讯节点"; marker.position=relay.position+D.Vec2(0,75); marker:addTo(self.arena.world)
	self.started=D.App.runningTime; self.nextRelayDamage=self.started+config.relayInterval
	self.arena:beginTrial(config.waves[1],attempt.model)
	self.phase="playing"; self.message="妮妮莉特已载入采用模型，导师负责支援。"
	self.arena.world:schedule(function() return self:update() end)
	return self
end
return Battle
