local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
local old=dofile(root..'/Test/Fixtures/CombatCandidateBefore/PartAim.lua');local new=require('Combat.PartAim')
math.randomseed(491020)
local count=0
for pose=1,250 do
 local regions={}
 for part=1,12 do
  local points={};local x,y=math.random(-1000,1000),math.random(-500,500)
  for v=1,16 do local t=2*math.pi*v/16;local radius=v%2==0 and 100 or 170;points[v]={x=x+math.cos(t)*radius,y=y+math.sin(t)*radius}end
  regions[#regions+1]={id='part'..(part%4),vertices=points,priority=part%3,enabled=part%7~=0}
 end
 for sample=1,16 do
  local origin=sample<=4 and regions[sample].vertices[1] or {x=math.random(-2000,2000),y=math.random(-900,900)}
  local facing=sample%2==0;local id='part'..(sample%4);local before,after={},{}
  local function blocked(rows)return function(a,b)rows[#rows+1]={x=b.x,y=b.y};return b.x>origin.x+150 and b.y>0 end end
  local a,ar=old.solve(origin,facing,id,regions,blocked(before));local b,br=new.solve(origin,facing,id,regions,blocked(after))
  assert(ar==br and (a~=nil)==(b~=nil)and #before==#after)
  for i,v in ipairs(before)do assert(v.x==after[i].x and v.y==after[i].y,'Changed terrain callbacks')end
  if a then for _,key in ipairs({'angle','distance','intendedPart'})do assert(a[key]==b[key],key)end;assert(a.point.x==b.point.x and a.point.y==b.point.y)end
  count=count+1
 end
 -- Pose tables are replaced on animation sampling; a new contour must never
 -- reuse containment results from the previous pose.
end
print('PASS '..count..' concave/boundary/disabled/multiple-origin candidate queries, exact result and callback order')
