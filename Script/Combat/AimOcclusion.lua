-- Conservative shadows shared by an immutable pose and muzzle. Ambiguous
-- directions retain exact nearest queries; external callbacks invalidate plans.
local G=require('Combat.HitGeometry');local M={}
local count=64;local step=2*math.pi/count;local eps=1e-8
local cache=setmetatable({},{__mode='k'})
local function finite(v)return type(v)=='number' and v==v and math.abs(v)<math.huge end
function M.invalidate(parts)cache[parts]=nil end
local function matches(plan,origin,parts,range)
 if not plan or plan.x~=origin.x or plan.y~=origin.y or plan.range~=range or #plan.rows~=#parts then return false end
 for i,part in ipairs(parts)do
  local row=plan.rows[i];local b=part.bounds
  if row.part~=part or row.id~=part.id or row.vertices~=part.vertices or row.enabled~=part.enabled or row.bounds~=b then return false end
  if b and (row.minX~=b.minX or row.maxX~=b.maxX or row.minY~=b.minY or row.maxY~=b.maxY)then return false end
 end
 return true
end
local function span(ax,ay,bx,by)
 local angle=math.atan(ay,ax);local delta=(math.atan(by,bx)-angle+math.pi)%(2*math.pi)-math.pi
 if delta<0 then angle=angle+delta;delta=-delta end
 return angle,delta
end
local function prepare(origin,parts,range)
 local plan={x=origin.x,y=origin.y,range=range,rows={},groups={},guard=(#parts+4)*eps*range*4}
 for i,part in ipairs(parts)do
  local box=part.bounds
  plan.rows[i]={part=part,id=part.id,vertices=part.vertices,enabled=part.enabled,bounds=box,minX=box and box.minX,maxX=box and box.maxX,minY=box and box.minY,maxY=box and box.maxY}
  if part.enabled~=false then
   if box and not(finite(box.minX)and finite(box.maxX)and finite(box.minY)and finite(box.maxY))then return nil end
   for _,v in ipairs(part.vertices)do
    if not finite(v.x)or not finite(v.y)then return nil end
    if box and(v.x<box.minX or v.x>box.maxX or v.y<box.minY or v.y>box.maxY)then return nil end
    plan.guard=math.max(plan.guard,(math.abs(v.x)+math.abs(v.y)+math.abs(origin.x)+math.abs(origin.y))*1e-12)
   end
  end
 end
 for _,part in ipairs(parts)do if part.enabled~=false then
  local group=plan.groups[part.id]
  if not group then
   group={pieces={},block={}};plan.groups[part.id]=group
   for i=1,count do group.block[i]=math.huge end
  end
  group.pieces[#group.pieces+1]=part
  for j,a in ipairs(part.vertices)do
   local b=part.vertices[j%#part.vertices+1];local dx,dy=b.x-a.x,b.y-a.y
   local ax,ay,bx,by=a.x-origin.x,a.y-origin.y,b.x-origin.x,b.y-origin.y
   local angle,delta=span(ax,ay,bx,by)
   local far=math.max(math.sqrt(ax*ax+ay*ay),math.sqrt(bx*bx+by*by))
   if delta<math.pi-1e-6 and far>plan.guard and math.abs(ax*by-ay*bx)>eps*4 then
    for k=math.floor(angle/step)+1,math.floor((angle+delta)/step)-1 do
     local bin=k%count+1;group.block[bin]=math.min(group.block[bin],far)
    end
   end

  end
 end end
 cache[parts]=plan;return plan
end
local function targetNear(plan,group,origin)
 group.near={};for i=1,count do group.near[i]=math.huge end
 for _,part in ipairs(group.pieces)do
  local box=part.bounds
  if not box or (origin.x>=box.minX-eps and origin.x<=box.maxX+eps and origin.y>=box.minY-eps and origin.y<=box.maxY+eps)then
   if G.contains(origin,part.vertices)then group.inside=true;return end
  end
  for j,a in ipairs(part.vertices)do
   local b=part.vertices[j%#part.vertices+1];local dx,dy=b.x-a.x,b.y-a.y
   local ax,ay,bx,by=a.x-origin.x,a.y-origin.y,b.x-origin.x,b.y-origin.y
   -- Near bounds include epsilon-accepted edge parameters. Blocker bounds
   -- above use only strict interior angles of the original segment.
   ax=ax-eps*dx;ay=ay-eps*dy;bx=bx+eps*dx;by=by+eps*dy
   local angle,delta=span(ax,ay,bx,by)
   local ex,ey=bx-ax,by-ay;local length=ex*ex+ey*ey
   local t=length>0 and math.max(0,math.min(1,-(ax*ex+ay*ey)/length))or 0
   local x,y=ax+t*ex,ay+t*ey;local distance=math.sqrt(x*x+y*y)
   local first,last=math.floor(angle/step)-1,math.floor((angle+delta)/step)+1
   if distance<=plan.guard or last-first+1>=count then first,last=0,count-1;distance=0 end
   for k=first,last do local bin=k%count+1;group.near[bin]=math.min(group.near[bin],distance)end
  end
 end
end
function M.build(origin,parts,id,range)
 if not finite(range)or range<=0 or not finite(origin.x)or not finite(origin.y)then return nil end
 local plan=cache[parts]
 if not matches(plan,origin,parts,range)then plan=prepare(origin,parts,range)end
 if not plan then return nil end
 local group=plan.groups[id];if not group then return nil end
 if not group.near then targetNear(plan,group,origin)end
 if group.inside then return nil end
 if group.proof~=nil then return group.proof or nil end
 local rejected={};local any=false
 for i=1,count do
  local bound=math.huge
  for other,g in pairs(plan.groups)do if other~=id then bound=math.min(bound,g.block[i])end end
  if group.near[i]<math.huge and bound+plan.guard<group.near[i]then rejected[i]=bound+plan.guard;any=true end
 end
 if not any then group.proof=false;return nil end
 local ox,oy=origin.x,origin.y
 group.proof=function(point)
  local dx,dy=point.x-ox,point.y-oy;local distance2=dx*dx+dy*dy
  if distance2>range*range then return false end
  local limit=rejected[math.floor((math.atan(dy,dx)%(2*math.pi))/step)%count+1]
  return limit and distance2>limit*limit or false
 end
 return group.proof
end
return M
