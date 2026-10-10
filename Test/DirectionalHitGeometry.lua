local root='/Users/Jin/Workspace/Dora/LSD'
local old=dofile(root..'/Test/Fixtures/CombatDirectionBefore/HitGeometry.lua')
local new=dofile(root..'/Script/Combat/HitGeometry.lua')
local checks=0
local function check(a,b,vertices)
 local one,two=old.segment(a,b,vertices),new.segment(a,b,vertices)
 assert((one~=nil)==(two~=nil),'contact presence '..checks)
 if one then
  assert(one.t==two.t and one.position.x==two.position.x and one.position.y==two.position.y and one.normal.x==two.normal.x and one.normal.y==two.normal.y and one.startedInside==two.startedInside,'contact changed '..checks)
 end
 checks=checks+1
end
math.randomseed(61745)
for pose=1,100 do
 local vertices={};local count=12+pose%49;local scale=({1e-5,1,1e6})[pose%3+1]
 for i=1,count do local angle=i*math.pi*2/count;local radius=scale*(.1+math.random())
  vertices[i]={x=math.cos(angle)*radius,y=math.sin(angle)*radius}
 end
 local origin={x=scale*(1.5+math.random()),y=scale*(math.random()-.5)}
 for _,variant in ipairs({'right','left','vertex','near-edge'})do
  if variant=='left'then origin.x=-origin.x
  elseif variant=='vertex'then origin.x=vertices[1].x;origin.y=vertices[1].y
  elseif variant=='near-edge'then origin.x=(vertices[1].x+vertices[2].x)/2+1e-9;origin.y=(vertices[1].y+vertices[2].y)/2-1e-9 end
  for i=0,255 do
   local angle=i*math.pi/128
   for _,shift in ipairs({0,-1e-12,1e-12})do
    check(origin,{x=origin.x+math.cos(angle+shift)*scale*4,y=origin.y+math.sin(angle+shift)*scale*4},vertices)
   end
  end
 end
end
-- Epsilon-tolerated negative t, angular wrap and almost collinear long edges.
local vertices={}
for i=0,11 do vertices[#vertices+1]={x=i,y=1e-10*i}end
for i=11,0,-1 do vertices[#vertices+1]={x=i,y=1+1e-10*i}end
for _,origin in ipairs({{x=12,y=0},{x=-1e-12,y=0},{x=5,y=-1e-12},{x=1e6,y=1e-9}})do
 for i=1,100 do for _,sign in ipairs({-1,1})do check(origin,{x=origin.x+sign*1e10,y=origin.y+(i-50)*1e-9},vertices)end end
end
print('PASS '..checks..' repeated-origin directional rays, wrap, bucket boundaries, scales, vertices and near-collinear contacts')
