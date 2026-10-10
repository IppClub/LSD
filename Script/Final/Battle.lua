local K=require('Combat.Displacement')
-- Final evacuation: the selected original auxiliary carries the recovered records.
local D=require('Dora');local A=require('CombatAnimation');local Defense=require('Academy.DefenseBattle')
local Battle={};Battle.__index=Battle
Battle.target=Defense.target;Battle.damage=Defense.damage;Battle.partyDamage=Defense.partyDamage
local stops={800,1450,2090};local names={'穿过受损入口','越过断电走廊','抵达撤离终端'}
function Battle:command(name)
 if name=='medicine'and self.phase=='playing'and self.emergencyRemaining>0 and self.mentorHP>0 and self.mentorHP<100 and not self.medicineBusy then
  self.emergencyRemaining=self.emergencyRemaining-1;self.emergencyUsed=self.emergencyUsed+1;self.mentorHP=math.min(100,self.mentorHP+25)
  self.message='已使用本次行动的紧急治疗水。';self.medicineRemaining=self.permanentMedicine+self.emergencyRemaining;return true
 end
 return Defense.command(self,name)
end
function Battle:contact(role,unit,n,strike,enemy)
 if self.phase~='playing'then return 0 end
 -- Same-lane impact segment intersects a visible cover panel. A blast checks
 -- its actual explosion origin, not the thrower's old location.
 local source=strike and strike.explosionX or enemy.x
 local sourceY=strike and strike.explosionX and self.world.offset+35 or enemy.y
 for _,x in ipairs(self.covers)do
  local blocked,impactY=require('Final.Cover').intersection(x,self.world.offset,source,sourceY,unit.x,unit.y)
  if blocked then
   self.coverBlocks=self.coverBlocks+1;self.coverEvents[#self.coverEvents+1]={x=x,targetX=unit.x,targetY=unit.y,sourceX=source,sourceY=sourceY,impactY=impactY,base=self.world.offset,role=role,kind=strike.kind,at=D.App.runningTime};return 0
  end
 end
 if role=='machine'then local before=self.support.machineHP;self.support:damageMachine(n);return before-self.support.machineHP end
 return self:partyDamage(role,n)
end
function Battle:spawnStage(index)
 self.stage=index;self.stageStarted=D.App.runningTime;self.stageName=names[index];self.enemies={}
 local positions=({{770,990},{1390,1610},{1920,2100}})[index]
 for i,x in ipairs(positions)do
  local u=self.arena.spawnUnit('xiaotaotie',2,x,{})
  local e={enemy=u,enemyHP=125,student=self.objective,studentHP=100,world=self.world,metrics=self.arena.metrics,enemyPhase='idle',nextEnemy=D.App.runningTime+1+i*.6,minX=150,maxX=2194,enemySpeed=65,projectiles=self.arena.projectiles,mode='trial'}
  e.enemyTargets=function()
   return {{unit=self.objective,immovable=true,damage=function(n,s)return self:contact('machine',self.objective,n,s,u)end},
    {unit=self.mentor,alive=function()return self.phase=='playing' and self.mentorHP>0 end,damage=function(n,s)return self:contact('mentor',self.mentor,n,s,u)end},
    {unit=self.arena.student,alive=function()return self.phase=='playing' and self.arena.studentHP>0 end,damage=function(n,s)return self:contact('learner',self.arena.student,n,s,u)end}}
  end
  e.controller=require('Academy.DefenseEnemy').new(e,i==1 and {'blow','butt','roll'}or {'bomb','swing','roll'});self.enemies[#self.enemies+1]=e
 end
end
function Battle:start()
 if self.phase~='ready'then return false end
 self.phase='playing';self.started=D.App.runningTime;self.arena.mode='trial';self.arena.nextDecision=self.started+.2;self:spawnStage(1);return true
end
function Battle:finish(status,reason)
 if self.phase~='ready'and self.phase~='playing'then return false end
 K.clear(self.mentor);K.clear(self.arena.student)
 self.phase='settling';self.reason=reason;self.arena.mode='review';self.mentor.velocityX=0;self.arena.student.velocityX=0;self.objective.velocityX=0
 for _,e in ipairs(self.enemies)do e.controller:stop()end
 D.thread(function()
  local deadline=D.App.runningTime+20
  while true do
   local busy=self.medicineBusy or self.mentor:isDoing('groundMentorShot')or self.arena:isAttacking()
   for _,e in ipairs(self.enemies)do busy=busy or e.enemyPhase=='attack'or e.controller.dying end
   busy=busy or (self.support.machineHP<=0 and not self.actor.completed.lose)
   if not busy then break end
   -- The engine swallows thread errors; degrade to settlement instead of a silent deadlock.
   if D.App.runningTime>=deadline then print('FinalBattle: action did not finish, settling anyway')break end
   D.sleep(.02)
  end
  for _,t in ipairs({{self.mentor,self.mentorHP},{self.arena.student,self.arena.studentHP}})do t[1]:stop();t[1].velocityX=0;if t[2]<=0 then A.playOnceAsync(t[1],'lose')else A.rest(t[1])end end
  local s=self.support
  self.report={encounter='last-promise',status=status,reason=reason,seconds=self.started and D.App.runningTime-self.started or 0,stages=self.completedStages,
   mentorHP=self.mentorHP,mentorX=self.mentor.x,mentorHits=self.mentorHits,fireHits=self.magic.fireHits,
   learner={hp=self.arena.studentHP,x=self.arena.student.x,modelActions=self.arena.metrics.modelActions,hits=self.arena.metrics.hits,samples=self.arena.trialModel.sampleCount,training=require("Training.Summary").record(self.arena.trialModel)},
   auxiliary={variant=s.variant,hp=s.machineHP,x=self.objective.x,startX=350,distance=self.escortDistance,seconds=self.escortSeconds,loops=self.actor.completed},
   support={gold=s.gold,spent=s.spent,healed=s.healed,hazardDamage=s.hazardDamage,initialGold=45,collected=self.collectedGold,radius=360},
   coverBlocks=self.coverBlocks,coverEvents=self.coverEvents,emergencyGranted=self.emergencyGranted,emergencyUsed=self.emergencyUsed,medicineUses=self.medicineUses}
  self.phase=status
 end);return true
end
-- Keep the authored range geometry local to its moving carrier. Only the
-- support state changes its color; health text only changes at a visible value.
function Battle:updateSupportDisplay()
 local s=self.support;local base=self.world.offset
 self.ring.position=D.Vec2(self.objective.x,base)
 if self.displaySupportActive~=s.active then
  self.displaySupportActive=s.active;self.ring:clear()
  local color=D.Color(s.active and 0x9952dfcf or 0x99ec936e)
  self.ring:drawSegment(D.Vec2(-360,8),D.Vec2(360,8),4,color)
  for _,x in ipairs({-360,360})do self.ring:drawSegment(D.Vec2(x,8),D.Vec2(x,80),3,color)end
 end
 self.machineLabel.position=D.Vec2(self.objective.x,base+350)
 local text='记录载体  '..math.ceil(s.machineHP)..' / 100'
 if self.displayMachineText~=text then self.displayMachineText=text;self.machineLabel.text=text end
end
function Battle:update(dt)
 local now=D.App.runningTime;local a=self.arena;local s=self.support
 self.holder.position=D.Vec2(self.objective.x,self.world.offset);self.actor:reveal(.4);self.actor:update(s,self.objective.x)
 self:updateSupportDisplay()
 for _,e in ipairs(self.enemies)do e.studentHP=math.min(self.mentorHP,a.studentHP,s.machineHP);e.controller:update(now)end
 if self.phase~='playing'then return false end
 self.magic:update()
 s.hp={self.mentorHP,a.studentHP};s:update(math.min(dt,1),{self.mentor.x,a.student.x},nil,{x=self.objective.x,radius=360});self.mentorHP=s.hp[1];a.studentHP=s.hp[2]
 for i,p in ipairs(self.goldPickups)do
  if not p.taken and math.abs(self.objective.x-p.x)<65 then
   local before=s.gold;if s:collect('final-gold-'..i,15,p.x,self.objective.x,self.objective.x)then p.taken=true;p.node.visible=false;p.label.visible=false;self.collectedGold=self.collectedGold+math.min(15,90-before) end
  end
 end
 local target=self:target(a.student)
 if target then self.followAnimation=nil;a.enemy=target.enemy;a.enemyHP=target.enemyHP;a.enemyPhase=target.enemyPhase;a:update()
 elseif not a:isAttacking()and not K.blocked(a.student)then
  local delta=self.objective.x-a.student.x;a.student.faceRight=delta>=0;a.student.velocityX=math.abs(delta)>100 and (delta>0 and 140 or -140)or 0
  local desired=a.student.velocityX~=0 and 'fmove'or a.student.data.combatRest
  if self.arena.student.playable.current~=desired then a.student:stop();self.followAnimation=desired;A.play(a.student,desired,true)end
 end
 self.mentor.x=math.max(150,math.min(2194,self.mentor.x))
 local safe=true;local cleared=true
 for _,e in ipairs(self.enemies)do if e.enemyHP>0 and math.abs(e.enemy.x-self.objective.x)<250 then safe=false end;if not e.controller.dead then cleared=false end end
 local near=math.abs(self.mentor.x-self.objective.x)<340 and math.abs(a.student.x-self.objective.x)<440
 self.escortHint=not safe and '辅助机暂停：清除近处敌人。'or not near and '辅助机等待：请与妮妮莉特靠拢。'or'保护记录载体向右前进。'
 if safe and near and s.active and self.actor.completed.deploy and self.actor.completed.shield then
  local old=self.objective.x;self.objective.x=math.min(stops[self.stage],old+100*dt)
  self.escortDistance=self.escortDistance+self.objective.x-old;if self.objective.x>old then self.escortSeconds=self.escortSeconds+dt end
 end
 self.world.camera.zoom=.85;self.world.camera.position=D.Vec2(math.max(850,math.min(1590,self.mentor.x+180)),350)
 if self.mentorHP<=0 or a.studentHP<=0 then self:finish('failed','队伍失去战斗能力，撤离未完成。')
 elseif s.machineHP<=0 then self:finish('failed','辅助机被破坏，回收记录未能送出。')
 elseif now-self.started>240 then self:finish('failed','撤离窗口关闭，未能及时抵达终端。')
 elseif cleared and self.objective.x>=stops[self.stage]and not a:isAttacking()and not self.mentor:isDoing('groundMentorShot')then
  -- The last checkpoint also requires both actual characters at the exit.
  if self.stage==3 and (self.mentor.x<1900 or a.student.x<1900)then self.escortHint='记录已到达；请带妮妮莉特走到出口。';return false end
  local r={stage=self.stage,seconds=now-self.stageStarted,x=self.objective.x,hp=s.machineHP,guards={}}
  for _,e in ipairs(self.enemies)do
   local strikes={};for _,strike in ipairs(e.enemyAttacks)do local copy={};for k,v in pairs(strike)do if type(v)=='number'or type(v)=='string'or type(v)=='boolean'then copy[k]=v end end;strikes[#strikes+1]=copy end
   r.guards[#r.guards+1]={hp=e.enemyHP,strikes=strikes,loseStarted=e.controller.loseStarted,loseEnded=e.controller.loseEnded,loseDuration=e.controller.loseDuration};e.closed=true;e.enemy:removeFromParent()
  end
  self.completedStages[#self.completedStages+1]=r
  if self.stage==3 then self:finish('won','妮妮莉特与回收记录均已抵达撤离终端。')else self:spawnStage(self.stage+1)end
 end
 return false
end
function Battle.createAsync(models,variant,attempt)
 assert(models and models.ninilite,'Adopted Nini model required');assert(variant=='defence'or variant=='cargo'or variant=='mobility','Confirmed auxiliary variant required')
 local self=setmetatable({noTacticsColumns=true,phase='loading',stage=0,stageName='撤离准备',mentorHP=100,mentorHits=0,nextMentorShot=0,medicineUses=0,enemies={},completedStages={},escortDistance=0,escortSeconds=0,collectedGold=0,coverBlocks=0,coverEvents={},covers={1080,1730}},Battle)
 self.permanentMedicine=require('Story.Supplies').count('mentor','first-aid-water')or 0
 self.emergencyGranted=self.permanentMedicine<1 and 1 or 0;self.emergencyRemaining=self.emergencyGranted;self.emergencyUsed=0;self.medicineRemaining=self.permanentMedicine+self.emergencyRemaining
 local a=require('Training.Arena').createAsync({scene='PassageA',manualUpdate=true,origin=280,minX=150,maxX=2194,actionPrefix='finalNi_'})
 if attempt and attempt.supplyAttempt then self.supplies=assert(require('Economy.CombatSession').open(attempt.supplyAttempt));a.supplies=self.supplies end
 self.arena=a;self.world=a.world;require('Story.AcademyLoss').damageWorld(self.world)
 D.Platformer.Data:setRelation(1,3,'Neutral');D.Platformer.Data:setRelation(2,3,'Neutral');D.Platformer.Data:setShouldContact(1,3,false);D.Platformer.Data:setShouldContact(2,3,false)
 assert(a:beginTrial(400,models.ninilite));a.externalRound=true;a.externalCombat=true;a.mode='review';a.enemy.visible=false;a.enemy.group=3
 a.damageOpponent=function(u,n)return self:damage(u,n)end
 self.mentorTarget=function()local e=self:target(self.mentor);return e and e.enemy end;self.damageMentorTarget=function(u,n)return self:damage(u,n*3)end
 require('Ground.Mentor').createAsync(self,require('Data.Config').char);self.mentor.position=D.Vec2(450,self.world.offset+155)
 self.support=require('Ground.LifeSupport').new(45,variant);self.support.x=350;self.support.active=true
 D.Platformer.Data:setRelation(2,4,'Enemy');D.Platformer.Data:setRelation(1,4,'Neutral');D.Platformer.Data:setShouldContact(1,4,false);D.Platformer.Data:setShouldContact(2,4,false);D.Platformer.Data:setShouldContact(4,D.Platformer.Data.groupTerrain,true)
 self.objective=a.spawnUnit('ninilite',4,350,{});self.objective.playable.visible=false
 -- Kinematic hover carrier retains a collision target; party bodies do not push it.
 D.Cache:loadAsync('Image/Auxiliary/'..variant..'.model');self.actor=require('Ground.AuxiliaryActor').create(variant);self.actor.touch.touchEnabled=false
 self.holder=D.Node();self.holder.scaleX=.5;self.holder.scaleY=.5;self.holder.order=-1;self.holder:addTo(self.world);self.actor.node:addTo(self.holder)
 local function label(text,x,y)local l=D.Label('SourceHanSansCN-Regular',22,true);l.outlineWidth=.16;l.outlineColor=D.Color(0xff101b28);l.text=text;l.position=D.Vec2(x,y);l:addTo(self.world);return l end
 self.machineLabel=label('',350,self.world.offset+350);self.ring=D.DrawNode();self.ring.order=-2;self.ring:addTo(self.world)
 self.goldPickups={}
 for i,x in ipairs({950,1590})do
  local node=D.DrawNode();node.position=D.Vec2(x,self.world.offset+28);node:drawPolygon({D.Vec2(-20,0),D.Vec2(0,25),D.Vec2(20,0),D.Vec2(0,-12)},D.Color(0xffd5b764));node:addTo(self.world)
  self.goldPickups[i]={x=x,node=node,label=label('金粉 +15',x,self.world.offset+90)}
 end
 for _,x in ipairs(self.covers)do
  local n=D.DrawNode();n.order=-3;n.position=D.Vec2(x,self.world.offset);n:addTo(self.world)
  n:drawPolygon({D.Vec2(-25,0),D.Vec2(25,0),D.Vec2(25,280),D.Vec2(-25,245)},D.Color(0xff617681),3,D.Color(0xffb7c3c7))
  for y=45,220,55 do n:drawSegment(D.Vec2(-20,y),D.Vec2(20,y-15),3,D.Color(0xff364652))end
  label('掩护板',x,self.world.offset+325)
 end
 label('撤离终端',2090,self.world.offset+450)
 self.magic=require('Ground.WindFire').new(self);self.world.finalBattle=self;self.phase='ready'
 self.world.camera.zoom=.85;self.world.camera.position=D.Vec2(850,350)
 local tick=D.Node();tick:addTo(self.world);tick:schedule(function(dt)return self:update(dt)end);return self
end
return Battle
