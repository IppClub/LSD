-- Original 2-15 interior dialogue. The public door/position gates remain in ControlPod.
local D=require('Dora');local Stage={}
function Stage.openAsync(c)
 local world=c.world
 local service,why=require('Story.Service').open();if not service then return nil,why end
 local allowed,why=service:canRead('control-pod-researchers',world.tag,false);if not allowed then return nil,why end
 if service:summary().completed['control-pod-researchers']then return nil,'ALREADY_RECORDED'end
 if c.phase~='ready' or c.floor~=7 or c.player.unit.x<2150 then return nil,'CONTROL_ROOM_POSITION_REQUIRED'end
 local stage={report={version=1,researchers=#c.researchers,doorOpen=c.state.doorOpen,playerX=c.player.unit.x},commands={}}
 world.controlPodDialogue=stage;c.phase='dialogue';c.held={}
 stage.threat=require('Story.FoxSpineThreat').attach(c.fox.model)
 for _,a in ipairs(c.actors)do a.model.speed=1;a.model.recovery=.2;a.model:play('idle',true);a.animation='idle';if a.isFox then a.model.movementState='idle'end end
 for _,a in ipairs(c.researchers)do a.model.recovery=.2;a.model:play('idle1',true)end
 local commands=require('System.Command');local disposed=false
 local function dispose()
  if disposed then return end;disposed=true
  if stage.threat then stage.threat:dispose()end
  for name,e in pairs(stage.commands)do if commands[name]==e.fn then commands[name]=e.previous end end
 end
 world:slot('Cleanup',dispose)
 local function install(name,action)
  local e={previous=rawget(commands,name)};stage.commands[name]=e
  e.fn=function()
   D.thread(function()
    local view=world.storyFlow and world.storyFlow.view
    local scale,effect=D.View.scale,D.View.postEffect
    if view then view.visible=false;D.View.scale=view._viewScale or scale;D.View.postEffect=view._viewEffect end
    local ok,err=xpcall(action,debug.traceback)
    if not ok then print('ControlPodDialogue: stage failed '..tostring(err)) end
    if world.parent then
     if view then view.visible=true;D.View.scale=scale;D.View.postEffect=effect end
     if ok then D.emit('Story.Advance')end
    end
   end)
   coroutine.yield('Command')
  end
  commands[name]=e.fn
 end
 install('controlPodAim',function()
  local start=D.App.runningTime;local aimed=0
  D.Cache:loadAsync('spine:kineticgun');stage.guns={}
  for _,a in ipairs({c.player,c.nini})do
   local gun=assert(D.Spine('kineticgun'));gun.look='PT';gun.scaleX=.3;gun.scaleY=.3;a.model:setSlot('pistol',gun);stage.guns[#stage.guns+1]=gun
   local stopped=false;a.model:slot('aimReady',function()if not disposed and not stopped then stopped=true;a.model.speed=0;aimed=aimed+1 end end)
   a.unit.faceRight=true;a.model.speed=1;a.model.recovery=.15;assert(a.model:play('aim',false)>0)
  end
  for _,a in ipairs(c.researchers)do a.model.fliped=true;a.model:play('idle',true)end
  while aimed<2 do assert(D.App.runningTime-start<4,'Gun aim frame missing');D.sleep(.02)end;D.sleep(.85)
  stage.report.aim={seconds=D.App.runningTime-start,mentor=true,nini=true,gunCount=#stage.guns,heldPose='aim',nativeAimFrames=aimed}
 end)
 install('controlPodWarning',function()
  local start=D.App.runningTime;local m=c.fox.model;m.fliped=true;m.speed=1;m.recovery=.2
  assert(m:play('prepare',true)>0);stage.threat:show(true);D.sleep(1.25)
  stage.report.warning={seconds=D.App.runningTime-start,pose='prepare',teethExpression=true,anchorFrames=stage.threat.frames}
  stage.threat:show(false);m:play('idle',true);m.movementState='idle'
 end)
 local flow,err=require('Story.Flow').openAsync('control-pod-researchers',world,function()
  dispose();stage.phase='complete';c.dialogueComplete=true;c.phase='ready'
  for _,a in ipairs({c.player,c.nini})do a.model.speed=1;a.model.recovery=.2;a.model:play('idle',true);a.animation='idle'end
  c.message='发射炮位于顶楼玻璃罩内。寻找阶梯，准备攀爬。'
 end,false)
 if not flow then dispose();c.phase='ready';return nil,err end
 stage.flow=flow;stage.phase='dialogue';return stage
end
return Stage
