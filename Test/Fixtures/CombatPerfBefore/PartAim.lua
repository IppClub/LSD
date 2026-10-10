-- Select an unobstructed ray to the requested visible polygon, never a guaranteed
-- hit. Projectile travel and later poses remain authoritative at impact time.
local G=require('Combat.HitGeometry');local A={}
function A.solve(origin,faceRight,partId,regions,blocked)
 assert(type(blocked)=='function','Terrain visibility callback required')
 local direction=faceRight and 1 or -1;local best
 for _,part in ipairs(regions)do
  if part.id==partId and part.enabled~=false then
   local center={x=0,y=0};for _,v in ipairs(part.vertices)do center.x=center.x+v.x;center.y=center.y+v.y end
   center.x=center.x/#part.vertices;center.y=center.y/#part.vertices
   local candidates={center}
   for _,v in ipairs(part.vertices)do candidates[#candidates+1]={x=(v.x+center.x)/2,y=(v.y+center.y)/2}end
   for _,point in ipairs(candidates)do
    local dx,dy=point.x-origin.x,point.y-origin.y;local forward=dx*direction
    local distance=math.sqrt(dx*dx+dy*dy)
    if forward>0 and distance<=2400 and math.abs(dy)<=forward and G.contains(point,part.vertices)then
     local hit=G.nearest(origin,point,regions)
     if hit and not hit.startedInside and hit.part==partId and not blocked(origin,hit.position)then
      local angle=-math.deg(math.atan(dy,forward))
      if not best or math.abs(angle)<math.abs(best.angle)then best={angle=angle,origin={x=origin.x,y=origin.y},point={x=point.x,y=point.y},intendedPart=partId,distance=distance}end
     end
    end
   end
  end
 end
 return best,best and 'AIMED' or 'PART_UNREACHABLE'
end
return A
