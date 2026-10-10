local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-shadow-animated-result.json';local r={status='RUNNING',poses=0,queries=0,callbacks=0}
local function save()D.Content:save(out,D.json.encode(r))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local old=assert(load(D.Content:load(root..'/Test/Fixtures/CombatShadowBefore/PartAim.lua')))()
  local new=assert(load(D.Content:load(root..'/Test/Fixtures/CombatShadowIntegrated/PartAim.lua')))();local R=require('Combat.SpineRegions')
  local manifest=D.json.decode(D.Content:load(root..'/Data/Combat/flower-regions.json'),32)
  local source=D.json.decode(D.Content:load(root..'/Docs/artwork/flower-probes-packed/dahuayao-probes-packed.json'),64)
  local model=assert(D.Spine('dahuayao-hitboxes.skel|dahuayao-hitboxes.atlas'));model.look='default';model.recovery=0;model.scaleX=.6;model.scaleY=.75;model:addTo(D.Director.entry)
  for name in pairs(source.animations)do for _,flip in ipairs({false,true})do
   model.fliped=flip;local duration=model:play(name,false)
   for pose=1,3 do
    D.sleep(duration/3);local regions=R.sample(model,manifest,D.Director.entry);assert(#regions==32);r.poses=r.poses+1
    for _,facing in ipairs({false,true})do
     local origin={x=facing and -450 or 450,y=pose*70}
     for _,id in ipairs({'flower-head','flower-core','petal-left','petal-right','roots'})do
      local results={}
      for _,aim in ipairs({old,new})do
       local calls={};local value,reason=aim.solve(origin,facing,id,regions,function(from,to)calls[#calls+1]={x=to.x,y=to.y};return to.y<20 end)
       results[#results+1]={value=value,reason=reason,calls=calls}
      end
      local a,b=results[1],results[2]
      assert(a.reason==b.reason and (a.value~=nil)==(b.value~=nil) and #a.calls==#b.calls,'animated reachability changed '..name..'/'..id)
      if a.value then assert(a.value.angle==b.value.angle and a.value.point.x==b.value.point.x and a.value.point.y==b.value.point.y,'animated aim preference changed')end
      for i,c in ipairs(a.calls)do assert(c.x==b.calls[i].x and c.y==b.calls[i].y,'terrain query changed')end
      r.queries=r.queries+1;r.callbacks=r.callbacks+#a.calls
     end
    end
   end
  end end
  model:removeFromParent()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
