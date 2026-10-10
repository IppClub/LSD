local K=require('Combat.Displacement')
-- Chapter-three corridor defense. Finite waves, real targets and native actions.
local D=require('Dora');local A=require('CombatAnimation');local Enemy=require('Academy.DefenseEnemy')
local Battle={};Battle.__index=Battle
local names={'清理学院入口','守住供电节点','护送撤离信标'}
function Battle:target(unit)
 local best,distance
 for _,e in ipairs(self.enemies)do local d=math.abs(e.enemy.x-unit.x);if e.enemyHP>0 and (not distance or d<distance)then best=e;distance=d end end
 return best
end
function Battle:damage(unit,n)
 if self.phase~='playing'then return 0 end
 for _,e in ipairs(self.enemies)do if e.enemy==unit then local dealt=math.min(e.enemyHP,n);e.enemyHP=e.enemyHP-dealt;return dealt end end
 return 0
end
function Battle:command(name)
 if self.phase~='playing'then return false,'NOT_PLAYING'end
 if name=='fire'then return self.magic:request('fire')end
 if name=='medicine'then
  if self.mentorHP<=0 then return false,'NOT_ALIVE'end
  if self.medicineBusy or self.mentorHP>=100 then return false,'NOT_NEEDED'end
  self.medicineBusy=true
  D.thread(function()
   local ok,err=require('Story.Supplies').consumeAsync('mentor','first-aid-water')
   if ok then self.medicineUses=self.medicineUses+1;if self.phase=='playing'and self.mentorHP>0 then self.mentorHP=math.min(100,self.mentorHP+25)end end
   self.medicineRemaining=require('Story.Supplies').count('mentor','first-aid-water')or 0
   self.medicineBusy=false;self.message=ok and '已使用治疗水，恢复25生命。'or err=='EMPTY'and '治疗水已用完。'or '药品未使用：'..tostring(err)
  end);return true
 end
 if K.blocked(self.mentor)then return false,'DISPLACED'end
 if name=='shoot'then if self.supplies and not self.supplies:canSpend('mentor','kinetic')then return false,'NO_SUPPLIES'end;local e=self:target(self.mentor);if not e then return false,'NO_TARGET'end;self.mentor.faceRight=e.enemy.x>=self.mentor.x;return self.mentor:start('groundMentorShot')end
 if name=='left'or name=='right'then if self.mentor:isDoing('groundMentorShot')then return false,'ACTION_BUSY'end;return require('Combat.Movement').command(self.mentor,name)end
 if name=='stop'then if self.mentor:isDoing('groundMentorMove')then self.mentor:stop();self.mentor.velocityX=0;A.rest(self.mentor)end;return true end
 return false,'UNKNOWN_COMMAND'
end
function Battle:partyDamage(role,n)
 if self.phase~='playing'then return 0 end
 if role=='mentor'then local dealt=math.min(n,self.mentorHP);self.mentorHP=self.mentorHP-dealt;return dealt end
 local a=self.arena;local dealt=math.min(n,a.studentHP);a.studentHP=a.studentHP-dealt;a.metrics.damageTaken=a.metrics.damageTaken+dealt;return dealt
