local D=require('Dora');local Gate={}
local function launch(model,cancelled,started)
 return require('Economy.Preparation').openAsync('c0-m09',model,cancelled,function(service,attempt)
  local options={attempt=attempt,baseText='返回研发室',onSettledAsync=function(status,report)return service:finishAsync(attempt,status,report)end}
  local level
  local function leave(status,_,action)
   local rows=D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=? AND mission=?',{attempt.id,'c0-m09'})
   if not rows or not rows[1]or rows[1][1]~=status then return false,'SAVE_REQUIRED'end
   if action=='again'and status~='won'then
    local panel,why=launch(model,function()if level then level.leaving=false;level.supplyPanel=nil end end)
    if level then level.supplyPanel=panel end
    return panel~=nil,why
   end
   require('Academy.Navigation').returnToRoomAsync('RDRoom');return true
  end
  local ok,value=xpcall(function()return require('Final.Level').openAsync({ninilite=attempt.model},attempt.auxiliaryVariant,leave,options)end,debug.traceback)
  if not ok then
   local saved=service:finishAsync(attempt,'aborted',{reason='Battle could not load'})
   print(value);if cancelled then cancelled()end
   return nil,saved and 'BATTLE_LOAD_FAILED'or'WRITE_FAILED'
  end
  level=value;level.attempt=attempt;if started then started(level)end
 end)
