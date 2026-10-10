local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=D.Path(root,'Test/roof-traverse-result.json');local report={status='RUNNING',scope='native full wall traversal fixture; not story or OS input'};D.Content:save(out,D.json.encode(report))
 local ok,why=xpcall(function()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff243440));bg:addTo(ui,-100)
  local results={};local done=0
  for i,name in ipairs({'charM','charF','ninilite'})do
   local lane=D.Node();lane.position=D.Vec2((i-1)*ui.width/3+60,65);lane:addTo(ui)
   local s=.9;lane.scaleX=s;lane.scaleY=s
   local wall=D.DrawNode();wall:drawPolygon({D.Vec2(150,0),D.Vec2(520,0),D.Vec2(520,450),D.Vec2(150,450)},D.Color(0xff454c48));wall:addTo(lane,-20)
   require('Factory.RoofArt').sprite('catwalk',lane,340,399,420,72,-10)
   local m=assert(D.Spine('Spine/Roof/'..name..'.json|Spine/'..name..'.atlas'));m.position=D.Vec2(110,0);m:addTo(lane,20)
   local title=D.Label('SourceHanSansCN-Regular',22);title.text=name..' · 起攀 / 越墙 / 落地';title.position=D.Vec2(250,1040);title:addTo(lane)
   local status=D.Label('SourceHanSansCN-Regular',20);status.position=D.Vec2(250,995);status:addTo(lane)
   D.thread(function()
    local r,err=require('Factory.RoofTraverse').runAsync(m,name,{top=450,wallX=150,landingX=340,onCrossing=function()D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-traverse-'..name..'-crossing.tga'))end});results[i]=r or err;done=done+1;status.text=r and '完成' or '失败'
   end)
  end
  D.sleep(7.9);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-traverse-climb.tga'))
  D.sleep(3);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-traverse-flight.tga'))
  local deadline=D.App.runningTime+10;while done<3 do assert(D.App.runningTime<deadline,'Fixture timeout');D.sleep(.05)end
  report.actors=results
  for _,r in ipairs(results)do assert(r.phase=='complete',r.error);assert(r.endX==340 and r.endY==450);assert(r.contactSamples>100);assert(r.flightSamples>30);assert(r.maxFrameDisplacement<25,'Traversal root teleported');assert(math.abs(r.recovery-.2)<.001)end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-traverse-landed.tga'));report.status='PASS';report.osInput=false;report.visualAcceptance=false
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