end
function Battle:spawnStage(index)
 self.stage=index;self.stageStarted=D.App.runningTime;self.stageName=names[index];self.enemies={}
 local positions=index==1 and {1200,1500}or index==2 and {850,1700}or {1700,2050}
 for i,x in ipairs(positions)do
  local u=self.arena.spawnUnit('xiaotaotie',2,x,{})
  local e={enemy=u,enemyHP=150,student=self.arena.student,studentHP=self.arena.studentHP,world=self.world,metrics=self.arena.metrics,enemyPhase='idle',nextEnemy=D.App.runningTime+i*.9,minX=150,maxX=self.maxX,enemySpeed=85,projectiles=self.arena.projectiles,mode='trial'}
  e.enemyTargets=function()
   -- Attack phases iterate these adapters every frame; cache per enemy and
   -- refresh the unit fields in place instead of rebuilding tables and closures.
   local targets=e._targets
   if not targets then
    targets={{alive=function()return self.phase=='playing' and self.mentorHP>0 end,damage=function(n)return self:partyDamage('mentor',n)end},{alive=function()return self.phase=='playing' and self.arena.studentHP>0 end,damage=function(n)return self:partyDamage('learner',n)end}}
    if index>1 then table.insert(targets,1,{immovable=true,damage=function(n)
     if self.phase~='playing'then return 0 end
     local hp=index==2 and self.powerHP or self.beaconHP;local dealt=math.min(n,hp)
     if index==2 then self.powerHP=hp-dealt else self.beaconHP=hp-dealt end;return dealt
    end})end
    e._targets=targets
   end
   if index>1 then targets[1].unit=self.objective end
   targets[index>1 and 2 or 1].unit=self.mentor;targets[index>1 and 3 or 2].unit=self.arena.student
   return targets
  end
  e.controller=Enemy.new(e,i==1 and {'blow','butt','roll'}or {'bomb','swing','roll'});self.enemies[#self.enemies+1]=e
 end
 self.objective.visible=index>1
 if index==2 then self.objective.x=1300 elseif index==3 then self.objective.x=1300;self.beaconStartX=1300 end
end
function Battle:start()
 if self.phase~='ready'then return false end
 self.phase='playing';self.started=D.App.runningTime;self.arena.mode='trial';self.arena.nextDecision=self.started+.2;self:spawnStage(1);return true
end
function Battle:finish(status,reason)
 if self.phase~='playing'and self.phase~='ready'then return false end
 K.clear(self.mentor);K.clear(self.arena.student)
 self.phase='settling';self.reason=reason;self.arena.mode='review'
 self.mentor.velocityX=0;self.arena.student.velocityX=0;self.objective.velocityX=0
 for _,e in ipairs(self.enemies)do e.controller:stop()end
 D.thread(function()
  local deadline=D.App.runningTime+15
  while true do
   local busy=self.medicineBusy or self.mentor:isDoing('groundMentorShot')or self.arena:isAttacking()
   local beacon=self.objectiveView.beacon
   busy=busy or (beacon and not beacon.active and not beacon.completed.lose)
   for _,e in ipairs(self.enemies)do busy=busy or e.enemyPhase=='attack'or e.controller.dying end
   if not busy then break end
   -- The engine swallows thread errors; degrade to settlement instead of a silent deadlock.
   if D.App.runningTime>=deadline then print('DefenseBattle: action did not finish, settling anyway')break end
   D.sleep(.02)
  end
  for _,t in ipairs({{self.mentor,self.mentorHP},{self.arena.student,self.arena.studentHP}})do t[1]:stop();t[1].velocityX=0;if t[2]<=0 then A.playOnceAsync(t[1],'lose')else A.rest(t[1])end end
  self.report={encounter='academy-defense',status=status,reason=reason,stages=self.completedStages,medicineUses=self.medicineUses,mentorHP=self.mentorHP,mentorHits=self.mentorHits,powerHP=self.powerHP,beaconHP=self.beaconHP,beaconX=self.objective.x,beaconStartX=self.beaconStartX,escortDistance=self.escortDistance,escortSeconds=self.escortSeconds,exitX=self.exitX,fireHits=self.magic.fireHits,learner={hp=self.arena.studentHP,modelActions=self.arena.metrics.modelActions,hits=self.arena.metrics.hits,samples=self.arena.trialModel.sampleCount,training=require("Training.Summary").record(self.arena.trialModel)},seconds=self.started and D.App.runningTime-self.started or 0}
  self.phase=status
 end);return true
end
function Battle:update(dt)
 local now=D.App.runningTime
 self.objectiveView:update(self,dt)
 for _,e in ipairs(self.enemies)do
  e.studentHP=math.min(self.mentorHP,self.arena.studentHP)
  if self.stage>1 then e.student=self.objective else e.student=self.mentor end
  e.controller:update(now)
 end
 if self.phase~='playing'then return false end
 self.magic:update()
 local target=self:target(self.arena.student)
 if target then self.followAnimation=nil;self.arena.enemy=target.enemy;self.arena.enemyHP=target.enemyHP;self.arena.enemyPhase=target.enemyPhase;self.arena:update()
 elseif self.stage~=3 and not self.arena:isAttacking()and not K.blocked(self.arena.student)then self.arena.student:stop();self.arena.student.velocityX=0;A.rest(self.arena.student)end
 self.mentor.x=math.max(150,math.min(self.maxX,self.mentor.x))
 local cleared=true
 for _,e in ipairs(self.enemies)do if not e.controller.dead then cleared=false end end
 if self.stage==3 then
  local mentorNearby=math.abs(self.mentor.x-self.objective.x)<360
  local learnerNearby=math.abs(self.arena.student.x-self.objective.x)<500
  local nearby=mentorNearby and learnerNearby
  local safe=true;for _,e in ipairs(self.enemies)do if e.enemyHP>0 and math.abs(e.enemy.x-self.objective.x)<450 then safe=false end end
  self.escortHint=not safe and '信标暂停：先清除附近敌人。'or not mentorNearby and '信标等待导师：请靠近悬浮机，再共同向右前进。'or not learnerNearby and '信标等待妮妮莉特归队。'or '信标正在前进：保持在附近，护送至右侧出口。'
  if nearby and safe then
   local old=self.objective.x;self.objective.x=math.min(self.exitX,old+85*dt)
   self.escortDistance=self.escortDistance+self.objective.x-old;self.escortSeconds=self.escortSeconds+dt
  end
  -- Learner follows the protected beacon between fights without resetting its model.
  if not target and not self.arena:isAttacking()and not K.blocked(self.arena.student)then local delta=self.objective.x-self.arena.student.x
   self.arena.student.faceRight=delta>=0;self.arena.student.velocityX=math.abs(delta)>150 and (delta>0 and 140 or -140)or 0
   local desired=self.arena.student.velocityX~=0 and 'fmove'or self.arena.student.data.combatRest
   if self.arena.student.playable.current~=desired then self.arena.student:stop();self.followAnimation=desired;A.play(self.arena.student,desired,true)end
  end
 end
 self.world.camera.zoom=.85;self.world.camera.position=D.Vec2(math.max(900,math.min(self.maxX-600,self.mentor.x+250)),350)
 if self.mentorHP<=0 or self.arena.studentHP<=0 then self:finish('failed','队伍失去战斗能力。')
 elseif self.powerHP<=0 then self:finish('failed','供电节点被破坏，撤离通道失去供电。')
 elseif self.beaconHP<=0 then self:finish('failed','撤离信标被破坏。')
 elseif now-self.started>240 then self:finish('failed','未能及时打开撤离通道。')
 elseif cleared and not self.arena:isAttacking()and not self.mentor:isDoing('groundMentorShot')and (self.stage<3 or self.objective.x>=self.exitX)then
  local record={stage=self.stage,name=self.stageName,seconds=now-self.stageStarted,powerHP=self.powerHP,beaconHP=self.beaconHP,guards={}}
  for _,e in ipairs(self.enemies)do
   local strikes={};for _,strike in ipairs(e.enemyAttacks)do local saved={};for key,value in pairs(strike)do if type(value)=='number'or type(value)=='string'or type(value)=='boolean'then saved[key]=value end end;strikes[#strikes+1]=saved end
   record.guards[#record.guards+1]={hp=e.enemyHP,strikes=strikes,loseStarted=e.controller.loseStarted,loseEnded=e.controller.loseEnded,loseDuration=e.controller.loseDuration};e.enemy:removeFromParent()
  end
  self.completedStages[#self.completedStages+1]=record
  if self.stage==3 then self:finish('won','入口与供电已守住，撤离信标抵达安全出口。')else self:spawnStage(self.stage+1)end
 end
 return false
end
function Battle.createAsync(models,attempt)
 assert(models and models.ninilite,'Adopted Nini model required')
 local self=setmetatable({phase='loading',stage=0,stageName='学院入口',mentorHP=100,mentorHits=0,nextMentorShot=0,medicineUses=0,powerHP=150,beaconHP=150,escortDistance=0,escortSeconds=0,enemies={},completedStages={}},Battle)
 self.medicineRemaining=require('Story.Supplies').count('mentor','first-aid-water')or 0
 local a=require('Training.Arena').createAsync({scene='PassageA',manualUpdate=true,origin=650,minX=150,maxX=2194,actionPrefix='defenseNi_'})
 if attempt and attempt.supplyAttempt then self.supplies=assert(require('Economy.CombatSession').open(attempt.supplyAttempt));a.supplies=self.supplies end
 self.arena=a;self.world=a.world;self.maxX=math.min(3000,self.world.sceneWidth-150);self.exitX=math.min(2800,self.maxX-100)
 D.Platformer.Data:setRelation(1,3,'Neutral');D.Platformer.Data:setRelation(2,3,'Neutral')
 D.Platformer.Data:setShouldContact(1,3,false);D.Platformer.Data:setShouldContact(2,3,false);D.Platformer.Data:setShouldContact(3,D.Platformer.Data.groupTerrain,true)
 assert(a:beginTrial(500,models.ninilite));a.externalRound=true;a.externalCombat=true;a.mode='review';a.enemy.visible=false;a.enemy.group=3
 a.damageOpponent=function(u,n)return self:damage(u,n)end
 self.mentorTarget=function()local e=self:target(self.mentor);return e and e.enemy end;self.damageMentorTarget=function(u,n)return self:damage(u,n*3)end
 require('Ground.Mentor').createAsync(self,require('Data.Config').char);self.mentor.position=D.Vec2(800,self.world.offset+155)
 self.objective=a.spawnUnit('ninilite',1,1600,{});self.objective.playable.visible=false;self.objective.visible=false
 D.Cache:loadAsync('Spine/operationRoom.png');D.Cache:loadAsync('Image/Auxiliary/mobility.model')
 self.objectiveView=require('Academy.DefenseObjectives').create(self.world)
 self.magic=require('Ground.WindFire').new(self);self.world.defenseBattle=self;self.phase='ready'
 self.world.camera.zoom=.85;self.world.camera.position=D.Vec2(1050,350)
 local tick=D.Node();tick:addTo(self.world);tick:schedule(function(dt)return self:update(dt)end);return self
end
return Battle
