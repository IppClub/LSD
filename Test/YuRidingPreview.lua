-- Standalone visual review: run only after the active training soak is terminal.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={runId=os.time(),status='RUNNING',runtimeInstalled=false,visualAcceptancePending=true,events={}}
local out=D.Path(root,'Test/yu-riding-preview-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local holder=D.Node();holder.position=D.Vec2(-D.App.bufferSize.width/2,-D.App.bufferSize.height/2);holder:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2(0,0),D.Vec2(1792,0),D.Vec2(1792,1136),D.Vec2(0,1136)},D.Color(0xff293341));bg:addTo(holder)
  local asset=D.Path(root,'Docs/artwork/yu-riding/riding-candidate.json')..'|'..D.Path(root,'Spine/yu.atlas')
  local original=assert(D.Spine('yu'));original.position=D.Vec2(500,190);original.scaleX=2;original.scaleY=2;original.recovery=0;original:play('idle',true);original:addTo(holder)
  local model=assert(D.Spine(asset));model.position=D.Vec2(1130,190);model.scaleX=2;model.scaleY=2;model.recovery=.2;model:play('idle',true);model:addTo(holder)
  for _,item in ipairs({{500,'原版待机'},{1130,'乘坐动作候选 · 尚未接入'}})do local l=D.Label('SourceHanSansCN-Regular',28);l.text=item[2];l.position=D.Vec2(item[1],900);l:addTo(holder)end
  model:slot('AnimationEnd',function(name)report.events[#report.events+1]={name=name,time=D.App.runningTime}end)
  local function finite(name)
   local before=#report.events;local start=D.App.runningTime;local duration=model:play(name,false);assert(duration>0)
   local ended=false
   while not ended do
    assert(D.App.runningTime-start<duration+.8,'Finite animation stalled: '..name)
    D.sleep(.02)
    for i=before+1,#report.events do local e=report.events[i];if e.name==name and e.time-start>=duration-.04 then ended=true end end
   end
   return D.App.runningTime-start
  end
  D.sleep(.3);report.sitSeconds=finite('sit');model.recovery=0;model:play('ride',true);D.sleep(.3)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/yu-riding-candidate.tga'));D.sleep(.2)
  local count=#report.events;D.sleep(4.1);local loops=0
  for i=count+1,#report.events do if report.events[i].name=='ride'then loops=loops+1 end end
  assert(loops>=2,'Ride loops cut short or missing');report.rideLoops=loops
  report.standSeconds=finite('stand');model.recovery=.2;model:play('idle',true);D.sleep(.4)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/yu-riding-recovered.tga'));D.sleep(.2)
  report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
