-- Small original vector props, animated in the existing OuterHeaven world.
local D=require('Dora');local Art={}
local function ellipse(n,x,y,rx,ry,c)
 local points={};for i=0,31 do local a=i*math.pi/16;points[#points+1]=D.Vec2(x+math.cos(a)*rx,y+math.sin(a)*ry) end
 n:drawPolygon(points,D.Color(c))
end
function Art.create(world)
 local a={};local function prop(x,order) local n=D.DrawNode();n.order=order or 0;n.position=D.Vec2(x,world.offset);n:addTo(world);return n end
 a.pond=prop(3600);ellipse(a.pond,0,5,260,65,0xff739c79);ellipse(a.pond,0,12,235,55,0xff58b8c0);ellipse(a.pond,0,16,210,40,0xff81d4cd)
 for i=1,8 do local x=-250+i*57;a.pond:drawSegment(D.Vec2(x,-38),D.Vec2(x+9,21+(i%3)*10),3,D.Color(0xff54845c)) end
 a.fishes={}
 for i=1,3 do
  local n=prop(3600);ellipse(n,0,0,25,10,0xfff4bb6a);ellipse(n,-4,2,19,7,0xffffdc93)
  n:drawPolygon({D.Vec2(18,0),D.Vec2(34,12),D.Vec2(31,-11)},D.Color(0xffd98655));n:drawDot(D.Vec2(-16,3),2.5,D.Color(0xff344956))
  a.fishes[i]=n
 end
 a.plots={};for i=1,3 do a.plots[i]=prop(4820+(i-2)*150) end
 a.peaches={};for i=1,3 do
  local n=prop(6300+(i-2)*200,-10);n:drawSegment(D.Vec2(0,0),D.Vec2(-12,195),15,D.Color(0xff735c4c))
  for j=1,5 do local bx=-140+j*47;local by=155+(j%2)*65;n:drawSegment(D.Vec2(-10,95),D.Vec2(bx,by),7,D.Color(0xff856a59));ellipse(n,bx,by,62,39,0xccd997ba);ellipse(n,bx-8,by+6,43,28,0xccf2b7d0)
   for k=1,8 do local t=k*2.4;local px=bx+math.sin(t)*45;local py=by+math.cos(t)*22;for q=0,4 do local angle=q*math.pi/2.5;n:drawDot(D.Vec2(px+math.cos(angle)*5,py+math.sin(angle)*5),4,D.Color(0xffffd9e5)) end;n:drawDot(D.Vec2(px,py),2,D.Color(0xfff2cc87)) end
  end
  a.peaches[i]=n
 end
 a.coop=prop(7600)
 for i=0,5 do a.coop:drawSegment(D.Vec2(-180+i*65,0),D.Vec2(-180+i*65,75),7,D.Color(0xffb99a72)) end
 a.coop:drawSegment(D.Vec2(-200,30),D.Vec2(170,30),6,D.Color(0xffd1bb8b));a.coop:drawSegment(D.Vec2(-200,60),D.Vec2(170,60),6,D.Color(0xffd1bb8b))
 a.chickens={}
 for i=1,2 do
  local n=prop(7980+i*100);ellipse(n,0,37,27,29,0xfff6ecd6);ellipse(n,3,40,21,24,0xfffff8e9);ellipse(n,-11,36,14,20,0xffd9cbbb)
  ellipse(n,17,64,16,18,0xfff6ecd6);n:drawPolygon({D.Vec2(29,63),D.Vec2(44,58),D.Vec2(29,54)},D.Color(0xffefbf65));n:drawDot(D.Vec2(21,68),3,D.Color(0xff39455b))
  for j=0,2 do n:drawDot(D.Vec2(10+j*6,83),5,D.Color(0xffdc757b)) end
  n:drawPolygon({D.Vec2(-17,35),D.Vec2(-46,65),D.Vec2(-44,31)},D.Color(0xff89899b))
  for j=-1,1,2 do n:drawSegment(D.Vec2(j*10,15),D.Vec2(j*12,0),3,D.Color(0xffc69a56));n:drawSegment(D.Vec2(j*12,0),D.Vec2(j*12+10,0),3,D.Color(0xffc69a56)) end
  a.chickens[i]=n
 end
 a.language=prop(9500);ellipse(a.language,0,0,140,30,0x557eaf88)
 return a
end
function Art.crop(n,stage,growth)
 n:clear();ellipse(n,0,0,65,20,0xff8b745c);ellipse(n,0,4,56,14,0xffa08c67)
 for i=-2,2 do n:drawSegment(D.Vec2(-40,i*5+4),D.Vec2(40,i*5+4),1,D.Color(0xff6f624f)) end
 if stage==1 then for i=-1,1 do n:drawDot(D.Vec2(i*25,5),3,D.Color(0xffe3c486)) end end
 if stage==2 then for i=-1,1 do local h=18+math.max(0,math.min(1,growth))*45;n:drawSegment(D.Vec2(i*25,5),D.Vec2(i*25,h),3,D.Color(0xff749857));ellipse(n,i*25-8,h*.65,12,5,0xff99bd70);ellipse(n,i*25+8,h*.8,12,5,0xffb2cd7d);if growth>=1 then ellipse(n,i*25,h,8,14,0xffe0c17b) end end end
end
return Art
