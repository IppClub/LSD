-- Sweep a point projectile through current world-space part polygons. The host
-- supplies animated vertices; this is not a substitute for moving-shape CCD.
local G={};local eps=1e-8
local function cross(x,y,u,v)return x*v-y*u end
local function onEdge(p,a,b)
 return math.abs(cross(p.x-a.x,p.y-a.y,b.x-a.x,b.y-a.y))<=eps and p.x>=math.min(a.x,b.x)-eps and p.x<=math.max(a.x,b.x)+eps and p.y>=math.min(a.y,b.y)-eps and p.y<=math.max(a.y,b.y)+eps
end
local function inside(p,vertices)
 local yes=false
 for i,a in ipairs(vertices)do
  local b=vertices[i%#vertices+1]
  if onEdge(p,a,b)then return true end
  if (a.y>p.y)~=(b.y>p.y) and p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x then yes=not yes end
 end
 return yes
end
G.contains=inside
function G.segment(a,b,vertices,bounds)
 assert(#vertices>=3,'Polygon needs at least three vertices')
 local dx,dy=b.x-a.x,b.y-a.y;local length=math.sqrt(dx*dx+dy*dy)
 if length<=eps then return nil end
 if (not bounds or (a.x>=bounds.minX-eps and a.x<=bounds.maxX+eps and a.y>=bounds.minY-eps and a.y<=bounds.maxY+eps)) and inside(a,vertices)then return {t=0,position={x=a.x,y=a.y},normal={x=-dx/length,y=-dy/length},startedInside=true}end
 local best
 for i,p in ipairs(vertices)do
  local q=vertices[i%#vertices+1];local ex,ey=q.x-p.x,q.y-p.y
  local denom=cross(dx,dy,ex,ey)
  if math.abs(denom)>eps then
   local px,py=p.x-a.x,p.y-a.y
   local t=cross(px,py,ex,ey)/denom;local u=cross(px,py,dx,dy)/denom
   if t>=-eps and t<=1+eps and u>=-eps and u<=1+eps and (not best or t<best.t)then
    t=math.max(0,math.min(1,t));local len=math.sqrt(ex*ex+ey*ey);local nx,ny=-ey/len,ex/len
    if nx*dx+ny*dy>0 then nx,ny=-nx,-ny end
    best={t=t,position={x=a.x+t*dx,y=a.y+t*dy},normal={x=nx,y=ny},startedInside=false}
   end
  end
 end
 return best
end
-- Ties use an explicit occlusion priority, then stable id, never damage value
-- or the order in which a skin happens to enumerate its attachments.
function G.nearest(a,b,parts)
 local best
 local minX,minY,maxX,maxY=math.min(a.x,b.x),math.min(a.y,b.y),math.max(a.x,b.x),math.max(a.y,b.y)
 for _,part in ipairs(parts)do
  local bounds=part.bounds
  if part.enabled~=false and (not bounds or (maxX>=bounds.minX-eps and minX<=bounds.maxX+eps and maxY>=bounds.minY-eps and minY<=bounds.maxY+eps))then
   local h=G.segment(a,b,part.vertices,part.bounds)
   if h then
    h.part=part.id;h.priority=part.priority or 0
    if not best or h.t<best.t-eps or (math.abs(h.t-best.t)<=eps and (h.priority>best.priority or (h.priority==best.priority and h.part<best.part)))then best=h end
   end
  end
 end
 return best
end
-- Closest point on the union of enabled polygons; zero when already inside.
function G.distance(point,parts)
 local best
 for _,part in ipairs(parts)do if part.enabled~=false then
  if inside(point,part.vertices)then return {distance=0,position={x=point.x,y=point.y},part=part.id,inside=true}end
  for i,a in ipairs(part.vertices)do
   local b=part.vertices[i%#part.vertices+1];local dx,dy=b.x-a.x,b.y-a.y
   local length2=dx*dx+dy*dy
   local t=length2>0 and math.max(0,math.min(1,((point.x-a.x)*dx+(point.y-a.y)*dy)/length2))or 0
   local x,y=a.x+t*dx,a.y+t*dy;local distance2=(point.x-x)^2+(point.y-y)^2
   if not best or distance2<best.distance2 then best={distance2=distance2,position={x=x,y=y},part=part.id,inside=false}end
  end
 end end
 if best then best.distance=math.sqrt(best.distance2);best.distance2=nil end
 return best
end
return G
