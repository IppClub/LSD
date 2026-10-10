local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-shadow-shared-mutation-result.json';local r={status='RUNNING',cases=0,callbacks=0}
local function save()D.Content:save(out,D.json.encode(r))end;save()
local ok,err=xpcall(function()
 local poses=D.json.decode(D.Content:load(root..'/Test/combat-slow-aims.json'),32)
 local function clone(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=clone(x)end;return t end
 for _,pose in ipairs(poses)do for _,mode in ipairs({'disable','reverse','bounds'})do
  local results={}
  for _,path in ipairs({'Test/Fixtures/CombatShadowBefore/PartAim.lua','Test/Fixtures/CombatShadowShared/PartAim.lua'})do
   package.loaded['Combat.HitGeometry']=nil;package.loaded['Combat.AimOcclusion']=nil
   local A=assert(load(D.Content:load(root..'/'..path)))();local parts=clone(pose.regions);local calls={}
   if mode=='bounds' then for _,part in ipairs(parts)do if part.id~=pose.part then part.bounds={minX=1e8,maxX=1e8+1,minY=1e8,maxY=1e8+1}end end end
   local result,reason=A.solve(pose.origin,pose.facing,pose.part,parts,function(from,to)
    calls[#calls+1]={x=to.x,y=to.y}
    if #calls==1 then
     if mode=='disable'then for _,part in ipairs(parts)do if part.id~=pose.part then part.enabled=false end end
     elseif mode=='reverse'then for i=1,math.floor(#parts/2)do parts[i],parts[#parts-i+1]=parts[#parts-i+1],parts[i]end end
    end
    return #calls<3
   end)
   results[#results+1]={result=result,reason=reason,calls=calls}
  end
  local a,b=results[1],results[2];assert(a.reason==b.reason and (a.result~=nil)==(b.result~=nil) and #a.calls==#b.calls,'mutation changed result')
  if a.result then assert(a.result.angle==b.result.angle and a.result.point.x==b.result.point.x and a.result.point.y==b.result.point.y,'aim changed')end
  for i,c in ipairs(a.calls)do assert(c.x==b.calls[i].x and c.y==b.calls[i].y,'callback changed')end
  r.cases=r.cases+1;r.callbacks=r.callbacks+#a.calls
 end end
 assert(r.callbacks>0)
end,debug.traceback)
r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
