local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
local G=require('Combat.HitGeometry');local S=require('Combat.AimOcclusion');local count,rejections=0,0
local function rect(x,y,w,h,id)return {id=id,vertices={{x=x,y=y},{x=x+w,y=y},{x=x+w,y=y+h},{x=x,y=y+h}},bounds={minX=x,maxX=x+w,minY=y,maxY=y+h}}end
for _,scale in ipairs({1e-8,1e-5,1,1e5,1e8})do
 for _,offset in ipairs({0,1e9,-1e9})do
  for _,sign in ipairs({-1,1})do
   local origin={x=offset,y=offset};local target=rect(offset+10*scale,offset-4*scale,scale,8*scale,'target')
   local wall=rect(offset+5*scale,offset-3*scale,.1*scale,6*scale,'wall')
   if sign<0 then for _,p in ipairs({target,wall})do for _,v in ipairs(p.vertices)do v.x=2*offset-v.x end;p.bounds=nil end end
   local parts={wall,target};local range=30*scale;local reject=S.build(origin,parts,'target',range)
   for i=0,63 do for _,epsilon in ipairs({-1e-10,0,1e-10})do
    local angle=i*math.pi/32+epsilon;local point={x=origin.x+math.cos(angle)*range*.9,y=origin.y+math.sin(angle)*range*.9}
    count=count+1
    if reject and reject(point)then
     rejections=rejections+1;local hit=G.nearest(origin,point,parts)
     assert(not hit or hit.part~='target','boundary rejection '..count)
    end
   end end
  end
 end
end
local parts={rect(5,-3,.2,6,'wall'),rect(10,-4,1,8,'target')};local o={x=0,y=0}
assert(S.build(o,parts,'target',30),'expected useful shadow')
parts[1].bounds={minX=100,maxX=101,minY=100,maxY=101}
assert(S.build(o,parts,'target',30)==nil,'invalid bounds must fall back')
parts[1].bounds=nil;parts[1].enabled=false
assert(S.build(o,parts,'target',30)==nil,'disabled blocker must not cast shadow')
assert(S.build(o,parts,'target',0)==nil)
print('PASS '..count..' bucket-boundary/scale/translated rays; '..rejections..' certified rejections; invalid bounds and disabled blocker fallback')
