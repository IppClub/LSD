-- Native aiming calibration; standalone scene, no game save access.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/medium-yingzhao-aim-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
local function angle(x,y)return math.deg(math.atan(y,x))end
local function wrap(a)return (a+180)%360-180 end
D.thread(function()
 local ok,err=xpcall(function()
  D.App.winSize=D.Size(960,600)
  local asset='zhongyingzhao-weapon.skel|zhongyingzhao.atlas'
  D.Cache:loadAsync('spine:'..asset);D.Cache:loadAsync('spine:kineticgun')
  local models={}
  local ui=D.Node();ui:addTo(D.Director.ui3D);local size=D.App.bufferSize;ui.position=D.Vec2(-size.width/2,-size.height/2)
  for _,flip in ipairs({false,true})do
   local m=assert(D.Spine(asset));m.look='default';m.fliped=flip;m.recovery=.2;m:addTo(ui);m.position=D.Vec2(size.width*(flip and .7 or .3),220)
   local gun=assert(D.Spine('kineticgun'));gun.look='PT';gun.scaleX=.3;gun.scaleY=-.3;m:setSlot('pistol',gun)
   for _,clip in ipairs({'gunidle','shoot'})do
    m.speed=1;m:play(clip,false);D.sleep(1/3);m.speed=0;D.sleep(.05)
    local base=gun:convertToWorldSpace(D.Vec2.zero)
    local target=D.Vec2(base.x+(flip and 500 or -500),base.y-260)
    local rotation=0
    for i=1,20 do
     local p=gun:convertToWorldSpace(D.Vec2.zero);local q=gun:convertToWorldSpace(D.Vec2(300,0))
     local delta=wrap(angle(target.x-p.x,target.y-p.y)-angle(q.x-p.x,q.y-p.y))
     rotation=math.max(-45,math.min(45,rotation+(flip and -1 or 1)*delta*.5))
     assert(m:setBoneRotation('weapon-aim',rotation));D.sleep(.02)
    end
    local p=gun:convertToWorldSpace(D.Vec2.zero);local q=gun:convertToWorldSpace(D.Vec2(300,0))
    local error=wrap(angle(target.x-p.x,target.y-p.y)-angle(q.x-p.x,q.y-p.y))
    r.cases[#r.cases+1]={flip=flip,clip=clip,rotation=rotation,error=error,origin={x=p.x,y=p.y},muzzle={x=q.x,y=q.y},target={x=target.x,y=target.y}}
    assert(math.abs(error)<1,'Aiming did not converge: '..error)
    assert((q.x-p.x)*(flip and 1 or -1)>0 and q.y<p.y,'Wrong barrel direction')
    if clip=='gunidle' then assert(m:setBoneRotation('weapon-aim',0));D.sleep(.04)end
   end
   -- Drive the control while the source animation is advancing. Freeze the
   -- target position at preparation; record error at the authored recoil onset.
   assert(m:setBoneRotation('weapon-aim',0));m.speed=1;m:play('gunidle',true);D.sleep(.25)
   local p0=gun:convertToWorldSpace(D.Vec2.zero)
   local target=D.Vec2(p0.x+(flip and 500 or -500),p0.y-260)
   local started=D.App.runningTime;local duration=m:play('shoot',false);local rotation=0
   local ended
   m:slot('AnimationEnd',function(name)if name=='shoot' then ended=D.App.runningTime end end)
   while D.App.runningTime-started<1/3 do
    local p=gun:convertToWorldSpace(D.Vec2.zero);local q=gun:convertToWorldSpace(D.Vec2(300,0))
    local delta=wrap(angle(target.x-p.x,target.y-p.y)-angle(q.x-p.x,q.y-p.y))
    rotation=math.max(-45,math.min(45,rotation+(flip and -1 or 1)*delta*.5))
    assert(m:setBoneRotation('weapon-aim',rotation));D.sleep()
   end
   local p=gun:convertToWorldSpace(D.Vec2.zero);local q=gun:convertToWorldSpace(D.Vec2(300,0))
   local error=wrap(angle(target.x-p.x,target.y-p.y)-angle(q.x-p.x,q.y-p.y))
   local row={flip=flip,clip='shoot-live',rotation=rotation,error=error,fireTime=D.App.runningTime-started,duration=duration};r.cases[#r.cases+1]=row
   assert(math.abs(error)<3,'Live aiming missed firing frame: '..error)
   local deadline=started+3
   while not ended do assert(D.App.runningTime<deadline);D.sleep()end
   row.elapsed=ended-started;assert(row.elapsed>=duration-.025,'Aiming truncated animation')
   assert(m:setBoneRotation('weapon-aim',0));m:play('gunidle',true);D.sleep(.25)
   -- Retain an aimed firing pose for the visual check after dynamic validation.
   m:play('shoot',false);D.sleep(1/3);m.speed=0;m:setBoneRotation('weapon-aim',rotation);D.sleep(.05)
   models[#models+1]=m
  end
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/medium-yingzhao-aim.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
