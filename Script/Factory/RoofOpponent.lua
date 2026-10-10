-- Wuyun's authored animations: damage only on the native attack event, no timer cuts.
local D=require('Dora');local A=require('CombatAnimation');local P=D.Platformer
local Opponent={};Opponent.__index=Opponent
Opponent.asset='Spine/Roof/wuyun.json|Spine/wuyun.atlas'
function Opponent.createAsync(world,x)
 D.Cache:loadAsync({'spine:'..Opponent.asset,'spine:coldweapon','spine:empgun'})
 local def=D.Dictionary();def.playable='spine:'..Opponent.asset;def.bodyType='Dynamic';def.size=D.Size(100,300);def.linearAcceleration=D.Vec2(0,-15);def.density=1;def.friction=1;def.defaultFaceRight=true;def.scale=1;def.actions=D.Array({})
 local marker=D.Node();D.Entity({roofOpponent=true,spawnMarker=marker});local entity=assert(D.Group({'roofOpponent','spawnMarker'}):find(function(e)return e.spawnMarker==marker end))
 local unit=assert(P.Unit(def,world,entity,D.Vec2(x,world.offset+155)));unit.group=2;unit.playable.y=-150;unit.faceRight=false;unit:addTo(world,20);entity.unit=unit
 A.configure(unit,Opponent.asset);A.rest(unit);world:addShadowTo(unit)
 local blade=assert(D.Spine('coldweapon'));blade.look='sword';blade.scaleX=.2;blade.scaleY=.2;unit.playable:setSlot('melee',blade)
 local gun=assert(D.Spine('empgun'));gun.look='PT';gun.scaleX=.2;gun.scaleY=.2;unit.playable:setSlot('pistol',gun)
 return unit
end
function Opponent.new(battle,record)
 local self=setmetatable({battle=battle,record=record,unit=record.enemy,strikes={},nextAttack=0,sequence=0},Opponent)
 self.unit.playable:slot('attack',function()self:release()end);return self
end
function Opponent:release()
 local s=self.strike;local b=self.battle;local u=self.unit
 if not s or s.releaseAt then return end
 s.releaseAt=D.App.runningTime;s.impactOffset=s.releaseAt-s.started
 if self.record.enemyHP<=0 or b.phase~='playing'then s.cancelledDamage=true;return end
 if s.kind=='shot'then
  local def=P.BulletDef();def.lifeTime=1.4;def.highSpeedFix=true;def.gravity=D.Vec2.zero;def:setAsCircle(8);def:setVelocity(0,1050)
  def.face=P.Face(function()local n=D.DrawNode();n:drawSegment(D.Vec2(-15,0),D.Vec2(8,0),3,D.Color(0xffa6dfff));return n end)
  local bullet=P.Bullet(def,u);local allow=P.TargetAllow();allow:allow('Enemy',true);allow.terrainAllowed=true;bullet.targetAllow=allow:toValue();bullet.position=u.position+D.Vec2(u.faceRight and 65 or -65,-20)
  bullet:slot('HitTarget',function(p,target)
   if b.phase=='playing'then for _,t in ipairs(b:targets())do if t.unit==target and t.hp()>0 then t.damage(8);s.hits=s.hits+1;break end end end;p.hitStop=true
  end);bullet:addTo(b.world);b.projectiles[#b.projectiles+1]=bullet
 else
  local direction=u.faceRight and 1 or -1
  for _,t in ipairs(b:targets())do
   local hit=s.kind=='wind'and require('Ground.Tactics').inWind(t.unit.x,t.unit.y,u.x,u.y,direction)or s.kind=='melee'and (t.unit.x-u.x)*direction>=0 and math.abs(t.unit.x-u.x)<=280 and math.abs(t.unit.y-u.y)<180
   if t.hp()>0 and hit then t.damage(s.kind=='wind'and 12 or 10);s.hits=s.hits+1 end
  end
  local slash=D.DrawNode();slash.position=u.position;slash:addTo(b.world,25)
  if s.kind=='wind'then
   slash:drawPolygon({D.Vec2(0,-90),D.Vec2(direction*700,-210),D.Vec2(direction*700,210),D.Vec2(0,90)},D.Color(0x225edcac))
   for i=1,5 do local y=(i-3)*45;slash:drawSegment(D.Vec2(direction*60,y*.3),D.Vec2(direction*670,y),3,D.Color(0x99b4efd7))end
  end
  slash:drawSegment(D.Vec2(direction*25,-65),D.Vec2(direction*160,115),5,D.Color(0xffe5fff4))
  slash:perform(D.Sequence(D.Opacity(.6,1,0),D.Event('Finished')));slash:slot('Finished',function()slash:removeFromParent()end)
 end
end
function Opponent:attack(kind,target)
 if self.busy or self.record.enemyHP<=0 or self.battle.phase~='playing'or not self.unit.onSurface then return false end
 assert(kind=='shot'or kind=='melee'or kind=='wind')
 self.unit.faceRight=target.x>=self.unit.x;self.unit.velocityX=0;self.approaching=false;self.busy=true
 local s={kind=kind,animation=kind=='shot'and 'pistol'or 'melee',started=D.App.runningTime,hits=0};self.strike=s;self.strikes[#self.strikes+1]=s
 self.unit.data.combatCompletedName='';s.duration=A.play(self.unit,s.animation,false);assert(s.duration>0);return true
end
function Opponent:update(now)
 local u=self.unit
 if self.busy then
  local s=self.strike
  if u.data.combatCompletedName==s.animation and u.data.combatCompletedAt>=s.started then
   s.completed=u.data.combatCompletedAt;self.busy=false;self.strike=nil;self.nextAttack=now+.9
   if self.record.enemyHP>0 then A.rest(u)end
  end
  return
 end
 if self.record.enemyHP<=0 then
  if not self.dying then self.dying=true;u.velocityX=0;u.group=3;self.loseStarted=now;u.data.combatCompletedName='';self.loseDuration=A.play(u,'lose',false)
  elseif u.data.combatCompletedName=='lose'and u.data.combatCompletedAt>=self.loseStarted then self.dead=true;self.loseEnded=u.data.combatCompletedAt end
  return
 end
 if self.battle.phase~='playing'then if self.approaching then self.approaching=false;u.velocityX=0;A.rest(u)end;return end
 if now<self.nextAttack then return end
 local target,distance
 for _,t in ipairs(self.battle:targets())do local d=math.abs(t.unit.x-u.x);if t.hp()>0 and(not distance or d<distance)then target=t.unit;distance=d end end
 if not target then return end
 if distance>650 then
  if not self.approaching then A.play(u,'fmove',true);self.approaching=true end
  u.faceRight=target.x>=u.x;u.velocityX=u.faceRight and 150 or -150
 else
  self.sequence=self.sequence+1
  self:attack(self.sequence%3==0 and 'wind'or distance<250 and 'melee'or 'shot',target)
 end
end
return Opponent
