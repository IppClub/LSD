-- The academy corridor is the only public entrance to chapter-three defense.
local D=require('Dora');local Gate={}
local errors={TRAINING_REQUIRED='先回训练室采用妮妮莉特的训练成果。',INVALID_FORMATION='先到指挥室将妮妮莉特编入队伍。',STORY_LOCKED='先在研发室确认异常信道。',MISSION_ALREADY_ACTIVE='已有行动记录待处理，请完成结算后再来。',WRITE_FAILED='行动记录未保存，请重试。'}
local function launch(model,cancelled,started)
 return require('Economy.Preparation').openAsync('c0-m07',model,cancelled,function(service,attempt)
  local options={attempt=attempt,baseText='返回防线',onSettledAsync=function(status,report)return service:finishAsync(attempt,status,report)end}
  local level
  local function leave(status,_,action)
   local rows=D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=? AND mission=?',{attempt.id,'c0-m07'})
   if not rows or not rows[1]or rows[1][1]~=status then return false,'SAVE_REQUIRED'end
   if action=='again'and status~='won'then
    local panel,why=launch(model,function()if level then level.leaving=false;level.supplyPanel=nil end end)
    if level then level.supplyPanel=panel end
    return panel~=nil,why
   end
   require('Academy.Navigation').returnToRoomAsync('PassageA');return true
  end
  local ok,value=xpcall(function()return require('Academy.DefenseLevel').openAsync({ninilite=attempt.model},leave,options)end,debug.traceback)
  if not ok then
   local saved=service:finishAsync(attempt,'aborted',{reason='Battle could not load'})
   print(value);if cancelled then cancelled()end
   return nil,saved and 'BATTLE_LOAD_FAILED'or'WRITE_FAILED'
  end
  level=value;level.attempt=attempt;if started then started(level)end
 end)
end
function Gate.attach(world)
 if world.defenseGate then return world.defenseGate end
 if world.tag~='PassageA'then return end
 local story,why=require('Story.Service').open();if not story then return nil,why end
 local facts=story:summary();if not facts or not facts.completed['network-warning']then return end
 local c={phase='ready'};world.defenseGate=c
 local marker=D.Node();marker.tag='academy-defense-ready';marker.position=D.Vec2(1100,world.offset+190);marker:addTo(world);c.marker=marker
 local menu=require('UI.Interaction')({text='学院入口防线',buttons={{facts.mission.unlocks['academy-defense-complete']and '查看防卫记录'or'准备防卫',''}},fliped=false})
 menu.transformTarget=marker;menu.scaleX=.325;menu.scaleY=.325;menu.order=100;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
 local hint=D.Label('SourceHanSansCN-Regular',24,true);hint.outlineWidth=.16;hint.outlineColor=D.Color(0xff101b28);hint.position=marker.position+D.Vec2(0,290);hint:addTo(world);c.hint=hint
 hint.text=facts.mission.unlocks['academy-defense-complete']and '主通道已守住 · 防卫记录已保存'or'入口受袭 · 妮妮莉特与导师共同防卫'
 -- 每帧靠近检测共享的组与谓词，避免逐帧重建闭包。
 local playerGroup=D.Group({'player','unit'})
 local function isLocalPlayer(e)return e.player and e.unit.world==world end
 local function player()return playerGroup:find(isLocalPlayer)end
 function c:showRecord()
  local rows=D.DB:query("SELECT report,model FROM lsd.Game0MissionAttempts WHERE mission='c0-m07' AND status='won' ORDER BY id LIMIT 1")
  if not rows or not rows[1]then return nil,'READ_FAILED'end
  local parsed,p,model=pcall(function()return D.json.decode(rows[1][1],32),D.json.decode(rows[1][2],32)end)
  if not parsed or not require('Academy.DefenseProof').validate(p,model)then return nil,'INVALID_DEFENSE_RECORD'end
  self.phase='record';world.data.journalOpen=true
  local view=require('UI.Settlement')({missionMode=true,economy=p.economy,missionTitle='学院防卫',resultTitle='防卫记录',resultStatus='Complete',reportText=string.format('入口清理、供电保护、撤离护送 · 3 / 3\n导师命中 %d · 妮妮命中 %d · 火焰命中 %d\n供电 %.0f · 信标 %.0f',p.mentorHits,p.learner.hits,p.fireHits,p.powerHP,p.beaconHP),storyText='主通道已守住。其他区域的情况仍需确认。',againText='返回防线',baseText='返回指挥室'})
  view:addTo(D.Director.ui3D);self.record=view
  local function onWorldCleanup()if view.parent then view:removeFromParent()end end
  local function close()view:removeFromParent();world:slot('Cleanup'):remove(onWorldCleanup);world.data.journalOpen=false;self.phase='ready'end
  view.againButton:slot('Tapped',close)
  view.baseButton:slot('Tapped',function()close();D.thread(function()require('Academy.Navigation').returnToOperationAsync()end)end)
  world:slot('Cleanup',onWorldCleanup);return view
 end
 function c:request()
  if self.phase~='ready'or world.data.storyBusy or world.data.journalOpen then return nil,'BUSY'end
  local p=player();if not p or p.busy or math.abs(p.unit.x-marker.x)>=180 then return nil,'DISCOVERY_LOCATION_REQUIRED'end
  local facts,why=story:summary();if not facts then return nil,why end
  if not facts.completed['network-warning']then return nil,'STORY_LOCKED'end
  if facts.mission.unlocks['academy-defense-complete']then
   local record,why=self:showRecord();if not record then hint.text='防卫记录暂不可读取，现有存档已保留。'end;return record,why
  end
  local progress=require('Training.Progress');if not progress.load()or not progress.adopted then hint.text=errors.TRAINING_REQUIRED;return nil,'TRAINING_REQUIRED'end
  local service=assert(require('Mission.Service').open());local formation,why=service:formation();if not formation then return nil,why end
  self.phase='budget'
  -- request() only runs from a clean state, so restore always returns to not-busy.
  p.busy=true;p.keyLeft=false;p.keyRight=false;p.unit.velocityX=0;world.data.journalOpen=true
  local function restore()p.busy=false;world.data.journalOpen=false;self.phase='ready';self.supplyPanel=nil end
  local panel,why=launch(progress.adopted,restore,function(level)self.level=level;self.phase='playing';self.supplyPanel=nil end)
  if not panel then restore();hint.text=errors[why]or'防卫暂未开始，请重试。'end
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
