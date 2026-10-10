local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
local D=require('Dora');local poses=D.json.decode(D.Content:load(root..'/Test/combat-slow-aims.json'),32);local times={};local counts={}
for index,file in ipairs({root..'/Test/Fixtures/CombatSlowAimBefore/HitGeometry.lua',root..'/Script/Combat/HitGeometry.lua'})do
 package.loaded['Combat.HitGeometry']=dofile(file);local Aim=dofile(root..'/Script/Combat/PartAim.lua')
 local start=os.clock();local count=0
 for rep=1,10 do for _,pose in ipairs(poses)do
  local n=0
  local a,reason=Aim.solve(pose.origin,pose.facing,pose.part,pose.regions,function(from,to)
   n=n+1;local row=assert(pose.terrain[n],'extra terrain call')
   assert(math.abs(row.to.x-to.x)<1e-6 and math.abs(row.to.y-to.y)<1e-6,'changed terrain query')
   return row.blocked
  end)
  assert(n==#pose.terrain and reason==pose.reason,'changed query order/result');count=count+n
  assert((a~=nil)==(pose.result~=nil))
 end end
 times[index]=os.clock()-start;counts[index]=count
end
print('PASS 120 slow aim queries and terrain callback order',counts[1],times[1],times[2],times[1]/times[2])
