-- Select an unobstructed ray to the requested visible polygon, never a guaranteed
-- hit. Projectile travel and later poses remain authoritative at impact time.
local G=require('Combat.HitGeometry');local Range=require('Combat.FirearmRules');local A={}
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
-- Only build the extra contour candidates if the existing interior choices
-- fail. Visible edge windows can remain shootable while the centre is covered.
local function edgeCandidates(vertices,plan)
 if plan.edges then return plan.edges end
 local centre=plan[1];local points={}
 for i,v in ipairs(vertices)do
  local nextVertex=vertices[i%#vertices+1]
  for _,t in ipairs({0,.25,.5,.75})do
   local x=v.x+(nextVertex.x-v.x)*t;local y=v.y+(nextVertex.y-v.y)*t
   points[#points+1]={x=x+(centre.x-x)*.02,y=y+(centre.y-y)*.02}
  end
 end
 plan.edges=points;return points
end
function A.solve(origin,faceRight,partId,regions,blocked,preferCenter,preblocked,originAtAngle)
 assert(type(blocked)=='function','Terrain visibility callback required')
 local direction=faceRight and 1 or -1;local best
 for _,part in ipairs(regions)do
  if part.id==partId and part.enabled~=false then
   local primary=candidatesFor(part.vertices)
   for pass=1,2 do
   local candidates=pass==1 and primary or edgeCandidates(part.vertices,primary)
   -- Keep the default minimum-angle ordering. Boss aiming may prefer the
   -- interior point to avoid repeatedly grazing an adjacent moving body part.
   local ordered={}
   for index,point in ipairs(candidates)do
    local dx,dy=point.x-origin.x,point.y-origin.y;local forward=dx*direction
    local distance=math.sqrt(dx*dx+dy*dy)
    if forward>0 and distance<=Range.travel and math.abs(dy)<=forward then
     local angle=-math.deg(math.atan(dy,forward))
     ordered[#ordered+1]={point=point,angle=angle,distance=distance,index=index+(pass==2 and #primary or 0)}
    end
   end
   table.sort(ordered,function(a,b)if preferCenter and (a.index==1 or b.index==1)and a.index~=b.index then return a.index==1 end;local aa,bb=math.abs(a.angle),math.abs(b.angle);if aa==bb then return a.index<b.index end;return aa<bb end)
   for _,candidate in ipairs(ordered)do
    local point=candidate.point
    local from=origin
    if originAtAngle then
     local angle=candidate.angle
     for iteration=1,8 do
      from=originAtAngle(angle)
      local dx=(point.x-from.x)*direction;local dy=point.y-from.y
      if dx<=0 then from=nil;break end
      local nextAngle=-math.deg(math.atan(dy,dx))
      if math.abs(nextAngle)>45 then from=nil;break end
      local difference=math.abs(nextAngle-angle);angle=nextAngle
      if difference<1e-5 then break end
     end
     if from then from=originAtAngle(angle);candidate.angle=angle;candidate.distance=math.sqrt((point.x-from.x)^2+(point.y-from.y)^2);if candidate.distance>Range.travel then from=nil end end
    end
    if from and point.inside==nil then point.inside=G.contains(point,part.vertices)end
    if from and point.inside and not (preblocked and preblocked(from,point,part))then
     local hit=G.nearest(from,point,regions,partId)
     if hit and not hit.startedInside and hit.part==partId and not blocked(from,hit.position)then
      return {angle=candidate.angle,origin={x=from.x,y=from.y},point={x=point.x,y=point.y},intendedPart=partId,distance=candidate.distance},'AIMED'
     end
    end
   end
   end
   -- The legal cone can cut a visible polygon below every sampled interior
   -- point. Check its two actual boundary rays from the angle-dependent muzzle.
   for _,angle in ipairs({-44.999,44.999,-45,45})do
    local from=originAtAngle and originAtAngle(angle)or origin
    local radians=math.rad(angle)
    local to={x=from.x+direction*math.cos(radians)*Range.travel,y=from.y-math.sin(radians)*Range.travel}
    local hit=G.nearest(from,to,regions,partId)
    if hit and not hit.startedInside and hit.part==partId and not blocked(from,hit.position)then
     -- Commit an interior point, not the exact contact boundary. Rebuilding
     -- the emitted ray from its actual muzzle must not turn rounding into a miss.
     for _,inset in ipairs({2,1,.5,.1})do
      local point={x=hit.position.x+direction*math.cos(radians)*inset,y=hit.position.y-math.sin(radians)*inset}
      local dx=point.x-from.x;local dy=point.y-from.y;local distance=math.sqrt(dx*dx+dy*dy)
      if distance<=Range.travel and G.contains(point,part.vertices)then
       return {angle=angle,origin={x=from.x,y=from.y},point=point,intendedPart=partId,distance=distance},'AIMED'
      end
     end
    end
   end
  end
 end
 -- Every workable ray returns early with 'AIMED' above.
 return nil,'PART_UNREACHABLE'
end
return A
