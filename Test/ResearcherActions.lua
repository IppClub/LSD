-- Offscreen native asset inspection; does not replace the player's current scene.
return function(root)
 local D=require('Dora')
 D.thread(function()
  local holder
  local report={status='RUNNING',runId=os.time(),sceneReplaced=false,productionAsset=true,samples={}}
  local output=D.Path(root,'Test/researcher-actions-result.json')
  local function save()assert(D.Content:save(output,D.json.encode(report)))end
  save()
  local ok,err=xpcall(function()
   holder=D.Node();holder.x=-5000;holder:addTo(D.Director.ui3D)
   local asset=require('Factory.Researcher').asset
   D.Cache:unload('spine:'..asset)
   local actor=assert(D.Spine(asset));actor.position=D.Vec2(360,30);actor:addTo(holder)
   local rt=D.RenderTarget(800,440);local camera=D.Camera2D();camera.position=D.Vec2(-4680,190);camera.zoom=3;rt.camera=camera
   local floor=D.DrawNode();floor:drawSegment(D.Vec2(0,30),D.Vec2(800,30),1,D.Color(0xff8999a9));floor:addTo(holder);floor.order=-1
   local ended={};actor:slot('AnimationEnd',function(name)ended[name]=(ended[name]or 0)+1 end)
   for _,sample in ipairs({{'idle',0.1},{'hit',.16},{'hit',.64},{'restrained',1},{'knockout',.3},{'knockout',.55},{'knockout',.8},{'knockout',1.35},{'unconscious',1.2},{'knockout',.55,true},{'knockout',1.35,true},{'unconscious',1.2,true}})do
    actor.recovery=0;actor.speed=1;actor.fliped=not not sample[3];actor.x=sample[3] and 260 or 360
    local duration=actor:play(sample[1],false);assert(duration>0,'missing animation '..sample[1])
    local start=D.App.runningTime;D.sleep(sample[2]);actor.speed=0;local sampledSeconds=D.App.runningTime-start
    local path=D.Path(root,'Docs/evidence/2026-10-04/researcher-'..sample[1]..'-'..sample[2]..(sample[3] and '-mirrored' or '')..'.png')
    rt:renderWithClear(holder,D.Color(0xff293341));rt:saveAsync(path)
    report.samples[#report.samples+1]={animation=sample[1],mirrored=not not sample[3],requestedSeconds=sample[2],actualSeconds=sampledSeconds,duration=duration,path=path}
   end
   actor.speed=1;actor.recovery=.15;actor:play('hit',false)
   local deadline=D.App.runningTime+3;local before=ended.hit or 0
   while (ended.hit or 0)==before do assert(D.App.runningTime<deadline,'finite hit did not finish');D.sleep(.02)end
   actor:play('restrained',true);D.sleep(.3)
   local knockoutBefore=ended.knockout or 0
   actor.recovery=.15;actor:play('knockout',false);local knockoutStart=D.App.runningTime
   while (ended.knockout or 0)==knockoutBefore do assert(D.App.runningTime-knockoutStart<4,'knockout did not finish');D.sleep(.02)end
   report.knockoutSeconds=D.App.runningTime-knockoutStart;assert(report.knockoutSeconds>=1.3)
   -- These two authored poses share an exact endpoint, so no setup-pose bridge.
   actor.recovery=0;actor:play('unconscious',true);D.sleep(.2)
   report.hitEnds=ended.hit;report.recovery=.15;report.status='PASS';report.visualAcceptancePending=true
  end,debug.traceback)
  if holder then holder:removeFromParent()end
  if not ok then report.status='FAIL';report.error=err end
  save();print(D.json.encode(report))
 end)
end
