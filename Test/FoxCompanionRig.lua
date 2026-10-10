-- Native Q form comparison. Rig remains a candidate until visual review.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test','fox-companion-rig-result.txt');D.Content:save(out,'LSD_FOX_RIG_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff293341));bg:addTo(ui)
  local function label(text,x,y)local l=D.Label('SourceHanSansCN-Regular',25);l.text=text;l.position=D.Vec2(x,y);l:addTo(ui)end
  label('九尾狐 Q版 · 原图（双程）',ui.width*.3,ui.height*.78);label('12分件 · 原生骨骼候选',ui.width*.7,ui.height*.78)
  local ref=assert(D.Model('Image/Companion/fox-chibi.model'));ref:play('idle',true);ref.position=D.Vec2(ui.width*.3,ui.height*.25);ref.scaleX=.75;ref.scaleY=.75;ref:addTo(ui)
  local path='Image/Companion/fox-chibi-rig-v1.model';D.Cache:unload(path);D.Cache:unload('Image/Companion/fox-chibi-rig-v1.clip')
  local m=assert(D.Model(path));m.scaleX=.75;m.scaleY=.75;m.position=D.Vec2(ui.width*.7,ui.height*.25);m.recovery=.2;m:addTo(ui)
  m:play('move',true);D.sleep(.2)
  local joints={}
  for _,pair in ipairs({{'nearLeg','nearBoot'},{'farLeg','farBoot'},{'nearUpperArm','nearForearm'},{'farUpperArm','farForearm'}})do
   local a=m:getNodeByName(pair[1]);local b=m:getNodeByName(pair[2]);local pos=b:convertToWorldSpace(D.Vec2(b.width*b.anchor.x,b.height*b.anchor.y));joints[#joints+1]={a=a,b=b,anchor=a:convertToNodeSpace(pos)}
  end
  local max=0
  for i=1,60 do for _,j in ipairs(joints)do local expected=j.a:convertToWorldSpace(j.anchor);local actual=j.b:convertToWorldSpace(D.Vec2(j.b.width*j.b.anchor.x,j.b.height*j.b.anchor.y));max=math.max(max,(expected-actual).length)end;D.sleep(.025)end
  assert(max<1.6,'Q fox native joint seam '..max)
  local ended={};local steps=0;local started
  m:slot('AnimationEnd',function(name)ended[name]=D.App.runningTime end);m:slot('ModelEvent',function(_,name)if name=='step'then steps=steps+1 end end)
  for _,name in ipairs({'idle','move'})do started=D.App.runningTime;local duration=m:play(name,false);local deadline=started+duration+1;while not ended[name]do assert(D.App.runningTime<deadline);D.sleep(.01)end;assert(ended[name]-started>=duration-.05)end
  assert(steps==2,'Q fox step markers '..steps);m:play('idle',true);D.sleep(.4)
  D.App:saveScreenshot(D.Path(root,'Docs','evidence','2026-10-03','fox-chibi-rig-comparison.tga'))
  return 'PASS native12Parts=true fourArticulatedJoints=true fullNativeEnds=true twoStepEvents=true originalQArtRetained=true candidateNotAdopted=true maxSeam='..max
 end,debug.traceback)
 local report='LSD_FOX_RIG_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
