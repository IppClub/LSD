-- First unfamiliar boss encounter. Limited exoskeleton energy is a new ground
-- constraint; it never changes, replaces or deletes the player's adopted model.
local D=require("Dora")
local P=D.Platformer
local Animation=require("CombatAnimation")
local Battle={}; Battle.__index=Battle
function Battle:command(action)
 if self.phase~="playing" then return false,"NOT_PLAYING" end
 local u=self.mentor
 if require('Combat.Displacement').blocked(u)then return false,'DISPLACED'end
 if action=="gather" then
  self.gatherPlan=require('Combat.Formation').plan(u.x,self.arena.enemy.x,{'ninilite'},self.arena.minX,self.arena.maxX)
  self.gatherUntil=D.App.runningTime+3;return true
 elseif action=="shoot" then
  if self.supplies and not self.supplies:canSpend('mentor','kinetic')then return false,'NO_SUPPLIES'end
  if D.App.runningTime<self.nextMentorShot or not u.onSurface then return false,"COOLDOWN" end
  if not (self.mentorAim and self.mentorAim.shot) then u.faceRight=self.arena.enemy.x>=u.x end
  return u:start("groundMentorShot")
 elseif action=="left" or action=="right" then
  if u:isDoing("groundMentorShot") then return false,"ACTION_BUSY" end
  return require("Combat.Movement").command(u,action)
 elseif action=="stop" then
  if u:isDoing("groundMentorShot") then return false,"ACTION_BUSY" end
  u:stop(); u.velocityX=0; Animation.rest(u); return true
 end
 return false,"UNKNOWN_COMMAND"
