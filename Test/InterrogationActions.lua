-- Native offscreen inspection of dedicated cover gestures; keeps the live scene.
return function(root)
 local D=require('Dora')
 D.thread(function()
  local holder
  local report={status='RUNNING',runId=os.time(),sceneReplaced=false,samples={}}
  local output=D.Path(root,'Test/interrogation-actions-result.json')
  local function save()assert(D.Content:save(output,D.json.encode(report)))end
  save()
  local ok,err=xpcall(function()
   holder=D.Node();holder.x=-5000;holder:addTo(D.Director.ui3D)
   local asset=D.Path(root,'Docs/artwork/interrogation/wuyun/export/actions.skel')..'|'..D.Path(root,'Spine/wuyun.atlas')
   D.Cache:unload('spine:'..asset)
   local actor=assert(D.Spine(asset));actor.position=D.Vec2(320,30);actor:addTo(holder)
   local rt=D.RenderTarget(800,540);local camera=D.Camera2D();camera.position=D.Vec2(-4680,195);camera.zoom=1.5;rt.camera=camera
   local floor=D.DrawNode();floor:drawSegment(D.Vec2(0,30),D.Vec2(800,30),1,D.Color(0xff8999a9));floor:addTo(holder);floor.order=-1
   for _,sample in ipairs({{'idle',.01},{'coverReach',.27},{'coverReach',.55},{'coverHold',1},{'coverRelease',.4}})do
    actor.recovery=0;actor.speed=1
    local duration=actor:play(sample[1],false);assert(duration>0,'missing '..sample[1])
    D.sleep(sample[2]);actor.speed=0
    local palm=actor:getKey('s:melee/s:melee')
    local path=D.Path(root,'Docs/evidence/2026-10-03/wuyun-'..sample[1]..'-'..sample[2]..'.png')
    rt:renderWithClear(holder,D.Color(0xff293341));rt:saveAsync(path)
    report.samples[#report.samples+1]={animation=sample[1],duration=duration,palm={x=palm.x,y=palm.y},path=path}
   end
   local elapsed={};local active,start
   actor:slot('AnimationEnd',function(name)if name==active then elapsed[name]=D.App.runningTime-start end end)
   for _,name in ipairs({'coverReach','coverRelease'})do
    active=nil;actor.speed=1;actor.recovery=0;local duration=actor:play(name,false);start=D.App.runningTime;active=name
    while not elapsed[name]do assert(D.App.runningTime-start<3,'finite action did not finish');D.sleep(.02)end
    assert(elapsed[name]>=duration-.035,'action ended early')
   end
   report.elapsed=elapsed;report.status='PASS';report.visualAcceptancePending=true
  end,debug.traceback)
  if holder then holder:removeFromParent()end
  if not ok then report.status='FAIL';report.error=err end
  save();print(D.json.encode(report))
 end)
end
