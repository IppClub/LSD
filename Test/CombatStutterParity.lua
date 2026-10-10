local root='/Users/Jin/Workspace/Dora/LSD'
package.path=root..'/Script/?.lua;'..package.path
local old=assert(loadfile(root..'/Test/Fixtures/CombatStutterBefore/HitGeometry.lua'))()
local new=require('Combat.HitGeometry')
math.randomseed(1947)
for i=1,20000 do
 local vertices={};local n=i%2==0 and 60 or 20;for j=1,n do local a=j*math.pi*2/n;local r=math.random()*1000;vertices[j]={x=math.cos(a)*r,y=math.sin(a)*r}end
 local a={x=math.random()*3000-1500,y=math.random()*3000-1500};local b={x=math.random()*3000-1500,y=math.random()*3000-1500}
 if i%10==0 then a=vertices[1]end
 local x,y=old.segment(a,b,vertices),new.segment(a,b,vertices)
 assert((x~=nil)==(y~=nil),'contact presence '..i)
 if x then assert(x.t==y.t and x.normal.x==y.normal.x and x.normal.y==y.normal.y and x.startedInside==y.startedInside,'contact changed '..i)end
 local parts={}
 for k=1,5 do
  local vs={};local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
  for _,v in ipairs(vertices)do local x,y=v.x+k*150,v.y-k*70;vs[#vs+1]={x=x,y=y};minX=math.min(minX,x);maxX=math.max(maxX,x);minY=math.min(minY,y);maxY=math.max(maxY,y)end
  parts[k]={id='p'..k,vertices=vs,priority=k%2,bounds={minX=minX,maxX=maxX,minY=minY,maxY=maxY}}
 end
 for _,point in ipairs({a,b,parts[1].vertices[1]})do
  local before,after=old.distance(point,parts),new.distance(point,parts)
  assert(before.distance==after.distance and before.position.x==after.position.x and before.position.y==after.position.y and before.part==after.part and before.inside==after.inside,'distance changed '..i)
 end
 local one,two=old.nearest(a,b,parts),new.nearest(a,b,parts)
 assert((one~=nil)==(two~=nil),'nearest presence '..i)
 if one then assert(one.part==two.part and one.t==two.t and one.normal.x==two.normal.x and one.normal.y==two.normal.y,'nearest changed '..i)end
end
print('PASS 20000 concave, boundary, crossing segment, and 60000 distance cases')
