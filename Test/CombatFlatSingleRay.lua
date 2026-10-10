local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-flat-single-result.json';local r={status='RUNNING',timings={}}
local function save()D.Content:save(out,D.json.encode(r))end;save()
local ok,err=xpcall(function()
 local poses=D.json.decode(D.Content:load(root..'/Test/combat-slow-aims.json'),32)
 for _,path in ipairs({'Test/Fixtures/CombatFlatBefore/HitGeometry.lua','Script/Combat/HitGeometry.lua'})do
  local seconds,count=0,0
  for rep=1,50 do for _,pose in ipairs(poses)do
   local G=assert(load(D.Content:load(root..'/'..path)))()
   local target=pose.regions[rep%#pose.regions+1].vertices[1]
   local t=D.App.runningTime;G.nearest(pose.origin,target,pose.regions);seconds=seconds+D.App.runningTime-t;count=count+1
  end end
  r.timings[#r.timings+1]={path=path,seconds=seconds,rays=count}
 end
end,debug.traceback)
r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
