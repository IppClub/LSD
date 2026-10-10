-- Existing tutorial kineticgun artwork and casing physics, shared by missions.
local D=require('Dora')
local V={}
function V.bulletFace(angle,right)
 local node=D.Node();local sprite=assert(D.Spine('kineticgun'));sprite.look='PTbullet';sprite.scaleX=.5;sprite.scaleY=.5
 sprite.angle=right and angle or 180-angle;sprite:addTo(node);return node
end
function V.casing(owner,gun,world,live)
 for i=#live,1,-1 do if not live[i].parent then table.remove(live,i)end end
 if #live>=24 then local old=table.remove(live,1);old:removeFromParent()end
 local def=D.BodyDef();def.type='Dynamic';def.linearAcceleration=D.Vec2(0,-9.8);def:attachPolygon(20,10,26,.4,.4)
 local pos=world:convertToNodeSpace(gun:convertToWorldSpace(D.Vec2.zero))
 local body=D.Body(def,world,pos);body.group=D.Platformer.Data.groupHide
 body.velocityX=(math.random()+1)*(owner.faceRight and -200 or 200);body.velocityY=(math.random()+1)*300
 local sprite=assert(D.Spine('kineticgun'));sprite.look='PTcasing';sprite.scaleX=.5;sprite.scaleY=.5;sprite:addTo(body)
 body:addTo(world,owner.order);live[#live+1]=body
 local elapsed=0;body:schedule(function(dt)
  elapsed=elapsed+dt
  if elapsed>10 then body.opacity=math.max(0,1-(elapsed-10)/.5)end
  if elapsed>=10.5 then body:removeFromParent();for i,n in ipairs(live)do if n==body then table.remove(live,i);break end end;return true end
  return false
 end)
 return body
end
return V
