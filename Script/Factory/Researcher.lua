-- Capture opponent: original researcher art; flee, react fully, then hold for interrogation.
local D=require('Dora');local P=D.Platformer;local R={};R.__index=R
R.asset='Spine/StoryActions/researcher.skel|Spine/shujuyuan.atlas'
function R.create(world,x)
 local def=D.Dictionary();def.playable='spine:'..R.asset;def.bodyType='Dynamic';def.size=D.Size(90,300);def.density=1;def.friction=1;def.linearAcceleration=D.Vec2(0,-15);def.defaultFaceRight=true;def.scale=1;def.actions=D.Array({})
 local marker=D.Node();D.Entity({researcher=true,spawnMarker=marker})
 local e=assert(D.Group({'researcher','spawnMarker'}):find(function(v)return v.spawnMarker==marker end));local u=assert(P.Unit(def,world,e,D.Vec2(x,world.offset+155)))
 u.group=2;u.playable.y=-150;u.playable.recovery=.15;u.faceRight=true;u:addTo(world);world:addShadowTo(u);e.unit=u
 u.data.combatRest='idle';u.playable:play('idle',true);return u
end
function R.new(battle,record)
 local self=setmetatable({battle=battle,record=record,unit=record.enemy,strikes={},lastHP=record.enemyHP,hits={}},R)
 self.unit.playable:slot('AnimationEnd',function(name)
  if name=='hit' and self.hit and D.App.runningTime-self.hit.started>=self.hit.duration-.035 then self.hit.ended=D.App.runningTime end
 end)
 return self
end
function R:update(now)
 local u=self.unit;local hp=self.record.enemyHP;local b=self.battle
 if self.dead then return end
 if hp<self.lastHP then self.pendingHit=true;self.damageTaken=(self.damageTaken or 0)+(self.lastHP-hp) end
 self.lastHP=hp
 if hp<=0 and not self.loseStarted then self.loseStarted=now end
 -- Repeated impacts never reset the currently playing finite hit animation.
 if self.hit then
  u.velocityX=0
  if not self.hit.ended then return end
  self.hit=nil;self.busy=false
  if hp<=0 then
   self.dead=true;self.loseEnded=now;self.capturedAt=now;u.group=3;u.data.combatRest='restrained';u.playable.recovery=.15;u.playable:play('restrained',true);return
  end
 end
 if self.pendingHit then
  self.pendingHit=false;u.velocityX=0;self.busy=true
  local hit={started=now}
  -- play() may synchronously emit the previous same-name track's completion.
  -- Publish the new record only after that call has returned.
  u.playable.recovery=.15;hit.duration=u.playable:play('hit',false);assert(hit.duration>0)
  self.hit=hit;self.hits[#self.hits+1]=hit
  if hp<=0 then self.loseStarted=now end
  return
 end
 if b.phase~='playing' then u.velocityX=0;if u.playable.current~='idle'then u.playable:play('idle',true)end;return end
 if not self.fleeStarted then self.fleeStarted=now end
 u.faceRight=true;u.velocityX=85
 if u.playable.current~='fmove'then u.playable:play('fmove',true)end
 if u.x>=3220 then self.escaped=true;u.velocityX=0 end
end
return R
