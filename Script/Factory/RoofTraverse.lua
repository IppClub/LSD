-- A native-animation traversal primitive; caller supplies the physical wall lip.
local D=require('Dora');local Climb=require('Factory.RoofClimb');local Traverse={}
function Traverse.runAsync(model,name,options)
 local def=Climb.definition(name);local scale=model.scaleY
 assert(model.scaleX==scale and scale>0 and not model.fliped,'Traversal requires an unmirrored right-facing rig')
 local origin=model.position;local top=assert(options.top);local wallX=assert(options.wallX)
 local cycles=math.floor((top-origin.y-def.HandL.highY*scale)/(60*scale));assert(cycles>=1,'Wall too short for climbing')
 local report={name=name,phase='reach',cycles=cycles,contactSamples=0,maxSupportError=0,minCrossingClearance=1e9,flightSamples=0}
 local tick=D.Node();tick.scheduler=D.Director.postScheduler;tick:addTo(model)
 local previous=model.position;report.maxFrameDisplacement=0;report.frameSamples=0
 local c;local phase='reach';local closed=false;local released=false;local supportY
 local release=function()released=true end;model:slot('roofReleased',release)
 model:slot('Cleanup',function()closed=true end)
 local function waitSeconds(seconds)
  local untilTime=D.App.runningTime+seconds
  while D.App.runningTime<untilTime do if closed then error('Traversal actor removed')end;D.sleep()end
 end
 local function foot(key)
  local p=model:getKey('climb'..key..'/climb'..key);return D.Vec2(model.x+p.x*scale,model.y+p.y*scale)
 end
 tick:schedule(function()
  if phase=='climb' then c:update()
  elseif phase=='pull' then local p=model:getKey('climbHandL/climbHandL');model.y=supportY-p.y*scale end
  local dx=model.x-previous.x;local dy=model.y-previous.y;report.maxFrameDisplacement=math.max(report.maxFrameDisplacement,math.sqrt(dx*dx+dy*dy));report.frameSamples=report.frameSamples+1;previous=model.position
  return false
 end)
 local ok,why=xpcall(function()
  model.speed=1;model.recovery=0;model:play('climbEnter',false);waitSeconds(.52)
  c=Climb.attach(model,name);c:start();phase='climb';report.phase=phase
  local deadline=D.App.runningTime+(cycles+1)*2.4
  while c.cycle<cycles do assert(D.App.runningTime<deadline,'Climb event timeout');waitSeconds(.01)end
  c:pause();report.contactSamples=c.samples;report.maxSupportError=c.maxSupportError
  supportY=c:hold('HandL',c.cycle).y;c:dispose();phase='pull';report.phase=phase
  model.speed=1;model.recovery=0;model:play('roofPull',false)
  deadline=D.App.runningTime+1
  while not released do assert(D.App.runningTime<deadline,'Pull release event timeout');waitSeconds(.01)end
  -- Apply the terminal contact once before detaching from the wall.
  local p=model:getKey('climbHandL/climbHandL');model.y=supportY-p.y*scale
  phase='flight';report.phase=phase;local launch=model.position
  local gravity=520*scale;local peak=top+50*scale;local velocity=math.sqrt(2*gravity*(peak-launch.y))
  local duration=(velocity+math.sqrt(2*gravity*(peak-top)))/gravity
  local started=D.App.runningTime;local crossingStart;local captured=false
  model.recovery=0;model:play('roofTuck',true);local unfoldedAt
  while true do
   local t=math.min(duration,D.App.runningTime-started);model.y=launch.y+velocity*t-.5*gravity*t*t
   local left=foot('FootL');local right=foot('FootR')
   if not unfoldedAt and model.y>top+10*scale then
    unfoldedAt=t;model.recovery=.12;model:play('jumping',true)
   end
   if unfoldedAt and not crossingStart and t-unfoldedAt>=.14 and math.min(left.y,right.y)>top+8*scale then crossingStart=t end
   if crossingStart then
    local u=math.max(0,math.min(1,(t-crossingStart)/(duration-crossingStart)));local smooth=u*u*(3-2*u)
    model.x=launch.x+(options.landingX-launch.x)*smooth
   end
   for _,key in ipairs({'FootL','FootR'})do local f=foot(key);if f.x>=wallX then report.minCrossingClearance=math.min(report.minCrossingClearance,f.y-top)end end
   report.flightSamples=report.flightSamples+1
   if crossingStart and not captured and t-crossingStart>.1 then captured=true;if options.onCrossing then options.onCrossing(report)end end
   if t>=duration then break end
   waitSeconds(.001)
  end
  assert(crossingStart,'Feet never cleared wall');assert(report.minCrossingClearance>-5*scale,'Foot intersected wall lip')
  model.position=D.Vec2(options.landingX,top);phase='landing';report.phase=phase
  model.recovery=.1;model:play('landing',false);waitSeconds(.72)
  model.recovery=.2;model:play('idle',true);waitSeconds(.25)
  phase='complete';report.phase=phase;report.endX=model.x;report.endY=model.y;report.recovery=model.recovery;report.crossingStart=crossingStart
 end,debug.traceback)
 tick:removeFromParent();model:slot('roofReleased'):remove(release)
 if c and not c.closed then c:dispose()end
 if not ok then report.phase='failed';report.error=why;return nil,report end
 return report
end
return Traverse
