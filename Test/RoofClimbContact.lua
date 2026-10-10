local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local result={status='RUNNING',scope='native planted-hand root and pause/resume; not roof route acceptance'};local out=D.Path(root,'Test/roof-climb-contact-result.json');D.Content:save(out,D.json.encode(result))
 local ok,why=xpcall(function()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff21333e));bg:addTo(ui,-100)
  local controllers={};local scale=1.65
  for i,name in ipairs({'charM','charF','ninilite'})do
   local x=ui.width*(i-.5)/3-45
   local wall=require('Factory.ControlPodArt').sprite('wall',ui,x+95,560,360,970,-20)
   local m=assert(D.Spine('Spine/Roof/'..name..'.json|Spine/'..name..'.atlas'));m.position=D.Vec2(x,150);m.scaleX=scale;m.scaleY=scale;m:addTo(ui)
   local c=require('Factory.RoofClimb').attach(m,name);controllers[#controllers+1]=c;c.maxStep=0;c.previousY=m.y
   local grips=D.DrawNode();grips:addTo(ui,-5)
   for row=0,5 do for _,key in ipairs({'HandL','HandR','FootL','FootR'})do
    local p=c:hold(key,row);grips:drawSegment(p-D.Vec2(12,4),p+D.Vec2(12,-4),5,D.Color(0xff35403d));grips:drawSegment(p-D.Vec2(10,0),p+D.Vec2(10,0),3,D.Color(0xffb69962))
   end end
   local l=D.Label('SourceHanSansCN-Regular',24);l.text=name..' · 支撑接触检查';l.position=D.Vec2(x,ui.height-40);l:addTo(ui,50)
  end
  local tick=D.Node();tick.scheduler=D.Director.postScheduler;tick:addTo(ui)
  tick:schedule(function()
   for _,c in ipairs(controllers)do c:update();if c.samples>3 then c.maxStep=math.max(c.maxStep,math.abs(c.model.y-c.previousY))end;c.previousY=c.model.y end
   return false
  end)
  for _,c in ipairs(controllers)do c:start()end
  D.sleep(1.05)
  local before={};for i,c in ipairs(controllers)do c:pause();before[i]={c.model.x,c.model.y,c:point('HandL').y}end
  D.sleep(.3)
  for i,c in ipairs(controllers)do assert(math.abs(c.model.y-before[i][2])<.001,'Paused root drift');assert(math.abs(c:point('HandL').y-before[i][3])<.001,'Paused animation drift');c:start()end
  D.sleep(1.3);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-climb-wall-contact.tga'))
  local deadline=D.App.runningTime+6
  while controllers[1].cycle<2 or controllers[2].cycle<2 or controllers[3].cycle<2 do assert(D.App.runningTime<deadline,'Missing grip cycle event');D.sleep(.01)end
  result.actors={}
  for _,c in ipairs(controllers)do
   c:pause();assert(c.maxSupportError<.2,'Planted support drift');assert(c.maxStep<3,'Root jump at handover or loop');assert(c.model.y-c.originY>190,'Root did not ascend two full cycles')
   result.actors[#result.actors+1]={name=c.definition.name,cycles=c.cycle,samples=c.samples,maxSupportError=c.maxSupportError,maxFrameRise=c.maxStep,rise=c.model.y-c.originY}
  end
  tick:unschedule()
  local transition={}
  for i,c in ipairs(controllers)do
   transition[i]={start=c:point('FootR').y,previous=c:point('FootR').y,maxStep=0,rootY=c.model.y}
   c:dispose();c.model.speed=1;c.model.recovery=0;c.model:play('climbSettle',false)
  end
  local startTransition=D.App.runningTime;local untilTime=startTransition+.8;local returned=false
  while D.App.runningTime<untilTime do
   D.sleep(.01)
   if not returned and D.App.runningTime-startTransition>=.42 then
    returned=true;for _,c in ipairs(controllers)do c.model.recovery=.2;c.model:play('idle',true)end
   end
   for i,c in ipairs(controllers)do
    local p=c:point('FootR').y;local tr=transition[i];tr.maxStep=math.max(tr.maxStep,math.abs(p-tr.previous));tr.previous=p
    assert(math.abs(c.model.y-tr.rootY)<.001,'Recovery moved actor root')
   end
  end
  for i,c in ipairs(controllers)do
   local tr=transition[i];result.actors[i].recoveryMaxFootStep=tr.maxStep;result.actors[i].recoveryFootDrop=tr.start-tr.previous;assert(tr.start-tr.previous>20,'Foot did not settle from climb to idle');assert(tr.maxStep<18,'Recovery snapped foot')
   result.actors[i].recoveryMaxFootStep=tr.maxStep;result.actors[i].recoveryFootDrop=tr.start-tr.previous
  end
  result.status='PASS';result.pauseResume=true;result.nativeRecovery=true;result.visualAcceptance=false
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end
 D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
