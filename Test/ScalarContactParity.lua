local root='/Users/Jin/Workspace/Dora/LSD'
local old=dofile(root..'/Test/Fixtures/CombatScalarContactBefore/HitGeometry.lua');local new=dofile(root..'/Script/Combat/HitGeometry.lua')
math.randomseed(703821)
local count=0
for pose=1,120 do
 local scale=({1e-5,1,1e6})[pose%3+1];local parts={}
 for j=1,8 do
  local x,y=scale*(math.random()-.5),scale*(math.random()-.5);local vertices={}
  local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
  for k=1,16 do
   local theta=k*math.pi/8;local radius=scale*(k%2==0 and .35 or .8)
   local p={x=x+math.cos(theta)*radius,y=y+math.sin(theta)*radius};vertices[k]=p
   minX=math.min(minX,p.x);maxX=math.max(maxX,p.x);minY=math.min(minY,p.y);maxY=math.max(maxY,p.y)
  end
  parts[j]={id='part'..j%3,priority=j%4,enabled=j%5~=0,vertices=vertices,bounds=j%2==0 and {minX=minX,minY=minY,maxX=maxX,maxY=maxY}or nil}
 end
 parts[9]={id='part1',priority=parts[1].priority,vertices=parts[1].vertices}
 for i=1,100 do
  local a={x=scale*(math.random()*4-2),y=scale*(math.random()*4-2)}
  local b={x=scale*(math.random()*4-2),y=scale*(math.random()*4-2)}
  if i%5==0 then a=parts[1].vertices[i%16+1]end
  if i%7==0 then b={x=a.x,y=a.y+scale*1e-10}end
  if i%11==0 then b={x=a.x,y=a.y}end
  local x,y=old.nearest(a,b,parts),new.nearest(a,b,parts)
  assert((x~=nil)==(y~=nil),'presence '..count)
  if x then
   for _,key in ipairs({'t','part','priority','startedInside'})do assert(x[key]==y[key],key..' '..count)end
   for _,key in ipairs({'position','normal'})do assert(x[key].x==y[key].x and x[key].y==y[key].y,key..' '..count)end
  end
  count=count+1
 end
end
print('PASS '..count..' compound contacts: exact distance, identity, normal, tie priority, inside and disabled parts')
