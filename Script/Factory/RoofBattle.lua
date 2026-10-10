-- Combat inside the existing rooftop: original player shot and adopted Nini executor.
local D=require('Dora');local A=require('CombatAnimation');local O=require('Factory.RoofOpponent');local Battle={};Battle.__index=Battle
function Battle:targets()
 return {{unit=self.mentor,hp=function()return self.mentorHP end,damage=function(n)self.mentorHP=math.max(0,self.mentorHP-n)end},
 {unit=self.arena.student,hp=function()return self.arena.studentHP end,damage=function(n)self.arena.studentHP=math.max(0,self.arena.studentHP-n)end}}
end
function Battle:damage(unit,n)
 if self.phase~='playing'or unit~=self.enemy.enemy then return 0 end
 local dealt=math.min(n,self.enemy.enemyHP);self.enemy.enemyHP=self.enemy.enemyHP-dealt;return dealt
end
function Battle:command(name)
 self.commands=self.commands or {};self.commands[name]=(self.commands[name]or 0)+1
 if self.phase~='playing'then return false,'NOT_PLAYING'end
 if name=='fire'then return self.magic:request('fire')end
 if name=='shoot'then if self.supplies then local ok,why=self.supplies:canSpend('mentor','kinetic');if not ok then return false,why end end;self.mentor.faceRight=self.enemy.enemy.x>=self.mentor.x;return self.mentor:start('groundMentorShot')end
 if name=='left'or name=='right'then if self.mentor:isDoing('groundMentorShot')then return false,'ACTION_BUSY'end;return require('Combat.Movement').command(self.mentor,name)end
 if name=='stop'then if self.mentor:isDoing('groundMentorMove')then self.mentor:stop();self.mentor.velocityX=0;A.rest(self.mentor)end;return true end
 return false,'UNKNOWN_COMMAND'
end
function Battle:start()
 if self.phase~='ready'then return false end
 self.phase='playing';self.started=D.App.runningTime;self.arena.mode='trial';self.arena.nextDecision=self.started+.2;self.opponent.nextAttack=self.started+.9;return true
end
function Battle:finish(status,reason)
 if self.phase~='playing'and self.phase~='ready'then return false end
 self.phase='settling';self.reason=reason;self.arena.mode='review';self.mentor.velocityX=0;self.arena.student.velocityX=0;self.enemy.enemy.velocityX=0
 D.thread(function()
  local deadline=D.App.runningTime+12
  -- The engine swallows thread errors; degrade to forced settlement instead of
  -- a silent deadlock. unit:stop() below recovers stuck actions.
  while self.mentor:isDoing('groundMentorShot')or self.arena:isAttacking()or self.opponent.busy do
   if D.App.runningTime>=deadline then print('RoofBattle: action did not finish, settling anyway')break end
   D.sleep(.02)
  end
  for _,t in ipairs(self:targets())do t.unit:stop();t.unit.velocityX=0;if t.hp()<=0 then A.playOnceAsync(t.unit,'lose')else A.rest(t.unit)end end
  -- Input cleanup can issue rejected stop commands after persistence. Keep
  -- the settled report independent of the live counters used by the controller.
  local commands
  if self.commands then commands={};for name,count in pairs(self.commands)do commands[name]=count end end
  self.report={encounter='roof-wuyun',commands=commands,status=status,reason=reason,seconds=self.started and D.App.runningTime-self.started or 0,mentorHP=self.mentorHP,mentorHits=self.mentorHits,fireHits=self.magic.fireHits,enemyHP=self.enemy.enemyHP,learner={hp=self.arena.studentHP,samples=self.arena.trialModel.sampleCount,training=require("Training.Summary").record(self.arena.trialModel),modelActions=self.arena.metrics.modelActions,hits=self.arena.metrics.hits,fallback=self.arena.metrics.fallback},opponent={strikes=self.opponent.strikes,loseStarted=self.opponent.loseStarted,loseEnded=self.opponent.loseEnded,loseDuration=self.opponent.loseDuration}}
  self.phase=status;self.settled=true
 end);return true
