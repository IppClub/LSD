-- Select an unobstructed ray to the requested visible polygon, never a guaranteed
-- hit. Projectile travel and later poses remain authoritative at impact time.
local G=require('Combat.HitGeometry');local Shadow=require('Combat.AimOcclusion');local Range=require('Combat.FirearmRules');local A={}
-- A sampled contour is immutable. Candidate points and containment depend
-- only on that contour, not on the actor, muzzle, facing or weapon range.
local plans=setmetatable({},{__mode='k'})
local function candidatesFor(vertices)
 local plan=plans[vertices];if plan then return plan end
 local center={x=0,y=0};for _,v in ipairs(vertices)do center.x=center.x+v.x;center.y=center.y+v.y end
 center.x=center.x/#vertices;center.y=center.y/#vertices
 plan={center}
 for _,v in ipairs(vertices)do plan[#plan+1]={x=(v.x+center.x)/2,y=(v.y+center.y)/2}end
 plans[vertices]=plan;return plan
end
function A.solve(origin,faceRight,partId,regions,blocked,visibilityReadOnly)
 assert(type(blocked)=='function','Terrain visibility callback required')
 local direction=faceRight and 1 or -1;local best;local tries=0;local reject;local shadowAllowed=true
 for _,part in ipairs(regions)do
  if part.id==partId and part.enabled~=false then
   local candidates=candidatesFor(part.vertices)
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
    if point.inside==nil then point.inside=G.contains(point,part.vertices)end
    if point.inside then
     tries=tries+1
     if shadowAllowed and tries==64 then reject=Shadow.build(origin,regions,partId,Range.travel)end
     local hit=not(reject and reject(point)) and G.nearest(origin,point,regions,partId)or nil
     if hit and not hit.startedInside and hit.part==partId then
      -- Retain proofs only when the caller guarantees a synchronous,
      -- read-only visibility callback; unknown callbacks invalidate the pose.
      if not visibilityReadOnly then reject=nil;shadowAllowed=false;Shadow.invalidate(regions)end
      if not blocked(origin,hit.position)then return {angle=candidate.angle,origin={x=origin.x,y=origin.y},point={x=point.x,y=point.y},intendedPart=partId,distance=candidate.distance},'AIMED'end
     end
    end
   end
  end
 end
 return best,best and 'AIMED' or 'PART_UNREACHABLE'
end
return A
