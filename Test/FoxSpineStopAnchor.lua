-- Deterministic native animation test, not simulated user input or gameplay acceptance.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local ContactLock=require('Story.FoxSpineContactLock')
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local asset=D.Path(root,'Docs/artwork/fox-export/fox-chibi-spine.skel')..'|'..D.Path(root,'Spine/FoxPrototype/fox-chibi-spine.atlas')
  D.Cache:unload('spine:'..asset);D.Cache:unload(D.Path(root,'Spine/FoxPrototype/fox-chibi-spine.atlas'))
  local ui=D.Node();ui:addTo(D.Director.ui3D)
  local fox=assert(D.Spine(asset));fox.scaleX=.55;fox.scaleY=.55;fox.y=320;fox:addTo(ui)
  local post=D.Node();post.scheduler=D.Director.postScheduler;post:addTo(ui)
  local active;local rows={};local maxDrift=0;local maxSettle=0;local maxUncorrected=0
  post:schedule(function(dt)
   if active then
    local done=ContactLock.update(active,fox,dt)
    if done then active.done=true;active=nil end
   end
   return false
  end)
  for _,direction in ipairs({-1,1})do for phase=0,11 do
   fox.x=800;fox.fliped=direction>0;fox.speed=180/(192*.55);fox.recovery=0;fox:play('fmove',true)
   D.sleep((phase/12)/fox.speed)
   local lock=ContactLock.begin(fox,.2);active=lock
   fox.speed=1;fox.recovery=.15;fox:play('idle',true)
   while not lock.done do D.sleep()end
   assert(lock.settled and not lock.timedOut,'foot anchor did not settle')
   -- Verify the rendered/native point remains anchored after the correction ends.
   D.sleep(.1)
   local p=fox:getKey(lock.name);local drift=math.abs(fox.x+p.x*fox.scaleX-lock.anchorX)
   local uncorrected=math.abs(lock.startX+p.x*fox.scaleX-lock.anchorX)
   assert(drift<.1,'support foot moved after recovery ended: '..D.json.encode({drift=drift,phase=phase,direction=direction,lock=lock,x=fox.x,pointX=p.x}))
   maxDrift=math.max(maxDrift,drift);maxSettle=math.max(maxSettle,math.abs(lock.settleDistance));maxUncorrected=math.max(maxUncorrected,uncorrected)
   rows[#rows+1]={direction=direction,phase=phase/12,contact=lock.name,frames=lock.frames,settleSeconds=lock.elapsed,postRecoveryDrift=drift,settleDistance=lock.settleDistance,uncorrectedEndpointDrift=uncorrected}
  end end
  return {status='PASS',nativeSpine=true,inputSimulation=false,cases=rows,maxPostRecoveryDrift=maxDrift,maxBodySettleDistance=maxSettle,maxUncorrectedEndpointDrift=maxUncorrected,
   otherFootStepUnverified=true,startAndTurnUnverified=true,productionIntegration=false}
 end,debug.traceback)
 local report=ok and result or {status='FAIL',error=result};report.runId=os.time()
 D.Content:save(D.Path(root,'Test/fox-spine-stop-anchor-result.json'),D.json.encode(report));print('LSD_FOX_STOP_ANCHOR '..D.json.encode(report))
end)