end
function Battle:update()
 self.opponent:update(D.App.runningTime)
 if self.opponent.dead then self.roof.beacon.mark.visible=false end
 if self.phase=='playing'then
  self.magic:update();self.arena.enemyHP=self.enemy.enemyHP;self.arena.enemyPhase=self.opponent.busy and 'attack'or 'idle';self.arena:update()
  if self.mentorHP<=0 or self.arena.studentHP<=0 then self:finish('failed','队伍失去战斗能力，请重新准备。')
  elseif D.App.runningTime-self.started>120 then self:finish('failed','未能及时阻止乌云，重新调整战术。')
  elseif self.enemy.enemyHP<=0 and self.opponent.dead then self:finish('won','乌云暂时停下了攻势。')end
 end
 self.mentor.x=math.max(1500,math.min(3600,self.mentor.x))
 self.world.camera.position=D.Vec2(math.max(2300,math.min(2850,(self.mentor.x+self.enemy.enemy.x)/2)),1320);return false
end
function Battle.createAsync(c,model)
 assert(c.stage==2 and c.confrontationComplete and c.phase=='ready','Roof confrontation must be complete')
 assert(model and model.characterId=='ninilite'and require('Training.Model').validate(model,'ninilite'),'Adopted Nini model required')
 local self=setmetatable({phase='loading',world=c.world,roof=c,mentorHP=100,mentorHits=0,nextMentorShot=0},Battle)
 c.phase='battle';c.held={};c.dome.front.opacity=.18;c.hud:removeFromParent();c.ui.visible=false
 for _,a in ipairs(c.actors)do a.model.visible=false end;c.wuyun.visible=false;c.beacon:dispose()
 local world=c.world;world.offset=require('Factory.RoofGeometry').top
 world.addShadowTo=function(w,u)local s=assert(D.Sprite('Image/shadow.png'));s.order=-1;s:addTo(u);s:schedule(function()s.y=w.offset-u.y;return false end);return s end
 D.Platformer.Data:setRelation(1,2,'Enemy');D.Platformer.Data:setRelation(1,3,'Neutral')
 for _,group in ipairs({1,2,3})do D.Platformer.Data:setShouldContact(group,D.Platformer.Data.groupTerrain,true)end
 D.Platformer.Data:setShouldContact(1,2,false);D.Platformer.Data:setShouldContact(1,3,false);D.Platformer.Data:setShouldContact(2,3,false)
 local ni=require('Training.Arena').createAsync({world=world,manualUpdate=true,actionPrefix='roofNi_',origin=2310,minX=1500,maxX=3600,enemyFactory=O.createAsync,enemyAsset='wuyun',enemyMaxHP=360})
 self.arena=ni;ni:beginTrial(850,model);ni.externalCombat=true;ni.externalRound=true;ni.mode='review';self.projectiles=ni.projectiles
 self.enemy={enemy=ni.enemy,enemyHP=360};self.enemies={self.enemy};self.opponent=O.new(self,self.enemy)
 ni.damageOpponent=function(u,n)return self:damage(u,n)end
 self.mentorTarget=function()return self.enemy.enemy end;self.damageMentorTarget=function(u,n)return self:damage(u,n*3)end
 require('Ground.Mentor').createAsync(self,require('Data.Config').char);self.mentor.position=D.Vec2(2490,world.offset+155);self.mentor.order=20;ni.student.order=20
 self.magic=require('Ground.WindFire').new(self);c.beacon=require('Factory.RoofBeacon').attach(world,ni.enemy.playable);c.beacon:activate()
 local tick=D.Node();tick:addTo(world);tick:schedule(function()return self:update()end);self.tick=tick;world.roofBattle=self;self.phase='ready';return self
end
return Battle
