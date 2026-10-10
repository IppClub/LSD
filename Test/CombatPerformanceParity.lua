local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/combat-perf-parity-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local function old(name)return assert(load(D.Content:load(root..'/Test/Fixtures/CombatPerfBefore/'..name..'.lua')))()end
  local G=require('Combat.HitGeometry');local A=require('Combat.PartAim');local R=require('Combat.SpineRegions')
  local oldG=old('HitGeometry');local oldR=old('SpineRegions')
  package.loaded['Combat.HitGeometry']=oldG;local oldA=old('PartAim');package.loaded['Combat.HitGeometry']=G
  local p=require('Training.PartPractice').createAsync('ninilite');local target=p.partCombat.target;local a=p.arena
  local checks,points=0,0
  for pose=1,12 do
   D.sleep(.1)
   a.enemy.faceRight=pose%2==0
   a.enemy.x=1000+pose*30
   local before=oldR.sample(target.model,target.manifest,target.space);local after=R.sample(target.model,target.manifest,target.space)
   for i,part in ipairs(before)do for j,v in ipairs(part.vertices)do local n=after[i].vertices[j];assert(math.abs(v.x-n.x)<1e-6 and math.abs(v.y-n.y)<1e-6,'Cached vertex changed');points=points+1 end end
   for _,facing in ipairs({false,true})do
    local origin={x=facing and a.enemy.x-550 or a.enemy.x+550,y=a.student.y+30}
    for _,part in ipairs(before)do
     local one=oldA.solve(origin,facing,part.id,before,function()return false end)
     local two=A.solve(origin,facing,part.id,after,function()return false end)
     assert((one~=nil)==(two~=nil),'Reachability changed')
     if one then assert(math.abs(one.angle-two.angle)<1e-9 and math.abs(one.point.x-two.point.x)<1e-6 and math.abs(one.point.y-two.point.y)<1e-6,'Aim preference changed')end
     checks=checks+1
    end
    for i=1,20 do
     local endpoint={x=a.enemy.x+(i-10)*40,y=a.student.y+i*20}
     local one=oldG.nearest(origin,endpoint,before);local two=G.nearest(origin,endpoint,after)
     assert((one~=nil)==(two~=nil),'Broad phase discarded hit')
     if one then assert(one.part==two.part and math.abs(one.t-two.t)<1e-9,'Nearest contact changed')end
     checks=checks+1
    end
   end
  end
  p:close();r.points=points;r.queries=checks
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
