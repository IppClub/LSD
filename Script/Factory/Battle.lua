-- Factory encounter: adopted models, authored flower skills and the emergency chant.
local D=require("Dora")
-- Shared static vitals contexts; CombatVitals:record only reads kind/source.
local UNKNOWN_STRIKE={kind='unknown',source='unknown'}
local VITALS_HEAL={kind='support-heal',source='life-support'}
local VITALS_HAZARD={kind='support-hazard',source='life-support'}
local Animation=require("CombatAnimation")
local Text=require("Factory.BattleText")
local Battle={}; Battle.__index=Battle
function Battle:target(unit)
 local selected; local distance=math.huge
 for _,e in ipairs(self.enemies) do
  if e.enemyHP>0 and not e.enemyCombat.dead then
   local dx=math.abs(e.enemy.x-unit.x)
   if dx<distance then selected=e; distance=dx end
  end
 end
 return selected
end
-- Snapshot only live encounter facts, independent of learned target choice.
function Battle:remainingEnemies()
 local rows={}
 for _,e in ipairs(self.enemies)do
  if e.enemyHP>0 and not e.enemyCombat.dead then
   rows[#rows+1]={id=e.combatSource,hp=e.enemyHP,maxHP=e.enemyMaxHP,x=e.enemy.x,y=e.enemy.y,
    summoned=e~=self.roots[1] and e~=self.roots[2] and e~=self.roots[3]}
  end
 end
 return rows
end
function Battle:damageEnemy(unit,n)
 if self.phase~="playing" then return 0 end
 for _,e in ipairs(self.enemies) do if e.enemy==unit and e.enemyHP>0 then if self.partCombat and e==self.roots[3] then return 0 end; local damage=math.min(e.enemyHP,n); e.enemyHP=e.enemyHP-damage; return damage end end
 return 0
end
function Battle:command(action)
 if self.phase~="playing" then return false,"NOT_PLAYING" end
 if action=="song" then return self.song:request() end
 local u=self.mentor
 if require('Combat.Displacement').blocked(u)then return false,'DISPLACED'end
 local blockedAction=(action=="left" or action=="right") and "fmove" or action
 if self.effects:blocked(u,blockedAction) then return false,"STATUS_BLOCKED" end
 if action=="gather" then
  self.gatherPlan=require('Combat.Formation').plan(u.x,self.roots[3].enemy.x,{'wuyun','ninilite'},self.minX,self.maxX)
  self.gatherUntil=D.App.runningTime+3;return true
 end
 if action=='shoot' and self.supplies and not self.supplies:canSpend('mentor','kinetic')then self.supplies.lastError='OUT_OF_SUPPLIES';return false,'OUT_OF_SUPPLIES'end
 if action=="shoot" then local target=self:target(u); if not target then return false,"NO_TARGET" end; if not self.mentorAim.shot then u.faceRight=target.enemy.x>=u.x end; return u:start("groundMentorShot") end
 if u:isDoing("groundMentorShot") then return false,"ACTION_BUSY" end
 if action=="left" or action=="right" then return require("Combat.Movement").command(u,action) end
 if action=="stop" then u:stop(); u.velocityX=0; Animation.rest(u); return true end
 return false,"UNKNOWN_COMMAND"
end
function Battle:start()
 if self.phase~="ready" then return false end
 self.phase="playing"; self.started=D.App.runningTime; self.last=self.started
 for _,a in ipairs(self.learners) do a.mode=(a.flowerDeployment or a.resourceCandidate) and "demo" or "trial"; a.nextFlowerDecision=D.App.totalTime+0.2; a.roundStarted=self.started; a.nextDecision=self.started+0.2 end
 -- Initial vines are a real, dodgeable authored attack; no scripted HP deduction.
 for i,e in ipairs(self.roots) do e.mode="trial"; e.nextEnemy=self.started+i*2 end
 self.roots[3].enemyCombat:start("twine")
 return true
