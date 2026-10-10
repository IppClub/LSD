local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-hint-replay-result.json';local r={status='RUNNING',timings={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
local ok,err=xpcall(function()
 local poses=D.json.decode(D.Content:load(root..'/Test/combat-slow-aims.json'),32)
 for _,mode in ipairs({'warm','cold'})do
  for _,path in ipairs({'Test/Fixtures/CombatHintBefore/HitGeometry.lua','Script/Combat/HitGeometry.lua'})do
   local function loadAim()package.loaded['Combat.HitGeometry']=assert(load(D.Content:load(root..'/'..path),'@'..path))();return assert(load(D.Content:load(root..'/Script/Combat/PartAim.lua')))()end
   local Aim=loadAim();local elapsed,count=0,0
   for rep=1,10 do
    if mode=='cold' then Aim=loadAim()end
    local start=D.App.elapsedTime
    for _,pose in ipairs(poses)do
     local n=0;local a,reason=Aim.solve(pose.origin,pose.facing,pose.part,pose.regions,function(from,to)
      n=n+1;local row=assert(pose.terrain[n],'extra terrain query')
      assert(math.abs(row.to.x-to.x)<1e-6 and math.abs(row.to.y-to.y)<1e-6,'changed terrain query');return row.blocked
     end)
     assert(n==#pose.terrain and reason==pose.reason and (a~=nil)==(pose.result~=nil),'changed aim result');count=count+n
     if a then assert(math.abs(a.angle-pose.result.angle)<1e-8 and math.abs(a.point.x-pose.result.point.x)<1e-6 and math.abs(a.point.y-pose.result.point.y)<1e-6)end
    end
    elapsed=elapsed+D.App.elapsedTime-start
   end
   r.timings[#r.timings+1]={mode=mode,path=path,seconds=elapsed,terrainCalls=count}
  end
 end
end,debug.traceback)
r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
