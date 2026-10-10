-- Finite scene supplies: reserve -> carry -> throw, or return on interruption.
local D=require('Dora');local P=D.Platformer
local Props={};Props.__index=Props
function Props.new(world,positions)
 local self=setmetatable({world=world,items={},flying={},closed=false},Props)
 for i,x in ipairs(positions)do
  local sprite=assert(D.Sprite('Image/box1.png'));sprite.scaleX=.6;sprite.scaleY=.6
  sprite.position=D.Vec2(x,world.offset+48);sprite:addTo(world)
  self.items[#self.items+1]={id=i,state='ready',node=sprite,home=sprite.position}
 end
 world:slot('Cleanup',function()self:close()end)
 return self
end
function Props:reserve(owner)
 if self.closed then return nil end
 local best,distance
 for _,item in ipairs(self.items)do
  local d=math.abs(owner.x-item.home.x)
  if item.state=='ready' and d<=240 and (not distance or d<distance)then best=item;distance=d end
 end
 if best then best.state='reserved';best.owner=owner end
 return best
end
function Props:carry(item,position)
 if item and (item.state=='reserved' or item.state=='carried')then item.state='carried';item.node.position=position;return true end
 return false
end
function Props:release(item)
 if item and (item.state=='reserved' or item.state=='carried')then item.state='ready';item.owner=nil;item.node.position=item.home end
end
function Props:throw(item,position,aim,onHit)
 if self.closed or not item or item.state~='carried' then return nil end
 local owner=item.owner;local arc=require('Enemy.ThrowArc').solve(position,aim)
 local speed=math.sqrt(arc.vx^2+arc.vy^2);local angle=math.deg(math.atan(arc.vy,arc.vx*(owner.faceRight and 1 or -1)))
 local def=P.BulletDef();def.lifeTime=3;def.highSpeedFix=true;def.gravity=D.Vec2(0,-arc.gravity/D.PhysicsWorld.scaleFactor);def:setAsCircle(40);def:setVelocity(angle,speed)
 def.face=P.Face(function()local sprite=assert(D.Sprite('Image/box1.png'));sprite.scaleX=.6;sprite.scaleY=.6;return sprite end)
 local bullet=P.Bullet(def,owner);local allow=P.TargetAllow();allow:allow('Enemy',true);allow.terrainAllowed=true;bullet.targetAllow=allow:toValue();bullet.position=position
 local hit={};bullet:slot('HitTarget',function(projectile,target)
  projectile.hitStop=false
  if not self.closed and target and not hit[target]then hit[target]=true;onHit(target,arc.vx>=0 and 1 or -1)end
 end)
 item.state='thrown';item.node:removeFromParent();item.owner=nil;self.flying[bullet]=true
 bullet:slot('Cleanup',function()self.flying[bullet]=nil;if not self.closed then item.state='spent' end end)
 bullet:addTo(self.world);return bullet
end
function Props:close()
 if self.closed then return end;self.closed=true
 local bullets={};for bullet in pairs(self.flying)do bullets[#bullets+1]=bullet end
 -- Cleanup notifications are queued; release ownership synchronously on exit.
 self.flying={}
 for _,bullet in ipairs(bullets)do if bullet.parent then bullet:removeFromParent()end end
 for _,item in ipairs(self.items)do if item.node.parent then item.node:removeFromParent()end;item.owner=nil;item.state='closed'end
end
return Props
