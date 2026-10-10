local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-shadow-readonly-batch-result.json';local r={status='RUNNING',timings={}}
local function save()D.Content:save(out,D.json.encode(r))end;save()
local ok,err=xpcall(function()
 local poses=D.json.decode(D.Content:load(root..'/Test/combat-slow-aims.json'),32)
 local expected={}
 for _,path in ipairs({'Test/Fixtures/CombatShadowBefore/PartAim.lua','Test/Fixtures/CombatShadowReadOnly/PartAim.lua'})do
  local seconds,queries,calls,max=0,0,0,0
  for rep=1,5 do for index,pose in ipairs(poses)do
   package.loaded['Combat.HitGeometry']=nil;package.loaded['Combat.AimOcclusion']=nil
   local A=assert(load(D.Content:load(root..'/'..path)))()
   local start=D.App.runningTime
   for _,id in ipairs({'flower-head','flower-core','petal-left','petal-right','roots'})do
    local contact={};local aim,reason=A.solve(pose.origin,pose.facing,id,pose.regions,function(from,to)
     contact[#contact+1]={x=to.x,y=to.y};return to.y<20
    end,true)
    local key=index..'/'..id;local before=expected[key]
    if not before then expected[key]={aim=aim,reason=reason,contact=contact}
    else
     assert(before.reason==reason and (before.aim~=nil)==(aim~=nil) and #before.contact==#contact,'batch reachability changed')
     if aim then assert(aim.angle==before.aim.angle and aim.point.x==before.aim.point.x and aim.point.y==before.aim.point.y,'batch preference changed')end
     for i,p in ipairs(contact)do assert(p.x==before.contact[i].x and p.y==before.contact[i].y,'batch terrain order changed')end
    end
    queries=queries+1;calls=calls+#contact
   end
   local elapsed=D.App.runningTime-start;seconds=seconds+elapsed;max=math.max(max,elapsed)
  end end
  r.timings[#r.timings+1]={path=path,seconds=seconds,maxBatch=max,queries=queries,terrainCalls=calls}
 end
end,debug.traceback)
r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
