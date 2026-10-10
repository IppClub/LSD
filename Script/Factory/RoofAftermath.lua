-- Original 2-17: Wuyun raises the marked arm and enters the beam. Party departure remains separate.
local D=require('Dora');local Stage={}
function Stage.openAsync(c)
 if c.phase~='ready'or not c.duelComplete or math.abs(c.player.model.x-2520)>160 then return nil,'ROOF_AFTERMATH_POSITION_REQUIRED'end
 local service,why=require('Story.Service').open();if not service then return nil,why end
 if service:summary().completed['roof-aftermath']then return nil,'ALREADY_RECORDED'end
 local stage={report={version=1,playerX=c.player.model.x},commands={}};local world=c.world;world.roofAftermath=stage;c.phase='dialogue';c.held={}
 local m=c.wuyun;m.speed=1;m.recovery=.2;m:play('idle',true)
 for _,a in ipairs(c.actors)do a.model.recovery=.2;a.model:play('idle',true);a.animation='idle';a.model.fliped=false end
 local commands=require('System.Command');local disposed=false
 local function dispose()if disposed then return end;disposed=true;for name,e in pairs(stage.commands)do if commands[name]==e.fn then commands[name]=e.previous end end end
 world:slot('Cleanup',dispose)
 local function wait(f,seconds)
  local deadline=D.App.runningTime+seconds
  while not f()do assert(not c.closed,'Scene closed during aftermath');assert(D.App.runningTime<deadline,'Roof aftermath animation timeout');D.sleep(.01)end
 end
 local function install(name,action)
  local e={previous=rawget(commands,name)};stage.commands[name]=e
  e.fn=function()
   D.thread(function()
    local view=world.storyFlow.view;local scale,effect=D.View.scale,D.View.postEffect
    view.visible=false;c.ui.visible=false;D.View.scale=view._viewScale or scale;D.View.postEffect=view._viewEffect
    local ok,err=xpcall(action,debug.traceback)
    if not ok then print('RoofAftermath: stage failed '..tostring(err)) end
    if not c.closed then view.visible=true;c.ui.visible=true;D.View.scale=scale;D.View.postEffect=effect;if ok then D.emit('Story.Advance')end end
   end)
   coroutine.yield('Command')
  end;commands[name]=e.fn
 end
 install('roofOpenVortex',function()
  local raised=false;local initial=m:getKey('roofMark/roofMark');local started=D.App.runningTime
  m:slot('roofArmRaised',function()if not disposed then raised=true;m.speed=0 end end)
  m.speed=1;m.recovery=.2;assert(m:play('roofRaise',false)>.79);wait(function()return raised end,2)
  D.sleep(.04);local high=m:getKey('roofMark/roofMark');stage.report.raise={seconds=D.App.runningTime-started,height=high.y-initial.y,nativeEvent=true}
  c.vortex:open();c.beacon.beam.scaleX=2;D.sleep(1.6)
  stage.report.vortex={frames=c.vortex.frames,seconds=c.vortex.elapsed,visible=c.vortex.node.visible}
 end)
 install('roofWuyunDeparture',function()
  local lowered=false;m:slot('roofArmLowered',function()lowered=true end);m.speed=1;m.recovery=0;m:play('roofLower',false);wait(function()return lowered end,2)
  m.recovery=.2;m:play('idle',true);D.sleep(.25)
  local ended=false;local jumpStarted=D.App.runningTime;m:slot('AnimationEnd',function(name)if name=='jump'then ended=true end end)
  m.recovery=.1;local duration=m:play('jump',false);assert(duration>0);wait(function()return ended end,duration+2)
  local launch=m.position;local started=D.App.runningTime;local frames=0;local maxStep=0;local previous=launch;m.recovery=.12;m:play('jumping',true)
  while true do
   assert(not c.closed);local u=math.min(1,(D.App.runningTime-started)/1.25);local smooth=u*u*(3-2*u)
   m.position=D.Vec2(launch.x+(2820-launch.x)*smooth,launch.y+(1530-launch.y)*(2*u-u*u));m.opacity=1-math.max(0,(u-.78)/.22)
   maxStep=math.max(maxStep,(m.position-previous).length);previous=m.position;frames=frames+1
   if u>=1 then break end;D.sleep()
  end
  m.visible=false;c.beacon.mark.visible=false
  stage.report.departure={jumpDuration=duration,jumpCompleted=true,seconds=D.App.runningTime-jumpStarted,flightFrames=frames,maxFrameStep=maxStep,endX=m.x,endY=m.y,hidden=not m.visible}
  D.sleep(.35)
 end)
 local flow,err=require('Story.Flow').openAsync('roof-aftermath',world,function()
  dispose();stage.phase='complete';c.aftermathComplete=true;c.phase='ready';c.message='乌云已进入漩涡。与妮妮莉特离开发射炮平台。'
 end,false)
 if not flow then dispose();c.phase='ready';return nil,err end;stage.flow=flow;return stage
end
return Stage
