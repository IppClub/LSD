-- 2-15 first patrol: real adopted learners, authored fire/wind, physical rifle fire.
local D=require('Dora');local K=require('Combat.Displacement');local A=require('CombatAnimation');local Guard=require('Factory.PatrolGuard');local Battle={};Battle.__index=Battle
local function constrain(u,minX,maxX)
 local x,vx=u.x,u.velocityX
 if x<minX or x>maxX then
  u.x=math.max(minX,math.min(maxX,x))
  if (x<minX and vx<0)or(x>maxX and vx>0)then u.velocityX=0 end
 end
end
function Battle:targets()
 -- Attack phases iterate these adapters every frame; cache per battle and
 -- refresh the unit fields in place instead of rebuilding tables and closures.
 if not self._targets then
  self._targets={
   {hp=function()return self.mentorHP end,damage=function(n)self.mentorHP=math.max(0,self.mentorHP-n)end},
   {hp=function()return self.arena.studentHP end,damage=function(n)self.arena.studentHP=math.max(0,self.arena.studentHP-n)end}}
  self._targetsWuyun={hp=function()return self.wuyun.studentHP end,damage=function(n)self.wuyun.studentHP=math.max(0,self.wuyun.studentHP-n)end}
 end
 local targets=self._targets
 targets[1].unit=self.mentor;targets[2].unit=self.arena.student
 if self.wuyun then
  targets[3]=self._targetsWuyun;targets[3].unit=self.wuyun.student
 elseif targets[3]then targets[3]=nil end
 return targets
end
function Battle:learnersAttacking()
 for _,a in ipairs(self.learners)do if a:isAttacking()then return true end end
 return false
end
function Battle:partyDefeated()
 for _,a in ipairs(self.learners)do if a.studentHP<=0 then return true end end
 return self.mentorHP<=0
