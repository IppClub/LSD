-- World-space protective field: finite capacity, stationary source, no global invulnerability.
local D=require('Dora');local Ward={};Ward.__index=Ward
function Ward.new(parent,x,y,radius,capacity)
 assert(radius>0 and capacity>0)
 local node=D.DrawNode();node.position=D.Vec2(x,y);node.order=-1;node:addTo(parent)
 return setmetatable({node=node,x=x,y=y,radius=radius,capacity=capacity,remaining=capacity,active=false,age=0,absorbed=0,hits=0},Ward)
end
function Ward:open()self.active=true;self.age=0;self.hitAt=nil;self.hitX=nil;self.hitY=nil end
function Ward:close()self.active=false;self.node:clear()end
function Ward:contains(x,y)
 local dx,dy=x-self.x,y-self.y;return dx*dx+dy*dy<=self.radius*self.radius
end
function Ward:protect(amount,x,y)
 assert(type(amount)=='number'and amount>=0 and amount<math.huge)
 if not self.active or self.age<.6 or not self:contains(x,y)then return amount,0 end
 local absorbed=math.min(amount,self.remaining);self.remaining=self.remaining-absorbed
 self.absorbed=self.absorbed+absorbed;if absorbed>0 then self.hits=self.hits+1;self.hitAt=self.age;self.hitX=x-self.x;self.hitY=y-self.y end
 return amount-absorbed,absorbed
end
function Ward:update(dt)
 self.age=self.age+dt;local n=self.node;n:clear();if not self.active or self.remaining<=0 then return end
 local progress=math.min(1,self.age/.6);local radius=self.radius*progress
 local strength=self.remaining/self.capacity
 local hitAge=self.hitAt and self.age-self.hitAt or math.huge
 local flash=math.max(0,1-hitAge/.35)
 local function gold(alpha,rgb)return D.Color(math.floor(math.max(0,math.min(255,alpha)))*0x1000000+(rgb or 0xffd781))end
 -- The ring only changes radius during the 0.6s opening; reuse the vertex
 -- table afterwards instead of rebuilding 96 Vec2s every frame.
 if not self._points or math.abs((self._pointsRadius or -1)-radius)>1e-6 then
  local points={};local count=96
  for i=0,count-1 do local a=i*math.pi*2/count;points[#points+1]=D.Vec2(math.cos(a)*radius,math.sin(a)*radius)end
  self._points=points;self._pointsRadius=radius
 end
 local points=self._points
 -- Keep the exact protection boundary legible; glow fades with capacity, not radius.
 n:drawPolygon(points,gold((5+strength*7+flash*10)*progress))
 n:drawPolygon(points,D.Color(0),7,gold((12+strength*12+flash*50)*progress))
 n:drawPolygon(points,D.Color(0),3,gold((22+strength*30+flash*50)*progress))
 n:drawPolygon(points,D.Color(0),1.2,gold((80+strength*100+flash*50)*progress))
 for i=1,16 do
  local a=i*math.pi/8+self.age*.12;local r=radius*(.88+.035*math.sin(self.age*.8+i))
  n:drawDot(D.Vec2(math.cos(a)*r,math.sin(a)*r),1.2+strength*.8,gold((70+strength*100)*progress))
 end
 -- A short ripple begins at the actual absorbed hit, never at an unrelated actor.
 if flash>0 and self.hitX then
  local r=12+hitAge*150;local origin=D.Vec2(self.hitX,self.hitY)
  for i=0,31 do local a=i*math.pi/16;local b=(i+1)*math.pi/16
   n:drawSegment(origin+D.Vec2(math.cos(a)*r,math.sin(a)*r),origin+D.Vec2(math.cos(b)*r,math.sin(b)*r),1.8,gold(flash*220,0xffefbc))
  end
 end
end
return Ward
