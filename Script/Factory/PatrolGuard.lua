-- New patrol artwork with native model events, body collisions and complete actions.
local D=require('Dora');local P=D.Platformer;local Guard={};Guard.__index=Guard
Guard.path='Image/Factory/patrol-guard.model'
function Guard.create(world,x)
 local def=D.Dictionary();def.playable='model:'..Guard.path;def.bodyType='Dynamic';def.size=D.Size(120,300);def.density=1;def.friction=1;def.linearAcceleration=D.Vec2(0,-15);def.defaultFaceRight=true;def.scale=.42;def.actions=D.Array({})
 local marker=D.Node();D.Entity({patrolGuard=true,spawnMarker=marker});local e=assert(D.Group({'patrolGuard','spawnMarker'}):find(function(v)return v.spawnMarker==marker end))
 local u=assert(P.Unit(def,world,e,D.Vec2(x,world.offset+155)));u.group=2;u.playable.y=-150;u.playable.recovery=.2;u.faceRight=false;u:addTo(world);world:addShadowTo(u);e.unit=u
 u.data.combatRest='prepare';u.playable:slot('AnimationEnd',function(name)u.data.combatCompletedName=name;u.data.combatCompletedAt=D.App.runningTime end)
 u.playable:play('prepare',true);return u
end
function Guard.new(battle,record)
 local self=setmetatable({battle=battle,record=record,unit=record.enemy,strikes={},nextAttack=0,lastHP=record.enemyHP},Guard)
 self.unit.playable:slot('ModelEvent',function(_,name)
  local strike=self.strike
  if name~='guard-shot' or not strike or strike.releaseAt then return end
  -- Record the authored event even when defeat/settlement suppresses its projectile.
  strike.releaseEventAt=D.App.runningTime;strike.releaseEventHP=record.enemyHP;strike.releaseEventPhase=battle.phase
  if record.enemyHP<=0 then strike.releaseCancelled='DEFEATED'
  elseif battle.phase~='playing' then strike.releaseCancelled='BATTLE_ENDED'
  else self:fire() end
 end)
 return self
end
function Guard:fire()
 local b=self.battle;local u=self.unit;local strike=self.strike;strike.releaseAt=D.App.runningTime;strike.impactOffset=strike.releaseAt-strike.started
 local def=P.BulletDef();def.lifeTime=2;def.highSpeedFix=true;def.gravity=D.Vec2.zero;def:setAsCircle(7);def:setVelocity(0,950)
 def.face=P.Face(function()local n=D.DrawNode();n:drawSegment(D.Vec2(-18,0),D.Vec2(8,0),4,D.Color(0xff73e2dd));return n end)
 local bullet=P.Bullet(def,u);local allow=P.TargetAllow();allow:allow('Enemy',true);allow.terrainAllowed=true;bullet.targetAllow=allow:toValue();bullet.position=u.position+D.Vec2(u.faceRight and 150 or -150,0)
 bullet:slot('HitTarget',function(p,target)
  if b.phase=='playing' then for _,t in ipairs(b:targets()) do if target==t.unit and t.hp()>0 then t.damage(6);strike.hits=strike.hits+1;break end end end;p.hitStop=true
 end)
 bullet:addTo(b.world);b.projectiles[#b.projectiles+1]=bullet
end
function Guard:shoot(target)
 if self.busy or self.record.enemyHP<=0 then return false end
 self.busy=true;self.unit.faceRight=target.x>=self.unit.x;self.unit.velocityX=0
 local strike={started=D.App.runningTime,hits=0};self.strikes[#self.strikes+1]=strike;self.strike=strike
 self.unit.data.combatCompletedName='';strike.duration=self.unit.playable:play('shoot',false)
 return true
end
function Guard:update(now)
 local u=self.unit;local record=self.record
 if self.approaching then self.approachTravel=(self.approachTravel or 0)+math.abs(u.x-(self.approachX or u.x));self.approachX=u.x end
 if record.enemyHP<self.lastHP then self.alerted=true end;self.lastHP=record.enemyHP
 if self.busy then
  if u.data.combatCompletedName=='shoot' and u.data.combatCompletedAt>=self.strike.started then
   self.strike.completed=u.data.combatCompletedAt;self.strike=nil;self.busy=false;self.nextAttack=now+.7
   if record.enemyHP>0 then u.playable:play('prepare',true) end
  end
  return
 end
 if record.enemyHP<=0 then
  if not self.dying then self.dying=true;self.loseStarted=now;self.approaching=false;u.group=3;u.data.combatCompletedName='';u.velocityX=0;self.loseDuration=u.playable:play('lose',false)
  elseif u.data.combatCompletedName=='lose' and u.data.combatCompletedAt>=self.loseStarted then self.dead=true;self.loseEnded=u.data.combatCompletedAt end
  return
 end
 if self.battle.phase~='playing' then
  if self.approaching then self.approaching=false;u.velocityX=0;u.playable:play('prepare',true)end
  return
 end
 if now<self.nextAttack then return end
 local selected,distance
 for _,t in ipairs(self.battle:targets()) do if t.hp()>0 and (not distance or math.abs(t.unit.x-u.x)<distance) then selected=t.unit;distance=math.abs(t.unit.x-u.x) end end
 local range=self.battle.scenario and self.battle.scenario.engageRange
 if selected and range and distance>range and self.alerted then
  if not self.approaching then self.approaching=true;self.approachX=u.x;u.playable:play('fmove',true)end
  u.faceRight=selected.x>=u.x;u.velocityX=u.faceRight and 110 or -110
 elseif selected and (not range or distance<=range) then
  self.approaching=false;self:shoot(selected)
 end
end
return Guard
