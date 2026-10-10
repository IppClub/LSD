-- Conservative angular shadows. This is a decision-local acceleration only;
-- ambiguous bins always fall back to the original exact nearest query.
local G=require('Combat.HitGeometry')
local M={};local count=64;local step=2*math.pi/count;local eps=1e-8
function M.build(origin,parts,id,range)
 local near,block={},{};local guard=(#parts+4)*eps*range*4
 for i=1,count do near[i]=math.huge;block[i]=math.huge end
 for _,part in ipairs(parts)do if part.enabled~=false then
  local target=part.id==id
  if target and G.contains(origin,part.vertices)then return nil end
  for j,a in ipairs(part.vertices)do
   local b=part.vertices[j%#part.vertices+1]
   local dx,dy=b.x-a.x,b.y-a.y
   local ax,ay=a.x-origin.x,a.y-origin.y
   local bx,by=b.x-origin.x,b.y-origin.y
   guard=math.max(guard,(math.abs(a.x)+math.abs(a.y)+math.abs(origin.x)+math.abs(origin.y))*1e-12)
   -- Expand target edges to include epsilon-accepted edge parameters.
   if target then ax=ax-eps*dx;ay=ay-eps*dy;bx=bx+eps*dx;by=by+eps*dy end
   local angle=math.atan(ay,ax)
   local delta=(math.atan(by,bx)-angle+math.pi)%(2*math.pi)-math.pi
   if delta<0 then angle=angle+delta;delta=-delta end
   if target then
    local ex,ey=bx-ax,by-ay;local length=ex*ex+ey*ey
    local t=length>0 and math.max(0,math.min(1,-(ax*ex+ay*ey)/length))or 0
    local x,y=ax+t*ex,ay+t*ey;local distance=math.sqrt(x*x+y*y)
    local first,last=math.floor(angle/step)-1,math.floor((angle+delta)/step)+1
    if distance<=guard or last-first+1>=count then first,last=0,count-1;distance=0 end
    for k=first,last do local bin=k%count+1;near[bin]=math.min(near[bin],distance)end
   else
    -- Use only bins strictly inside a segment's angular coverage. Endpoint
    -- maxima bound every intersection distance on the segment.
    local first,last=math.floor(angle/step)+1,math.floor((angle+delta)/step)-1
    local distance=math.max(math.sqrt(ax*ax+ay*ay),math.sqrt(bx*bx+by*by))
    if delta<math.pi-1e-6 and distance>guard then
     for k=first,last do local bin=k%count+1;block[bin]=math.min(block[bin],distance)end
    end
   end
  end
 end end
 local rejected={};local any=false
 for i=1,count do
  if near[i]<math.huge and block[i]+guard<near[i]then rejected[i]=block[i]+guard;any=true end
 end
 if not any then return nil end
 return function(point)
  local dx,dy=point.x-origin.x,point.y-origin.y
  local bin=math.floor((math.atan(dy,dx)%(2*math.pi))/step)%count+1
  local limit=rejected[bin]
  return limit and dx*dx+dy*dy>limit*limit or false
 end
end
return M
