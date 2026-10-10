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
function G.segment(a,b,vertices)
 assert(#vertices>=3,'Polygon needs at least three vertices')
 local dx,dy=b.x-a.x,b.y-a.y;local length=math.sqrt(dx*dx+dy*dy)
 if length<=eps then return nil end
 if inside(a,vertices)then return {t=0,position={x=a.x,y=a.y},normal={x=-dx/length,y=-dy/length},startedInside=true}end
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
 for _,part in ipairs(parts)do
  if part.enabled~=false then
   local h=G.segment(a,b,part.vertices)
   if h then
    h.part=part.id;h.priority=part.priority or 0
    if not best or h.t<best.t-eps or (math.abs(h.t-best.t)<=eps and (h.priority>best.priority or (h.priority==best.priority and h.part<best.part)))then best=h end
   end
  end
 end
 return best
end
return G
