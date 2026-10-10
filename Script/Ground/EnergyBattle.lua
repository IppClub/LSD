-- Both adopted controllers execute concurrently in one real city world.
local D=require("Dora")
local Animation=require("CombatAnimation")
local Battle={}; Battle.__index=Battle
function Battle:command(action)
 if self.phase~="playing" then return false,"NOT_PLAYING" end
 if action=="fire" or action=="wind" then return self.magic:request(action) end
 local u=self.mentor
 if action=="shoot" then
  if self.supplies and not self.supplies:canSpend('mentor','kinetic')then return false,'NO_SUPPLIES'end
  local target=self.mentorTarget(); if not target then return false,"NO_TARGET" end
  if u:isDoing("groundMentorShot") then return false,"ACTION_BUSY" end
  u.faceRight=target.x>=u.x; return u:start("groundMentorShot")
 elseif action=="gather" then self.gatherUntil=D.App.runningTime+1; return true
 elseif action=="left" or action=="right" then
  if u:isDoing("groundMentorShot") then return false,"ACTION_BUSY" end
  return require("Combat.Movement").command(u,action)
 elseif action=="stop" then
  if u:isDoing("groundMentorShot") then return false,"ACTION_BUSY" end
  u:stop(); u.velocityX=0; Animation.rest(u); return true
 end
 return false,"UNKNOWN_COMMAND"
end
function Battle:finish(status,reason)
 if self.phase~="playing" then return end
 self.pendingStatus=status; self.reason=reason; self.phase="saving"
 for _,a in ipairs(self.learners) do a.mode="review"; a.student:stop(); a.student.velocityX=0 end
 self.mentor:stop(); self.mentor.velocityX=0
 for _,a in ipairs(self.enemies) do a.mode="review"; a.enemy:stop(); a.enemy.velocityX=0 end
 self.report={reason=reason,seconds=D.App.runningTime-self.started,mentorHits=self.mentorHits,machineHP=self.support.machineHP,gold=self.support.gold,
  simultaneous=true,opponents=3,learners={},coverBlocks=self.coverBlocks,coveredDamage=self.coveredDamage,fireHits=self.magic.fireHits,windHits=self.magic.windHits,synergyHits=self.magic.synergyHits,casts=self.magic.logs}
 self.report.rewardMultiplier=require("Ground.Tactics").rewardMultiplier(self.report)
 for _,a in ipairs(self.learners) do self.report.learners[a.character.id]={samples=a.trialModel.sampleCount,training=require("Training.Summary").record(a.trialModel),hits=a.metrics.hits,actions=a.metrics.modelActions,fallback=a.metrics.fallback,hp=a.studentHP,used=a.metrics.actions} end
 self:saveResult()
end
function Battle:saveResult()
 if self.saving then return end; self.saving=true
 D.thread(function()
  local ok,r,e=xpcall(function() return self.service:finishAsync(self.attempt,self.pendingStatus,self.report) end,debug.traceback)
  if not ok then print('EnergyBattle: finishAsync failed '..tostring(r)) end
  self.saving=false
  self.phase=ok and r and self.pendingStatus or "save-error"; self.saveError=ok and e or tostring(r)
 end)
end
function Battle:update()
 if self.arena.closed then return true end
 if self.phase~="playing" then return false end
 local now=D.App.runningTime; local dt=math.min(1,now-self.last); self.last=now
 self.magic:update()
 for _,a in ipairs(self.learners) do
  if self.gatherUntil>now and not a:isAttacking() and a.studentHP>0 then
   a.student.faceRight=self.mentor.x>=a.student.x
   if math.abs(a.student.x-self.mentor.x)>160 then a.student:start(a.physical.fmove) else a.student:stop(); a.student.velocityX=0; Animation.rest(a.student) end
   a.nextDecision=now+0.1
  end
  a:update()
 end
 self.central.studentHP=self.mentorHP; self.central.enemyCombat:update(now)
 self.support.hp={self.mentorHP,self.arena.studentHP,self.wuyun.studentHP}
 self.support:update(dt,{self.mentor.x,self.arena.student.x,self.wuyun.student.x})
 self.mentorHP=self.support.hp[1]; self.arena.studentHP=self.support.hp[2]; self.wuyun.studentHP=self.support.hp[3]
 self.supportView:update(self.support,math.min(self.mentor.x,self.arena.student.x,self.wuyun.student.x),math.max(self.mentor.x,self.arena.student.x,self.wuyun.student.x))
 self.machine.position=D.Vec2(self.support.x,self.arena.world.offset+80); self.machine.velocity=D.Vec2.zero
 self.mentor.x=math.max(4800,math.min(6900,self.mentor.x))
 local low=math.min(self.mentor.x,self.arena.student.x,self.wuyun.student.x); local high=math.max(self.mentor.x,self.arena.student.x,self.wuyun.student.x)
 for _,enemy in ipairs(self.enemies) do low=math.min(low,enemy.enemy.x); high=math.max(high,enemy.enemy.x) end
 local camera=self.arena.world.camera; local targetZoom=math.min(1.0,D.View.size.width/(high-low+460))
 camera.zoom=camera.zoom+(targetZoom-camera.zoom)*math.min(1,dt*8)
 camera.position=D.Vec2((low+high)/2,360)
 if self.mentorHP<=0 or self.arena.studentHP<=0 or self.wuyun.studentHP<=0 then self:finish("failed","队伍失去战斗能力。返回补给和训练后再来。")
 elseif self.support.machineHP<=0 then self:finish("failed","辅助机被摧毁，能源调查中止。")
 elseif now-self.started>=90 then self:finish("failed","行动超时，先撤回列车。")
 else
  local alive=false; for _,a in ipairs(self.enemies) do if a.enemyHP>0 then alive=true end end
  if not alive and not self.arena:isAttacking() and not self.wuyun:isAttacking() and not self.mentor:isDoing("groundMentorShot") then
   if self.arena.metrics.hits>0 and self.wuyun.metrics.hits>0 then self:finish("won","两侧学员按各自成果作战，中央道路已清理。前往能源箱完成回收。")
   else self:finish("failed","两侧学员未能完成配合，请先补充训练。") end
  end
 end
 return false
