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
-- Repeated rays from one muzzle only touch edges in their line direction.
-- Index unoriented angles (period pi), so epsilon-accepted negative t contacts
-- remain candidates too. Bucket lists retain original edge order and include
-- neighboring buckets around extended endpoints for conservative boundaries.
local function directionalEdges(plan,dx,dy)
 plan.rayUses=(plan.rayUses or 0)+1
 if #plan<12 or plan.rayUses<4 then return plan,plan.blocks end
 if not plan.rayBuckets then
  local count=64;local step=math.pi/count;local buckets={}
  for i=1,count do buckets[i]={}end
  for _,edge in ipairs(plan)do
   local ax,ay=edge.px-eps*edge.dx,edge.py-eps*edge.dy
   local bx,by=edge.px+(1+eps)*edge.dx,edge.py+(1+eps)*edge.dy
   local angle=math.atan(ay,ax)
   local delta=(math.atan(by,bx)-angle+math.pi)%(2*math.pi)-math.pi
   if delta<0 then angle=angle+delta;delta=-delta end
   local first,last=math.floor(angle/step)-1,math.floor((angle+delta)/step)+1
   if last-first+1>=count or (ax==0 and ay==0) or (bx==0 and by==0) then
    for i=1,count do local bucket=buckets[i];bucket[#bucket+1]=edge end
   else
    for i=first,last do local bucket=buckets[i%count+1];bucket[#bucket+1]=edge end
   end
  end
  for _,bucket in ipairs(buckets)do bucket.blocks={{first=1,last=#bucket}}end
  plan.rayBuckets=buckets
 end
 local bucket=plan.rayBuckets[math.floor((math.atan(dy,dx)%math.pi)/(math.pi/64))%64+1]
 return bucket,bucket.blocks
end
-- One segment is tested against many parts. Share ray arithmetic and keep
-- candidate contacts scalar; allocate position/normal only for the winner.
local function rayFor(a,b)
 local dx,dy=b.x-a.x,b.y-a.y
 return {dx=dx,dy=dy,length=math.sqrt(dx*dx+dy*dy),minX=math.min(a.x,b.x),maxX=math.max(a.x,b.x),minY=math.min(a.y,b.y),maxY=math.max(a.y,b.y),padX=eps*math.abs(dx),padY=eps*math.abs(dy)}
end
local function segment(a,b,vertices,bounds,ray)
 assert(#vertices>=3,'Polygon needs at least three vertices')
 local dx,dy,length=ray.dx,ray.dy,ray.length
 if length<=eps then return nil end
 local plan=edges(vertices)
 -- All candidate rays for one decision share a muzzle and immutable pose.
 -- Cache the origin-dependent edge numerator; direction remains per ray.
 if plan.rayOriginX~=a.x or plan.rayOriginY~=a.y then
  plan.rayOriginX,plan.rayOriginY=a.x,a.y
  plan.rayUses=0;plan.rayBuckets=nil
  for _,edge in ipairs(plan)do
   edge.px,edge.py=edge.a.x-a.x,edge.a.y-a.y
   edge.numerator=cross(edge.px,edge.py,edge.dx,edge.dy)
  end
 end
 if not bounds or (a.x>=bounds.minX-eps and a.x<=bounds.maxX+eps and a.y>=bounds.minY-eps and a.y<=bounds.maxY+eps)then
  -- Candidate rays share a muzzle on this immutable pose. Store coordinates,
  -- not the caller's mutable point object; a different origin recomputes.
  if plan.originX~=a.x or plan.originY~=a.y then
   plan.originInside=inside(a,vertices);plan.originX,plan.originY=a.x,a.y
  end
  if plan.originInside then return 0,-dx/length,-dy/length,true end
 end
 local bestT,bestEX,bestEY
 local minX,maxX,minY,maxY=ray.minX,ray.maxX,ray.minY,ray.maxY
 local rayPadX,rayPadY=ray.padX,ray.padY
 local candidates,blocks=directionalEdges(plan,dx,dy)
 for _,block in ipairs(blocks)do
  local blockPadX,blockPadY=rayPadX+(block.padX or 0),rayPadY+(block.padY or 0)
  if not block.minX or (block.maxX>=minX-blockPadX and block.minX<=maxX+blockPadX and block.maxY>=minY-blockPadY and block.minY<=maxY+blockPadY)then
  for index=block.first,block.last do
  local edge=candidates[index]
  local ex,ey=edge.dx,edge.dy
  -- Parametric tolerances scale with both edge lengths, not world units.
  local padX=rayPadX+edge.padX;local padY=rayPadY+edge.padY
  if edge.maxX>=minX-padX and edge.minX<=maxX+padX and edge.maxY>=minY-padY and edge.minY<=maxY+padY then
  local denom=cross(dx,dy,ex,ey)
  if math.abs(denom)>eps then
   local px,py=edge.px,edge.py
   local t=edge.numerator/denom;local u=cross(px,py,dx,dy)/denom
   if t>=-eps and t<=1+eps and u>=-eps and u<=1+eps and (not bestT or t<bestT)then
    bestT=math.max(0,math.min(1,t));bestEX,bestEY=ex,ey
   end
  end
 end
 end
 end
 end
 return bestT,bestEX,bestEY,false
end
local function contact(a,ray,t,ex,ey,startedInside)
 if t==nil then return nil end
 if startedInside then return {t=0,position={x=a.x,y=a.y},normal={x=ex,y=ey},startedInside=true}end
 local len=math.sqrt(ex*ex+ey*ey);local nx,ny=-ey/len,ex/len
 if nx*ray.dx+ny*ray.dy>0 then nx,ny=-nx,-ny end
 return {t=t,position={x=a.x+t*ray.dx,y=a.y+t*ray.dy},normal={x=nx,y=ny},startedInside=false}
end
function G.segment(a,b,vertices,bounds)
 local ray=rayFor(a,b)
 return contact(a,ray,segment(a,b,vertices,bounds,ray))
end
-- Slab clipping rejects polygons whose boxes overlap the ray's box but
-- never the ray itself. Keep endpoint tolerances for existing grazing hits.
local function intersects(a,b,bounds,ray)
 local lo,hi=0,1
 local vx,vy=ray.dx,ray.dy
 local lower,upper=bounds.minX,bounds.maxX
 local pad=eps*(1+math.abs(vx)+upper-lower);lower=lower-pad;upper=upper+pad
 if math.abs(vx)<1e-30 then if a.x<lower or a.x>upper then return false end
 else
  local x,y=(lower-a.x)/vx,(upper-a.x)/vx;if x>y then x,y=y,x end
  lo=math.max(lo,x);hi=math.min(hi,y);if lo>hi then return false end
 end
 lower,upper=bounds.minY,bounds.maxY
 pad=eps*(1+math.abs(vy)+upper-lower);lower=lower-pad;upper=upper+pad
 if math.abs(vy)<1e-30 then if a.y<lower or a.y>upper then return false end
 else
  local x,y=(lower-a.y)/vy,(upper-a.y)/vy;if x>y then x,y=y,x end
  lo=math.max(lo,x);hi=math.min(hi,y);if lo>hi then return false end
 end
 return lo
end
-- Ties use an explicit occlusion priority, then stable id, never damage value
-- or the order in which a skin happens to enumerate its attachments.
local hints=setmetatable({},{__mode='k'})
function G.nearest(a,b,parts,requiredPart)
 local ray=rayFor(a,b);local bestT,bestEX,bestEY,bestInside,bestPart,bestPriority,bestShape,bestIndex
 -- Re-test the last winning polygon against this ray. Its hit is only an
 -- upper bound: preserve original traversal and all tie priorities. A chain
 -- of N epsilon ties can drift by at most N*eps, so leave that entire margin.
 local limit
 local hintRow=hints[parts]
 local hint=hintRow and parts[hintRow.index]==hintRow.part and hintRow.part
 if hint and hint.enabled~=false then
  local bounds=hint.bounds
  if not bounds or (ray.maxX>=bounds.minX-eps and ray.minX<=bounds.maxX+eps and ray.maxY>=bounds.minY-eps and ray.minY<=bounds.maxY+eps)then
  local entry=hint.bounds and intersects(a,b,hint.bounds,ray) or(not hint.bounds and 0)
  if entry then local t=segment(a,b,hint.vertices,hint.bounds,ray);if t then limit=t+(#parts+1)*eps end end
  end
 end
 -- Optional part selection still respects all occluders. If a verified
 -- different part is in front of every requested piece (including the full
 -- epsilon tie margin), the ordinary nearest hit cannot be the requested id.
 if requiredPart and limit and hint.id~=requiredPart then
  local possible=false
  for _,part in ipairs(parts)do
   if part.id==requiredPart and part.enabled~=false then
    local bounds=part.bounds
    local entry=bounds and intersects(a,b,bounds,ray)or(not bounds and 0)
    if entry and entry<=limit then
     local t=segment(a,b,part.vertices,bounds,ray)
     if t and t<=limit then possible=true;break end
    end
   end
  end
  if not possible then return nil end
 end
 local minX,minY,maxX,maxY=ray.minX,ray.minY,ray.maxX,ray.maxY
 for index,part in ipairs(parts)do
  local bounds=part.bounds
  if part.enabled~=false and (not bounds or (maxX>=bounds.minX-eps and minX<=bounds.maxX+eps and maxY>=bounds.minY-eps and minY<=bounds.maxY+eps))then
   local entry=bounds and intersects(a,b,bounds,ray) or (not bounds and 0)
   if entry and (not limit or entry<=limit) and (not bestT or entry<=bestT+eps)then
    local t,ex,ey,startedInside=segment(a,b,part.vertices,bounds,ray)
    if t then
     local priority=part.priority or 0
     if not bestT or t<bestT-eps or (math.abs(t-bestT)<=eps and (priority>bestPriority or (priority==bestPriority and part.id<bestPart)))then
      bestT,bestEX,bestEY,bestInside,bestPart,bestPriority,bestShape,bestIndex=t,ex,ey,startedInside,part.id,priority,part,index
     end
    end
   end
  end
 end
 if bestShape then hintRow=hintRow or {};hintRow.part=bestShape;hintRow.index=bestIndex;hints[parts]=hintRow else hints[parts]=nil end
 if requiredPart and bestPart~=requiredPart then return nil end
 local best=contact(a,ray,bestT,bestEX,bestEY,bestInside)
 if best then best.part=bestPart;best.priority=bestPriority end
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
