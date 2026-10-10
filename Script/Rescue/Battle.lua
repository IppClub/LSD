local K=require('Combat.Displacement')
-- Two physical evacuation legs. Original twins walk beside their collision bodies;
-- only the authored enemy release events can damage them during normal play.
local D=require('Dora');local A=require('CombatAnimation');local Enemy=require('Academy.DefenseEnemy')
local Defense=require('Academy.DefenseBattle');local Battle={};Battle.__index=Battle
Battle.target=Defense.target;Battle.damage=Defense.damage;Battle.command=Defense.command;Battle.partyDamage=Defense.partyDamage
local stops={{4800,4960},{5400,5560}}
function Battle:damageTwin(twin,amount,strike)
 if self.phase~='playing'or twin.actor.hp<=0 then return 0 end
 local unshielded,absorbed=self.ward:protect(amount,twin.unit.x,twin.unit.y)
 local dealt=twin.actor:damage(unshielded)
 self.contacts[#self.contacts+1]={role=twin.actor.asset,x=twin.unit.x,y=twin.unit.y,amount=amount,absorbed=absorbed,dealt=dealt,stage=self.stage,kind=strike and strike.kind or 'unknown',at=D.App.runningTime}
 if dealt>0 then twin.hitAt=D.App.runningTime;twin.lastDamage=dealt end
 return dealt
end
function Battle:spawnStage(index)
 self.stage=index;self.stageStarted=D.App.runningTime;self.stageName=index==1 and '抵达临时安全点'or '穿过出口危险区';self.enemies={}
 for i,x in ipairs(index==1 and {4730,4980}or {5270,5500})do
  local u=self.arena.spawnUnit('xiaotaotie',2,x,{})
  local e={enemy=u,enemyHP=135,student=self.twins[i].unit,studentHP=100,world=self.world,metrics=self.arena.metrics,enemyPhase='idle',nextEnemy=D.App.runningTime+1+i*.5,minX=3700,maxX=5590,enemySpeed=65,projectiles=self.arena.projectiles,mode='trial'}
  e.enemyTargets=function()
   local targets={};for _,t in ipairs(self.twins)do if t.actor.hp>0 then targets[#targets+1]={unit=t.unit,immovable=true,damage=function(n,s)return self:damageTwin(t,n,s)end}end end
   targets[#targets+1]={unit=self.mentor,alive=function()return self.phase=='playing' and self.mentorHP>0 end,damage=function(n)return self:partyDamage('mentor',n)end}
   targets[#targets+1]={unit=self.arena.student,alive=function()return self.phase=='playing' and self.arena.studentHP>0 end,damage=function(n)return self:partyDamage('learner',n)end};return targets
  end
  e.controller=Enemy.new(e,i==1 and {'blow','butt','roll'}or {'bomb','swing','roll'});self.enemies[#self.enemies+1]=e
 end
end
function Battle:start()
 if self.phase~='ready'then return false end
 D.thread(function()self.jadeCarrier:mountAsync()end)
 self.phase='playing';self.started=D.App.runningTime;self.arena.mode='trial';self.arena.nextDecision=self.started+.2;self:spawnStage(1);return true
end
function Battle:finish(status,reason)
 if self.phase~='playing'and self.phase~='ready'then return false end
 K.clear(self.mentor);K.clear(self.arena.student)
 self.phase='settling';self.reason=reason;self.arena.mode='review';self.mentor.velocityX=0;self.arena.student.velocityX=0
 for _,t in ipairs(self.twins)do t.unit.velocityX=0 end
 for _,e in ipairs(self.enemies)do e.controller:stop()end
 D.thread(function()
  local deadline=D.App.runningTime+15
  while true do
   local busy=self.medicineBusy or self.mentor:isDoing('groundMentorShot')or self.arena:isAttacking()
   for _,e in ipairs(self.enemies)do busy=busy or e.enemyPhase=='attack'or e.controller.dying end
   for _,t in ipairs(self.twins)do busy=busy or t.actor:isReacting()end
   if not busy then break end
   -- The engine swallows thread errors; degrade to settlement instead of a silent deadlock.
   if D.App.runningTime>=deadline then print('RescueBattle: action did not finish, settling anyway')break end
   D.sleep(.02)
  end
  for _,t in ipairs({{self.mentor,self.mentorHP},{self.arena.student,self.arena.studentHP}})do t[1]:stop();t[1].velocityX=0;if t[2]<=0 then A.playOnceAsync(t[1],'lose')else A.rest(t[1])end end
  if self.jadeCarrier.active then
   while self.jadeCarrier.active do if not self.world.parent then return end;D.sleep()end
  end
  if self.jadeCarrier.phase=='riding' then self.jadeCarrier:landAsync()end
  self.ward:close()
  local twins={};for i,t in ipairs(self.twins)do twins[i]={role=t.actor.asset,hp=t.actor.hp,startX=t.startX,x=t.unit.x,distance=t.actor.distance,walkSeconds=t.walkSeconds,loops=t.actor.completed,reactions=t.actor.events}end
  self.report={encounter='twins-evacuation',status=status,reason=reason,stages=self.completedStages,twins=twins,contacts=self.contacts,ward={x=self.ward.x,y=self.ward.y,radius=self.ward.radius,capacity=self.ward.capacity,remaining=self.ward.remaining,absorbed=self.ward.absorbed,hits=self.ward.hits},mentorHP=self.mentorHP,mentorHits=self.mentorHits,fireHits=self.magic.fireHits,medicineUses=self.medicineUses,learner={hp=self.arena.studentHP,modelActions=self.arena.metrics.modelActions,hits=self.arena.metrics.hits,samples=self.arena.trialModel.sampleCount,training=require("Training.Summary").record(self.arena.trialModel)},seconds=self.started and D.App.runningTime-self.started or 0}
  self.report.carrier={phase=self.jadeCarrier.phase,x=self.jade.model.x,events=self.jadeCarrier.events,pulses=self.jadeWardPulses}
  self.phase=status
 end);return true
end
function Battle:update(dt)
 local now=D.App.runningTime
 self.healthHud.visible=self.phase=='ready'or self.phase=='playing'
 local playing=self.phase=='playing'
 local jadeVelocity=playing and self.jadeCarrier.phase=='riding' and self.jade.model.x<4650 and math.min(140,(4650-self.jade.model.x)/dt)or 0
 self.jade.model.x=self.jade.model.x+jadeVelocity*dt
 if playing and not self.ward.active and self.jade.model.x>=4649.9 then self.ward:open()end
 self.ward:update(dt)
 self.jadeCarrier:guard(self.ward.active and self.ward.remaining>0)
 if self.ward.hits>self.jadeWardHits then
  self.jadeWardPulses=self.jadeWardPulses+self.ward.hits-self.jadeWardHits;self.jadeCarrier.robot:emit('Pulse')
 end
 self.jadeWardHits=self.ward.hits
 for _,t in ipairs(self.twins)do
  -- Use measured body travel for animation; never move the skeleton independently.
  local dx=t.unit.x-t.actor.model.x;t.actor:update(dt>0 and dx/dt or 0,dt);t.actor.model.y=t.unit.y-150
  local hit=t.hitAt and now-t.hitAt<.45
  t.health.hp.scaleX=math.max(0,math.min(1,t.actor.hp/100))
  t.health.hp.color3=D.Color3(hit and 0xff8a8a or t.actor.hp<=25 and 0xff6b6b or 0x80d4b2)
  local text=(t.actor.asset=='vika'and '烛参'or'烛商')..'  '..math.ceil(t.actor.hp)..' / 100'..(hit and ('  -'..math.ceil(t.lastDamage))or t.actor.hp<=25 and '  危险'or '')
  if t.label.text~=text then t.label.text=text end
 end
 local wardText=self.ward.active and ('玉 · 保护场 '..math.ceil(self.ward.remaining)..' / '..self.ward.capacity..(self.ward.remaining<=0 and ' · 已耗尽'or ''))or'玉正在前往支撑点'
 if self.wardLabel.text~=wardText then self.wardLabel.text=wardText end
 self.wardHealth.node.visible=self.ward.active
 self.wardHealth.hp.scaleX=math.max(0,math.min(1,self.ward.remaining/self.ward.capacity))
 self.wardHealth.hp.color3=D.Color3(self.ward.remaining<=self.ward.capacity*.25 and 0xffd074 or 0x8dbef3)
 for i,e in ipairs(self.enemies)do e.student=self.twins[i].unit;e.studentHP=math.min(self.mentorHP,self.arena.studentHP,self.twins[i].actor.hp);e.controller:update(now)end
 if not playing then return false end
 self.magic:update();local target=self:target(self.arena.student)
 if target then self.followAnimation=nil;self.arena.enemy=target.enemy;self.arena.enemyHP=target.enemyHP;self.arena.enemyPhase=target.enemyPhase;self.arena:update()
 elseif not self.arena:isAttacking()and not K.blocked(self.arena.student)then
  local delta=self.twins[1].unit.x-self.arena.student.x;self.arena.student.faceRight=delta>=0
  self.arena.student.velocityX=math.abs(delta)>130 and (delta>0 and 140 or -140)or 0
  local desired=self.arena.student.velocityX~=0 and 'fmove'or self.arena.student.data.combatRest
  if self.arena.student.playable.current~=desired then self.arena.student:stop();self.followAnimation=desired;A.play(self.arena.student,desired,true)end
 end
 self.mentor.x=math.max(3700,math.min(5590,self.mentor.x))
 local arrived=true;local hint='双子正在前进，请保持在附近。'
 for i,t in ipairs(self.twins)do
  local safe=true;for _,e in ipairs(self.enemies)do if e.enemyHP>0 and math.abs(e.enemy.x-t.unit.x)<260 then safe=false end end
  local near=math.abs(self.mentor.x-t.unit.x)<440 and math.abs(self.arena.student.x-t.unit.x)<650
  local remaining=stops[self.stage][i]-t.unit.x
  if remaining>1 then
   arrived=false
   local room=i==1 and math.max(0,self.twins[2].unit.x-160-t.unit.x)or remaining
   if t.actor:blocksMovement()then t.unit.velocityX=0;hint='双子正在恢复，请保护她们。'
   elseif safe and near and room>.001 then t.unit.velocityX=math.min(85,remaining/dt,room/dt);t.walkSeconds=t.walkSeconds+dt
   else t.unit.velocityX=0;hint=not safe and '双子暂停：请先清除近处的敌人。'or '双子等待队伍：请靠近后共同向右前进。'end
  else
   -- Finish the sub-unit remainder so the front twin cannot reserve spacing
   -- that prevents the rear twin from reaching the same arrival tolerance.
   t.unit.velocityX=0;if not t.actor:blocksMovement()then t.unit.x=stops[self.stage][i]end
  end
 end
 self.escortHint=hint
 self.world.camera.zoom=.85;self.world.camera.position=D.Vec2(math.max(4300,math.min(4990,self.mentor.x+250)),350)
 if self.mentorHP<=0 or self.arena.studentHP<=0 then self:finish('failed','队伍失去战斗能力，双子尚未撤离。')
 elseif self.twins[1].actor.hp<=0 or self.twins[2].actor.hp<=0 then self:finish('failed','双子受到致命伤害，救援未完成。')
 elseif now-self.started>240 then self:finish('failed','未能及时穿过研究区。')
 elseif arrived and not self.arena:isAttacking()and not self.mentor:isDoing('groundMentorShot')then
  local cleared=true;for _,e in ipairs(self.enemies)do if not e.controller.dead then cleared=false end end
  if cleared then
   local record={stage=self.stage,seconds=now-self.stageStarted,positions={self.twins[1].unit.x,self.twins[2].unit.x},guards={}}
   for _,e in ipairs(self.enemies)do
    local strikes={};for _,s in ipairs(e.enemyAttacks)do local saved={};for k,v in pairs(s)do if type(v)=='number'or type(v)=='string'or type(v)=='boolean'then saved[k]=v end end;strikes[#strikes+1]=saved end
    record.guards[#record.guards+1]={hp=e.enemyHP,strikes=strikes,loseStarted=e.controller.loseStarted,loseEnded=e.controller.loseEnded,loseDuration=e.controller.loseDuration};e.closed=true;e.enemy:removeFromParent()
   end
   self.completedStages[#self.completedStages+1]=record
   if self.stage==2 then self:finish('won','双子均已穿过两段危险区，抵达研究区出口。')else self:spawnStage(2)end
  end
 end
 return false
end
function Battle.createAsync(models,attempt)
 assert(models and models.ninilite,'Adopted Nini model required')
 local self=setmetatable({noTacticsColumns=true,phase='loading',stage=0,stageName='研究区救援',mentorHP=100,mentorHits=0,nextMentorShot=0,medicineUses=0,enemies={},completedStages={},contacts={},twins={}},Battle)
 self.medicineRemaining=require('Story.Supplies').count('mentor','first-aid-water')or 0
 local a=require('Training.Arena').createAsync({scene='RDRoom',manualUpdate=true,origin=3800,minX=3700,maxX=5590,actionPrefix='rescueNi_'})
 if attempt and attempt.supplyAttempt then self.supplies=assert(require('Economy.CombatSession').open(attempt.supplyAttempt));a.supplies=self.supplies end
 self.arena=a;self.world=a.world;require('Story.AcademyLoss').damageWorld(self.world)
 D.Platformer.Data:setRelation(1,3,'Neutral');D.Platformer.Data:setRelation(2,3,'Neutral');D.Platformer.Data:setShouldContact(1,3,false);D.Platformer.Data:setShouldContact(2,3,false)
 assert(a:beginTrial(400,models.ninilite));a.externalRound=true;a.externalCombat=true;a.mode='review';a.enemy.visible=false;a.enemy.group=3
 a.damageOpponent=function(u,n)return self:damage(u,n)end
 self.mentorTarget=function()local e=self:target(self.mentor);return e and e.enemy end;self.damageMentorTarget=function(u,n)return self:damage(u,n*3)end
 require('Ground.Mentor').createAsync(self,require('Data.Config').char);self.mentor.position=D.Vec2(3950,self.world.offset+155)
 local Actor=require('Rescue.Actor');Actor.loadAsync()
 self.jadeCarrier=require('Rescue.BuddhaCarrier').new(self.world,3920,self.world.offset,'Spine/StoryActions/yu-riding.json|Spine/yu.atlas',require('Rescue.BuddhaChibiStyle'))
 self.jade={model=self.jadeCarrier.node};self.jadeWardHits=0;self.jadeWardPulses=0
 self.ward=require('Rescue.Ward').new(self.world,4700,self.world.offset+150,440,160)
 -- Keep escort health clear of the tall carrier and overlapping world actors.
 local hud=D.Node();hud.order=20;hud:addTo(D.Director.ui3D);self.healthHud=hud
 self.world:slot('Cleanup',function()if hud.parent then hud:removeFromParent()end end)
 local cards={}
 local function healthCard()
  local holder=D.Node();holder:addTo(hud);cards[#cards+1]=holder
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2(-78,-40),D.Vec2(78,-40),D.Vec2(78,40),D.Vec2(-78,40)},D.Color(0xee101b28));bg:addTo(holder)
  local l=D.Label('SourceHanSansCN-Regular',18,true);l.outlineWidth=.16;l.outlineColor=D.Color(0xff101b28);l.textWidth=146;l.alignment='Center';l.position=D.Vec2(0,12);l:addTo(holder)
  local node,hp,ap=require('UI.View.StatusBar').default(1,0,0x80d4b2,false)
  if ap then ap.visible=false end;node.position=D.Vec2(0,-30);node.scaleX=1.3;node:addTo(holder)
  return l,{node=node,hp=hp,ap=ap}
 end
 self.wardLabel,self.wardHealth=healthCard()
 for i,asset in ipairs({'vika','vivi'})do
  local x=i==1 and 4150 or 4350;local unit=a.spawnUnit(asset,1,x,{});unit.playable.visible=false
  local name,health=healthCard()
  self.twins[i]={unit=unit,actor=Actor.new(asset,self.world,x,self.world.offset+5),startX=x,walkSeconds=0,label=name,health=health}
 end
 local function layoutHealth()
  local size=D.App.bufferSize;local scale=math.min(1,size.width/1366)
  hud.size=size
  for i,card in ipairs(cards)do
   card.scaleX=scale;card.scaleY=scale
   card.position=D.Vec2(size.width-24-((#cards-i)*166+78)*scale,size.height-155*scale)
  end
 end
 layoutHealth();hud:gslot('AppChange',function(name)if name=='Size'then layoutHealth()end end)
 self.magic=require('Ground.WindFire').new(self);self.world.rescueBattle=self;self.phase='ready'
 self.world.camera.zoom=.85;self.world.camera.position=D.Vec2(4300,350)
 local tick=D.Node();tick:addTo(self.world);tick:schedule(function(dt)return self:update(dt)end);return self
end
return Battle
