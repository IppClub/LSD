-- Authored 2-15 public approach and first patrol; later infiltration stages follow.
local D=require('Dora');local Route={}
function Route.enterAsync()
 local store,why=require('Story.InfiltrationStore').open();if not store then return nil,why end
 local progress=require('Training.Progress');local ok,err=progress.load();if not ok then return nil,err end
 local wu=progress.forCharacter('wuyun');local loaded,loadError=wu.load();if not loaded then return nil,loadError end
 if not progress.adopted or not wu.adopted then return nil,'TRAINING_REQUIRED'end
 local saved,saveError=store:writeAsync('enter');if not saved then return nil,saveError end
 local options=assert(store.resumeOptions(assert(require('Story.Service').open()):summary()));local world=require('Academy.Navigation').returnToRoomAsync('Factory',options)
 return world.infiltration
end
function Route.attach(world)
 if world.infiltration then return world.infiltration end
 local store,why=require('Story.InfiltrationStore').open();if not store then return nil,why end
 local c={phase='loading',store=store};world.infiltration=c
 local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end)end
 local function facts()return assert(require('Story.Service').open()):summary()end
 local state=assert(store:load());c.state=state;c.wuyunGone=not not facts().completed['roof-aftermath'];c.interrogated=not not facts().completed['researcher-interrogation']
 if c.interrogated then c.secondStore=assert(require('Story.SecondPatrolStore').open());c.second=assert(c.secondStore:load())end
 local marker=D.Node();marker.tag='patrol-approach-ready';marker.position=D.Vec2(1000,world.offset+210);marker:addTo(world)
 local cleared=D.Node();cleared.tag='patrol-cleared-ready';cleared.position=D.Vec2(2200,world.offset+210);cleared:addTo(world)
 local scout=D.Node();scout.tag='researcher-scout-ready';scout.position=D.Vec2(4100,world.offset+210);scout:addTo(world)
 local pathStore,pathState
 if state.firstPatrol then pathStore=assert(require('Story.InfiltrationPathStore').open());pathState=assert(pathStore:load());c.pathCompleted=pathState.completed end
 local menu=require('UI.Interaction')({text='工厂潜入',buttons={{'继续行动',''},{'返回指挥室',''}},fliped=false});menu.transformTarget=state.firstPatrol and cleared or marker;menu.scaleX=.325;menu.scaleY=.325;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
 require('Story.FoxCompanion').loadAnimatedAsync();c.fox=require('Story.FoxCompanion').createAnimated();c.fox.position=D.Vec2(state.firstPatrol and 2500 or 1300,world.offset);c.fox:addTo(world)
 local function showResearcher()
  c.fox.x=c.interrogated and 3550 or 4550
  c.captureStore=assert(require('Story.ResearcherStore').open());c.capture=assert(c.captureStore:load())
  local actor=assert(D.Spine(require('Factory.Researcher').asset));actor.position=D.Vec2(4290,world.offset);actor.recovery=.15;actor.fliped=true;actor:play(c.interrogated and 'unconscious' or c.capture.caught and 'restrained' or 'idle',true);actor:addTo(world);c.researcher=actor
 end
 if c.pathCompleted then c.fox.x=4400;menu.transformTarget=scout;showResearcher()end
 local origin=c.pathCompleted and 4100 or state.firstPatrol and 2200 or 1000
 for id,offset in pairs({ninilite=-320,wuyun=-640})do
  local e=D.Group({'name','unit'}):find(function(e)return not e.player and e.name==id and e.unit.world==world end)
  if e and id=='wuyun'and c.wuyunGone then e.unit:removeFromParent();e:destroy();e=nil end
  if e then e.unit:stop();e.unit.velocityX=0;e.unit.x=origin+offset;e.unit.faceRight=true;if id=='wuyun' and c.interrogated then e.unit.x=4680;e.unit.faceRight=false end end
 end
 local ui=D.Node();ui.size=D.App.bufferSize;ui.tag='infiltration-status';ui:addTo(D.Director.ui3D)
 local text=D.Label('SourceHanSansCN-Regular',24);text.anchor=D.Vec2(0,1);text.alignment='Left';text.textWidth=ui.width-440;text.position=D.Vec2(30,ui.height-170);text:addTo(ui);c.status=text
 local back=D.DrawNode();back:drawPolygon({D.Vec2.zero,D.Vec2(ui.width-430,0),D.Vec2(ui.width-430,110),D.Vec2(0,110)},D.Color(0xbb101b28));back.position=D.Vec2(15,ui.height-260);back:addTo(ui);back.order=-1
 world:slot('Cleanup',function()ui:removeFromParent()end)
 function c:locateFromLens(lens)
  if self.phase~='ready' or not facts().completed['patrol-approach'] or math.abs(player().unit.x-1000)>=180 then return false,'APPROACH_REQUIRED'end
  if self.state.located then lens.view.detail.text='巡逻守卫已定位。关闭夜光镜，准备制服巡逻队。';return true end
  if self.scanning then return false,'BUSY'end
  self.scanning=true;D.thread(function()
   local began=D.App.runningTime;local x=player().unit.x
   for i=1,20 do if not world.parent or lens.phase~='map' then self.scanning=false;return end;lens.view.detail.text='巡逻队定位中 · '..(i*5)..'%\n保持隐蔽，正在核对守卫火力。';D.sleep(.1)end
   while D.App.runningTime-began<2 do if not world.parent or lens.phase~='map'then self.scanning=false;return end;D.sleep(.01)end
   local ok,err=store:writeAsync('locate',{fromLens=true,x=x,seconds=D.App.runningTime-began});self.scanning=false
   if ok then self.error=nil;self.state=assert(store:load());lens.view.detail.text='巡逻守卫已定位。\n三人协同：导师射击、妮妮莉特火焰、乌云旋风。关闭夜光镜后行动。'
   else lens.view.detail.text='定位尚未保存，请再次点击巡逻守卫重试。';self.error=err end
  end);return true
 end
 local function dialogue(id,onClosed)
  c.phase='dialogue';local f,err=require('Story.Flow').openAsync(id,world,function()c.phase='ready';if onClosed then onClosed()end end,not not facts().completed[id]);if not f then c.phase='ready';c.error=err end;return f
 end
 local function beginPath()
  if not c.path then c.path=require('Factory.InfiltrationPath').attach(world,c);c.path.onComplete=function()menu.transformTarget=scout;showResearcher()end end
  return c.path:beginAsync()
 end
 local function beginResearcher()
  c.phase='launching'
  D.thread(function()
   local capture,why=require('Story.ResearcherStore').open();if not capture then c.error=why;c.phase='ready';return end
   local progress=require('Training.Progress');assert(progress.load());local wu=progress.forCharacter('wuyun');assert(wu.load())
   if not progress.adopted or not wu.adopted then c.phase='ready';c.error='TRAINING_REQUIRED';return end
   local models={ninilite=progress.adopted,wuyun=wu.adopted}
   require('Story.Flow').freeze(world,true)
   local function cancel()c.supplyPanel=nil;c.phase='ready';require('Story.Flow').freeze(world,false)end
   local panel,why=require('Economy.Preparation').openAsync('c0-researcher',models,cancel,function(missionService,attempt)
    c.supplyPanel=nil
    c.battleLevel=require('Factory.ResearcherLevel').openAsync(models,function(status,report,action)
    if action=='base'then
     local ok,err=store:writeAsync('withdraw');if not ok then return false,err end
     require('Academy.Navigation').returnToOperationAsync()
    else require('Academy.Navigation').returnToRoomAsync('Factory',{infiltrationRoute=true,spawn=4100})end
    return true
   end,{
    requireSavedExit=true,
    beforeStartAsync=function(w)
     local f,err=require('Story.Flow').openAsync('researcher-contact',w,nil,not not facts().completed['researcher-contact']);if not f then return false,err end
     while f.phase~='complete'do if not w.parent then return false,'LEFT_SCENE'end;D.sleep(.03)end;return true
    end,
    supplyAttempt=attempt.supplyAttempt,
    onSettledAsync=function(status,report)return missionService:finishAsync(attempt,status,report)end,
   })
   end)
   c.supplyPanel=panel;if not panel then cancel();c.error=why end
  end)
  return true
 end
 local function beginSecondPatrol()
  c.secondStore=assert(require('Story.SecondPatrolStore').open());c.second=assert(c.secondStore:load())
  if c.second.completed then
   c.phase='launching';D.thread(function()local opened,why=require('Factory.ControlPod').openAsync();if not opened then c.phase='ready';c.error=why end end);return true
  end
  c.phase='launching'
  D.thread(function()
   local progress=require('Training.Progress');local ok,err=progress.load()
   if not ok or not progress.adopted then c.phase='ready';c.error=err or 'TRAINING_REQUIRED';return end
   require('Story.Flow').freeze(world,true)
   local function cancel()c.supplyPanel=nil;c.phase='ready';require('Story.Flow').freeze(world,false)end
   local panel,why=require('Economy.Preparation').openAsync('c0-patrol-second',progress.adopted,cancel,function(missionService,attempt)
    c.supplyPanel=nil
    c.battleLevel=require('Factory.SecondPatrolLevel').openAsync({ninilite=attempt.model},function(status,report,action)
    if action=='base'then
     local saved,why=store:writeAsync('withdraw');if not saved then return false,why end
     require('Academy.Navigation').returnToOperationAsync()
    else require('Academy.Navigation').returnToRoomAsync('Factory',{infiltrationRoute=true,spawn=4100})end
    return true
   end,{requireSavedExit=true,supplyAttempt=attempt.supplyAttempt,onSettledAsync=function(status,report)return missionService:finishAsync(attempt,status,report)end})
   end)
   c.supplyPanel=panel;if not panel then cancel();c.error=why end
  end)
  return true
 end
 function c:request()
  if self.phase~='ready' or world.data.storyBusy or world.data.journalOpen then return false,'BUSY'end
  local x=self.pathCompleted and 4100 or self.state.firstPatrol and 2200 or 1000;if math.abs(player().unit.x-x)>=180 then return false,'OUT_OF_RANGE'end
  if not facts().completed['patrol-approach'] then return dialogue('patrol-approach')end
  if not self.state.located then local lens,err=require('Ground.NightLens').openAsync(world);self.error=err;return lens,err end
  if self.state.firstPatrol then
   if not facts().completed['patrol-cleared'] then return dialogue('patrol-cleared')end
   if self.pathCompleted then
    if not facts().completed['infiltration-researcher-scout'] then return dialogue('infiltration-researcher-scout')end
    local capture=assert(require('Story.ResearcherStore').open());self.capture=assert(capture:load())
    if self.capture.caught then
     if facts().completed['researcher-interrogation']then return beginSecondPatrol()end
     self.phase='dialogue'
     local stage,why=require('Factory.Interrogation').openAsync(world,function()
      self.phase='ready';self.interrogated=true;self.message='乌云留下看守研发人员。前往第七层控制舱。'
      self.fox.x=3550;self.researcher.recovery=0;self.researcher.fliped=true;self.researcher:play('unconscious',true)
      local wu=D.Group({'name','unit'}):find(function(e)return e.name=='wuyun' and e.unit.world==world end);if wu then wu.unit.x=4680;wu.unit.faceRight=false end
     end)
     if not stage then self.phase='ready';self.error=why end
     return stage,why
    end
    return beginResearcher()
   end
   if not facts().completed['infiltration-fox-guide']then return dialogue('infiltration-fox-guide',beginPath)end
   return beginPath()
  end
  self.phase='launching'
  D.thread(function()
   local progress=require('Training.Progress');assert(progress.load());local wu=progress.forCharacter('wuyun');assert(wu.load())
   if not progress.adopted or not wu.adopted then c.phase='ready';c.error='TRAINING_REQUIRED';return end
   local models={ninilite=progress.adopted,wuyun=wu.adopted}
   require('Story.Flow').freeze(world,true)
   local function cancel()c.supplyPanel=nil;c.phase='ready';require('Story.Flow').freeze(world,false)end
   local panel,why=require('Economy.Preparation').openAsync('c0-patrol',models,cancel,function(missionService,attempt)
    c.supplyPanel=nil
    c.battleLevel=require('Factory.PatrolLevel').openAsync(models,function(status,report,action)
    if action=='base' then local ok,err=store:writeAsync('withdraw');if not ok then return false,err end;require('Academy.Navigation').returnToOperationAsync()
    else local saved=assert(store:load());require('Academy.Navigation').returnToRoomAsync('Factory',{infiltrationRoute=true,spawn=saved.firstPatrol and 2200 or 1000})end
    return true
   end,{
    requireSavedExit=true,
    battleFactory=function()
     local b=require('Factory.PatrolBattle').createAsync(models)
     b.supplies=assert(require('Economy.CombatSession').open(attempt.supplyAttempt))
     for _,a in ipairs(b.learners)do a.supplies=b.supplies end
     return b
    end,
    beforeStartAsync=function(w)
     local f,err=require('Story.Flow').openAsync('patrol-contact',w,nil,not not facts().completed['patrol-contact']);if not f then return false,err end
     -- The engine swallows thread errors; report the timeout so the level can recover.
     local deadline=D.App.runningTime+300;while f.phase~='complete'do if not w.parent then return false,'LEFT_SCENE'end;if D.App.runningTime>=deadline then return false,'PATROL_DIALOGUE_TIMEOUT'end;D.sleep(.03)end;return true
    end,
    onSettledAsync=function(status,report)return missionService:finishAsync(attempt,status,report)end
   })
   end)
   c.supplyPanel=panel
   if not panel then cancel();c.error=why end
  end);return true
 end
 menu:slot('Tapped',function(index)
  if index==1 then D.thread(function()c:request()end)
  elseif c.phase=='ready' and not world.data.storyBusy and not world.data.journalOpen then c.phase='leaving';D.thread(function()local ok,err=store:writeAsync('withdraw');if ok then require('Academy.Navigation').returnToOperationAsync()else c.phase='ready';c.error=err end end)end
 end)
 local near=false;local tick=D.Node();tick:addTo(world);c.phase='ready'
 tick:schedule(function()
  local p=player();local x=c.pathCompleted and 4100 or c.state.firstPatrol and 2200 or 1000;local now=p and c.phase=='ready' and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-x)<180
  if(not not now)~=near then near=not not now;if near then menu.visible=true;menu:show()else menu:hide(false)end end
  text.text=c.error and '行动尚未保存或暂不可用，请重试。' or c.message or (c.wuyunGone and '乌云已经进入漩涡。返回指挥室，与同伴汇合。'or c.second and c.second.completed and '控制舱前的守卫已制服。乌云继续看守研发人员。' or c.interrogated and '乌云留下看守研发人员。前往第七层控制舱。' or c.capture and c.capture.caught and '研发人员已被控制。接下来核实指挥中心的位置。' or c.pathCompleted and '已绕过巡逻。走近研发人员，继续行动。' or c.state.firstPatrol and '首波巡逻队已制服。走近狐狸确认下一段行动。' or c.state.located and '守卫已定位。走近狐狸，三人协同制服巡逻队。' or '走近狐狸确认隐蔽行动，然后打开夜光镜，点击巡逻守卫定位。')
  text.visible=not world.data.storyBusy and not world.data.journalOpen;back.visible=text.visible;return false
 end)
 if pathState and pathState.started and not pathState.completed then beginPath()end
 return c
end
return Route
