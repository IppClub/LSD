local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
local G=require('Combat.HitGeometry');local Shadow=require('Combat.AimOcclusion')
math.randomseed(892451)
local queries,rejected=0,0
for scene=1,120 do
 local scale=({1e-5,1,1e6})[scene%3+1];local parts={}
 for j=1,12 do
  local points={};local x,y=(math.random()-.5)*scale*6,(math.random()-.5)*scale*6
  local bounds={minX=math.huge,minY=math.huge,maxX=-math.huge,maxY=-math.huge}
  for k=1,12 do
   local angle=k*math.pi/6;local radius=scale*(k%2==0 and .15 or .7)
   local v={x=x+math.cos(angle)*radius,y=y+math.sin(angle)*radius};points[k]=v
   bounds.minX=math.min(bounds.minX,v.x);bounds.maxX=math.max(bounds.maxX,v.x);bounds.minY=math.min(bounds.minY,v.y);bounds.maxY=math.max(bounds.maxY,v.y)
  end
  parts[j]={id='part'..j%3,priority=j%4,vertices=points,bounds=j%2==0 and bounds or nil,enabled=j%7~=0}
 end
 for o=1,3 do
  local origin={x=(math.random()-.5)*scale*8,y=(math.random()-.5)*scale*8}
  for target=0,2 do
   local id='part'..target;local reject=Shadow.build(origin,parts,id,scale*20)
   if reject then
    for i=1,200 do
     local angle=i*math.pi/100;local p={x=origin.x+math.cos(angle)*scale*20,y=origin.y+math.sin(angle)*scale*20}
     if i%3==0 then local v=parts[i%12+1].vertices[i%12+1];p={x=v.x,y=v.y}end
     queries=queries+1
     if reject(p)then
      rejected=rejected+1;local hit=G.nearest(origin,p,parts)
      assert(not hit or hit.part~=id,'shadow rejected requested contact '..scene..'/'..o..'/'..i)
     end
    end
   end
  end
 end
end
assert(rejected>0)
print('PASS conservative shadows: '..queries..' rays, '..rejected..' certified rejections; concavity, disabled pieces, scales and exact vertex rays')
