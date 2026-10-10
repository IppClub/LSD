local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={runId=os.time(),status='RUNNING',runtimeSceneIntegrated=false,visualAcceptancePending=true,cases={}}
local out=D.Path(root,'Test/yu-carrier-lifecycle-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local screen=D.Node();screen.position=D.Vec2(-D.App.bufferSize.width/2,-D.App.bufferSize.height/2);screen:addTo(D.Director.ui3D)
  local asset=D.Path(root,'Docs/artwork/yu-riding/riding-candidate.json')..'|'..D.Path(root,'Spine/yu.atlas')
  local carrier=require('Rescue.BuddhaCarrier').new(screen,750,180,asset,require('Test.BuddhaChibiStyle'));carrier.node.scaleX=1.15;carrier.node.scaleY=1.15
  for cycle=1,2 do
   assert(carrier:mountAsync());assert(carrier.phase=='riding' and carrier.weight==1)
   local started=D.App.runningTime
   while D.App.runningTime-started<2.2 do
    carrier.node.x=750+math.sin((D.App.runningTime-started)*2)*100;carrier:guard(true);D.sleep()
   end
   D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/yu-carrier-riding-'..cycle..'.tga'));D.sleep(.15)
   assert(carrier:landAsync());D.sleep(.25)
   report.landed={phase=carrier.phase,weight=carrier.weight,x=carrier.rider.x,y=carrier.rider.y,recovery=carrier.rider.recovery}
   assert(carrier.phase=='ground' and carrier.weight==0 and carrier.rider.position.length<.001 and math.abs(carrier.rider.recovery-.2)<.00001, D.json.encode(report.landed))
   report.cases[#report.cases+1]={cycle=cycle,mountSeconds=carrier.events[#carrier.events-1].ended-carrier.events[#carrier.events-1].started,landSeconds=carrier.events[#carrier.events].ended-carrier.events[#carrier.events].started}
  end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/yu-carrier-landed.tga'));D.sleep(.15)
  local done,result,reason=false
  D.thread(function()result,reason=carrier:mountAsync();done=true end)
  D.sleep(.2);assert(carrier.phase=='mounting');local accepted,why=carrier:mountAsync();assert(not accepted and why=='BUSY')
  carrier:dispose();local limit=D.App.runningTime+2
  while not done do assert(D.App.runningTime<limit,'Disposed transfer did not terminate');D.sleep()end
  assert(not result and reason=='CLOSED');report.cleanupCancelled=true;report.reentryRejected=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
