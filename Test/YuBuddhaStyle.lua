-- Combined visual contact study; does not change production actors or Ward.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={runId=os.time(),status='RUNNING',runtimeInstalled=false,visualAcceptancePending=true}
local out=D.Path(root,'Test/yu-buddha-style-v3-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local screen=D.Node();screen.position=D.Vec2(-D.App.bufferSize.width/2,-D.App.bufferSize.height/2);screen:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2(0,0),D.Vec2(1792,0),D.Vec2(1792,1136),D.Vec2(0,1136)},D.Color(0xff293341));bg:addTo(screen)
  local cases={}
  for i,mirrored in ipairs({false,true})do
   local group=D.Node();group.position=D.Vec2(i==1 and 480 or 1280,610);group.scaleX=1.2;group.scaleY=1.2;group:addTo(screen)
   local robot=require('Rescue.BuddhaPrototype').create(i==2 and require('Test.BuddhaChibiStyle') or nil);robot:addTo(group)
   local yu=assert(D.Spine(D.Path(root,'Docs/artwork/yu-riding/riding-candidate.json')..'|'..D.Path(root,'Spine/yu.atlas')));yu.order=1;yu.recovery=0;yu:play('ride',true);yu:addTo(group)
   local hands={};for _,a in ipairs(robot.arms)do if a.index==3 then hands[#hands+1]=a.hand end end
   local sample={robot=robot,yu=yu,group=group,hands=hands,handY=i==2 and 210 or 250};cases[#cases+1]=sample
   local label=D.Label('SourceHanSansCN-Regular',25);label.text=i==2 and '新版：浅金、大头比例' or '旧版：对照';label.position=D.Vec2(group.x,1000);label:addTo(screen)
  end
  local tick=D.Node();tick:addTo(screen);local frames=0
  tick:schedule(function()
   for _,s in ipairs(cases)do
    local p=s.group:convertToNodeSpace(s.hands[1]:convertToWorldSpace(D.Vec2(310,s.handY)))
    local q=s.group:convertToNodeSpace(s.hands[2]:convertToWorldSpace(D.Vec2(310,s.handY)))
    s.yu.position=(p+q)*.5-D.Vec2(5,75)
   end
   frames=frames+1;return false
  end)
  D.sleep(1.2);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/yu-buddha-style-v3.tga'));D.sleep(.2)
  for _,s in ipairs(cases)do s.robot:emit('Guard',true)end
  D.sleep(1);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/yu-buddha-style-v3-guard.tga'));D.sleep(.2)
  report.frames=frames;report.status='PASS';report.scope='Combined preview loaded; palm anchors provisional, no visual acceptance assertion'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
