-- Authored throw/melee release events, physical fire rain and directional gust.
local D=require("Dora")
local Animation=require("CombatAnimation")
local Displacement=require("Combat.Displacement")
local T=require("Ground.Tactics")
local Magic={}; Magic.__index=Magic
function Magic:busy(name) return not self.closed and self.roles[name] and self.roles[name].student:isDoing(self.actions[name]) or false end
function Magic:available(name,at)
 if self.closed then return false,'CLOSED'end
 local a=self.roles[name]
 if not a then return false,"ROLE_ABSENT" end
 if self.battle.phase~="playing" or a.studentHP<=0 then return false,"NOT_PLAYING" end
 if Displacement.blocked(a.student) then return false,"DISPLACED" end
 if self:busy(name) then return false,"ALREADY_CASTING" end
 if (at or D.App.runningTime)<self.ready[name] then return false,"COOLDOWN" end
 if a:isAttacking() then return false,"ACTION_BUSY" end
 if not a.student.onSurface then return false,"AIRBORNE" end
 return true
end
function Magic:request(name,context)
 context=context or {}
 if type(context)~='table'or(context.faceRight~=nil and type(context.faceRight)~='boolean')or(context.source~=nil and type(context.source)~='string')or(context.noQueue~=nil and type(context.noQueue)~='boolean')or(context.requestedAt~=nil and(type(context.requestedAt)~='number'or context.requestedAt~=context.requestedAt or math.abs(context.requestedAt)==math.huge or context.requestedAt>D.App.runningTime))then return false,'INVALID_CONTEXT'end
 local ok,why=self:available(name)
 if not ok then
  if why=='ACTION_BUSY'and not context.noQueue then
   self.pending[name]=D.App.runningTime+2
   self.pendingContext[name]={faceRight=context.faceRight,source=context.source,noQueue=context.noQueue,requestedAt=context.requestedAt or D.App.runningTime}
   return true,'QUEUED_AFTER_ATTACK'
  end
  return false,why
 end
 self.requestContext[name]={faceRight=context.faceRight,source=context.source,requestedAt=context.requestedAt or D.App.runningTime,observation=self.onStarting and self.onStarting(name)or nil}
 local started=self.roles[name].student:start(self.actions[name]);self.requestContext[name]=nil
 if started then self.pending[name]=nil;self.pendingContext[name]=nil end
 return started,started and 'STARTED'or'ACTION_UNAVAILABLE'
end
-- A newer movement order replaces waiting casts, never running animations.
function Magic:cancelPending()
 local count=0;for _ in pairs(self.pending)do count=count+1 end
 self.pending={};self.pendingContext={}
 return count
end
function Magic:finish(name,log,status,reason)
 if not log or log.endedAt then return end
 log.endedAt=D.App.runningTime;log.status=status;log.reason=reason
 if status=='completed'then log.completedAt=log.endedAt else log.cancelledAt=log.endedAt end
 if self.activeLogs[name]==log then
  self.activeLogs[name]=nil
  local role=self.roles[name];local playable=role and role.student and role.student.playable
  if playable then playable:slot('attack'):clear()end
 end
 if self.onStopped then self.onStopped(name,log)end
