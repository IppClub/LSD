-- Same animated geometry and query order on both implementations. Run in Dora,
-- or inject a Dora Content/json adapter for a standalone Lua benchmark.
local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
local D=require('Dora')
local poses=D.json.decode(D.Content:load(root..'/Test/combat-stutter-poses.json'),32)
local old=assert(loadfile(root..'/Test/Fixtures/CombatStutterBefore/HitGeometry.lua'))()
local new=require('Combat.HitGeometry')
for _,pose in ipairs(poses)do
 local a,b=old.distance(pose.origin,pose.regions),new.distance(pose.origin,pose.regions)
 assert(a.distance==b.distance and a.part==b.part and a.position.x==b.position.x and a.position.y==b.position.y and a.inside==b.inside,'distance changed')
end
local times={}
for i,g in ipairs({old,new})do
 local start=os.clock()
 for repeatIndex=1,1000 do for _,pose in ipairs(poses)do g.distance(pose.origin,pose.regions)end end
 times[i]=os.clock()-start
end
print(string.format('PASS %d real poses; 1000 repeats before %.6fs after %.6fs speedup %.2fx',#poses,times[1],times[2],times[1]/times[2]))
