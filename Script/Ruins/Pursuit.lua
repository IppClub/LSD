-- Original 2-11: physical escort and diversion, not a kill-all substitute.
local D=require('Dora');local P=D.Platformer;local A=require('CombatAnimation')
local Sequence=require('Enemy.Sequence')
local Battle={};Battle.__index=Battle
Battle.startX=7100;Battle.escapeX=11200;Battle.safeX=5100
local specs={
 dashanxiao={{name='throw',at={1.33333},projectile=true,damage=14,prop=true},{name='slum',at={.63333,1.4,2.26667},range=300,damage=8,stamina=35,area=true},{name='punch',at={1.5,2.16667,2.9},range=240,damage=8,stamina=35},{name='ambush',ambush=true,range=260,damage=18,stamina=50}},
 xiaoshanxiao={{name='throw',at={1.13333},projectile=true,damage=9},{name='scratch',at={.60,1.15},range=195,damage=5},{name='rush',at={},range=185,damage=12,rush=true},{name='litter',at={1.0,1.2},projectile=true,damage=7},{name='evade',at={},evade=true}}
}
Battle.attackSpecs=specs
function Battle:command(command)
 if self.phase~='playing' then return false,'NOT_PLAYING' end
 if self.stamina and self.stamina.down then return false,'KNOCKED_DOWN'end
 if command=='left' or command=='right' then
  if self.mentor:isDoing('groundMentorShot') or self.mentor:isDoing('pursuitTool') then return false,'ACTION_BUSY' end
  return require('Combat.Movement').command(self.mentor,command)
 elseif command=='idle' then
  if self.mentor:isDoing('groundMentorMove') then self.mentor:stop();self.mentor.velocityX=0;A.rest(self.mentor) end;return true
 elseif command=='shoot' then
  if self.supplies and not self.supplies:canSpend('mentor','kinetic')then return false,'NO_AMMO'end
  if self.mentor:isDoing('pursuitTool') then return false,'ACTION_BUSY' end
  return self.mentor:start('groundMentorShot')
 elseif command=='smoke' or command=='flare' then
  if self.supplies and not self.supplies:canSpend('mentor',command)then return false,'NO_SUPPLIES'end
  if self.mentor:isDoing('groundMentorShot') or self.mentor:isDoing('pursuitTool') then return false,'ACTION_BUSY' end
  if D.App.runningTime<(self.toolReady[command] or 0) then return false,'COOLDOWN' end
  self.pendingTool=command;return self.mentor:start('pursuitTool')
 elseif command=='medicine' then
  if self.mentorHP<=0 then return false,'NOT_ALIVE'end
  if self.medicineBusy or self.mentorHP>=100 then return false,'NOT_NEEDED' end
  self.medicineBusy=true
  D.thread(function()
   -- The engine swallows thread errors; always release medicineBusy so settlement can proceed.
   local ok,r,e=xpcall(function() return require('Story.Supplies').consumeAsync('mentor','first-aid-water') end,debug.traceback)
   if ok and r then
    self.medicineUses=self.medicineUses+1
    if self.phase=='playing' and self.mentorHP>0 then self.mentorHP=math.min(100,self.mentorHP+25)end
   end
   self.medicineBusy=false;self.message=ok and r and '已经使用应急治疗水。' or '药品未使用：'..tostring(ok and e or r)
  end);return true
 end
 return false,'UNKNOWN_COMMAND'
end
function Battle:inSmoke(x)
 local now=D.App.runningTime
 for _,cloud in ipairs(self.smoke) do if now<cloud.ends and math.abs(x-cloud.x)<=cloud.radius then return true end end
 return false
end
function Battle:lineObscured(x1,x2)
 for _,cloud in ipairs(self.smoke) do if D.App.runningTime<cloud.ends and cloud.x+cloud.radius>math.min(x1,x2) and cloud.x-cloud.radius<math.max(x1,x2) then return true end end
 return false
