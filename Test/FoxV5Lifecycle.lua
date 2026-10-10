-- Actual world translation, source-pixel joints, toe orientation and recovery.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test/fox-v5-lifecycle-result.txt');D.Content:save(out,'LSD_FOX_V5_LIFECYCLE_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff293341));bg:addTo(ui)
  local m=require('Story.FoxCompanionCandidate').create('v5');m.position=D.Vec2(600,250);m:addTo(ui)
  local move=require('Story.FoxMovement');local manifest=assert(D.json.decode(D.Content:load('Image/Companion/fox-chibi-motion-v5-manifest.json')))
  local label=D.Label('SourceHanSansCN-Regular',26);label.position=D.Vec2(ui.width/2,700);label:addTo(ui)
  local function point(name,pixel)
   -- transformTarget caches are refreshed by render traversal; tests run before render.
   local chain={};local node=m:getNodeByName(name..'-bone');while node do chain[#chain+1]=node;node=node.parent end
   for i=#chain,1,-1 do chain[i]:convertToWorldSpace(D.Vec2.zero)end
   local r=manifest.landmarks[name][1];return m:getNodeByName(name):convertToWorldSpace(D.Vec2(pixel[1]-r[1],r[4]-(pixel[2]-r[2])))end
  local pairs={{'nearUpperArm','nearForearm'},{'farUpperArm','farForearm'},{'nearThigh','nearShin'},{'farThigh','farShin'},{'nearShin','nearFoot'},{'farShin','farFoot'}}
  local velocity=0;local ends,steps,maxJoint,maxStance,stanceSamples=0,0,0,0,0;local stanceStart;local events={};local gaitReadyAt=0;local stanceRecords={}
  m:slot('AnimationEnd',function(name)if name=='move'then ends=ends+1 end end)
  m:slot('ModelEvent',function(_,name)if name=='step'then steps=steps+1;events[#events+1]={time=D.App.runningTime,velocity=velocity,fliped=m.fliped}end end)
  local tick=D.Node();tick:addTo(ui);tick:schedule(function(dt)
   if velocity~=0 then move.step(m,velocity,dt)end
   for _,pair in ipairs(pairs)do local a,b=pair[1],pair[2];maxJoint=math.max(maxJoint,(point(a,manifest.landmarks[a][3])-point(b,manifest.landmarks[b][2])).length)end
   for _,name in ipairs({'nearFoot','farFoot'})do
    local p=point(name,manifest.landmarks[name][2]);local toe=point(name,manifest.footForwardLandmarks[name]);local sign=m.fliped and 1 or -1
    assert((toe.x-p.x)*sign>0,'Toe points against character direction')
   end
   local f=m:getNodeByName('rig'):convertToNodeSpace(point('nearFoot',manifest.landmarks.nearFoot[2]))
   if velocity~=0 and D.App.runningTime>=gaitReadyAt and math.abs(f.y-57)<.001 and f.x>-80 and f.x<0 then
    local x=point('nearFoot',manifest.landmarks.nearFoot[2]).x
    stanceRecords[#stanceRecords+1]={time=D.App.runningTime,x=x,modelX=m.x,localX=f.x,velocity=velocity,speed=m.speed}
    if stanceStart then maxStance=math.max(maxStance,math.abs(x-stanceStart));stanceSamples=stanceSamples+1 else stanceStart=x end
   else stanceStart=nil end
   return false
  end)
  local function run(v,n)
   stanceStart=nil;gaitReadyAt=D.App.runningTime;velocity=v;move.setVelocity(m,v);label.text=v>0 and '实际向右行走 · 200 单位/秒' or '实际向左行走 · 200 单位/秒'
   assert(m.fliped==(v>0));assert(math.abs(m.recovery/m.speed-.2)<1e-5)
   local target=ends+n;local deadline=D.App.runningTime+n/m.speed+2
   while ends<target do assert(D.App.runningTime<deadline,'Missing complete movement cycles');D.sleep(.01)end
  end
  run(200,3);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-v5-world-right.tga'));D.sleep(.05)
  run(-200,5);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-v5-world-left.tga'));D.sleep(.05)
  velocity=0;move.setVelocity(m,0);label.text='停步恢复 idle · 双脚固定';D.sleep(.3)
  local p=point('nearFoot',manifest.landmarks.nearFoot[2]);local q=point('farFoot',manifest.landmarks.farFoot[2]);D.sleep(.6)
  assert((p-point('nearFoot',manifest.landmarks.nearFoot[2])).length<.05 and(q-point('farFoot',manifest.landmarks.farFoot[2])).length<.05,'Idle feet drift')
  local endAt;local began=D.App.runningTime;m:slot('AnimationEnd',function(name)if name=='prepare'then endAt=D.App.runningTime;m:play('idle',true)end end)
  local duration=m:play('prepare',false)
  while not endAt do assert(D.App.runningTime<began+duration+1);D.sleep(.01)end
  assert(endAt-began>=duration-.05,'Finite action reset early');D.sleep(.3);assert(m.current=='idle')
  run(200,2);m:pause();velocity=0;local pausedFoot=point('nearFoot',manifest.landmarks.nearFoot[2]);local oldSteps=steps;D.sleep(.4)
  assert((point('nearFoot',manifest.landmarks.nearFoot[2])-pausedFoot).length<.001 and steps==oldSteps,'Pause moved foot '..(point('nearFoot',manifest.landmarks.nearFoot[2])-pausedFoot).length..' paused='..tostring(m.paused)..' steps='..steps..'/'..oldSteps)
  m:resume();run(-200,2);velocity=0;move.setVelocity(m,0);D.sleep(.3)
  D.Content:save(D.Path(root,'Docs/evidence/2026-10-03/fox-v5-stance-samples.json'),D.json.encode(stanceRecords,false,true))
  assert(maxJoint<1.2,'Joint separation during recovery '..maxJoint);assert(stanceSamples>20 and maxStance<2,'World foot stance slid '..maxStance)
  assert(m.face.cycles>=3 and steps>=24,'Animation events missing')
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-v5-world-idle.tga'))
  D.Content:save(D.Path(root,'Docs/evidence/2026-10-03/fox-v5-lifecycle-events.json'),D.json.encode(events,false,true))
  return 'PASS sourcePixelJoints=true actualVelocity200=true correctFacingBothWays=true bothFeetForward=true fullFiniteRecovery=true pauseResume=true idleFeetFixed=true maxJoint='..maxJoint..' stanceDrift='..maxStance..' stanceSamples='..stanceSamples..' blinkCycles='..m.face.cycles..' steps='..steps
 end,debug.traceback)
 local report='LSD_FOX_V5_LIFECYCLE_'..(ok and result or 'FAIL '..result)..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
