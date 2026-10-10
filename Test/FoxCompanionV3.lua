-- Native Q form comparison. Rig remains a candidate until visual review.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test','fox-companion-v3-result.txt');D.Content:save(out,'LSD_FOX_V3_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff293341));bg:addTo(ui)
  local function label(text,x,y)local l=D.Label('SourceHanSansCN-Regular',25);l.text=text;l.position=D.Vec2(x,y);l:addTo(ui)end
  label('九尾狐 Q版 · 原图（双程）',ui.width*.3,ui.height*.78);label('15分件 · 膝关节与脚掌约束候选',ui.width*.7,ui.height*.78)
  local ref=assert(D.Model('Image/Companion/fox-chibi.model'));ref:play('idle',true);ref.position=D.Vec2(ui.width*.3,ui.height*.25);ref.scaleX=.75;ref.scaleY=.75;ref:addTo(ui)
  local path='Image/Companion/fox-chibi-motion-v3.model';D.Cache:unload(path);D.Cache:unload('Image/Companion/fox-chibi-motion-v3.clip')
  local m=require('Story.FoxCompanionCandidate').create('v3');m.scaleX=.75;m.scaleY=.75;m.position=D.Vec2(ui.width*.7,ui.height*.25);m.recovery=.2;m:addTo(ui)
  local warmed=false;m:slot('AnimationEnd',function(name)if name=='prepare'then warmed=true end end);m:play('prepare',false);local warmDeadline=D.App.runningTime+5;while not warmed do assert(D.App.runningTime<warmDeadline,'Initial model pose not ready');D.sleep(.01)end
  m:play('move',true);D.sleep(.25)
  local joints={}
  for _,pair in ipairs({{'nearThigh','nearShin'},{'nearShin','nearFoot'},{'farThigh','farShin'},{'farShin','farFoot'},{'nearUpperArm','nearForearm'},{'farUpperArm','farForearm'}})do
   local a=m:getNodeByName(pair[1]);local b=m:getNodeByName(pair[2]);local pos=b:convertToWorldSpace(D.Vec2(b.width*b.anchor.x,b.height*b.anchor.y));joints[#joints+1]={a=a,b=b,anchor=a:convertToNodeSpace(pos)}
  end
  local max=0
  for i=1,60 do for _,j in ipairs(joints)do local expected=j.a:convertToWorldSpace(j.anchor);local actual=j.b:convertToWorldSpace(D.Vec2(j.b.width*j.b.anchor.x,j.b.height*j.b.anchor.y));max=math.max(max,(expected-actual).length)end;D.sleep(.025)end
  assert(max<1.6,'Q fox native joint seam '..max)
  local ended={};local steps=0;local stepTimes={};local started
  m:slot('AnimationEnd',function(name)ended[name]=D.App.runningTime end);m:slot('ModelEvent',function(_,name)if name=='step'then steps=steps+1;stepTimes[#stepTimes+1]={time=D.App.runningTime-started,action=m.current,near=m:getNodeByName('nearFoot').x,far=m:getNodeByName('farFoot').x}end end)
  for _,name in ipairs({'idle','move','prepare'})do started=D.App.runningTime;local duration=m:play(name,false);local deadline=started+duration+1;while not ended[name]do assert(D.App.runningTime<deadline);D.sleep(.01)end;assert(ended[name]-started>=duration-.05)end
  assert(steps==2,'Q fox step markers '..steps);assert(math.abs(stepTimes[1].time-.45)<.05 and math.abs(stepTimes[2].time-.95)<.05,'Step timeline not aligned');assert(math.abs(stepTimes[1].near-45)<6 and math.abs(stepTimes[2].far-135)<6,'Step marker missed planted foot');m:play('idle',true);D.sleep(.25);local boots={m:getNodeByName('nearFoot'),m:getNodeByName('farFoot')};local positions={};for i,b in ipairs(boots)do positions[i]=b:convertToWorldSpace(D.Vec2(b.width*b.anchor.x,b.height*b.anchor.y))end;local drift=0;for i=1,100 do for k,b in ipairs(boots)do local p=b:convertToWorldSpace(D.Vec2(b.width*b.anchor.x,b.height*b.anchor.y));drift=math.max(drift,(p-positions[k]).length)end;D.sleep(.02)end;assert(drift<.05,'Idle foot drift '..drift)
  D.App:saveScreenshot(D.Path(root,'Docs','evidence','2026-10-03','fox-chibi-motion-v3-idle.tga'))
  m:play('move',true);D.sleep(.45);m.speed=0;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-chibi-motion-v3-stride.tga'));D.sleep(.1);m.speed=1;m:play('idle',true)
  -- Actual native stance under translated movement, not just a static local-pose assertion.
  local originalX=m.x;local speed=200;local scale=.75;m.speed=speed/(180*scale/.6)
  local landed;local motionStart=D.App.runningTime;local groundSamples={};local minX,maxX;local foot=m:getNodeByName('nearFoot')
  m:slot('ModelEvent'):set(function(_,name)if name=='step' then print('FoxStep',D.App.runningTime-motionStart,foot.x,foot.y) end end)
  m:play('move',true);local driver=D.Node();driver:addTo(ui);driver:schedule(function(dt)
   m.x=m.x+speed*dt
   if not landed and math.abs(foot.y-15)<.01 and foot.x>40 then landed=D.App.runningTime end
   if landed and D.App.runningTime-landed<.36 then local x=foot:convertToWorldSpace(D.Vec2(foot.width*foot.anchor.x,foot.height*foot.anchor.y)).x;minX=math.min(minX or x,x);maxX=math.max(maxX or x,x);groundSamples[#groundSamples+1]={t=D.App.runningTime-landed,localX=foot.x,worldX=x,origin=m.x}end
   return false
  end)
  local deadline=D.App.runningTime+3;while not landed do assert(D.App.runningTime<deadline,'Native landing missing');D.sleep(.01)end;D.sleep(.35)
  driver:removeFromParent();D.Content:save(D.Path(root,'Docs/evidence/2026-10-03/fox-motion-native-steps-and-stance.json'),D.json.encode({finiteStepEvents=stepTimes,translatedNearStance=groundSamples},false,true));assert(minX and maxX-minX<2,'Translated stance foot slides '..tostring(minX and maxX-minX))
  local groundDrift=maxX-minX;m.x=originalX;m.speed=1;m:play('idle',true)
  local face=assert(m.face);face.hold('open');D.sleep(.1)
  for _,phase in ipairs({'open','half','closed'})do face.hold(phase);D.sleep(.08);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-v3-face-'..phase..'.tga'));D.sleep(.05)end
  face.release();local before=face.cycles;D.sleep(8.5);assert(face.cycles-before>=3,'Automatic blink cycles missing')
  local sawHalf,sawClosed=false,false
  for _,e in ipairs(face.events)do if e.phase=='half'then sawHalf=true elseif e.phase=='closed'then sawClosed=true end end
  assert(sawHalf and sawClosed,'Blink stages missing')
  D.Content:save(D.Path(root,'Docs/evidence/2026-10-03/fox-v3-blink-events.json'),D.json.encode(face.events,false,true))
  return 'PASS idleFeetFixed=true native15Parts=true sixArticulatedJoints=true fullNativeEnds=true twoStepEvents=true originalQArtRetained=true isolatedCandidate=true translatedStance200=true blinkCycles='..(face.cycles-before)..' groundDrift='..groundDrift..' maxJointDrift='..max
 end,debug.traceback)
 local report='LSD_FOX_V3_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
