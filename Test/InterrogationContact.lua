-- Paired native render with contact markers; never replaces the live scene.
return function(root)
 local D=require('Dora')
 D.thread(function()
  local holder
  local report={status='RUNNING',runId=os.time(),sceneReplaced=false,productionAsset=true,samples={}}
  local function save()D.Content:save(D.Path(root,'Test/interrogation-contact-result.json'),D.json.encode(report))end
  save()
  local ok,err=xpcall(function()
   holder=D.Node();holder.x=-5000;holder:addTo(D.Director.ui3D)
   local function actor(skel,atlas,x,order)
    local asset=D.Path(root,skel)..'|'..D.Path(root,atlas);D.Cache:unload('spine:'..asset)
    local node=assert(D.Spine(asset));node.position=D.Vec2(x,30);node.order=order;node:addTo(holder);node.recovery=0;return node
   end
   local researcher=actor('Spine/StoryActions/researcher.skel','Spine/shujuyuan.atlas',270,0)
   local wuyun=actor('Spine/StoryActions/wuyun.skel','Spine/wuyun.atlas',380,1)
   local rt=D.RenderTarget(1000,700);local camera=D.Camera2D();camera.position=D.Vec2(-4650,205);camera.zoom=1.8;rt.camera=camera
   local markers=D.DrawNode();markers.order=10;markers:addTo(holder)
   local floor=D.DrawNode();floor:drawSegment(D.Vec2(0,30),D.Vec2(900,30),1,D.Color(0xff8999a9));floor:addTo(holder);floor.order=-1
   researcher:play('restrained',true);wuyun:play('coverHold',true);D.sleep(.05);researcher.speed=0;wuyun.speed=0
   local mouth=researcher:getKey('contact:mouth/mouth');local palm=wuyun:getKey('s:melee/s:melee')
   wuyun.x=researcher.x+mouth.x-palm.x
   report.initialVerticalError=palm.y-mouth.y
   report.centers={researcher=researcher.x,wuyun=wuyun.x};report.mouth={x=mouth.x,y=mouth.y};report.palm={x=palm.x,y=palm.y}
   for _,sample in ipairs({{'coverReach',.275},{'coverReach',.55},{'coverHold',1},{'coverRelease',.4}})do
    wuyun.speed=1;wuyun:play(sample[1],false);D.sleep(sample[2]);wuyun.speed=0
    local m=researcher:getKey('contact:mouth/mouth');local p=wuyun:getKey('s:melee/s:melee')
    local mx,my=researcher.x+m.x,researcher.y+m.y;local px,py=wuyun.x+p.x,wuyun.y+p.y
    markers:clear();markers:drawDot(D.Vec2(mx,my),2,D.Color(0xffff6060));markers:drawDot(D.Vec2(px,py),2,D.Color(0xff60ffff))
    local path=D.Path(root,'Docs/evidence/2026-10-04/interrogation-pair-'..sample[1]..'-'..sample[2]..'.png')
    rt:renderWithClear(holder,D.Color(0xff293341));rt:saveAsync(path)
    report.samples[#report.samples+1]={animation=sample[1],time=sample[2],contactDistance=math.sqrt((mx-px)^2+(my-py)^2),path=path}
   end
   researcher:removeFromParent();wuyun:removeFromParent();markers:clear()
   package.loaded['Factory.InterrogationActors']=nil
   local pair=require('Factory.InterrogationActors').new(holder);pair.node.position=D.Vec2(270,30)
   D.sleep(.05);assert(pair:coverAsync());assert(pair.phase=='holding')
   local maxDistance=0
   for i=1,150 do
    D.sleep(.02);local m,p=pair:contact();maxDistance=math.max(maxDistance,(m-p).length)
   end
   report.maxBreathingContactDistance=maxDistance
   assert(maxDistance<3,'Hand loses mouth contact during breathing')
   assert(pair:releaseAsync());assert(pair.phase=='ready');report.events=pair.events
   D.sleep(.2)
   pair.node:removeFromParent()
   report.mirroredCycles={}
   for _,delay in ipairs({0,.83})do
    local other=require('Factory.InterrogationActors').new(holder)
    other.node.position=D.Vec2(450,30);other.node.scaleX=-1
    if delay>0 then D.sleep(delay)end
    assert(other:coverAsync());local maximum=0
    for i=1,70 do D.sleep(.02);local m,p=other:contact();maximum=math.max(maximum,(m-p).length)end
    assert(maximum<3,'Mirrored hold loses mouth contact')
    assert(other:releaseAsync())
    report.mirroredCycles[#report.mirroredCycles+1]={initialDelay=delay,maxContactDistance=maximum,events=other.events}
    other.node:removeFromParent()
   end
   report.status='PASS';report.visualAcceptancePending=true
  end,debug.traceback)
  if holder then holder:removeFromParent()end
  if not ok then report.status='FAIL';report.error=err end
  save();print(D.json.encode(report))
 end)
end
