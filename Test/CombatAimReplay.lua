local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
-- Run with Dora after CombatStutterProfile has captured fresh animated poses.
local D=require('Dora')
local poses=D.json.decode(D.Content:load(root..'/Test/combat-stutter-poses.json'),32)
local old=assert(loadfile(root..'/Test/Fixtures/CombatStutterBefore/HitGeometry.lua'))()
local new=require('Combat.HitGeometry')
package.loaded['Combat.HitGeometry']=old;local before=assert(loadfile(root..'/Script/Combat/PartAim.lua'))()
package.loaded['Combat.HitGeometry']=new;local after=assert(loadfile(root..'/Script/Combat/PartAim.lua'))()
local times={0,0};local count=0
for _,pose in ipairs(poses)do for _,part in ipairs({'flower-head','flower-core','petal-left','petal-right','roots'})do
 local values={}
 for i,solver in ipairs({before,after})do local t=os.clock();values[i]=solver.solve(pose.origin,pose.facing,part,pose.regions,function()return false end);times[i]=times[i]+os.clock()-t end
 local a,b=values[1],values[2];assert((a~=nil)==(b~=nil),'reachability');if a then assert(a.angle==b.angle and a.point.x==b.point.x and a.point.y==b.point.y,'aim changed')end
 count=count+1
end end
print(string.format('PASS %d identical real-pose aim queries; before %.6fs after %.6fs speedup %.2fx',count,times[1],times[2],times[1]/times[2]))