end
function Battle:finish(status,reason)
 if self.phase~="playing" and self.phase~="ready" then return end
 local outcome=require("Factory.Outcome").capture(self)
 self.mentorAim:cancel()
 require('Combat.Displacement').clear(self.mentor)
 for _,a in ipairs(self.learners)do require('Combat.Displacement').clear(a.student)end
 self.pendingStatus=status; self.reason=reason; self.phase="saving"
 for _,a in ipairs(self.learners) do a.mode="review"; a.student:stop(); a.student.velocityX=0; if a.studentHP<=0 then Animation.play(a.student,"lose",false) else Animation.rest(a.student) end end
 self.mentor:stop(); self.mentor.velocityX=0
 if self.mentorHP<=0 then Animation.play(self.mentor,"lose",false) else Animation.rest(self.mentor) end
 for _,e in ipairs(self.enemies) do
  e.mode="review"; e.enemy.velocityX=0
  local strike=e.enemyStrike
  if strike and not strike.completedAt then strike.interruptedAt=D.App.runningTime; strike.interruptedReason="encounter-ended" end
  if e.enemyHP>0 and e.enemy.playable.visible then Animation.rest(e.enemy) end
 end
 self.report={remainingEnemies=self:remainingEnemies(),outcome=outcome,reason=reason,seconds=self.started and D.App.runningTime-self.started or 0,mentorHits=self.mentorHits,mentorHP=self.mentorHP,
  auxiliary=require("Factory.Support").report(self.support),injury=self.injury,poisonDamage=self.effects.poisonDamage,confusions=self.effects.confusions,virusHits=self.effects.virusHits,chants=self.song.logs,learners={},opponents=#self.enemies}
 for _,a in ipairs(self.learners) do self.report.learners[a.character.id]={hp=a.studentHP,hits=a.metrics.hits,actions=a.metrics.modelActions,fallback=a.metrics.fallback,samples=a.trialModel.sampleCount,training=require("Training.Summary").record(a.trialModel),used=a.metrics.actions} end
 for _,a in ipairs(self.learners)do
  local identity=require('Training.FlowerController').identity(a)
  if identity then local report=self.report.learners[a.character.id];report.baseTraining=report.training;report.training=identity;report.samples=identity.qAdoptionId and report.samples or identity.count;report.qUpdates=identity.updates;report.controller=identity.resourceCandidate and 'resource-q-trial' or identity.qAdoptionId and 'flower-qlearning' or 'flower-c45';report.adoptionId=identity.adoptionId;report.teamAdoptionId=identity.teamAdoptionId;report.qAdoptionId=identity.qAdoptionId;report.qDecisions=identity.qAdoptionId and a.flowerDeployment.decisions or nil end
 end
 self.report.flowerDeploymentContext=self.flowerDeploymentContext
 self.report.summonsCreated=self.summonsCreated or 0
 self.report.bossPhase=self.roots[3].enemyCombat.bossPhase;self.report.bossPhaseEvents=self.roots[3].enemyCombat.phaseEvents
 for _,root in ipairs(self.roots)do root.enemyCombat:close()end
 self.report.partHits={};local hits=self.partCombat.events;self.report.partHitCount=#hits;self.report.partHitsTruncated=#hits>64
 for i=math.max(1,#hits-63),#hits do self.report.partHits[#self.report.partHits+1]=hits[i]end
 self.report.partArmor=self.partCombat.target.damage.parts
 self.partCombat:close();self.combatEpisode=self.partCombat.journal:snapshot();self.combatEpisode.outcome=outcome;self.combatEpisode.versions.outcome=1;self.combatEpisode.versions.trainingGoal=self.trainingGoal
 self.effects:clear()
 self:saveResult()
end
-- Preparation may fail independently of persistence. Retry it before saving,
-- and publish a complete report only after every evidence stage succeeds.
function Battle:prepareResult()
 if self.resultPrepared then return true end
 if self.supplies then
  self.combatEpisode.resources=self.supplies:evidence()
  local attributed,why=require('Training.ResourceEvidence').attribute(self.combatEpisode.resources,self.combatEpisode.steps)
  if not attributed then return false,why or 'RESOURCE_ATTRIBUTION_FAILED' end
  self.combatEpisode.resourceCosts=attributed
 end
 self.combatEpisode.creditTargets=self.partCombat.credits.targets;self.combatEpisode.vitals=self.partCombat.vitals:snapshot();self.report.combatSamples=#self.combatEpisode.steps
 local evaluation,evalWhy=require('Training.FlowerEvaluation').build(self.combatEpisode)
 if not evaluation then return false,evalWhy or 'EVALUATION_FAILED' end
 self.report.evaluation=evaluation
 if self.supplies and self.supplies.isVirtual then
  local closed,virtualWhy=self.supplies:closeVirtual(self.pendingStatus)
  if not closed then return false,virtualWhy or 'VIRTUAL_ECONOMY_FAILED' end
  self.report.virtualEconomy=closed
 end
 self.resultPrepared=true
 return true
end
function Battle:saveResult()
 if self.saving then return end; self.saving=true
 D.thread(function()
 local ok,r,e=xpcall(function()
  local prepared,why=self:prepareResult()
  if not prepared then return false,why end
  return self.service:finishAsync(self.attempt,self.pendingStatus,self.report,self.combatEpisode)
 end,debug.traceback)
 if not ok then print('FactoryBattle: finishAsync failed '..tostring(r)) end
 self.saving=false; self.phase=ok and r and self.pendingStatus or "save-error"; self.saveError=ok and e or tostring(r)
 end)
end
function Battle:update()
 if self.arena.closed then return true end
 local now=D.App.runningTime; local dt=math.max(0,math.min(1,now-self.last)); self.last=now
 if self.phase=="playing" then
  self.effects:update(now); self.song:update()
  local chant=self.song.logs[#self.song.logs]
  if chant and chant.releaseAt and chant.releaseAt~=self.lastChantCompleted then self.lastChantCompleted=chant.releaseAt; self.message=Text.chantReleased end
  for _,a in ipairs(self.learners) do
   local enemy=self:target(a.student)
   if enemy then a.enemy=enemy.enemy; a.enemyHP=enemy.enemyHP; a.enemyPhase=enemy.enemyPhase
   else a.enemyHP=0; a.enemyPhase="defeated" end -- Reject new actions while final attack animations settle.
   if self.gatherUntil>now then
    require('Combat.Formation').step(a,self.gatherPlan and self.gatherPlan[a.character.id],self)
    a.nextDecision=now+0.1
   else require('Combat.Formation').stop(a)end
   if enemy then
   a:update()
   if (a.flowerDeployment or a.resourceCandidate) and D.App.totalTime>=a.nextFlowerDecision and self.gatherUntil<=now then
    a.nextFlowerDecision=D.App.totalTime+.25
    require('Training.FlowerController').step(self,a,a.flowerDeployment and a.flowerDeployment.policy)
   end
  elseif not a:isAttacking() and not require('Combat.Displacement').blocked(a.student) then a.student:stop(); a.student.velocityX=0; Animation.rest(a.student) end
  end
  for _,e in ipairs(self.roots) do e.studentHP=self.arena.studentHP; e.enemyCombat:update(now) end
  local support=self.support;support.hp={self.mentorHP,self.arena.studentHP,self.wuyun.studentHP}
  if self.injury then support.maxHP=support.maxHP or {100,100,100};support.maxHP[2]=math.min(90,support.maxHP[2])end
  -- Reuse the positions scratch table; support:update only reads it for this tick.
  local positions=self._supportPositions
  if not positions then positions={0,0,0};self._supportPositions=positions end
  positions[1],positions[2],positions[3]=self.mentor.x,self.arena.student.x,self.wuyun.student.x
  support:update(dt,positions)
  -- Vitals:record only reads kind/source, so shared static contexts are safe.
  self.partCombat.vitals:record('mentor',self.mentorHP,support.hp[1],support.hp[1]>=self.mentorHP and VITALS_HEAL or VITALS_HAZARD,D.App.totalTime)
  self.partCombat.vitals:record('ninilite',self.arena.studentHP,support.hp[2],support.hp[2]>=self.arena.studentHP and VITALS_HEAL or VITALS_HAZARD,D.App.totalTime)
  self.partCombat.vitals:record('wuyun',self.wuyun.studentHP,support.hp[3],support.hp[3]>=self.wuyun.studentHP and VITALS_HEAL or VITALS_HAZARD,D.App.totalTime)
  self.mentorHP,self.arena.studentHP,self.wuyun.studentHP=table.unpack(support.hp)
  if self.injury and not self.injuryAnnounced then self.injuryAnnounced=true; self.message=Text.injury end
  if self.mentorHP<=0 or self.arena.studentHP<=0 or self.wuyun.studentHP<=0 then self:finish("failed",Text.defeat)
  elseif now-self.started>=120 then self:finish("failed",Text.timeout)
  elseif not self:target(self.mentor) and not self.arena:isAttacking() and not self.wuyun:isAttacking() and not self.mentor:isDoing("groundMentorShot") then
   local O=require('Factory.Outcome');local outcome=O.capture(self)
   if O.satisfied(outcome,self.trainingGoal)then self:finish("won",self.trainingGoal and "虚拟战斗完成：队伍存活，敌人已清除。" or Text.victory)
   else self:finish("failed","敌人已清除，但任务条件未完成："..table.concat(O.missing(outcome),"；").."。")end
  end
 end
 local low,high=self.mentor.x,self.mentor.x
 for _,a in ipairs(self.learners) do a.student.x=math.max(self.minX,math.min(self.maxX,a.student.x)); low=math.min(low,a.student.x); high=math.max(high,a.student.x) end
 self.mentor.x=math.max(self.minX,math.min(self.maxX,self.mentor.x))
 for _,e in ipairs(self.enemies) do if e.enemyHP>0 then low=math.min(low,e.enemy.x); high=math.max(high,e.enemy.x) end end
 self.supportView:update(self.support,math.min(self.mentor.x,self.arena.student.x,self.wuyun.student.x),math.max(self.mentor.x,self.arena.student.x,self.wuyun.student.x))
 -- Keep the authored 1:1 boss clear of the top panel and bottom controls.
 -- Padding includes its petals; camera fitting never changes combat/model scale.
 local camera=self.arena.world.camera
 local height=D.View.size.height
 local top=self.cameraTopInset or height*.22;local bottom=self.cameraBottomInset or height*.26
 local usable=math.max(height*.25,height-top-bottom)
 local z=math.min(1,D.View.size.width/(high-low+800),usable/900)
 camera.zoom=camera.zoom+(z-camera.zoom)*math.min(1,dt*8)
 local center=(bottom+height-top)/2
 camera.position=D.Vec2((low+high)/2,self.arena.world.offset+400-(center-height/2)/camera.zoom)
 return false
end
function Battle.createAsync(service,attempt,support,options)
 options=options or {}
 assert(options.trainingGoal==nil or options.trainingGoal=="resource-clear-v1" and options.training and options.virtualSupplies,"Resource goal requires virtual training")
 assert(not options.virtualSupplies or options.training and not attempt.supplyAttempt,'Virtual supplies require an isolated training battle')
 assert(not (options.training and attempt.supplyAttempt),'Training cannot charge a mission wallet')
 local virtual
 if options.virtualSupplies then virtual=assert(require('Economy.CombatSession').virtual('virtual:'..tostring(attempt.id or D.App.totalTime),options.virtualSupplies))end
 local shift=options.training and -3500 or 0;local minX,maxX=4300+shift,6600+shift
 assert(attempt.mission=="c0-m05" and attempt.models)
 local self=setmetatable({service=service,attempt=attempt,trainingGoal=options.trainingGoal,phase="loading",mentorHP=100,mentorHits=0,nextMentorShot=0,gatherUntil=0,minX=minX,maxX=maxX,mentorActionOrigin=options.training and "scripted" or "player",enemies={},roots={}},Battle)
 local Arena=require("Training.Arena")
 local ni=Arena.createAsync({scene=options.training and "VRTraining" or "Factory",manualUpdate=true,origin=5100+shift,minX=minX,maxX=maxX,actionPrefix="factoryNi_",enemyAsset="xiaohuayao",flowerLook="white"})
 local wu=Arena.createAsync({world=ni.world,manualUpdate=true,characterId="wuyun",origin=5430+shift,minX=minX,maxX=maxX,actionPrefix="factoryWu_",enemyAsset="xiaohuayao",flowerLook="normal"})
 -- Combat bounds already constrain the party. The scene's 1080-high camera
 -- clamp would prevent framing a full-size boss beneath the HUD on short views.
 ni.world.camera.boundary=D.Rect.zero
 self.arena=ni; self.wuyun=wu; self.learners={ni,wu}
 ni:beginTrial(430,attempt.models.ninilite); wu:beginTrial(470,attempt.models.wuyun)
 for _,a in ipairs(self.learners) do
  a.externalCombat=true; a.externalRound=true; a.mode="review"; a.damageOpponent=function(unit,n) return self:damageEnemy(unit,n) end
  -- These opponents get independent records below; discard their unused hidden bud.
  if a.enemyCombat.bud then a.enemyCombat.bud:removeFromParent(); a.enemyCombat.bud=nil end
 end
 require("Ground.Mentor").createAsync(self,require("Data.Config").char); self.mentor.position=D.Vec2(5320+shift,ni.world.offset+155)
 self.mentorTarget=function() local e=self:target(self.mentor); return e and e.enemy end
 self.damageMentorTarget=function(unit,n) return self:damageEnemy(unit,n*3) end
 self.effects=require("Factory.Effects").new(function() return self.targets() end)
 self.targets=function()
  -- Attack phases iterate these adapters every frame; cache per battle and
  -- refresh the unit fields in place instead of rebuilding tables and closures.
  local result=self._targets
  if not result then
   result={}
   for _,a in ipairs(self.learners) do result[#result+1]={unit=a.student,alive=function() return a.studentHP>0 end,isAttacking=function() return a:isAttacking() end,damage=function(n,strike) local before=a.studentHP;local damage=math.min(n,before); a.studentHP=before-damage;if self.partCombat then self.partCombat.vitals:record(a.character.id,before,a.studentHP,strike or UNKNOWN_STRIKE,D.App.totalTime)end; a.metrics.damageTaken=a.metrics.damageTaken+damage; if a==ni and strike and (strike.kind=="twine" or strike.kind=="poison") and damage>0 then self.injury=true end; return damage end} end
   result[#result+1]={unit=self.mentor,alive=function() return self.mentorHP>0 end,isAttacking=function() return self.mentor:isDoing("groundMentorShot") end,damage=function(n,strike) local before=self.mentorHP;local dealt=math.min(n,before); self.mentorHP=before-dealt;if self.partCombat then self.partCombat.vitals:record('mentor',before,self.mentorHP,strike or UNKNOWN_STRIKE,D.App.totalTime)end; return dealt end}
   for _,target in ipairs(result)do
    local actor=target.unit==self.mentor and 'mentor' or target.unit.entity.name
    target.onForcedMovement=function(event)
     if self.partCombat and not self.partCombat.closed then event.actor=actor;assert(self.partCombat.journal:movementEvent(event))end
    end
   end
   self._targets=result
  end
  for i,a in ipairs(self.learners) do result[i].unit=a.student end
  result[#self.learners+1].unit=self.mentor
  return result
 end
 for _,a in ipairs(self.learners) do a.studentEffects=self.effects end
 self.song=require("Factory.Song").new(wu,self.effects)
 D.Cache:loadAsync("spine:dahuayao-hitboxes")
 local flower=require("Factory.FlowerCombat")
 local originals={ni.enemy,wu.enemy,ni.spawnUnit("dahuayao",2,5750+shift,{},"dahuayao-hitboxes")}
 for i,unit in ipairs(originals) do
  local e={world=ni.world,enemy=unit,enemyAsset=i==3 and "dahuayao" or "xiaohuayao",combatSource=i==3 and "factory-flower" or "factory-flower-root-"..i,enemyHP=i==3 and 220 or 100,enemyMaxHP=i==3 and 220 or 100,student=ni.student,studentHP=100,metrics={damageTaken=0},mode="review",enemyPhase="idle",enemyAttacks={},nextEnemy=math.huge,minX=minX,maxX=maxX,projectiles=ni.projectiles,spawnUnit=ni.spawnUnit,enemyTargets=self.targets}
  if i==3 then unit.position=D.Vec2(5750+shift,ni.world.offset+220) end
  e.enemyCombat=flower.new(e,{effects=self.effects,phases=i==3,onSpawn=function(child) child.combatSource="factory-summon-"..tostring((self.summonsCreated or 0)+1);self.enemies[#self.enemies+1]=child;self.summonsCreated=(self.summonsCreated or 0)+1 end,
   onDespawn=function(child)for index,enemy in ipairs(self.enemies)do if enemy==child then table.remove(self.enemies,index);break end end end})
  self.enemies[#self.enemies+1]=e; self.roots[#self.roots+1]=e; Animation.rest(unit)
 end
 self.partCombat=require('Factory.PartCombat').new(self)
 for _,a in ipairs(self.learners)do
  a.beginCombatAction=function(owner,source)return self.partCombat:begin(owner,source=='mentor' and 'mentor' or a.character.id,'shoot',source=='mentor' and self.mentorActionOrigin or a.currentActionSource or 'scripted')end
  a.targetFacingForAction=function(action)if action=='laser' and a.flowerTargetPart then return self.roots[3].enemy.x>=a.student.x end end
  a.recordEnergySpent=function(id,amount)local step=id and self.partCombat.journal.steps[id];if step then step.action.energySpent=(step.action.energySpent or 0)+amount end end
  a.prepareStudentShot=function(owner,step)return self.partCombat:prepareShot(owner,step)end
  a.finishCombatAction=function(step,owner,source,status)self.partCombat:finish(step,owner,status)end
  a.beginMeleeAction=function(owner)return self.partCombat:begin(owner,a.character.id,'melee',a.currentActionSource or 'scripted')end
  a.finishMeleeAction=function(step,owner,status)self.partCombat:finish(step,owner,status)end
  a.beginMovementAction=function(owner,action,origin)return self.partCombat:begin(owner,a.character.id,action,origin)end
  a.finishMovementAction=function(step,owner,action)self.partCombat:finishMovement(step,owner,action)end
  a.observeProjectile=function(bullet,source,step)self.partCombat:projectile(bullet,source=='mentor' and 'mentor' or a.character.id,source=='mentor' and 'mentor' or 'laser',step)end
  a.observeRedirectedProjectile=function(bullet,source,step)self.partCombat:projectile(bullet,source=='mentor' and 'mentor' or a.character.id,source=='mentor' and 'mentor' or 'laser',step,true)end
  a.meleeContact=function(owner,step)return self.partCombat:melee(owner,a.character.id,step)end
 end
 self.support,self.supportView=require('Factory.Support').create(ni.world,options.training and {100,100,100} or require('Factory.Health').load(),support)
 local hp=self.support.hp;self.mentorHP=hp[1];ni.studentHP=hp[2];wu.studentHP=hp[3]
 if not options.training then require('Training.FlowerController').attach(self,attempt.models)end
 if attempt.supplyAttempt or virtual then
  self.supplies=virtual or assert(require('Economy.CombatSession').open(attempt.supplyAttempt))
  if virtual then self.partCombat.journal.versions.resourceSimulation=1 end
  self.partCombat.journal.versions.resources=1;self.partCombat.journal.versions.resourceAttribution=1;self.partCombat.journal.versions.resourceFeatures=1
  for _,arena in ipairs(self.learners)do arena.supplies=self.supplies end
 end
 self.phase="ready"; self.last=D.App.runningTime
 ni.world:schedule(function() return self:update() end)
 return self
end
return Battle
