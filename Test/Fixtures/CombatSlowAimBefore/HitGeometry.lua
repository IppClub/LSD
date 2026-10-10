-- Sweep a point projectile through current world-space part polygons. The host
-- supplies animated vertices; this is not a substitute for moving-shape CCD.
local G={};local eps=1e-8
local function cross(x,y,u,v)return x*v-y*u end
-- Animated samples are immutable snapshots. Weak keys discard edge plans with
-- their pose, while repeated candidate rays share the same computed bounds.
local plans=setmetatable({},{__mode='k'})
local function edges(vertices)
 local plan=plans[vertices];if plan then return plan end
 plan={}
 for i,a in ipairs(vertices)do
  local b=vertices[i%#vertices+1]
  plan[i]={a=a,b=b,dx=b.x-a.x,dy=b.y-a.y,padX=eps*math.abs(b.x-a.x),padY=eps*math.abs(b.y-a.y),minX=math.min(a.x,b.x),maxX=math.max(a.x,b.x),minY=math.min(a.y,b.y),maxY=math.max(a.y,b.y)}
 end
 -- Consecutive contour edges usually occupy a small area. Keep their order
 -- for exact tie handling while rejecting whole blocks before edge tests.
 local blocks={}
 for first=1,#plan,8 do
  local block={first=first,last=math.min(first+7,#plan),minX=math.huge,minY=math.huge,maxX=-math.huge,maxY=-math.huge,padX=0,padY=0}
  for i=first,block.last do local e=plan[i]
   block.minX=math.min(block.minX,e.minX);block.maxX=math.max(block.maxX,e.maxX)
   block.minY=math.min(block.minY,e.minY);block.maxY=math.max(block.maxY,e.maxY)
   block.padX=math.max(block.padX,e.padX);block.padY=math.max(block.padY,e.padY)
  end
  blocks[#blocks+1]=block
 end
 plan.blocks=blocks
 plans[vertices]=plan;return plan
end
local function containmentEdges(point,vertices)
 local plan=edges(vertices)
 if #plan<24 then return plan end
 if not plan.buckets then
  local lower,upper=math.huge,-math.huge
  for _,edge in ipairs(plan)do lower=math.min(lower,edge.minY-eps);upper=math.max(upper,edge.maxY+eps)end
  local count=math.min(64,math.ceil(math.sqrt(#plan)))
  plan.lower,plan.upper,plan.count=lower,upper,count
  plan.step=math.max((upper-lower)/count,eps)
  local buckets={};for i=1,count do buckets[i]={}end
  -- Insert in original edge order; the parity and boundary rules stay exact.
  for _,edge in ipairs(plan)do
   local first=math.max(1,math.min(count,math.floor((edge.minY-eps-lower)/plan.step)+1))
   local last=math.max(1,math.min(count,math.floor((edge.maxY+eps-lower)/plan.step)+1))
   for i=first,last do local bucket=buckets[i];bucket[#bucket+1]=edge end
  end
  plan.buckets=buckets
 end
 if point.y<plan.lower or point.y>plan.upper then return nil end
 return plan.buckets[math.max(1,math.min(plan.count,math.floor((point.y-plan.lower)/plan.step)+1))]
end
local function inside(p,vertices)
 local candidates=containmentEdges(p,vertices);if not candidates then return false end
 local yes=false
 for _,e in ipairs(candidates)do
  local a,b=e.a,e.b
  if p.y>=e.minY-eps and p.y<=e.maxY+eps and p.x>=e.minX-eps and p.x<=e.maxX+eps and math.abs(cross(p.x-a.x,p.y-a.y,e.dx,e.dy))<=eps then return true end
  if (a.y>p.y)~=(b.y>p.y) and p.x<e.dx*(p.y-a.y)/e.dy+a.x then yes=not yes end
 end
 return yes
end
G.contains=inside
function G.segment(a,b,vertices,bounds)
 assert(#vertices>=3,'Polygon needs at least three vertices')
 local dx,dy=b.x-a.x,b.y-a.y;local length=math.sqrt(dx*dx+dy*dy)
 if length<=eps then return nil end
 local plan=edges(vertices)
 if not bounds or (a.x>=bounds.minX-eps and a.x<=bounds.maxX+eps and a.y>=bounds.minY-eps and a.y<=bounds.maxY+eps)then
  -- Candidate rays share a muzzle on this immutable pose. Store coordinates,
  -- not the caller's mutable point object; a different origin recomputes.
  if plan.originX~=a.x or plan.originY~=a.y then
   plan.originInside=inside(a,vertices);plan.originX,plan.originY=a.x,a.y
  end
  if plan.originInside then return {t=0,position={x=a.x,y=a.y},normal={x=-dx/length,y=-dy/length},startedInside=true}end
 end
 local best
 local minX,maxX=math.min(a.x,b.x),math.max(a.x,b.x)
 local minY,maxY=math.min(a.y,b.y),math.max(a.y,b.y)
 local rayPadX,rayPadY=eps*math.abs(dx),eps*math.abs(dy)
 for _,block in ipairs(plan.blocks)do
  local blockPadX,blockPadY=rayPadX+block.padX,rayPadY+block.padY
  if block.maxX>=minX-blockPadX and block.minX<=maxX+blockPadX and block.maxY>=minY-blockPadY and block.minY<=maxY+blockPadY then
  for index=block.first,block.last do
  local edge=plan[index]
  local p=edge.a;local ex,ey=edge.dx,edge.dy
  -- Parametric tolerances scale with both edge lengths, not world units.
  local padX=rayPadX+edge.padX;local padY=rayPadY+edge.padY
  if edge.maxX>=minX-padX and edge.minX<=maxX+padX and edge.maxY>=minY-padY and edge.minY<=maxY+padY then
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
 end
 end
 end
 return best
end
-- Slab clipping rejects polygons whose boxes overlap the ray's box but
-- never the ray itself. Keep endpoint tolerances for existing grazing hits.
local axes={'x','y'}
local function intersects(a,b,bounds)
 local lo,hi=0,1
 for _,axis in ipairs(axes)do
  local v=b[axis]-a[axis];local lower=axis=='x' and bounds.minX or bounds.minY;local upper=axis=='x' and bounds.maxX or bounds.maxY
  local pad=eps*(1+math.abs(v)+upper-lower);lower=lower-pad;upper=upper+pad
  if math.abs(v)<1e-30 then if a[axis]<lower or a[axis]>upper then return false end
  else
   local x,y=(lower-a[axis])/v,(upper-a[axis])/v;if x>y then x,y=y,x end
   lo=math.max(lo,x);hi=math.min(hi,y);if lo>hi then return false end
  end
 end
 return lo
end
-- Ties use an explicit occlusion priority, then stable id, never damage value
-- or the order in which a skin happens to enumerate its attachments.
function G.nearest(a,b,parts)
 local best
 local minX,minY,maxX,maxY=math.min(a.x,b.x),math.min(a.y,b.y),math.max(a.x,b.x),math.max(a.y,b.y)
 for _,part in ipairs(parts)do
  local bounds=part.bounds
  if part.enabled~=false and (not bounds or (maxX>=bounds.minX-eps and minX<=bounds.maxX+eps and maxY>=bounds.minY-eps and minY<=bounds.maxY+eps))then
   local entry=bounds and intersects(a,b,bounds) or (not bounds and 0)
   if entry and (not best or entry<=best.t+eps)then
   local h=G.segment(a,b,part.vertices,part.bounds)
   if h then
    h.part=part.id;h.priority=part.priority or 0
    if not best or h.t<best.t-eps or (math.abs(h.t-best.t)<=eps and (h.priority>best.priority or (h.priority==best.priority and h.part<best.part)))then best=h end
   end
  end
 end
 end
 return best
end
-- Closest point on the union of enabled polygons; zero when already inside.
local function boxDistance2(point,box)
 local dx=math.max(box.minX-point.x,0,point.x-box.maxX)
 local dy=math.max(box.minY-point.y,0,point.y-box.maxY)
 return dx*dx+dy*dy
end
function G.distance(point,parts)
 local best
 for _,part in ipairs(parts)do if part.enabled~=false then
  local bounds=part.bounds
  -- Containment still precedes distance pruning: overlapping polygons retain
  -- their original identity, including epsilon-tolerant boundary points.
  local mayContain=not bounds or (point.x>=bounds.minX-eps and point.x<=bounds.maxX+eps and point.y>=bounds.minY-eps and point.y<=bounds.maxY+eps)
  if mayContain and inside(point,part.vertices)then return {distance=0,position={x=point.x,y=point.y},part=part.id,inside=true}end
  if not best or not bounds or boxDistance2(point,bounds)<=best.distance2 then
   for _,edge in ipairs(edges(part.vertices))do
    if not best or boxDistance2(point,edge)<=best.distance2 then
     local a=edge.a;local dx,dy=edge.dx,edge.dy
     local length2=dx*dx+dy*dy
     local t=length2>0 and math.max(0,math.min(1,((point.x-a.x)*dx+(point.y-a.y)*dy)/length2))or 0
     local x,y=a.x+t*dx,a.y+t*dy;local distance2=(point.x-x)^2+(point.y-y)^2
     if not best or distance2<best.distance2 then best={distance2=distance2,position={x=x,y=y},part=part.id,inside=false}end
    end
   end
  end
 end end
 if best then best.distance=math.sqrt(best.distance2);best.distance2=nil end
 return best
end

return G
