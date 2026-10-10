local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=D.Path(root,'Test/control-pod-aim-preview-result.json');local report={status='RUNNING'};D.Content:save(out,D.json.encode(report))
 local ok,why=xpcall(function()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff263640));bg:addTo(ui)
  local ready=0;local models={}
  for i,name in ipairs({'charM','charF','ninilite'})do
   local m=assert(D.Spine('Spine/ControlPod/'..name..'.json|Spine/'..name..'.atlas'));m.position=D.Vec2(ui.width*(i-.5)/3,230);m.scaleX=1.5;m.scaleY=1.5;m.recovery=.15;m:addTo(ui);models[#models+1]=m
   local gun=assert(D.Spine('kineticgun'));gun.look='PT';gun.scaleX=.3;gun.scaleY=.3;m:setSlot('pistol',gun)
   m:slot('aimReady',function()m.speed=0;ready=ready+1 end);assert(m:play('aim',false)>0)
   local l=D.Label('SourceHanSansCN-Regular',26);l.text=name..' · 持枪';l.position=D.Vec2(m.x,800);l:addTo(ui)
  end
  local deadline=D.App.runningTime+5;while ready<3 do assert(D.App.runningTime<deadline);D.sleep(.02)end
  D.sleep(.2);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/control-pod-aim-three-actors.tga'))
  report.status='PASS';report.nativeAimReady=ready;report.threeActors=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