end
function Battle.createAsync(service,attempt,loadout)
 assert(attempt.mission=="c0-m03" and attempt.models)
 local self=setmetatable({service=service,attempt=attempt,phase="loading",mentorHP=100,mentorHits=0,nextMentorShot=0,gatherUntil=0,coverBlocks=0,coveredDamage=0},Battle)
 local Arena=require("Training.Arena")
 local ni=Arena.createAsync({scene="AbandonedCity",manualUpdate=true,origin=5350,minX=4800,maxX=6900,actionPrefix="energyNi_"})
 local wu=Arena.createAsync({world=ni.world,manualUpdate=true,characterId="wuyun",origin=6300,minX=4800,maxX=6900,actionPrefix="energyWu_"})
 self.arena=ni; self.wuyun=wu; self.learners={ni,wu}
 if attempt.supplyAttempt then self.supplies=assert(require('Economy.CombatSession').open(attempt.supplyAttempt));ni.supplies=self.supplies;wu.supplies=self.supplies end
 ni:beginTrial(400,attempt.models.ninilite); wu:beginTrial(220,attempt.models.wuyun)
 ni.enemy.position=D.Vec2(4950,ni.world.offset+155); ni.student.faceRight=false
 local central={world=ni.world,enemy=ni.spawnUnit("xiaotaotie",2,5920,{}),enemyHP=60,studentHP=100,metrics={damageTaken=0},student=ni.student,mode="trial",minX=ni.minX,maxX=ni.maxX,projectiles=ni.projectiles,extraEnemyTargets={}}
 central.enemyPhase="idle"; central.nextEnemy=D.App.runningTime+2.5
 self.central=central; self.enemies={ni,wu,central}
 self.mentorTarget=function() for _,a in ipairs({central,ni,wu}) do if a.enemyHP>0 then return a.enemy end end end
 self.damageMentorTarget=function(target,n) for _,a in ipairs(self.enemies) do if a.enemy==target then a.enemyHP=math.max(0,a.enemyHP-n); return end end end
 require("Ground.Mentor").createAsync(self,require("Data.Config").char); self.mentor.position=D.Vec2(5670,ni.world.offset+155)
 central.student=self.mentor
 self.support=loadout or require("Ground.LifeSupport").new(65)
 self.mentorHP=self.support.hp[1]; ni.studentHP=self.support.hp[2]; wu.studentHP=self.support.hp[3] or 100
 self.support.hp={self.mentorHP,ni.studentHP,wu.studentHP}
 self.supportView=require("Ground.SupportView").create(ni.world,self.support.variant)
 local def=D.Dictionary(); def.playable="spine:kineticgun"; def.bodyType="Dynamic"; def.size=D.Size(140,160); def.density=1; def.actions=D.Array({}); def.linearAcceleration=D.Vec2.zero
 D.Entity({energyMachine=true}); local entity=assert(D.Group({"energyMachine"}):find(function(e) return e.energyMachine end))
 self.machine=assert(D.Platformer.Unit(def,ni.world,entity,D.Vec2(5840,ni.world.offset+80))); self.machine.group=1; self.machine.playable.visible=false; self.machine:addTo(ni.world)
 local function targets(sourceX)
  return {{unit=ni.student,damage=function(n) ni.studentHP=math.max(0,ni.studentHP-n); ni.metrics.damageTaken=ni.metrics.damageTaken+n end},
   {unit=wu.student,damage=function(n) wu.studentHP=math.max(0,wu.studentHP-n); wu.metrics.damageTaken=wu.metrics.damageTaken+n end},
   {unit=self.mentor,damage=function(n,strike)
    local source=strike and strike.explosionX or sourceX
    if require("Ground.Tactics").covered(self.mentor.x,source) then self.coverBlocks=self.coverBlocks+1; self.coveredDamage=self.coveredDamage+n; return 0 end
    self.mentorHP=math.max(0,self.mentorHP-n); return n
   end},
   {unit=self.machine,immovable=true,damage=function(n) self.support:damageMachine(n) end}}
 end
 for _,a in ipairs(self.enemies) do a.enemyTargets=function() return targets(a.enemy.x) end end
 central.enemyCombat=require("Training.EnemyCombat").new(central)
 self.magic=require("Ground.WindFire").new(self)
 self.started=D.App.runningTime; self.last=self.started; self.phase="playing"
 ni.world:schedule(function() return self:update() end)
 return self
end
return Battle