end
function Battle:tool(kind)
 if self.supplies then local ok,why=self.supplies:emit('mentor',kind,1,'mentor');if not ok then self.message='道具未生效：'..tostring(why);return false end end
 local now=D.App.runningTime;local x=self.mentor.x
 self.toolUses[kind]=self.toolUses[kind]+1;self.toolReady[kind]=now+(kind=='smoke' and 6 or 5)
 if kind=='smoke' then self.smoke[#self.smoke+1]={x=x-80,radius=270,started=now,ends=now+4.5};return true end
 -- A real thrown flare body collides with pursuers before its effect is applied.
 local def=P.BulletDef();def.lifeTime=1.8;def.highSpeedFix=true;def.gravity=D.Vec2(0,-2)
 def:setAsCircle(18);def:setVelocity(0,700)
 def.face=P.Face(function() local n=D.DrawNode();n:drawDot(D.Vec2.zero,13,D.Color(0xffffd074));return n end)
 local bullet=P.Bullet(def,self.mentor);local allow=P.TargetAllow();allow:allow('Enemy',true);allow.terrainAllowed=true;bullet.targetAllow=allow:toValue()
 bullet.position=self.mentor.position+D.Vec2(self.mentor.faceRight and 60 or -60,15)
 bullet:slot('HitTarget',function(projectile,target)
  if self.phase=='playing' then for _,e in ipairs(self.enemies) do if e.unit==target and e.hp>0 then e.stunUntil=D.App.runningTime+2.5;self.flareHits=self.flareHits+1;self.flashes[#self.flashes+1]={x=target.x,started=D.App.runningTime,ends=D.App.runningTime+.6};break end end end
  projectile.hitStop=true
 end)
 bullet:addTo(self.world);self.projectiles[#self.projectiles+1]=bullet
 return true
end
function Battle:enemyProjectile(e,spec,strike)
 if spec.prop then
  local item=strike.prop
  local origin=require('Enemy.BigShanRelease').point(e.unit,self.world)
  self.props:carry(item,origin)
  strike.release={x=origin.x,y=origin.y,faceRight=e.unit.faceRight}
  local bullet=self.props:throw(item,origin,self.mentor.position,function(target,direction)
   if self.phase~='playing' then return end
   if self:damageFriendly(target,spec.damage,spec.stamina)then strike.hits=strike.hits+1 end
   target:stop();target.velocityX=direction*460;target.velocityY=280
  end)
  if bullet then self.projectiles[#self.projectiles+1]=bullet;strike.propReleased=D.App.runningTime end
  return
 end
 local origin=e.unit.position+D.Vec2(e.unit.faceRight and 70 or -70,10)
 local angle,hand=0,nil;local speed,gravity,flight=850,0,nil
 if e.asset=='xiaoshanxiao' then
  origin,hand=require('Enemy.ShanRelease').point(e.unit,self.world,spec.name,#strike.impacts)
  local arc=require('Enemy.ThrowArc').solve(origin,self.mentor.position)
  angle=math.deg(math.atan(arc.vy,arc.vx*(e.unit.faceRight and 1 or -1)))
  speed=math.sqrt(arc.vx*arc.vx+arc.vy*arc.vy);gravity=-arc.gravity/D.PhysicsWorld.scaleFactor;flight=arc.time
 end
 strike.releases=strike.releases or {};strike.releases[#strike.releases+1]={x=origin.x,y=origin.y,hand=hand,angle=angle,flight=flight,targetX=self.mentor.x,targetY=self.mentor.y}
 local def=P.BulletDef();def.lifeTime=3;def.highSpeedFix=true;def.gravity=D.Vec2(0,gravity);def:setAsCircle(13);def:setVelocity(angle,speed)
 def.face=P.Face(function() local n=D.DrawNode();n:drawPolygon({D.Vec2(-14,0),D.Vec2(0,12),D.Vec2(14,0),D.Vec2(0,-12)},D.Color(0xffbc9d83));return n end)
 local bullet=P.Bullet(def,e.unit);local allow=P.TargetAllow();allow:allow('Enemy',true);allow.terrainAllowed=true;bullet.targetAllow=allow:toValue()
 bullet.position=origin
 bullet:slot('HitTarget',function(p,target)
  if target and self.phase=='playing' then
   if self:inSmoke(target.x) then self.smokeBlocks=self.smokeBlocks+1 elseif self:damageFriendly(target,spec.damage,spec.stamina)then strike.hits=strike.hits+1 end
  end;p.hitStop=true
 end)
 bullet:addTo(self.world);self.projectiles[#self.projectiles+1]=bullet;self.hostileProjectiles[#self.hostileProjectiles+1]={bullet=bullet,strike=strike,release=strike.releases[#strike.releases]}
end
function Battle:damageFriendly(target,damage,stamina)
 if self.phase~='playing'then return false end
 if target==self.mentor then
  self.mentorHP=math.max(0,self.mentorHP-damage);if stamina then self.stamina:hit(stamina)end;return true
 end
 for _,escort in ipairs(self.escorts)do if escort.unit==target and escort.hp>0 then
  escort.hp=math.max(0,escort.hp-damage);if stamina and escort.stamina then escort.stamina:hit(stamina)end;self.message=string.format("撤离伙伴受击，剩余生命 %.0f/100。请把追兵引向右侧。",escort.hp);return true
 end end
 return false
end
function Battle:enemyStrike(e,spec)
 if spec.ambush then return require('Enemy.Ambush').start(self,e,spec)end
 if e.busy or e.hp<=0 or self.phase~='playing' then return false end
 local prop=spec.prop and self.props:reserve(e.unit) or nil
 if spec.prop and not prop then return false,'NO_PROP'end
 e.busy=true;e.unit:stop();e.unit.faceRight=self.mentor.x>=e.unit.x;e.unit.velocityX=0
 local strike={kind=spec.name,started=D.App.runningTime,at=spec.at,hits=0,impacts={},prop=prop};e.strikes[#e.strikes+1]=strike
 local sequence
 sequence=Sequence.new({now=function() return D.App.runningTime end,
  play=function(name)
   e.unit.data.combatCompletedName='';e.unit.data.combatCompletedAt=-1
   local duration=A.play(e.unit,name,false);strike.duration=duration;return duration
  end,
  impact=function()
   if e.hp<=0 or self.phase~='playing' then return end
   strike.impacts[#strike.impacts+1]=D.App.runningTime-strike.started
   if D.App.runningTime<e.stunUntil then self.flareBlocks=(self.flareBlocks or 0)+1;return end
   if spec.projectile then
    if self:lineObscured(e.unit.x,self.mentor.x)then self.smokeBlockedAttacks=self.smokeBlockedAttacks+1 else self:enemyProjectile(e,spec,strike)end
   else
    local targets={self.mentor};if spec.area then for _,escort in ipairs(self.escorts)do targets[#targets+1]=escort.unit end end
    for _,target in ipairs(targets)do
     if math.abs(target.x-e.unit.x)<spec.range and math.abs(target.y-e.unit.y)<240 and (spec.area or (target.x>=e.unit.x)==e.unit.faceRight)then
      if self:lineObscured(e.unit.x,target.x)then self.smokeBlockedAttacks=self.smokeBlockedAttacks+1
      elseif self:damageFriendly(target,spec.damage,spec.stamina)then strike.hits=strike.hits+1 end
     end
    end
   end
  end,
  complete=function() strike.completed=D.App.runningTime end,
  stop=function(reason) strike.cancelled=reason;strike.cancelledAt=D.App.runningTime;e.unit.velocityX=0 end})
 e.attackSequence=sequence
 sequence:start({{name=spec.name,impacts=spec.at}})
 local rushPrevious
 D.thread(function()
  while sequence.status=='playing' do
   if e.hp<=0 or self.phase~='playing' or not e.unit.parent then sequence:cancel(e.hp<=0 and 'DEAD' or 'BATTLE_ENDED');break end
   local elapsed=D.App.runningTime-strike.started
   if prop and elapsed>=.4 then self.props:carry(prop,require('Enemy.BigShanRelease').point(e.unit,self.world))end
   if spec.evade and elapsed>.45 and elapsed<.9 and D.App.runningTime>=e.stunUntil then e.unit.velocityX=e.unit.faceRight and -360 or 360
   elseif spec.rush and elapsed>.6 and elapsed<1.5 and D.App.runningTime>=e.stunUntil and not strike.rushStopped then
    local current={x=self.mentor.x-e.unit.x,y=self.mentor.y-e.unit.y}
    -- Both pursuit actors have authored 100 x 300 bodies; use relative
    -- movement so a fast target cannot tunnel across the active contact box.
    local touched=require('Enemy.RushContact').hit(rushPrevious or current,current,100,300,e.unit.faceRight)
    rushPrevious=current
    if touched then
     strike.rushStopped=elapsed;strike.impacts[#strike.impacts+1]=elapsed;e.unit.velocityX=0
     if self:lineObscured(e.unit.x,self.mentor.x) then self.smokeBlockedAttacks=self.smokeBlockedAttacks+1
     else self.mentorHP=math.max(0,self.mentorHP-spec.damage);strike.hits=strike.hits+1;if spec.stamina then self.stamina:hit(spec.stamina)end end
    else e.unit.velocityX=e.unit.faceRight and 420 or -420 end
   else e.unit.velocityX=0;rushPrevious=nil end
   if e.unit.data.combatCompletedName==spec.name and (e.unit.data.combatCompletedAt or -1)>=sequence.started then sequence:ended(spec.name,sequence.serial,sequence.index) end
   sequence:update();D.sleep(.01)
  end
  if prop then self.props:release(prop)end
  if self.world.parent and e.unit.parent then e.unit.velocityX=0 end
  e.busy=false;e.nextAttack=D.App.runningTime+.65
  if self.phase=='playing' and e.hp>0 and self.world.parent and e.unit.parent then A.rest(e.unit) end
 end)
 return true
end
function Battle:finish(status,reason)
 if self.phase~='playing' then return end
 self.phase='saving';self.props:close();self.pendingStatus=status;self.reason=reason
 self.mentor:stop();self.mentor.velocityX=0
 for _,e in ipairs(self.enemies) do if e.attackSequence then e.attackSequence:cancel('BATTLE_ENDED') end;e.unit.velocityX=0;e.unit:stop() end
 for _,e in ipairs(self.escorts) do e.unit:stop();e.unit.velocityX=0 end
 local finishedAt=D.App.runningTime
 D.thread(function()
 local deadline=D.App.runningTime+15
 while self.medicineBusy do
  -- The engine swallows thread errors; degrade instead of a silent deadlock.
  if D.App.runningTime>=deadline then print('Pursuit: medicine did not finish before settlement, continuing')break end
  D.sleep(.02)
 end
 self.report={reason=reason,seconds=finishedAt-self.started,mentorHP=self.mentorHP,mentorHits=self.mentorHits,toolUses=self.toolUses,toolAnimations=self.toolAnimations,flareHits=self.flareHits,smokeBlocks=self.smokeBlocks,smokeBlockedAttacks=self.smokeBlockedAttacks,escortsSafe=self.escortsSafe,routeCheckpoints=self.checkpoints,medicineUses=self.medicineUses,stamina=self.stamina.value,knockdowns=self.stamina.knockdowns}
 self.report.enemySkills={};for _,enemy in ipairs(self.enemies)do for _,strike in ipairs(enemy.strikes)do local key=enemy.asset..':'..strike.kind;local metric=self.report.enemySkills[key] or {uses=0,hits=0,cancelled=0};metric.uses=metric.uses+1;metric.hits=metric.hits+strike.hits;metric.cancelled=metric.cancelled+(strike.cancelled and 1 or 0);self.report.enemySkills[key]=metric end end
 self.report.escortHP={};for _,escort in ipairs(self.escorts)do self.report.escortHP[escort.name]=escort.hp end
 self:saveResult()
 end)
end
function Battle:saveResult()
 if self.saving then return end;self.saving=true
 D.thread(function()
 local ok,r,e=xpcall(function() return self.service:finishAsync(self.attempt,self.pendingStatus,self.report) end,debug.traceback)
 if not ok then print('Pursuit: finishAsync failed '..tostring(r)) end
 self.saving=false;if ok and r then self.phase=self.pendingStatus else self.phase='save-error';self.saveError=ok and e or tostring(r) end
 end)
end
function Battle:update()
 if self.phase~='playing' then return false end
 local now=D.App.runningTime;local dt=math.min(.1,now-self.last);self.last=now
 self.stamina:update(dt)
 self.mentor.x=math.max(6700,math.min(11400,self.mentor.x))
 self.escortsSafe=0
 for _,escort in ipairs(self.escorts)do if escort.hp<=0 then self:finish('failed','伙伴受重伤，掩护失败。请重新选择引开追兵的路线。');return false end end
 for _,e in ipairs(self.escorts) do
  if e.stamina then e.stamina:update(dt)end
  e.healthBar:clear();if e.hp<100 then
   e.healthBar:drawSegment(D.Vec2(-45,0),D.Vec2(45,0),5,D.Color(0xff283747))
   e.healthBar:drawSegment(D.Vec2(-45,0),D.Vec2(-45+90*e.hp/100,0),5,D.Color(0xffe78371))
  end
  if e.unit.x<=Battle.safeX then self.escortsSafe=self.escortsSafe+1;if e.unit:isDoing('pursuitEscort') then e.unit:stop();e.unit.velocityX=0;A.rest(e.unit) end
  elseif not e.unit:isDoing('pursuitEscort') then e.unit.faceRight=false;e.unit:start('pursuitEscort') end
  e.walked=e.walked+math.abs(e.unit.x-e.lastX);e.lastX=e.unit.x
 end
 for _,e in ipairs(self.enemies) do if e.hp>0 and not e.busy then
  -- The same cloud that blocks a shot also conceals the escape route.
  -- Leaving the cloud must not restore tracking through its opaque trail.
  if now<e.stunUntil or self:lineObscured(e.unit.x,self.mentor.x) then if e.unit:isDoing('pursuitEnemyMove') then e.unit:stop();e.unit.velocityX=0;A.rest(e.unit) end
  elseif now<e.nextAttack then
   -- Keep the recovered rest pose during the attack cooldown instead of
   -- immediately replacing it with chase movement on the next update.
   if e.unit:isDoing('pursuitEnemyMove') then e.unit:stop();e.unit.velocityX=0;A.rest(e.unit) end
  elseif math.abs(e.unit.x-self.mentor.x)<(e.asset=='dashanxiao' and 680 or 550) then
   if e.asset=='xiaoshanxiao' then
    e.sequence=e.sequence+1
    local tactics=require('Enemy.ShanTactics');local context=tactics.context(e,self.enemies)
    local name=tactics.choose(context,math.abs(e.unit.x-self.mentor.x),e.sequence)
    for _,spec in ipairs(specs[e.asset])do if spec.name==name then self:enemyStrike(e,spec);break end end
   else e.sequence=e.sequence%#specs[e.asset]+1;self:enemyStrike(e,specs[e.asset][e.sequence])end
  else e.unit.faceRight=self.mentor.x>=e.unit.x;if not e.unit:isDoing('pursuitEnemyMove') then e.unit:start('pursuitEnemyMove') end end
 end end
 for _,p in ipairs(self.hostileProjectiles) do if not p.blocked and p.bullet.parent and self:inSmoke(p.bullet.x) then p.blocked=true;p.bullet.hitStop=true;p.bullet:removeFromParent();self.smokeBlocks=self.smokeBlocks+1 end end
 -- Compact expired entries so long pursuits do not retain dead bullets or clouds.
 do
  local live=0
  for _,cloud in ipairs(self.smoke) do if now<cloud.ends then live=live+1;self.smoke[live]=cloud end end
  for i=live+1,#self.smoke do self.smoke[i]=nil end
  live=0
  for _,f in ipairs(self.flashes) do if now<f.ends then live=live+1;self.flashes[live]=f end end
  for i=live+1,#self.flashes do self.flashes[i]=nil end
  live=0
  for _,p in ipairs(self.hostileProjectiles) do if not p.blocked and p.bullet.parent then live=live+1;self.hostileProjectiles[live]=p end end
  for i=live+1,#self.hostileProjectiles do self.hostileProjectiles[i]=nil end
 end
 self.fx:clear()
 for _,cloud in ipairs(self.smoke) do if now<cloud.ends then
  for i=1,18 do local x=cloud.x+math.sin(i*3.4+(now-cloud.started)*.3)*cloud.radius;local y=self.world.offset+35+(i%5)*38
   self.fx:drawDot(D.Vec2(x,y),35+(i%4)*12,D.Color(0x66526370))
  end
 end end
 for _,flash in ipairs(self.flashes) do if now<flash.ends then self.fx:drawDot(D.Vec2(flash.x,self.world.offset+130),(now-flash.started)*210+20,D.Color(0x99ffe2a5)) end end
 for i,x in ipairs({8200,9400,10500}) do if self.mentor.x>=x then self.checkpoints[i]=true end end
 -- Fit the authored full-size pursuer with the camera, never model scaling.
 local sizeRatio=1
 for _,e in ipairs(self.enemies)do
  if e.asset=='dashanxiao' and e.hp>0 and (self.ambushActive or math.abs(e.unit.x-self.mentor.x)<1800)then sizeRatio=math.max(sizeRatio,math.abs(e.unit.playable.scaleX)/.65)end
 end
 local blend=math.min(1,dt*8);local targetZoom=self.cameraBaseZoom*(self.ambushActive and .5 or 1)/sizeRatio
 self.world.camera.zoom=self.world.camera.zoom+(targetZoom-self.world.camera.zoom)*blend
 local targetHeight=self.world.offset+((self.ambushActive and 550 or 360)-self.world.offset)*sizeRatio
 self.cameraHeight=self.cameraHeight+(targetHeight-self.cameraHeight)*blend
 self.world.camera.position=D.Vec2(math.max(7350,math.min(10800,self.mentor.x+180)),self.cameraHeight)
 if self.mentorHP<=0 then self:finish('failed','导师失去行动能力。重新准备烟雾与火光掩护。')
 elseif now-self.started>=100 then self:finish('failed','追兵包围了道路。重新选择掩护时机。')
 elseif self.mentor.x>=Battle.escapeX and self.escortsSafe==4 and self.checkpoints[1] and self.checkpoints[2] and self.checkpoints[3] and self.mentorHits>0 and self.flareHits>0 and self.toolAnimations.smoke>0 and self.toolAnimations.flare>0 and not self.mentor:isDoing('groundMentorShot') and not self.mentor:isDoing('pursuitTool') and not self.medicineBusy then self:finish('won','四人已撤离，导师沿光路引开追兵，跌入桃源谷。') end
 return false
end
function Battle.createAsync(service,attempt)
 assert(attempt.mission=='c0-m06')
 local self=setmetatable({service=service,attempt=attempt,phase='loading',mentorHP=100,mentorHits=0,nextMentorShot=0,enemies={},escorts={},projectiles={},hostileProjectiles={},smoke={},flashes={},toolReady={},toolUses={smoke=0,flare=0},toolAnimations={smoke=0,flare=0},medicineUses=0,smokeBlocks=0,smokeBlockedAttacks=0,flareHits=0,checkpoints={},escortsSafe=0},Battle)
 for _,asset in ipairs({'charM','charF','ninilite','wuyun','vika','vivi','dashanxiao','dashanxiao-release','xiaoshanxiao','xiaoshanxiao-release','kineticgun'}) do D.Cache:loadAsync('spine:'..asset) end
 local Scene=require('Scene.AbandonedCity');Scene:loadAsync();D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();P.Data.store:clear();P.Data:setRelation(1,2,'Enemy')
 self.world=Scene();self.cameraBaseZoom=self.world.camera.zoom;self.cameraHeight=360;self.world:addTo(D.Director.entry);P.Data.store.world=self.world;self.world.ruinsPursuit=self
 -- The authored sky is finite; fill the exposed upper sky behind it when
 -- the camera pulls out. Keep every original scenery layer unscaled.
 local sky=D.DrawNode();sky:drawPolygon({D.Vec2(-23040,0),D.Vec2(23040,0),D.Vec2(23040,10000),D.Vec2(-23040,10000)},D.Color(0xff78b9ef))
 self.world:setLayerRatio(-111,D.Vec2(1,0));sky:addTo(self.world,-111)
 local skyFade=D.DrawNode()
 for i=0,31 do
  local y=952+i*4;local color=D.Color(0xff78b9ef);color.opacity=(i+1)/32
  skyFade:drawPolygon({D.Vec2(-23040,y),D.Vec2(23040,y),D.Vec2(23040,y+4),D.Vec2(-23040,y+4)},color)
 end
 skyFade:addTo(self.world,-110)
 local function spawn(asset,group,x,actions)
  local def=D.Dictionary();def.playable='spine:'..(asset=='xiaoshanxiao' and 'xiaoshanxiao-release' or asset=='dashanxiao' and 'dashanxiao-release' or asset);def.bodyType='Dynamic';def.size=D.Size(asset=='dashanxiao' and 200 or 100,300);def.density=1;def.friction=1;def.linearAcceleration=D.Vec2(0,-15);def.defaultFaceRight=asset~='dashanxiao' and asset~='xiaoshanxiao';def.scale=asset=='xiaoshanxiao' and .75 or 1;def.actions=D.Array(actions or {})
  local marker=D.Node();D.Entity({pursuitActor=true,name=asset,spawnMarker=marker});local e=assert(D.Group({'pursuitActor','name'}):find(function(e) return e.spawnMarker==marker end))
  local u=assert(P.Unit(def,self.world,e,D.Vec2(x,self.world.offset+155)));u.group=group;u.playable.y=-150;u:addTo(self.world);A.configure(u,asset);e.unit=u;self.world:addShadowTo(u);return u,e
 end
 local function move(name,track,speed)
  P.UnitAction:add(name,{priority=1,reaction=0,recovery=.2,available=function(u) return u.onSurface end,create=function(u) A.play(u,track,true);return function(v) v.velocityX=v.faceRight and speed or -speed;return not v.onSurface end end,stop=function(u) u.velocityX=0;A.rest(u) end})
 end
 move('pursuitEscort','fmove',230);move('pursuitEnemyMove','move',245)
 self.arena={world=self.world,spawnUnit=function(asset,group,x,actions) return spawn(asset,group,x,actions) end,projectiles=self.projectiles,enemyHP=100}
 self.mentorTarget=function() local target,dist;for _,e in ipairs(self.enemies) do if e.hp>0 and not e.untargetable then local d=math.abs(e.unit.x-self.mentor.x);if not dist or d<dist then target=e.unit;dist=d end end end;return target end
 self.damageMentorTarget=function(target,n) for _,e in ipairs(self.enemies) do if e.unit==target and e.hp>0 and not e.untargetable then e.hp=math.max(0,e.hp-n);e.stunUntil=D.App.runningTime+.2;if e.hp<=0 then if e.attackSequence then e.attackSequence:cancel('DEAD') end;e.unit.velocityX=0;D.thread(function() while e.busy and self.phase=='playing' do D.sleep(.02) end;if self.phase=='playing' then A.playOnceAsync(e.unit,'lose');e.unit.visible=false end end) end;break end end end
 if attempt.supplyAttempt then self.supplies=assert(require('Economy.CombatSession').open(attempt.supplyAttempt))end
 local mentor=require('Ground.Mentor').createAsync(self,require('Data.Config').char);mentor.position=D.Vec2(Battle.startX,self.world.offset+155);mentor.entity.player=true
 self.stamina=require('Ruins.Stamina').new(self)
 local battleRef=setmetatable({self},{__mode='v'})
 P.UnitAction:add('pursuitTool',{priority=3,reaction=0,recovery=.2,available=function(u) local self=battleRef[1];return self~=nil and u.onSurface and self.phase=='playing' end,create=function(u)
  local self=battleRef[1];if not self then return function()return true end end
  local kind=self.pendingTool;u.velocityX=0;local log={kind=kind,started=D.App.runningTime};self.lastTool=log
  u.playable:slot('attack'):set(function() if self.phase=='playing' and not log.attempted then log.attempted=true;if self:tool(kind)then log.released=D.App.runningTime end end end)
  return D.once(function() A.playOnceAsync(u,'throw');log.completed=D.App.runningTime;self.toolAnimations[kind]=self.toolAnimations[kind]+1;A.rest(u);return true end)
 end})
 mentor:attachAction('pursuitTool')
 for i,asset in ipairs({'ninilite','wuyun','vika','vivi'}) do local u=spawn(asset,1,Battle.startX-160-i*130,{'pursuitEscort'});local escort={unit=u,name=asset,hp=100,walked=0,lastX=u.x};self.escorts[#self.escorts+1]=escort
  local animations={};for _,name in ipairs(D.Spine:getAnimations(asset))do animations[name]=true end
  if animations.fall and animations.standUp then escort.stamina=require('Ruins.Stamina').new(self,{unit=u,health=function()return escort.hp end,action='pursuitKnockdown-'..asset})end
  local bar=D.DrawNode();bar.y=-164;bar:addTo(u,20);escort.healthBar=bar;A.rest(u) end
 for i,asset in ipairs({'dashanxiao','xiaoshanxiao','xiaoshanxiao'}) do local u=spawn(asset,2,Battle.startX+420+(i-1)*280,{'pursuitEnemyMove'});self.enemies[#self.enemies+1]={unit=u,asset=asset,hp=asset=='dashanxiao' and 180 or 100,sequence=0,nextAttack=D.App.runningTime+1.3+(i-1)*.4,stunUntil=0,strikes={}};A.rest(u) end
 self.props=require('Enemy.ThrowProps').new(self.world,{7520,8500,9450})
 self.fx=D.DrawNode();self.fx.order=30;self.fx:addTo(self.world)
 local route=D.DrawNode();route.tag='pursuit-route';route:addTo(self.world)
 for _,x in ipairs({8200,9400,10500,11200}) do route:drawSegment(D.Vec2(x-50,self.world.offset+20),D.Vec2(x+50,self.world.offset+20),6,D.Color(0xffecd394));route:drawSegment(D.Vec2(x+50,self.world.offset+20),D.Vec2(x+15,self.world.offset+50),6,D.Color(0xffecd394)) end
 self.started=D.App.runningTime;self.last=self.started;self.phase='playing'
 local tick=D.Node();tick:addTo(self.world);tick:schedule(function() return self:update() end)
 return self
end
return Battle