end
function Battle:arriveRescuer()
 local a=self.arena
 self.rescue=a.spawnUnit("wuyun",1,math.min(a.maxX,a.enemy.x+240),{"groundRescueMelee"})
 self.rescueHP=100; self.rescue.faceRight=false
 local blade=D.Spine("coldweapon"); blade.look="sword"; blade.scaleX=0.2; blade.scaleY=0.2; self.rescue.playable:setSlot("melee",blade)
 Animation.rest(self.rescue)
 -- Completion is counted once by the owned finite action below, rather than
 -- counting every animation-end notification delivered by the playable.
 self.rescueAt=D.App.runningTime; self.nextRescueShot=0
 self.message="乌云：小扎西们，退到辅助机旁！我来守住这一边。"
 a.extraEnemyTargets[#a.extraEnemyTargets+1]={unit=self.rescue,alive=function()return self.rescueHP>0 end,damage=function(n) self.rescueHP=math.max(0,self.rescueHP-n) end}
end
function Battle:finish(status,reason)
 if self.phase~="playing" then return end
 if self.partCombat then self.partCombat:close(status)end
 self.phase="saving"; self.pendingStatus=status; self.reason=reason
 local a=self.arena; a.mode="review"
 for _,u in ipairs({a.student,a.enemy,self.mentor,self.rescue}) do if u then require('Combat.Displacement').clear(u);u:stop(); u.velocityX=0 end end
 self.report={reason=reason,seconds=D.App.runningTime-self.started,learnerHits=a.metrics.hits,modelActions=a.metrics.modelActions,fallback=a.metrics.fallback,targetFallback=a.metrics.targetFallback or 0,targetUnavailable=a.metrics.targetUnavailable or 0,
  mentorHits=self.mentorHits,rescueHits=self.rescueHits,rescueFullAnimations=self.rescueCompleted,rescueTactics=self.rescueTactics,learnerEnergy=a.studentEnergy,learnerHP=a.studentHP,mentorHP=self.mentorHP,
  machineHP=self.support.machineHP,gold=self.support.gold,goldSpent=self.support.spent,healed=self.support.healed,modelSamples=self.attempt.model.sampleCount,training=require("Training.Summary").record(self.attempt.model)}
 self.combatEpisode=self.partCombat.journal:snapshot()
 if self.supplies then self.combatEpisode.resources=self.supplies:evidence()end
 self.report.combatSamples=#self.combatEpisode.steps;self.report.combatSchemaVersion=1
 self:saveResult()
end
function Battle:saveResult()
 if self.saving then return end; self.saving=true
 D.thread(function()
  local ok,r,e=xpcall(function() return self.service:finishAsync(self.attempt,self.pendingStatus,self.report,self.combatEpisode) end,debug.traceback)
  if not ok then print('GroundBattle: finishAsync failed '..tostring(r)) end
  self.saving=false
  if ok and r then self.phase=self.pendingStatus else self.phase="save-error"; self.saveError=ok and e or tostring(r) end
 end)
end
function Battle:update()
 local a=self.arena; if a.closed then return true end
 if self.phase~="playing" then return false end
 local now=D.App.runningTime; local dt=math.min(1,now-self.last); self.last=now
 if self.gatherUntil>now then
  require('Combat.Formation').step(a,self.gatherPlan and self.gatherPlan.ninilite,self)
  a.nextDecision=now+0.1
 else require('Combat.Formation').stop(a)end
 a:update()
 self.mentor.x=math.max(a.minX,math.min(a.maxX,self.mentor.x))
 self.support.hp={self.mentorHP,a.studentHP}; self.support:update(dt,self.mentor.x,a.student.x)
 self.mentorHP=self.support.hp[1]; a.studentHP=self.support.hp[2]
 self.machine.position=D.Vec2(self.support.x,a.world.offset+80); self.machine.velocity=D.Vec2.zero
 self.supportView:update(self.support,self.mentor.x,a.student.x)
 a.world.camera.position=D.Vec2((math.min(self.mentor.x,a.student.x)+math.max(a.enemy.x,a.student.x))/2,360)
 if not self.rescue and a.metrics.hits>0 and (a.studentEnergy<a.shotEnergyCost or a.studentHP<35 or a.enemyHP<=80 or now-self.started>=30) then self:arriveRescuer() end
 if self.rescue and self.rescueHP>0 and a.enemyHP>0 and self.rescue.onSurface and not require('Combat.Displacement').blocked(self.rescue) and not self.rescue:isDoing("groundRescueMelee") then
  local plan=require('Ground.RescueTactics').plan(self.rescue.x,a.enemy.x,a.enemyPhase=='attack'and a.enemyStrike or nil,a.minX,a.maxX,self.rescueTactic)
  if self.rescueTactic~=plan.mode then
   self.rescueTactic=plan.mode;self.rescueTactics=self.rescueTactics or {}
   if #self.rescueTactics<128 then self.rescueTactics[#self.rescueTactics+1]={at=now,origin='scripted-support',mode=plan.mode,reason=plan.reason,x=self.rescue.x,bossX=a.enemy.x}end
  end
  require('Ground.RescueTactics').move(self.rescue,plan)
  if plan.mode=='attack'and now>=self.nextRescueShot then self.rescue:start("groundRescueMelee")end
 end
 if self.mentorHP<=0 or a.studentHP<=0 then self:finish("failed","队伍失去战斗能力；回去补给和训练后再试。")
 elseif self.support.machineHP<=0 then self:finish("failed","采集辅助机被摧毁，地面调查中止。")
 elseif now-self.started>=75 then self:finish("failed","地面行动超时，先撤回列车。")
 elseif a.enemyHP<=0 and (not self.rescue or not self.rescue:isDoing("groundRescueMelee")) then
  if self.rescue and self.rescueHits>0 and a.metrics.hits>0 then self:finish("won","训练成果与乌云的支援共同守住了退路。")
  else self:finish("failed","未能完成调查队伍的协作；请返回补练。") end
 end
 return false
end
function Battle.createAsync(service,attempt,loadout)
 local self=setmetatable({service=service,attempt=attempt,phase="loading",mentorHP=100,nextMentorShot=0,mentorHits=0,rescueHits=0,rescueCompleted=0,gatherUntil=0},Battle)
 local config=assert(require("Mission.Catalog")[attempt.mission]); assert(attempt.mission=="c0-m02")
 local a=require("Training.Arena").createAsync({scene="AbandonedCity",manualUpdate=true,enemyAsset="dataotie",enemyPlayable="dataotie-combat",enemyMaxHP=config.bossHP,enemySpeed=75,
  origin=2350,minX=1900,maxX=3800,studentEnergy=100,roundLimit=75})
 self.arena=a
 if attempt.supplyAttempt then self.supplies=assert(require('Economy.CombatSession').open(attempt.supplyAttempt));a.supplies=self.supplies end
 D.Cache:loadAsync("spine:wuyun"); D.Cache:loadAsync("spine:coldweapon"); D.Cache:loadAsync("spine:kineticgun")
 local mentor=require("Data.Config").char
 require("Ground.Mentor").createAsync(self,mentor)
 self.mentor.position=D.Vec2(2180,a.world.offset+155)
 self.support=loadout or require("Ground.LifeSupport").new(45)
 self.mentorHP=self.support.hp[1]
 self.supportView=require("Ground.SupportView").create(a.world,self.support.variant)
 local def=D.Dictionary(); def.playable="spine:kineticgun"; def.bodyType="Dynamic"; def.size=D.Size(140,160); def.density=1; def.actions=D.Array({}); def.linearAcceleration=D.Vec2.zero
 D.Entity({groundMachine=true}); local e=assert(D.Group({"groundMachine"}):find(function(e) return e.groundMachine end))
 self.machine=assert(P.Unit(def,a.world,e,D.Vec2(2265,a.world.offset+80))); self.machine.group=1; self.machine.playable.visible=false; self.machine:addTo(a.world)
 a.extraEnemyTargets={{unit=self.mentor,alive=function()return self.mentorHP>0 end,damage=function(n) self.mentorHP=math.max(0,self.mentorHP-n) end},
  {unit=self.machine,immovable=true,damage=function(n) self.support:damageMachine(n) end}}
 local battleRef=setmetatable({self},{__mode='v'})
 P.UnitAction:add("groundRescueMelee",{priority=3,reaction=0,recovery=0.2,
  available=function(u) local self=battleRef[1];return self~=nil and not self.arena.closed and u.onSurface and not require('Combat.Displacement').blocked(u) and self.phase=="playing" and self.rescueHP>0 end,
  create=function(u)
   local self=battleRef[1];if not self or self.arena.closed then return function()return true end end
   local a=self.arena
   local combatStep=self.partCombat:beginAction(u,"rescue")
   self.nextRescueShot=D.App.runningTime+1.2; u.velocityX=0
   u.playable:slot("attack"):set(function()
    if self.phase~="playing" or a.enemyHP<=0 then return end
    if math.abs(u.x-a.enemy.x)<=380 and ((a.enemy.x>=u.x)==u.faceRight) then
     self.partCombat:melee(u,combatStep)
     local flash=D.DrawNode(); flash:drawSegment(D.Vec2(-80,-50),D.Vec2(80,90),8,D.Color(0xffbbf2f4)); flash.position=a.enemy.position; flash:addTo(a.world)
     flash:runAction(D.Sequence(D.Opacity(0.3,1,0),D.Event("Remove"))); flash:slot("Remove",function() flash:removeFromParent() end)
    end
   end)
   return D.once(function()
    -- The native completion marker proves the authored clip ended; the action
    -- coroutine owns the single completion count and cannot count it twice.
    Animation.playOnceAsync(u,"melee")
    self.rescueCompleted=self.rescueCompleted+1
    self.partCombat:finishAction(combatStep,u,"rescue");Animation.rest(u); return true
   end)
  end})
 a:beginTrial(600,attempt.model); a.studentHP=self.support.hp[2]
 self.partCombat=require("Ground.PartCombat").new(self)
 self.started=D.App.runningTime; self.last=self.started; self.phase="playing"
 self.message="妮妮莉特已载入采用模型。地面驱动能量有限，注意辅助机与退路。"
 a.world:schedule(function() return self:update() end)
 -- Register before rescue spawn; callback is added to the unit on arrival below.
 return self
end
return Battle
