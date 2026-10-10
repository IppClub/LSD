local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
local D=require('Dora');local poses=D.json.decode(D.Content:load(root..'/Test/combat-stutter-poses.json'),32)
local solvers={}
for i,file in ipairs({root..'/Test/Fixtures/CombatRayBefore/HitGeometry.lua',root..'/Script/Combat/HitGeometry.lua'})do package.loaded['Combat.HitGeometry']=dofile(file);solvers[i]=dofile(root..'/Script/Combat/PartAim.lua')end
local function unblocked()return false end
local times={0,0}
for repeatIndex=1,10 do for _,pose in ipairs(poses)do for _,part in ipairs({'flower-head','flower-core','petal-left','petal-right','roots'})do
 local results={}
 for i,solver in ipairs(solvers)do local t=os.clock();results[i]=solver.solve(pose.origin,pose.facing,part,pose.regions,unblocked);times[i]=times[i]+os.clock()-t end
 local a,b=results[1],results[2];assert((a~=nil)==(b~=nil));if a then assert(a.angle==b.angle and a.point.x==b.point.x and a.point.y==b.point.y)end
end end end
print('PASS exact aim; before',times[1],'after',times[2],'speedup',times[1]/times[2])
