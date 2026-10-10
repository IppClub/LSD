-- The academy corridor is the only public entrance to twins evacuation.
local D=require('Dora');local Gate={}
local errors={TRAINING_REQUIRED='先回训练室采用妮妮莉特的训练成果。',INVALID_FORMATION='先到指挥室将妮妮莉特编入队伍。',STORY_LOCKED='先与玉及双子交谈。',MISSION_ALREADY_ACTIVE='已有行动记录待处理，请完成结算后再来。',WRITE_FAILED='行动记录未保存，请重试。'}
local function launch(model,cancelled,started)
 return require('Economy.Preparation').openAsync('c0-m08',model,cancelled,function(service,attempt)
  local options={attempt=attempt,baseText='返回研发室',onSettledAsync=function(status,report)return service:finishAsync(attempt,status,report)end}
  local level
  local function leave(status,_,action)
   local rows=D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=? AND mission=?',{attempt.id,'c0-m08'})
   if not rows or not rows[1]or rows[1][1]~=status then return false,'SAVE_REQUIRED'end
   if action=='again'and status~='won'then
    local panel,why=launch(model,function()if level then level.leaving=false;level.supplyPanel=nil end end)
    if level then level.supplyPanel=panel end
    return panel~=nil,why
   end
   require('Academy.Navigation').returnToRoomAsync('RDRoom');return true
  end
  local ok,value=xpcall(function()return require('Rescue.Level').openAsync({ninilite=attempt.model},leave,options)end,debug.traceback)
  if not ok then
   local saved=service:finishAsync(attempt,'aborted',{reason='Battle could not load'})
   print(value);if cancelled then cancelled()end
   return nil,saved and 'BATTLE_LOAD_FAILED'or'WRITE_FAILED'
  end
  level=value;level.attempt=attempt;if started then started(level)end
 end)
end
function Gate.attach(world)
 if world.rescueGate then return world.rescueGate end
 if world.tag~='RDRoom'then return end
 local story,why=require('Story.Service').open();if not story then return nil,why end
 local facts=story:summary();if not facts or not facts.completed['jade-arrival']then return end
 local c={phase='ready'};world.rescueGate=c
 local marker=D.Node();marker.tag='twins-evacuation-ready';marker.position=D.Vec2(facts.mission.unlocks['twins-rescued']and 5270 or 4410,world.offset+190);marker:addTo(world);c.marker=marker
 local menu=require('UI.Interaction')({text='研究区撤离通道',buttons={{facts.mission.unlocks['twins-rescued']and '查看救援记录'or'准备护送双子',''}},fliped=false})
 menu.transformTarget=marker;menu.scaleX=.325;menu.scaleY=.325;menu.order=100;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
 local hint=D.Label('SourceHanSansCN-Regular',24,true);hint.outlineWidth=.16;hint.outlineColor=D.Color(0xff101b28);hint.position=marker.position+D.Vec2(0,320);hint:addTo(world);c.hint=hint
 hint.text=facts.mission.unlocks['twins-rescued']and '双子已抵达出口 · 救援记录已保存'or'与妮妮莉特共同掩护双子撤离'
 local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end)end
 function c:showRecord()
  local rows=D.DB:query("SELECT report,model FROM lsd.Game0MissionAttempts WHERE mission='c0-m08' AND status='won' ORDER BY id LIMIT 1")
  if not rows or not rows[1]then return nil,'READ_FAILED'end
  local parsed,p,model=pcall(function()return D.json.decode(rows[1][1],32),D.json.decode(rows[1][2],32)end)
  if not parsed or not require('Rescue.Proof').validate(p,model)then return nil,'INVALID_RESCUE_RECORD'end
  self.phase='record';world.data.journalOpen=true;require('Story.Flow').freeze(world,true)
  local view=require('UI.Settlement')({missionMode=true,economy=p.economy,missionTitle='双子救援',resultTitle='救援记录',resultStatus='Complete',reportText=string.format('两段危险区已通过 · 2 / 2\n烛参 %.0f · 烛商 %.0f\n保护场吸收 %.0f · 导师命中 %d',p.twins[1].hp,p.twins[2].hp,p.ward.absorbed,p.mentorHits),storyText='双子已脱离研究区。学院的损失仍然存在。',againText='返回研发室',baseText='返回指挥室'})
  view:addTo(D.Director.ui3D);self.record=view
  local function close()view:removeFromParent();world.data.journalOpen=false;require('Story.Flow').freeze(world,false);self.phase='ready'end
  view.againButton:slot('Tapped',close)
  view.baseButton:slot('Tapped',function()close();D.thread(function()require('Academy.Navigation').returnToOperationAsync()end)end)
  world:slot('Cleanup',function()if view.parent then view:removeFromParent()end end);return view
 end
 function c:request()
  if self.phase~='ready'or world.data.storyBusy or world.data.journalOpen then return nil,'BUSY'end
  local p=player();if not p or p.busy or math.abs(p.unit.x-marker.x)>=180 then return nil,'DISCOVERY_LOCATION_REQUIRED'end
  local facts,why=story:summary();if not facts then return nil,why end
  if not facts.completed['jade-arrival']then return nil,'STORY_LOCKED'end
  if facts.mission.unlocks['twins-rescued']then
   local record,why=self:showRecord();if not record then hint.text='救援记录暂不可读取，现有存档已保留。'end;return record,why
  end
  local progress=require('Training.Progress');if not progress.load()or not progress.adopted then hint.text=errors.TRAINING_REQUIRED;return nil,'TRAINING_REQUIRED'end
  local service=assert(require('Mission.Service').open());local formation,why=service:formation();if not formation then return nil,why end
  self.phase='budget';local previousBusy=p.busy;local previousJournal=world.data.journalOpen
  p.busy=true;p.keyLeft=false;p.keyRight=false;p.unit.velocityX=0;world.data.journalOpen=true
  local function restore()p.busy=previousBusy;world.data.journalOpen=previousJournal;self.phase='ready';self.supplyPanel=nil end
  local panel,why=launch(progress.adopted,restore,function(level)self.level=level;self.phase='playing';self.supplyPanel=nil end)
  if not panel then restore();hint.text=errors[why]or'救援暂未开始，请重试。'end
  self.supplyPanel=panel;return panel,why
 end
 menu:slot('Tapped',function()D.thread(function()c:request()end)end)
 local near=false;marker:schedule(function()
  local p=player();local now=c.phase=='ready'and p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-marker.x)<180
  if (not not now)~=near then near=not not now;if near then menu.visible=true;menu:show()else menu:hide(false)end end
  return false
 end)
 return c
end
return Gate