end
function Gate.attach(world)
 if world.finalGate then return world.finalGate end
 if world.tag~='RDRoom'then return end
 local story=assert(require('Story.Service').open());local facts=assert(story:summary());if not facts.completed['jade-distance']then return end
 local c={phase='ready'};world.finalGate=c
 local marker=D.Node();marker.tag='last-promise-ready';marker.position=D.Vec2(math.min(5770,world.sceneWidth-220),world.offset+460);marker:addTo(world);c.marker=marker
 local menu=require('UI.Interaction')({text='学院撤离出口',buttons=facts.mission.unlocks['last-promise-complete']and {{'前往撤离终端',''},{'查看撤离记录',''}}or {{'准备最后的约定',''}},fliped=true})
 menu.transformTarget=marker;menu.scaleX=.325;menu.scaleY=.325;menu.order=100;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
 local hint=D.Label('SourceHanSansCN-Regular',24,true);hint.outlineWidth=.16;hint.outlineColor=D.Color(0xff101b28);hint.position=marker.position+D.Vec2(-120,260);hint.text=facts.mission.unlocks['last-promise-complete']and '撤离完成 · 查看已保存记录'or '与妮妮莉特一起，将记录带到出口';hint:addTo(world);c.hint=hint
 local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end)end
 local function close()
  if c.view then c.view:removeFromParent();c.view=nil end
  world.data.journalOpen=false;require('Story.Flow').freeze(world,false);c.phase='ready'
 end
 function c:showRecord()
  local rows=D.DB:query("SELECT report,model FROM lsd.Game0MissionAttempts WHERE mission='c0-m09' AND status='won' ORDER BY id LIMIT 1")
  if not rows or not rows[1]then return nil,'READ_FAILED'end
  local ok,p,m=pcall(function()return D.json.decode(rows[1][1],32),D.json.decode(rows[1][2],32)end)
  if not ok or not require('Final.Proof').validate(p,m.ninilite,m.auxiliaryVariant)then return nil,'INVALID_EVACUATION_RECORD'end
  c.phase='record';world.data.journalOpen=true;require('Story.Flow').freeze(world,true)
  local text=string.format('三个区段通过 · 妮妮莉特 %.0f · 辅助机 %.0f\n实际护送 %.0f · 学员模型动作 %d',p.learner.hp,p.auxiliary.hp,p.auxiliary.distance,p.learner.modelActions)
  local supportText=require('Factory.Support').resultText(p);if supportText then text=text..'\n'..supportText end
  local view=require('UI.Settlement')({missionMode=true,economy=p.economy,missionTitle='最后的约定',resultTitle='撤离记录',resultStatus='Complete',reportText=text,storyText='妮妮莉特与回收记录均已抵达撤离终端。',againText='返回研发室',baseText='关闭记录'})
  c.view=view;view:addTo(D.Director.ui3D);view.againButton:slot('Tapped',close);view.baseButton:slot('Tapped',close);return view
 end
 function c:prepare()
  local store,why=require('Ground.AuxiliarySelection').open();if not store then return nil,why end
  local selected,why=store:load();if not selected then return nil,why end
  local progress=require('Training.Progress');if not progress.load()or not progress.adopted then return nil,'TRAINING_REQUIRED'end
  local service=assert(require('Mission.Service').open());local formation=assert(service:formation())
  if formation.learner~='ninilite'then return nil,'INVALID_FORMATION'end
  c.variant=selected.variant or 'defence';c.recorded=selected.recorded;c.phase='briefing';world.data.journalOpen=true;require('Story.Flow').freeze(world,true)
  local mentor=require('Data.Config').char=='charF'and 'charF'or 'charM'
  D.Cache:loadAsync('spine:'..mentor..'Figure');D.Cache:loadAsync('spine:niniliteFigure');D.Cache:loadAsync('bone:formationRole');D.Cache:loadAsync('bone:lsdOSBack')
  local render
  render=function(message)
   if c.view then c.view:removeFromParent()end
   local count=require('Story.Supplies').count('mentor','first-aid-water')or 0
   local text=message or (c.recorded and '沿用上次确认的辅助机，可在出发前改选。'or'此前未记录机型。请确认这次携带的辅助机；不会补写历史选择。')
   local view=require('UI.Formation')({missionMode=true,missionTitle='最后的约定 · 撤离准备',mentorRole=mentor,learnerIncluded=true,squadStatus='妮妮莉特 · 采用 '..require('Training.Summary').short(progress.adopted)..'\n'..text..'\n金粉45，途中两处各15；治疗水 '..count..(count<1 and ' + 本次任务紧急补给1（重试不累积）'or '')})
   c.view=view;view:addTo(D.Director.ui3D);view.rosterButton.visible=false;view.learnerCard.touchEnabled=false;c.buttons={}
   local holder=D.Node();holder.position=D.Vec2(1090,130);holder:addTo(view.figure)
   local preview=require('Ground.AuxiliaryModel').create(c.variant);preview.scaleX=.8;preview.scaleY=.8;preview.position=D.Vec2(0,80);preview:play('idle',true);preview:addTo(holder)
   for i,v in ipairs(require('Ground.AuxiliaryActor').variants)do
    local b=require('UI.Button')({text=(c.variant==v.id and '✓ 'or '')..v.name});b.position=D.Vec2(-182,-170-(i-1)*105);b:addTo(holder);c.buttons[v.id]=b
    b:slot('Tapped',function()if c.phase=='briefing'then c.variant=v.id;render('已预选'..v.name..'；确认出发时保存。')end end)
   end
   view.backButton:slot('Tapped',function()if c.phase=='briefing'then close()end end)
   view.startButton:slot('Tapped',function()
    if c.phase~='briefing'then return end;c.phase='saving'
    D.thread(function()
     local ok,why=store:saveAsync(c.variant,'final-preparation')
     if ok then
      c.recorded=true;c.phase='budget';c.view.visible=false
      local panel;panel,why=launch(progress.adopted,function()c.supplyPanel=nil;c.phase='briefing';render()end,function(level)c.level=level;c.supplyPanel=nil;c.phase='playing'end)
      if panel then c.supplyPanel=panel;return end
     end
     c.phase='briefing';c.error=why;render('撤离尚未开始，记录保存或准备失败，请重试。')
    end)
   end)
  end
  render();return c
 end
 function c:request(index)
  local p=player();if c.phase~='ready'or world.data.storyBusy or world.data.journalOpen or not p or p.busy then return nil,'BUSY'end
  if math.abs(p.unit.x-marker.x)>=180 then return nil,'DISCOVERY_LOCATION_REQUIRED'end
  local facts=assert(story:summary());if not facts.completed['jade-distance']then return nil,'STORY_LOCKED'end
  if facts.mission.unlocks['last-promise-complete']then
   if index==1 then c.phase='opening';return require('Final.Betrayal').openAsync(facts.completed['final-betrayal']or false)end
   return c:showRecord()
  end
  local result,why=c:prepare();if not result then hint.text='撤离准备暂不可用：'..tostring(why)end;return result,why
 end
 menu:slot('Tapped',function(index)D.thread(function()c:request(index)end)end)
 local near=false;marker:schedule(function()
  local p=player();local now=c.phase=='ready'and p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-marker.x)<180
  hint.visible=not now
  if (not not now)~=near then near=not not now;if near then menu.visible=true;menu:show()else menu:hide(false)end end;return false
 end)
 world:slot('Cleanup',function()if c.view and c.view.parent then c.view:removeFromParent()end end);return c
end
return Gate
