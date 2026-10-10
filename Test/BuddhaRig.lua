local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={status='RUNNING',runId=os.time(),osInput=false};local out=D.Path(root,'Test/buddha-rig-result.json');D.Content:save(out,D.json.encode(report))
local robot=require('Rescue.BuddhaPrototype').create();robot:addTo(D.Director.ui3D)
D.thread(function()
 local ok,why=xpcall(function()
  assert(#robot.arms==6);local frames=0;local maxHandTilt=0
  for _,state in ipairs({true,false,true,false})do
   local before=robot.completedTransitions;robot:emit('Guard',state);local started=D.App.runningTime
   while robot.state=='recovering'do
    assert(D.App.runningTime-started<.35,'Recovery did not finish');D.sleep()
   end
   assert(robot.completedTransitions==before+1);assert(D.App.runningTime-started>=.18)
   local untilTime=D.App.runningTime+1.1
   while D.App.runningTime<untilTime do
    robot:emit('Guard',state);assert(robot.state==(state and 'guard'or'idle'),'Repeated state restarted recovery')
    for _,a in ipairs(robot.arms)do
     assert(a.elbow.parent==a.shoulder and a.wrist.parent==a.elbow and a.hand.parent==a.wrist)
     if a.index==3 then local tilt=math.abs(a.shoulder.angle+a.elbow.angle+a.hand.angle);maxHandTilt=math.max(maxHandTilt,tilt);assert(tilt<.001)end
    end
    frames=frames+1;D.sleep()
   end
  end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/buddha-rig-idle-recovered.tga'))
  report.frames=frames;report.transitions=robot.completedTransitions;report.maxHandTilt=maxHandTilt;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
