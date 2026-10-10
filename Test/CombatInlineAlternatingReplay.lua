local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-inline-alternating-result.json';local r={status='RUNNING',timings={}}
local function save()D.Content:save(out,D.json.encode(r))end;save()
local ok,err=xpcall(function()
 local poses=D.json.decode(D.Content:load(root..'/Test/combat-live-aims.json'),64)
 local function equal(a,b)
  if type(a)~=type(b)then return false end
  if type(a)~='table'then return a==b end
  for k,v in pairs(a)do if not equal(v,b[k])then return false end end
  for k in pairs(b)do if a[k]==nil then return false end end
  return true
 end
 local exact={};r.serializationMaxDelta=0
 local frames={}
 for _,pose in ipairs(poses)do
  local prior=frames[pose.frame]
  if prior then
   assert(equal(prior,pose.regions),'same-frame geometry changed; cannot share this snapshot')
   pose.regions=prior
  else frames[pose.frame]=pose.regions end
 end
 local configs={{name='baseline',path='Test/Fixtures/CombatInlineBefore/PartAim.lua',geometry='Test/Fixtures/CombatInlineBefore/HitGeometry.lua'}, {name='inline',path='Script/Combat/PartAim.lua',geometry='Test/Fixtures/CombatInlineTrial/HitGeometry.lua'}}
 for round=1,4 do
 for index=1,2 do
  local config=configs[round%2==1 and index or 3-index]
  local seconds,max,queries,calls,slow=0,0,0,0,0
  for rep=1,1 do
   local last,elapsed,A
   local function finish()if elapsed then max=math.max(max,elapsed);if elapsed>1/60 then slow=slow+1 end end end
   for poseIndex,pose in ipairs(poses)do
    if last~=pose.frame then
     finish();last=pose.frame;elapsed=0
     package.loaded['Combat.HitGeometry']=assert(load(D.Content:load(root..'/'..config.geometry)))()
     A=assert(load(D.Content:load(root..'/'..config.path)))()
    end
    local n=0;local t=D.App.runningTime
    local result,reason=A.solve(pose.origin,pose.facing,pose.part,pose.regions,function(from,to)
     n=n+1;local row=assert(pose.terrain[n],'extra terrain callback')
     assert(math.abs(to.x-row.to.x)<1e-6 and math.abs(to.y-row.to.y)<1e-6,'terrain contact changed');return row.blocked
    end,config.readOnly)
    local dt=D.App.runningTime-t;elapsed=elapsed+dt;seconds=seconds+dt
    assert(n==#pose.terrain and reason==pose.reason and (result~=nil)==(pose.result~=nil),'aim availability changed')
    if result then
     local delta=math.max(math.abs(result.angle-pose.result.angle),math.abs(result.point.x-pose.result.point.x),math.abs(result.point.y-pose.result.point.y))
     r.serializationMaxDelta=math.max(r.serializationMaxDelta,delta)
     assert(math.abs(result.angle-pose.result.angle)<1e-8 and math.abs(result.point.x-pose.result.point.x)<1e-6 and math.abs(result.point.y-pose.result.point.y)<1e-6,'captured aim changed beyond serialization tolerance')
    end
    local baseline=exact[poseIndex]
    if not baseline then exact[poseIndex]={result=result,reason=reason}
    else
     assert(baseline.reason==reason and (baseline.result~=nil)==(result~=nil),'paired availability changed')
     if result then assert(result.angle==baseline.result.angle and result.point.x==baseline.result.point.x and result.point.y==baseline.result.point.y,'paired aim preference changed')end
    end
    queries=queries+1;calls=calls+n
   end
   finish()
  end
  r.timings[#r.timings+1]={round=round,name=config.name,seconds=seconds,maxFrameAim=max,aimFramesOver16ms=slow,queries=queries,terrainCalls=calls}
 end
 end
end,debug.traceback)
r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
