-- A layered aperture inside the cannon's light column, animated in world space.
local D=require('Dora');local Vortex={}
function Vortex.attach(world)
 local node=D.DrawNode();node.position=D.Vec2(2820,1690);node:addTo(world,32);node.visible=false
 local c={node=node,active=false,elapsed=0,frames=0};local function point(r,a)return D.Vec2(math.cos(a)*r,math.sin(a)*r*1.22)end
 node:schedule(function(dt)
  if not c.active then return false end
  c.elapsed=c.elapsed+dt;c.frames=c.frames+1;local t=c.elapsed;local u=math.min(1,t/1.2);local scale=u*u*(3-2*u);node.scaleX=scale;node.scaleY=scale;node:clear()
  local disc={};for i=0,79 do disc[#disc+1]=point(180,i/80*math.pi*2)end;node:drawPolygon(disc,D.Color(0xc519344c))
  for _,ring in ipairs({{190,11,0x245edfff},{184,5,0x687bf4ed},{177,1.8,0xffc8fffa}})do
   for i=0,79 do local a=i/80*math.pi*2;node:drawSegment(point(ring[1],a),point(ring[1],a+math.pi/40),ring[2],D.Color(ring[3]))end
  end
  for arm=0,4 do
   local previous
   for i=0,56 do local f=i/56;local r=12+160*f;local a=arm*math.pi*.4+t*1.8-f*4.5;local p=point(r,a)
    if previous then node:drawSegment(previous,p,1+f*2,D.Color(arm%2==0 and 0x9996f7ef or 0x7798d7fa))end;previous=p
   end
  end
  for i=1,16 do local phase=(i/16+t*.32)%1;local r=175*(1-phase);local a=i*2.39+t*1.6;node:drawDot(point(r,a),1+phase*2,D.Color(0xdde3fffb))end
  node:drawDot(D.Vec2.zero,13,D.Color(0xffd3fffa));return false
 end)
 function c:open()self.active=true;node.visible=true end
 function c:dispose()self.active=false;node:removeFromParent()end
 return c
end
return Vortex
