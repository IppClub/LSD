-- Encounter composition; public mission routing and adoption schema are separate.
local D=require('Dora');local Rules=require('Enemy.BigYingzhaoRules');local M={}
function M.createAsync(models,supplies,options)
 options=options or {}
 local E=require('Enemy.BigYingzhao');E.loadAsync()
 local b=require('Factory.PatrolBattle').createAsync(models,{id='big-yingzhao',arena={minX=200,maxX=3640,niniliteX=1120,wuyunX=1270,mentorX=1320,cameraMinX=200,cameraMaxX=3640,cameraInitialX=1920},enemyX=1920,scene=options.virtual and 'VRTraining'or'AbandonedCity',enemyAsset=E.asset,enemyFactory=E.create,controller=E,singleEnemy=true,enemyHP=Rules.maxHP,timeLimit=180,victory=function()return true,'大英招已击退。'end})
 local boss=b.enemies[1];b.supplies=supplies
 b.bossTrace={schemaVersion=1,arenaVersion=2,observationVersion=1,hitTimeVersion=1,skillTimeVersion=1,trainable=false,steps={},hits={},limit=1500}
 local known={};local knownSummons={}
 local trace=b.bossTrace
 trace.gatherVersion=1;trace.gathers={}
 local gatherRecord
 local function planSnapshot(plan)
  return {anchor=plan._anchor,ninilite=plan.ninilite,wuyun=plan.wuyun,spacing=plan._spacing,compressed=plan._compressed,away=plan._away}
 end
 local function closeGather(reason)
  if gatherRecord and not gatherRecord.ended then
   gatherRecord.ended=D.App.runningTime;gatherRecord.reason=reason
   gatherRecord.final={mentorX=b.mentor.x,niniliteX=b.arena.student.x,wuyunX=b.wuyun.student.x,machineX=b.support and b.support.x}
   b.gatherFeedback=nil
   if reason=='DEADLINE'then
    local message=require('Combat.Formation').deadlineFeedback(b.learners,b.gatherPlan,b.gatherMode,
     {b.mentorHP,b.arena.studentHP,b.wuyun.studentHP},b.support and b.support.maxHP,
     b.support and b.support.gold>0 and b.support.machineHP>0)
    if message then b.gatherFeedback={text=message,untilAt=D.App.runningTime+4}end
   end
  end
 end
 local function append(list,row)if #list>=trace.limit then trace.truncated=true;return end;list[#list+1]=row;return #list end
 b.bossCombat=require('Enemy.BigYingzhaoProjectiles').new(b,boss,function(e)
  e.at=D.App.runningTime
  append(trace.hits,e)
  if e.target=='big-yingzhao'then known[e.part]={ap=e.apAfter,observedAt=D.App.runningTime}elseif e.summoned then knownSummons[e.target]=true end
  if e.source=='mentor'then b.mentorHits=b.mentorHits+1 else for _,a in ipairs(b.learners)do if a.character.id==e.source then a.metrics.hits=a.metrics.hits+1 end end end
 end)
 b.target=function(self,unit)
  local found,distance
  for _,e in ipairs(self.enemies)do if e.enemyHP>0 and e.enemy.visible and e.enemy.opacity>.1 then
   local d=math.abs(e.enemy.x-unit.x);if not distance or d<distance then found=e;distance=d end
  end end
  return found
 end
 local oldDamage=b.damage
 b.damage=function(self,u,n)if u==boss.enemy then return 0 end;return oldDamage(self,u,n)end
 b.gatherSupported=true
 b.gatherThreat=function(self)
  local target=self:target(self.mentor)
  return self.bossCombat.armor:available()and self.bossCombat.boss.enemy.x or target and target.enemy.x or self.mentor.x+(self.mentor.faceRight and 700 or -700)
 end
 b.gatherActive=function(self)
  if self.phase~='playing'or D.App.runningTime>=(self.gatherUntil or 0)then return false end
  if self.gatherMode=='recover'and (not self.support or self.support.gold<=0 or self.support.machineHP<=0)then return false end
  for _,a in ipairs(self.learners)do if a.studentHP>0 and not a.regroupComplete then return true end end
  return self.gatherMode=='recover'and require('Combat.Formation').recoveryNeeded(
   {self.mentorHP,self.arena.studentHP,self.wuyun.studentHP},self.support and self.support.maxHP,
   self.support and self.support.gold>0 and self.support.machineHP>0)
 end
 local command=b.command
 b.command=function(self,name)
  if name=='gather'or name=='recover-gather'then
   if self.phase~='playing'then return false,'NOT_PLAYING'end
   if name=='recover-gather'and (not self.support or self.support.gold<=0 or self.support.machineHP<=0)then return false,'SUPPORT_UNAVAILABLE'end
   if name=='gather'and self:gatherActive()then
    closeGather('PLAYER_CANCELLED')
    self.gatherUntil=0;self.gatherPlan=nil;self.gatherMode=nil
    for _,a in ipairs(self.learners)do
     require('Combat.Formation').stop(a)
     a.nextDecision=D.App.runningTime
    end
    return true,'GATHER_CANCELLED'
   end
   if name=='recover-gather'and self:gatherActive()and self.gatherMode=='recover'then return true,'ALREADY_RECOVERING'end
   self.gatherClearedPending=(self.gatherClearedPending or 0)+self.magic:cancelPending()
   local threat=self:gatherThreat()
   local F=require('Combat.Formation')
   self.gatherMode=name=='recover-gather'and 'recover'or 'normal'
   self.gatherPlan=F.plan(self.mentor.x,threat,{'wuyun','ninilite'},self.minX,self.maxX,{keepAway=true,spacing=self.gatherMode=='recover'and F.recoverySpacing or F.spacing})
   self.gatherPlan._anchor=self.mentor.x
   self.gatherDuration=self.gatherMode=='recover'and F.recoveryDuration(self.gatherPlan,self.learners,{self.mentorHP,self.arena.studentHP,self.wuyun.studentHP},self.support.maxHP,self.support.healingRate)or F.duration(self.gatherPlan,self.learners)
   self.gatherUntil=D.App.runningTime+self.gatherDuration
   closeGather('REPLACED')
   self.gatherFeedback=nil
   gatherRecord={started=D.App.runningTime,mode=self.gatherMode,deadline=self.gatherUntil,initialPlan=planSnapshot(self.gatherPlan),latestPlan=planSnapshot(self.gatherPlan),replans=0,arrivals={},threatX=threat}
   if #trace.gathers<trace.limit then trace.gathers[#trace.gathers+1]=gatherRecord else trace.gatherTruncated=true end
   return true
  end
  if name=='shoot'and self.mentorAim.shot then
   if self.phase~='playing'then return false,'NOT_PLAYING'end
   if not self:target(self.mentor)then return false,'NO_TARGET'end
   return self.mentor:start('groundMentorShot')
  end
  return command(self,name)
 end
 local function observation(owner,actor)return require('Training.YingzhaoFeatures').capture(b,owner,known,knownSummons)end
 b.observeYingzhao=function(owner)return observation(owner)end
 for _,a in ipairs(b.learners)do
  assert(not a.observeProjectile and not a.beginCombatAction,'Encounter cannot replace another observer')
  a.supplies=supplies
  a.allowMeleeImpact=function()return b.phase=='playing'end
  local available=a.available
  a.available=function(self,action)
   if (action=='fmove'or action=='bmove')and require('Combat.Formation').stationaryRecovery(self,b,D.App.runningTime)then return false,'RECOVERY_FORMATION'end
   return available(self,action)
  end
  local update=a.update
  a.update=function(self,...)
   if gatherRecord and not gatherRecord.ended then
    if b.phase~='playing'then closeGather('BATTLE_ENDED')
    elseif D.App.runningTime>=gatherRecord.deadline then closeGather('DEADLINE')
    elseif b.gatherMode=='recover'and not b:gatherActive()then
     closeGather(b.support and b.support.gold>0 and b.support.machineHP>0 and 'RECOVERED'or'SUPPORT_UNAVAILABLE')
    end
   end
   -- Recovery follows retreat and visible threat-side changes. Ordinary
   -- gather remains frozen; neither case extends the original deadline.
   if b.phase=='playing' and b.gatherMode=='recover' and b:gatherActive() and b.gatherPlan then
    local F=require('Combat.Formation')
    local threat=b:gatherThreat()
    if F.needsRecoveryReplan(b.gatherPlan,b.mentor.x,threat)then
     b.gatherPlan=F.plan(b.mentor.x,threat,{'wuyun','ninilite'},b.minX,b.maxX,{keepAway=true,spacing=F.recoverySpacing})
     b.gatherPlan._anchor=b.mentor.x
     if gatherRecord and not gatherRecord.ended then gatherRecord.replans=gatherRecord.replans+1;gatherRecord.latestPlan=planSnapshot(b.gatherPlan)end
    end
   end
   if self.regroupPlan~=b.gatherPlan then self.regroupPlan=b.gatherPlan;self.regroupComplete=false end
   if b.phase=='playing'and b.gatherMode=='recover'and b:gatherActive()and self.regroupComplete and math.abs(self.student.x-b.gatherPlan[self.character.id])>require('Combat.Formation').tolerance then self.regroupComplete=false end
   if b.phase=='playing'and b.gatherMode=='recover'and not b:gatherActive()then b.gatherUntil=0;b.gatherMode=nil end
   if b.phase=='playing'and D.App.runningTime<(b.gatherUntil or 0)and not self.regroupComplete then
    if require('Combat.Formation').step(self,b.gatherPlan[self.character.id],b)then
     self.regroupComplete=true
     if gatherRecord and not gatherRecord.ended then
      gatherRecord.arrivals[self.character.id]={at=D.App.runningTime,x=self.student.x,target=b.gatherPlan[self.character.id],anchor=b.gatherPlan._anchor}
      if b.gatherMode=='normal'and not b:gatherActive()then closeGather('ARRIVED')end
     end
    else self.nextDecision=D.App.runningTime+.15;return end
   end
   if b.phase=='playing'and b.gatherMode=='recover'and b:gatherActive()then
    -- Keep the healing slot, but let the saved model choose legal stationary
    -- actions. Arrival does not invent a policy or release autonomous movement.
    require('Combat.Formation').stop(self)
   end
   require('Combat.Formation').stop(self);return update(self,...)
  end
  local function actorFor(source)return source=='mentor'and'mentor'or a.character.id end
  local function begin(owner,source,action)
   local actor=actorFor(source)
   return append(trace.steps,{actor=actor,action=action,started=D.App.runningTime,origin=source=='mentor'and(b.mentorActionOrigin or 'scripted')or a.currentActionSource or 'unknown',before=observation(owner,actor)})
  end
  local activeAim,activeStep
  local pendingEmission={}
  local aimNode=D.Node();aimNode:addTo(b.world)
  aimNode:schedule(function()
   if activeAim then
    if b.phase=='playing'and a.student:isDoing(a.physical.laser)then
     local emitted=activeStep and trace.steps[activeStep].aimEmission
     a.student.playable:setBoneRotation('aim',-(emitted and emitted.angle or activeAim.angle))
    else a.student.playable:setBoneRotation('aim',0);activeAim=nil end
   end
   return b.bossCombat.closed
  end)
  a.beginCombatAction=function(owner,source)
   local id=begin(owner,source,'shoot')
   if id and source=='mentor'and b.mentorPartAim then trace.steps[id].aim=D.json.decode(D.json.encode(b.mentorPartAim),32)end
   if id and source~='mentor'and a.yingzhaoAim then trace.steps[id].aim=D.json.decode(D.json.encode(a.yingzhaoAim),32);activeAim=trace.steps[id].aim;activeStep=id end
   return id
  end
  a.updateWithoutVisibleTarget=function(self)
   if self.mode=='demo'or (b.yingzhaoQTraining and b.yingzhaoQTraining.actor==self.character.id)or (b.yingzhaoCandidates and b.yingzhaoCandidates[self.character.id])then self:update();return true end
   return false
  end
  a.targetFacingForAction=function(action)
   if action=='laser'and a.yingzhaoAim then return a.yingzhaoAim.faceRight end
   if a.yingzhaoMovementFace~=nil then return a.yingzhaoMovementFace end
   local target=b:target(a.student)
   if not target then return a.student.faceRight end
   return require('Training.YingzhaoActions').movementFaceRight(a.student,target.enemy)
  end
  a.finishCombatAction=function(step,owner,source,status)local row=step and trace.steps[step];if row and not row.ended then row.ended=D.App.runningTime;row.completion=status;row.after=observation(owner,actorFor(source))end end
  a.observeProjectile=function(bullet,source,step)
   local actor=actorFor(source);local owner=source=='mentor'and b.mentor or a.student
   local row=step and trace.steps[step];if row then row.aimEmission=pendingEmission[step];pendingEmission[step]=nil;row.emitted=(row.emitted or 0)+1;row.muzzle={x=bullet.x,y=bullet.y};row.velocity={x=bullet.velocityX,y=bullet.velocityY}end
   b.bossCombat:projectile(bullet,actor,source=='mentor'and'mentor'or'laser',owner,step)
  end
  a.prepareStudentShot=function(owner,step)
   if b.phase~='playing'then return end
   local row=step and trace.steps[step]
   if row and row.aim then
    owner.faceRight=row.aim.faceRight
    local shot,why=require('Training.YingzhaoActions').emission(row.aim,require('Combat.Muzzle').actual(b.world,owner))
    if not shot then row.emissionCancelled=why;return end
    if row.aim.muzzleMode then pendingEmission[step]={angle=shot.angle,origin=shot.origin,at=D.App.runningTime} end
    return shot
   end
   if b.phase~='playing'or not b:target(owner)then return end
   return {angle=0,origin=require('Combat.Muzzle').actual(b.world,owner)}
  end
  a.prepareMentorShot=function(owner,step,muzzle,angle)
   local row=step and trace.steps[step]
   if not row or not row.aim then return {angle=angle,origin=muzzle}end
   local shot,why=require('Training.YingzhaoActions').emission(row.aim,muzzle)
   if not shot then row.emissionCancelled=why;return end
   if row.aim.muzzleMode then pendingEmission[step]={angle=shot.angle,origin=shot.origin,at=D.App.runningTime}end
   b.mentorAim.angle=shot.angle
   return shot
  end
  a.beginMovementAction=function(owner,action,origin)
   local id=begin(owner,'learner',action);if id then trace.steps[id].origin=a.regroupPlan==b.gatherPlan and not a.regroupComplete and D.App.runningTime<(b.gatherUntil or 0)and'command-gather'or origin end;return id
  end
  a.finishMovementAction=function(step,owner)a.finishCombatAction(step,owner,'learner')end
  a.beginMeleeAction=function(owner)return begin(owner,'learner','melee')end
  a.finishMeleeAction=function(step,owner,status)a.finishCombatAction(step,owner,'learner',status)end
  a.meleeContact=function(owner,step)return b.bossCombat:melee(owner,a.character.id,step)end
 end
 b.magic.onStarting=function(name)return observation(b.magic.roles[name].student)end
 b.magic.onStarted=function(name,log,before)
  local owner=b.magic.roles[name].student
  log.step=append(trace.steps,{actor=log.actor,action=name,origin=log.source,started=log.startedAt,before=before or observation(owner,log.actor),skill=log})
 end
 b.magic.onReleased=function(name,log)
  local row=log.step and trace.steps[log.step];if row then row.emitted=1 end
 end
 b.magic.onStopped=function(name,log)
  local row=log.step and trace.steps[log.step]
  if row then
   row.ended=log.endedAt
   if log.reason=='CLEANUP'then row.afterUnavailable='WORLD_CLEANUP'
   else row.after=observation(b.magic.roles[name].student,log.actor)end
  end
 end
 require('Enemy.BigYingzhaoMagic').attach(b)
 local closeVitals=require('Training.YingzhaoVitals').attach(b)
 local finish=b.finish
 b.finish=function(self,status,reason)
  local ok=finish(self,status,reason)
  if ok then
   closeGather('BATTLE_ENDED')
   -- Close training intent now while the authored animation tail may finish.
   for name,log in pairs(self.magic.activeLogs)do self.magic:finish(name,log,'cancelled','BATTLE_ENDED')end
   self.magic.pending={};self.magic.pendingContext={}
   closeVitals()
   self.mentorAim:cancel();trace.closed=true;trace.status=status;trace.encounter={maxHP=Rules.maxHP,hp=boss.enemyHP,defeated=boss.guard.dead==true}
   if supplies then trace.resources=supplies:evidence()end
   self.report.bossTrace=trace;self.report.partArmor=self.bossCombat.armor.target.damage.parts
   self.bossCombat:close()
  end
  return ok
 end
 if options.physicalSupport then
  assert(options.virtual,'Formal host supplies its actual auxiliary machine')
  require('Ground.BattleSupport').attach(b,require('Ground.LifeSupport').new(45,'defence'))
 end
 return b
end
return M
