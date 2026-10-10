local D=require('Dora');local Stage={}
function Stage.openAsync(c)
 if c.phase~='ready' or c.stage~=2 or math.abs(c.player.model.x-2520)>160 then return nil,'ROOF_CANNON_POSITION_REQUIRED'end
 local service,why=require('Story.Service').open();if not service then return nil,why end
 if service:summary().completed['roof-confrontation']then return nil,'ALREADY_RECORDED'end
 local stage={report={version=1,stage=c.stage,playerX=c.player.model.x},phase='dialogue'};c.world.roofDialogue=stage;c.phase='dialogue';c.held={}
 for _,a in ipairs(c.actors)do a.model.speed=1;a.model.recovery=.2;a.model:play('idle',true);a.animation='idle';a.model.fliped=false end
 local commands=require('System.Command');local previous=rawget(commands,'roofBeacon');local installed
 local function dispose()if commands.roofBeacon==installed then commands.roofBeacon=previous end end
 c.world:slot('Cleanup',dispose)
 installed=function()
  D.thread(function()
   local view=c.world.storyFlow.view;local scale,effect=D.View.scale,D.View.postEffect
   view.visible=false;D.View.scale=view._viewScale or scale;D.View.postEffect=view._viewEffect
   c.beacon:activate();D.sleep(1.8)
   stage.report.beacon={seconds=c.beacon.elapsed,anchorFrames=c.beacon.frames,anchor=c.beacon.lastAnchor,axis=c.beacon.lastAxis,beamVisible=c.beacon.beam.visible}
   if not c.closed then view.visible=true;D.View.scale=scale;D.View.postEffect=effect;D.emit('Story.Advance')end
  end)
  coroutine.yield('Command')
 end
 commands.roofBeacon=installed
 local flow,err=require('Story.Flow').openAsync('roof-confrontation',c.world,function()
  dispose();stage.phase='complete';c.confrontationComplete=true;c.phase='ready';c.message='乌云不肯停下。准备与妮妮莉特并肩迎战。'
  for _,a in ipairs(c.actors)do a.model.recovery=.2;a.model:play('prepare',true);a.animation='prepare'end
  c.wuyun:play('prepare',true)
 end,false)
 if not flow then dispose();c.phase='ready';return nil,err end
 stage.flow=flow;return stage
end
return Stage
