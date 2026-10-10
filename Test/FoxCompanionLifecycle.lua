-- Native candidate lifecycle at the actual companion height; no save is attached.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test/fox-companion-lifecycle-result.txt')
D.Content:save(out,'LSD_FOX_LIFECYCLE_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local m=require('Story.FoxCompanionCandidate').create('v4');m.position=D.Vec2(ui.width*.35,ui.height*.25);m:addTo(ui)
  local ends,steps,events=0,0,{};local velocity=0
  m:slot('AnimationEnd',function(name)if name=='move'then ends=ends+1 end end)
  m:slot('ModelEvent',function(_,name)if name=='step'then steps=steps+1;events[#events+1]={time=D.App.runningTime,kind='step',cycle=ends,fliped=m.fliped}end end)
  local driver=D.Node();driver:addTo(ui);driver:schedule(function(dt)m.x=m.x+velocity*dt;return false end)
  local function cycles(n)
   local base=ends;local baseSteps=steps;local deadline=D.App.runningTime+n/m.speed+3
   while ends-base<n do assert(D.App.runningTime<deadline,'Missing looping AnimationEnd');D.sleep(.01)end
   assert(steps-baseSteps==2*n,'Looped step events '..(steps-baseSteps)..' expected '..2*n)
  end
  local speed=200/(180*(300/699)/.6);m.speed=speed;m:play('move',true);velocity=200;cycles(4)
  local foot=m:getNodeByName('nearFoot');m:pause();velocity=0
  local x,y=foot.x,foot.y;local count=steps;local countEnds=ends;D.sleep(.4)
  assert(m.paused and math.abs(foot.x-x)<.001 and math.abs(foot.y-y)<.001 and steps==count and ends==countEnds,'Pause changed pose/events')
  m:resume();assert(not m.paused);velocity=200;cycles(2)
  -- Turn around while retaining the same gait and without restarting its timeline.
  velocity=-200;m.fliped=true;cycles(4);velocity=0
  m.speed=1;m:play('idle',true);D.sleep(.25)
  local p=foot:convertToWorldSpace(D.Vec2(foot.width*foot.anchor.x,foot.height*foot.anchor.y));D.sleep(.5)
  assert((foot:convertToWorldSpace(D.Vec2(foot.width*foot.anchor.x,foot.height*foot.anchor.y))-p).length<.05,'Stopped idle foot drift')
  local prepared=false;local began=D.App.runningTime;local duration=m:play('prepare',false)
  m:slot('AnimationEnd',function(name)if name=='prepare'then prepared=true;assert(D.App.runningTime-began>=duration-.05,'Early finite reset');m:play('idle',true)end end)
  while not prepared do assert(D.App.runningTime<began+duration+1);D.sleep(.01)end
  D.sleep(.25);assert(m.current=='idle','Finite action did not recover to idle')
  velocity=200;m.fliped=false;m.speed=speed;m:play('move',true);cycles(3);velocity=0;m.speed=1;m:play('idle',true)
  assert(m.face.cycles>=3,'Realtime blink did not survive gait lifecycle')
  D.Content:save(D.Path(root,'Docs/evidence/2026-10-03/fox-lifecycle-events.json'),D.json.encode(events,false,true))
  return 'PASS actualHeight300=true velocity200=true thirteenGaitCycles=true pauseResume=true turn=true restart=true recoveryToIdle=true blinkCycles='..m.face.cycles..' stepEvents='..steps..' speed='..speed
 end,debug.traceback)
 local report='LSD_FOX_LIFECYCLE_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