end
function Magic:fire(log)
 local b=self.battle; local u=b.arena.student; local direction=log.direction
 local aim=log.aim
 log.aim=aim; log.direction=direction; log.releaseAt=D.App.runningTime
 for i=1,3 do
  local vx,vy=direction*260,-900; local angle=-math.atan(vy,vx)*180/math.pi
  local def=D.Platformer.BulletDef(); def.lifeTime=1.2; def.highSpeedFix=true; def.gravity=D.Vec2.zero; def:setAsCircle(12); def:setVelocity(-90,900)
  local born=D.App.runningTime
  def.face=D.Platformer.Face(function()
   local n=D.DrawNode(); n.angle=angle
   local fire=false
   local function draw(warm)
    n:clear(); local color=D.Color(warm and 0xffff963e or 0xfff8fcff)
    n:drawPolygon({D.Vec2(-28,0),D.Vec2(4,10),D.Vec2(34,0),D.Vec2(4,-10)},color)
    n:drawSegment(D.Vec2(-30,0),D.Vec2(34,0),3,D.Color(warm and 0xfff34b32 or 0xffd4e4ed))
    for j=1,3 do local x=-20+j*10; n:drawSegment(D.Vec2(x-9,0),D.Vec2(x,8),2,D.Color(0xfff8eddf)); n:drawSegment(D.Vec2(x-9,0),D.Vec2(x,-8),2,D.Color(0xfff8eddf)) end
   end
   draw(false); n:schedule(function() if not fire and D.App.runningTime-born>=0.12 then fire=true; draw(true) end; return false end)
   return n
  end)
  local arrow=D.Platformer.Bullet(def,u)
  local allow=D.Platformer.TargetAllow(); allow:allow("Enemy",true); allow.terrainAllowed=true; arrow.targetAllow=allow:toValue()
  local item={bullet=arrow,direction=direction,enhanced=false,spent=false}; self.arrows[#self.arrows+1]=item
  arrow.position=D.Vec2(aim-direction*60+(i-2)*35,b.arena.world.offset+500)
  arrow.velocity=D.Vec2(vx,vy); arrow:addTo(b.arena.world); b.arena.projectiles[#b.arena.projectiles+1]=arrow
  arrow:slot("HitTarget",function(projectile,target)
   if not item.spent and b.phase=="playing" then
    for _,enemy in ipairs(b.enemies) do if target==enemy.enemy and enemy.enemyHP>0 then
     enemy.enemyHP=math.max(0,enemy.enemyHP-(item.enhanced and 18 or 12)); self.fireHits=self.fireHits+1
     if item.enhanced then self.synergyHits=self.synergyHits+1 end
     log.hits=(log.hits or 0)+1; item.spent=true; break
    end end
   end
   projectile.hitStop=true; item.spent=true
  end)
  if b.observeFireArrow then b.observeFireArrow(arrow,item,log,self)end
 end
end
function Magic:wind(log)
 local b=self.battle; local u=b.wuyun.student; local direction=log.direction
 local gust={x=u.x,y=u.y,direction=direction,untilTime=D.App.runningTime+0.75}; self.gust=gust
 log.releaseAt=D.App.runningTime; log.direction=direction
 if b.applyWind then b.applyWind(gust,log,self) else
 for _,enemy in ipairs(b.enemies) do
  if enemy.enemyHP>0 and T.inWind(enemy.enemy.x,enemy.enemy.y,gust.x,gust.y,direction) then
   enemy.enemyHP=math.max(0,enemy.enemyHP-12); self.windHits=self.windHits+1; log.hits=(log.hits or 0)+1
  end
 end
 end
 local wave=D.DrawNode(); wave.order=25; wave.position=D.Vec2(gust.x,gust.y); wave:addTo(b.arena.world)
 wave:drawPolygon({D.Vec2(0,-110),D.Vec2(direction*700,-250),D.Vec2(direction*700,250),D.Vec2(0,110)},D.Color(0x335cdaa8))
 for i=1,5 do local y=(i-3)*60; wave:drawSegment(D.Vec2(direction*50,y*0.3),D.Vec2(direction*650,y),4,D.Color(0x88a8f3ca)) end
 wave:drawSegment(D.Vec2(direction*10,-80),D.Vec2(direction*140,100),7,D.Color(0xffd8f4ed))
 wave:perform(D.Sequence(D.Opacity(0.75,1,0),D.Event("Finished"))); wave:slot("Finished",function() wave:removeFromParent() end)
end
function Magic:update()
 if self.closed then return end
 local now=D.App.runningTime
 for i=#self.arrows,1,-1 do local item=self.arrows[i];if item.spent or not item.bullet.parent then table.remove(self.arrows,i)end end
 if self.battle.phase~="playing" then self.pending={};self.pendingContext={}; return end
 for name,expires in pairs(self.pending) do
  if now>expires then self.pending[name]=nil;self.pendingContext[name]=nil
  elseif not self.roles[name]:isAttacking() then local context=self.pendingContext[name];self.pending[name]=nil;self.pendingContext[name]=nil;self:request(name,context) end
 end
 if self.gust and now<self.gust.untilTime then
  for _,item in ipairs(self.arrows) do
   local arrow=item.bullet
   if not item.spent and not item.enhanced and arrow.parent and T.inWind(arrow.x,arrow.y,self.gust.x,self.gust.y,self.gust.direction) and T.aligned(arrow.velocityX,self.gust.direction) then
    item.enhanced=true; arrow.velocity=D.Vec2(arrow.velocityX+self.gust.direction*120,arrow.velocityY)
   end
  end
 end
end
function Magic.new(b)
 local self=setmetatable({closed=false,battle=b,roles={fire=b.arena,wind=b.wuyun},actions={fire="energyFeatherFire",wind="energySilverWind"},ready={fire=0,wind=0},pending={},pendingContext={},requestContext={},activeLogs={},arrows={},logs={},fireHits=0,windHits=0,synergyHits=0},Magic)
 local magicRef=setmetatable({self},{__mode='v'})
 for _,name in ipairs(b.wuyun and {"fire","wind"} or {"fire"}) do
  local a=self.roles[name]; local inherited=a.isAttacking
  a.isAttacking=function(controller) return inherited(controller) or self:busy(name) end
  D.Platformer.UnitAction:add(self.actions[name],{priority=4,reaction=0,recovery=0.2,
   available=function(u) local self=magicRef[1];local a=self and self.roles[name];return a~=nil and not self.closed and not a.closed and self.battle.phase=="playing" and a.studentHP>0 and not Displacement.blocked(u) and u.onSurface and D.App.runningTime>=self.ready[name] end,
   create=function(u)
    local self=magicRef[1];if not self or self.closed or self.battle.arena.closed then return function()return true end end
    local b=self.battle;local a=self.roles[name]
    self.ready[name]=D.App.runningTime+6; u.velocityX=0
    local context=self.requestContext[name]or {}
    local face=context.faceRight;if face==nil then face=b.mentor.faceRight end
    local direction=face and 1 or -1;u.faceRight=face
    local log={schemaVersion=1,skill=name,actor=a.character.id,source=context.source or 'mentor-command',requestedAt=context.requestedAt or D.App.runningTime,startedAt=D.App.runningTime,direction=direction,aim=name=='fire'and(b.mentor.x+direction*240)or nil,cooldownUntil=self.ready[name],status='casting'}
    self.logs[#self.logs+1]=log;self.activeLogs[name]=log
    if self.onStarted then self.onStarted(name,log,context.observation)end
    u.playable:slot("attack"):set(function()
     if self.activeLogs[name]==log and not log.releaseAt and b.phase=="playing" and a.studentHP>0 and u:isDoing(self.actions[name])then
      if name=="fire"then self:fire(log)else self:wind(log)end
      if self.onReleased then self.onReleased(name,log)end
     end
    end)
    return D.once(function()
     Animation.playOnceAsync(u,name=="fire" and "throw" or "melee")
     self:finish(name,log,'completed')
     if b.phase=="playing" and a.studentHP>0 then Animation.rest(u)end
     return true
    end)
   end,
   stop=function()
    local self=magicRef[1];if not self then return end
    local b=self.battle;local a=self.roles[name]
    local reason=self.closed and'CLEANUP'or b.phase~='playing'and'BATTLE_ENDED'or a.studentHP<=0 and'DEFEATED'or Displacement.blocked(a.student)and'DISPLACED'or'INTERRUPTED'
    self:finish(name,self.activeLogs[name],'cancelled',reason)
   end})
  a.student:attachAction(self.actions[name])
 end
 -- Columns are cover silhouettes, not horizontal walls; characters walk beside them.
 for _,x in ipairs(b.noTacticsColumns and {} or T.columns) do
  local pillar=D.DrawNode(); pillar.order=-5; pillar.position=D.Vec2(x,b.arena.world.offset); pillar:addTo(b.arena.world)
  pillar:drawPolygon({D.Vec2(-45,0),D.Vec2(45,0),D.Vec2(34,330),D.Vec2(-32,330)},D.Color(0xff789092))
  pillar:drawPolygon({D.Vec2(20,0),D.Vec2(45,0),D.Vec2(34,330),D.Vec2(13,330)},D.Color(0xff405c64))
  pillar:drawSegment(D.Vec2(-45,12),D.Vec2(45,12),12,D.Color(0xffa6bab5)); pillar:drawSegment(D.Vec2(-32,330),D.Vec2(34,330),13,D.Color(0xffb2c2b9))
  pillar:drawSegment(D.Vec2(-10,230),D.Vec2(12,200),3,D.Color(0xff4b6063)); pillar:drawSegment(D.Vec2(12,200),D.Vec2(-5,150),3,D.Color(0xff4b6063))
  pillar:drawSegment(D.Vec2(-90,4),D.Vec2(90,4),3,D.Color(0x8853e0c2))
 end
 b.arena.world:slot('Cleanup',function()
  self.closed=true
  for name,log in pairs(self.activeLogs)do self:finish(name,log,'cancelled','CLEANUP')end
  self.arrows={};self.pending={};self.pendingContext={};self.requestContext={};self.gust=nil
 end)
 return self
end
return Magic
