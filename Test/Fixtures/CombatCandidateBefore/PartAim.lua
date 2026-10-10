-- Select an unobstructed ray to the requested visible polygon, never a guaranteed
-- hit. Projectile travel and later poses remain authoritative at impact time.
local G=require('Combat.HitGeometry');local Range=require('Combat.FirearmRules');local A={}
function A.solve(origin,faceRight,partId,regions,blocked)
 assert(type(blocked)=='function','Terrain visibility callback required')
 local direction=faceRight and 1 or -1;local best
 for _,part in ipairs(regions)do
  if part.id==partId and part.enabled~=false then
   local center={x=0,y=0};for _,v in ipairs(part.vertices)do center.x=center.x+v.x;center.y=center.y+v.y end
   center.x=center.x/#part.vertices;center.y=center.y/#part.vertices
   local candidates={center}
   for _,v in ipairs(part.vertices)do candidates[#candidates+1]={x=(v.x+center.x)/2,y=(v.y+center.y)/2}end
   -- Visit candidates in exactly the original preference order: smallest
   -- absolute angle, then original index. The first clear ray is the old best.
   local ordered={}
   for index,point in ipairs(candidates)do
    local dx,dy=point.x-origin.x,point.y-origin.y;local forward=dx*direction
    local distance=math.sqrt(dx*dx+dy*dy)
    if forward>0 and distance<=Range.travel and math.abs(dy)<=forward then
     local angle=-math.deg(math.atan(dy,forward))
     ordered[#ordered+1]={point=point,angle=angle,distance=distance,index=index}
    end
   end
   table.sort(ordered,function(a,b)local aa,bb=math.abs(a.angle),math.abs(b.angle);if aa==bb then return a.index<b.index end;return aa<bb end)
   for _,candidate in ipairs(ordered)do
    local point=candidate.point
    if G.contains(point,part.vertices)then
     local hit=G.nearest(origin,point,regions)
     if hit and not hit.startedInside and hit.part==partId and not blocked(origin,hit.position)then
      return {angle=candidate.angle,origin={x=origin.x,y=origin.y},point={x=point.x,y=point.y},intendedPart=partId,distance=candidate.distance},'AIMED'
     end
    end
   end
  end
 end
 return best,best and 'AIMED' or 'PART_UNREACHABLE'
end
return A