end
function Battle:defeatReason()
 local fallen={}
 if self.mentorHP<=0 then fallen[#fallen+1]='导师' end
 for _,a in ipairs(self.learners)do
  if a.studentHP<=0 then fallen[#fallen+1]=a.character.name end
 end
 return #fallen>0 and table.concat(fallen,'、')..'倒下，行动中止。'or nil
end
function Battle:target(unit)
 local selected,distance
 for _,e in ipairs(self.enemies) do if e.enemyHP>0 and (not distance or math.abs(e.enemy.x-unit.x)<distance) then selected=e;distance=math.abs(e.enemy.x-unit.x) end end
 return selected
end
function Battle:damage(target,n)
 if self.phase~='playing' then return 0 end
 for _,e in ipairs(self.enemies) do if e.enemy==target and e.enemyHP>0 then local dealt=math.min(n,e.enemyHP);e.enemyHP=e.enemyHP-dealt;return dealt end end
 return 0
end
function Battle:command(name)
 if self.phase~='playing' then return false,'NOT_PLAYING' end
 if name=='fire' or name=='wind' then return self.magic:request(name) end
 if name=='shoot' then if self.mentor.data.weaponDisarmed then return false,'WEAPON_DISARMED'end;if self.supplies then local ok,why=self.supplies:canSpend('mentor','kinetic');if not ok then return false,why end end;local e=self:target(self.mentor);if not e then return false,'NO_TARGET' end;self.mentor.faceRight=e.enemy.x>=self.mentor.x;return self.mentor:start('groundMentorShot') end
 if name=='left' or name=='right' then if self.mentor:isDoing('groundMentorShot') then return false,'ACTION_BUSY' end;return require('Combat.Movement').command(self.mentor,name) end
 if name=='stop' then if self.mentor:isDoing('groundMentorMove') then self.mentor:stop();self.mentor.velocityX=0;A.rest(self.mentor) end;return true end
 return false,'UNKNOWN_COMMAND'
end
function Battle:start()
 if self.phase~='ready' then return false end
 self.phase='playing';self.started=D.App.runningTime
 for _,a in ipairs(self.learners) do a.mode='trial';a.roundStarted=self.started;a.nextDecision=self.started+.2 end
 for i,e in ipairs(self.enemies) do e.guard.nextAttack=self.started+i*.6 end
 return true
end
function Battle:finish(status,reason)
 if self.phase~='playing' and self.phase~='ready' then return false end
 self.phase='settling';self.pendingStatus=status;self.reason=reason
 if not K.blocked(self.mentor)then self.mentor.velocityX=0 end
 for _,a in ipairs(self.learners)do a.mode='review';if not K.blocked(a.student)then a.student.velocityX=0 end end
 -- Do not interrupt a finite native shot/cast; its own completion restores prepare.
 self.report={encounter=self.scenario.id or 'first-patrol',status=status,reason=reason,mentorHP=self.mentorHP,mentorHits=self.mentorHits,fireHits=self.magic.fireHits,windHits=self.magic.windHits,synergyHits=self.magic.synergyHits,seconds=self.started and D.App.runningTime-self.started or 0,learners={},guards={}}
 for _,a in ipairs(self.learners) do self.report.learners[a.character.id]={hp=a.studentHP,samples=a.trialModel.sampleCount,training=require("Training.Summary").record(a.trialModel),hits=a.metrics.hits,modelActions=a.metrics.modelActions,fallback=a.metrics.fallback} end
 -- The commander's history also contains retired summons, which are no
 -- longer in enemies. Keep it in the saved report for contact attribution.
 for _,e in ipairs(self.enemies) do self.report.guards[#self.report.guards+1]={alerted=e.guard.alerted,approachTravel=e.guard.approachTravel,strikes=e.guard.strikes,summons=e.guard.hunt and e.guard.hunt.history or nil,loseStarted=e.guard.loseStarted,loseEnded=e.guard.loseEnded,reactions=e.guard.hits,capturedAt=e.guard.capturedAt,escaped=e.guard.escaped} end
 D.thread(function()
  local deadline=D.App.runningTime+10
  local function pendingActions()
   local displaced=false
   for _,t in ipairs(self:targets())do if not t.immovable and K.blocked(t.unit)then
    displaced=true
    -- Keep the ordinary arena bounds while learner updates are suspended.
    constrain(t.unit,self.minX,self.maxX)
   end end
   return displaced or self.mentor:isDoing('groundMentorShot')or self:learnersAttacking()
  end
  -- The engine swallows thread errors, so a watchdog assert here would deadlock
  -- the settlement silently. Log and settle anyway; unit:stop() below recovers.
  while pendingActions()do
   if D.App.runningTime>=deadline then print('PatrolBattle: character action/recovery did not finish, settling anyway')break end
   D.sleep(.01)
  end
  for _,t in ipairs(self:targets()) do if not t.immovable then t.unit:stop();t.unit.velocityX=0;if t.hp()<=0 then A.playOnceAsync(t.unit,'lose') else A.rest(t.unit) end end end
  self.phase=status;self.settled=true
 end)
 return true
end
function Battle:update()
 local now=D.App.runningTime
 for _,e in ipairs(self.enemies) do if not e.summonOwner then e.guard:update(now) end end
 if self.phase~='playing' then return false end
 self.magic:update()
 for _,a in ipairs(self.learners) do local e=self:target(a.student);if e then a.enemy=e.enemy;a.enemyHP=e.enemyHP;a.enemyPhase=e.guard.busy and 'attack' or 'idle';a:update() elseif a.updateWithoutVisibleTarget and a:updateWithoutVisibleTarget()then elseif not a:isAttacking() then a.student:stop();a.student.velocityX=0;A.rest(a.student) end end
 local alive=false;local complete=true
 for _,e in ipairs(self.enemies) do if e.enemyHP>0 then alive=true end;if not e.guard.dead then complete=false end end
 -- An arrived recovery order can suspend Arena:update while a hit launches
 -- its learner. Keep the arena bounds independent of AI/gather/action state.
 -- Retain vertical launch and complete authored hit/fall/standUp recovery.
 constrain(self.mentor,self.minX,self.maxX)
 for _,a in ipairs(self.learners)do constrain(a.student,self.minX,self.maxX)end
 if not self.cameraFrame then self.world.camera.zoom=.9;self.world.camera.position=D.Vec2(math.max(self.cameraMinX,math.min(self.cameraMaxX,(self.controlledUnit or self.mentor).x+350)),360)end
 if self:partyDefeated() then self:finish('failed',self:defeatReason())
 elseif self.scenario.failed and self.scenario.failed(self) then self:finish('failed',self.scenario.failureReason)
 elseif now-self.started>(self.scenario.timeLimit or 90) then self:finish('failed',self.scenario.timeoutReason or '巡逻队封锁了路线，重新准备行动。')
 elseif not alive and complete and not self:learnersAttacking() and not self.mentor:isDoing('groundMentorShot') then
  if self.scenario.victory then
   local ok,reason=self.scenario.victory(self);self:finish(ok and 'won' or 'failed',reason)
  elseif self.mentorHits>0 and self.magic.fireHits>0 and self.magic.windHits>0 then self:finish('won','首波守卫已制服；继续跟随狐狸潜入。') else self:finish('failed','本次尚未完成导师射击、火焰与旋风协同。') end
 end
 return false
end
function Battle.createAsync(models,scenario)
 scenario=scenario or {}
 assert(models and models.ninilite and (scenario.leaveWuyun or models.wuyun),'Participating adopted models required')
 local arena=scenario.arena or {}
 local minX,maxX=arena.minX or 1200,arena.maxX or 3300
 assert(minX<maxX,'Invalid battle arena')
 local self=setmetatable({minX=minX,maxX=maxX,cameraMinX=arena.cameraMinX or 1950,cameraMaxX=arena.cameraMaxX or 2500,phase='loading',mentorHP=100,mentorHits=0,nextMentorShot=0,enemies={},scenario=scenario},Battle)
 D.Cache:unload(Guard.path);D.Cache:unload('Image/Factory/patrol-guard.clip')
 local Arena=require('Training.Arena')
 local enemyFactory=scenario.enemyFactory or Guard.create
 local enemyHP=scenario.enemyHP or 240
 local firstEnemy
 local function sharedEnemy(world,x)
  if scenario.singleEnemy and firstEnemy then return firstEnemy end
  local unit=enemyFactory(world,x);firstEnemy=firstEnemy or unit;return unit
 end
 local ni=Arena.createAsync({scene=scenario.scene or 'Factory',manualUpdate=true,origin=arena.niniliteX or 1700,minX=minX,maxX=maxX,actionPrefix='patrolNi_',enemyAsset=scenario.enemyAsset or 'patrol-guard',enemyFactory=sharedEnemy,enemyMaxHP=enemyHP})
 local wu
 if not scenario.leaveWuyun then wu=Arena.createAsync({world=ni.world,manualUpdate=true,characterId='wuyun',origin=arena.wuyunX or 1850,minX=minX,maxX=maxX,actionPrefix='patrolWu_',enemyAsset=scenario.enemyAsset or 'patrol-guard',enemyFactory=sharedEnemy,enemyMaxHP=enemyHP})end
 D.Platformer.Data:setRelation(1,3,'Neutral');D.Platformer.Data:setShouldContact(1,3,false);D.Platformer.Data:setShouldContact(2,3,false);D.Platformer.Data:setShouldContact(3,D.Platformer.Data.groupTerrain,true)
 self.arena=ni;self.wuyun=wu;self.learners=wu and {ni,wu} or {ni};self.world=ni.world;self.projectiles=ni.projectiles
 ni:beginTrial(500,models.ninilite);if wu then wu:beginTrial(690,models.wuyun)end
 for _,a in ipairs(self.learners) do a.externalCombat=true;a.externalRound=true;a.mode='review';a.damageOpponent=function(unit,n)return self:damage(unit,n)end end
 self.enemies={{enemy=ni.enemy,enemyHP=enemyHP}}
 if not scenario.singleEnemy then
  self.enemies[2]={enemy=wu and wu.enemy or enemyFactory(self.world,2640),enemyHP=enemyHP};self.enemies[3]={enemy=enemyFactory(self.world,2850),enemyHP=enemyHP}
 else ni.enemy.x=scenario.enemyX or 2500 end
 for _,e in ipairs(self.enemies) do e.guard=(scenario.controller or Guard).new(self,e) end
 self.mentorTarget=function()local e=self:target(self.mentor);return e and e.enemy end;self.damageMentorTarget=function(unit,n)return self:damage(unit,n*3)end
 require('Ground.Mentor').createAsync(self,require('Data.Config').char);self.mentor.position=D.Vec2(arena.mentorX or 1900,self.world.offset+155)
 self.magic=require('Ground.WindFire').new(self);self.world.patrolBattle=self;self.world.camera.zoom=.9;self.world.camera.position=D.Vec2(arena.cameraInitialX or 2250,360);self.phase='ready'
 self.world:schedule(function()return self:update()end)
 return self
end
return Battle
