-- Unified original controls; completion is a combat result, not a chapter reward.
local D=require('Dora');local Level={}
function Level.openAsync(models,onResult,options)
 options=options or {}
 local presentation=options.presentation or {}
 local b=(options.battleFactory or require('Factory.PatrolBattle').createAsync)(models,options.attempt);local c={battle=b,phase='ready'};b.world.patrolLevel=c
 require('System.Music').battle(b.world,b,options.music or 'Music/战斗2.mp3')
 local hud=require('UI.HUDControl')({weaponIcon=b.demonstrator and 'empgun'or'kineticgun'});hud.tag='patrol-battle-hud';hud.weapon.visible=true;hud.topControl.visible=false;hud.message.visible=false;hud:addTo(D.Director.ui3D);D.emit('HUD.DisplayMove',true);c.hud=hud
 local fire=require('UI.Skill')({visible=true,text='火焰 F'});fire.tag='patrol-fire';fire.position=hud.weapon.position-D.Vec2(296,0);fire:addTo(hud.skillArea);c.fire=fire
 local wind=require('UI.Skill')({visible=true,text='旋风 R'});wind.tag='patrol-wind';wind.position=hud.weapon.position-D.Vec2(592,0);wind:addTo(hud.skillArea);c.wind=wind;wind.visible=b.wuyun~=nil
 local inputActive=function()return true end
 fire:slot('TapBegan',function()if inputActive()then b:command('fire')end end);wind:slot('TapBegan',function()if inputActive()then b:command('wind')end end)
 local gather
 local gatherGesture
 if b.gatherSupported then
  gatherGesture=require('Combat.GatherGesture').new(function()return b.phase=='playing'end,function(name)return b:command(name)end,function()return b.gatherMode=='recover'and b:gatherActive()end)
  gather=require('UI.Skill')({visible=true,text='集合 G\n长按恢复'});gather.position=hud.weapon.position-D.Vec2(888,0);gather:addTo(hud.skillArea)
  gather:slot('TapBegan',function()if inputActive()then gatherGesture:press('touch',D.App.runningTime)end end)
  gather:slot('TapEnded',function()gatherGesture:release('touch')end);c.gather=gather
 end
 local held={left=false,right=false};hud.move.onMove=function(key,down)local side=key=='keyLeft' and 'left' or 'right';held[side]=down and inputActive();if held[side]then b:command(side)elseif not held.left and not held.right then b:command('stop')end end
 if b.demonstrator then hud:gslot('Skill.Began',function()b:command('shoot')end)else require('Ground.Mentor').bindAim(hud,b)end
 local ui=D.Node();ui.tag='patrol-battle-controls';ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D);c.controls=ui;local bg=D.DrawNode();bg:addTo(ui)
 local pendingFire,pendingWind,pendingMelee=false,false,false
 local melee
 if b.demonstrator and b.demonstrator.character.legal.melee then melee=require('UI.Skill')({visible=true,text='刀击 E'});melee.position=hud.weapon.position-D.Vec2(888,gather and -296 or 0);melee:addTo(hud.skillArea);melee:slot('TapBegan',function()if inputActive()then b:command('melee')end end);c.melee=melee end
 local function clearInput()
  pendingFire,pendingWind,pendingMelee=false,false,false
  held.left,held.right=false,false
  if gatherGesture then gatherGesture:clear()end
  -- Clear held player input; preserve issued orders and finite attack actions.
  if not b.closed and not b.arena.closed then b:command('stop')end
 end
 local controlsActive=require('UI.InputAvailability').bind(ui,clearInput)
 inputActive=function()return controlsActive()and hud.visible end
 -- Chapter-specific buttons use the same availability as the common HUD.
 c.commandInput=function(name)
  if not inputActive()then return false,'INPUT_INACTIVE'end
  return b:command(name)
 end
ui.keyboardEnabled=true
 ui:slot('KeyDown',function(key)if not inputActive()then return end;if key=='F'then pendingFire=true elseif key=='R'then pendingWind=true elseif key=='E'and melee then pendingMelee=true elseif key=='G'and gatherGesture then gatherGesture:press('keyboard',D.App.runningTime)end end)
 ui:slot('KeyUp',function(key)if key=='G'and gatherGesture then gatherGesture:release('keyboard')end end)
 ui:slot('Cleanup',clearInput)
 local status=D.Label('SourceHanSansCN-Regular',24);status.anchor=D.Vec2(0,1);status.alignment='Left';status:addTo(ui);c.status=status
 local function button(text)
  local holder=D.Node();holder.scaleX=.5;holder.scaleY=.5;holder:addTo(ui)
  local v=require('UI.InputButton')({text=text,textBG=''});v:slot('Tapped'):clear();v:addTo(holder);return v,holder
 end
 local start,startHolder=button(presentation.start or '开始潜入');c.start=start;start:slot('Tapped',function()
  if c.phase~='ready'then return end;c.phase='starting';start.visible=false
  D.thread(function()
   -- The engine swallows thread errors; recover to 'ready' so the level stays operable.
   local ok,r,e=true,true,nil
   if options.beforeStartAsync then ok,r,e=xpcall(function() return options.beforeStartAsync(b.world) end,debug.traceback) end
   if ok and r~=false and b:start()then c.phase='playing'else c.phase='ready';c.error=not ok and tostring(r)or e;start.visible=true end
  end)
 end)
 local withdraw,withdrawHolder=button(presentation.withdrawButton or '撤回指挥室');c.withdraw=withdraw;withdraw:slot('Tapped',function()if c.phase=='starting'then return end;b:finish('aborted',presentation.withdraw or '已撤离，守卫未制服。')end)
 local function headerHeight()
  local height=(presentation.headerHeight and presentation.headerHeight(b)or 255)+(b.physicalShield and 80 or b.support and 40 or 0)
  if presentation.fitHeader then height=math.max(height,status.height+50,c.targetSelectorHeaderHeight or 0)end
  return height
 end
 local function layout()
  ui.size=D.App.bufferSize;status.position=D.Vec2(30,ui.height-25);status.textWidth=ui.width-390
  startHolder.position=D.Vec2(ui.width-210,ui.height-185);withdrawHolder.position=D.Vec2(ui.width-210,ui.height-105)
  if presentation.layoutControls then presentation.layoutControls(c,ui,startHolder,withdrawHolder)end
  c.headerHeight=headerHeight()
  bg:clear();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,c.headerHeight),D.Vec2(0,c.headerHeight)},D.Color(0xdd101b28));bg.position=D.Vec2(0,ui.height-c.headerHeight)
 end
 if b.yingzhaoDemonstration then require('Training.YingzhaoTargetSelector').attach(c)end
 layout();ui:gslot('AppChange',function(name)if name=='Size'then layout()end end)
 if presentation.frameCamera then presentation.frameCamera(b,c)end
 if presentation.playerMarker then require('UI.CombatPlayerMarker').attach(b,c)end
 ui:schedule(function()
  if b.arena.closed then if gatherGesture then gatherGesture:clear()end;return true end
  local active=inputActive()
  if not active then clearInput()end
  if gatherGesture and active then gatherGesture:update(D.App.runningTime)end
  if gather and gather.textLabel then
   local active=b.gatherActive and b:gatherActive()
   local text=active and string.format('%s\n取消 G · %.1fs',b.gatherMode=='recover'and'恢复集合'or'集合中',math.max(0,b.gatherUntil-D.App.runningTime))or (b.phase=='playing'and b.gatherFeedback and D.App.runningTime<b.gatherFeedback.untilAt and b.gatherFeedback.text)or '集合 G\n长按恢复'
   if gather.textLabel.text~=text then gather.textLabel.text=text;c.gatherLabelWrites=(c.gatherLabelWrites or 0)+1 end
  end
  if presentation.headerHeight and c.headerHeight~=headerHeight()then layout()end
  withdraw.visible=c.phase~='starting'
  hud.weapon.opacity=(b.controlledUnit or b.mentor).data.weaponDisarmed and .45 or 1
  local alive=0;for _,e in ipairs(b.enemies)do if e.enemyHP>0 then alive=alive+1 end end
  local text
  if presentation.statusText then text=presentation.statusText(b)
  elseif b.wuyun then text=string.format('%s %d / %d\n导师 %.0f · 妮妮莉特 %.0f · 乌云 %.0f\n摇杆/A、D移动 · J射击 · F火焰 · R旋风\n命中：射击 %d · 火焰 %d · 旋风 %d\n%s',presentation.title or '工厂潜入 · 首波巡逻守卫',alive,#b.enemies,b.mentorHP,b.arena.studentHP,b.wuyun.studentHP,b.mentorHits,b.magic.fireHits,b.magic.windHits,b.phase=='ready' and (presentation.ready or '夜光定位：前方有守卫。确认操作后开始，注意隐蔽。') or (presentation.playing or '靠近守卫，射击时配合两名学员的火焰和旋风。'))
  else text=string.format('%s %d / %d\n导师 %.0f · 妮妮莉特 %.0f · 乌云留守\n摇杆/A、D移动 · J射击 · F火焰\n命中：射击 %d · 火焰 %d\n%s',presentation.title or '工厂潜入',alive,#b.enemies,b.mentorHP,b.arena.studentHP,b.mentorHits,b.magic.fireHits,b.phase=='ready' and presentation.ready or presentation.playing)end
  if presentation.supportText then
   local supportText=presentation.supportText(b);if supportText and supportText~=''then text=text..'\n'..supportText end
  else
   if b.support then text=text..string.format('\n辅助机 %.0f / 100 · 金粉 %.1f · 维生场%s',b.support.machineHP,b.support.gold,b.support.active and '运行' or '停机')end
   if b.physicalShield then text=text..string.format('\n护盾 %.0f / %.0f · %s',b.physicalShield.charge,b.physicalShield.capacity,b.physicalShield:status())end
  end
  if b.supplies then local supply=b.supplies:statusText();if presentation.supplyText then supply=presentation.supplyText(supply)end;text=text..'\n'..supply end
  -- Label.setText rebuilds glyph layout even for identical strings.
  if status.text~=text then status.text=text;c.statusWrites=(c.statusWrites or 0)+1 end
  if presentation.fitHeader and c.headerHeight~=headerHeight()then layout()end
  if b.phase=='playing' then
   if active then
    if held.left~=held.right then b:command(held.right and 'right' or 'left')end
    if pendingMelee then b:command('melee')end
    if pendingFire or D.Keyboard:isKeyDown('F')then b:command('fire')end;if b.wuyun and (pendingWind or D.Keyboard:isKeyDown('R'))then b:command('wind')end
   end
  elseif b.phase=='won' or b.phase=='failed' or b.phase=='aborted' then
   c.phase='saving-result';hud:removeFromParent();withdraw.visible=false;start.visible=false;status.text=presentation.saving or '正在保存行动记录…'
   local showResult,saveResult
   showResult=function(saveError)
    if ui.parent then ui:removeFromParent()end
    if c.result then c.result:removeFromParent()end
    c.phase='building-result';c.error=saveError
    local reportText=presentation.reportText and presentation.reportText(b) or b.wuyun and string.format('导师命中 %d · 火焰 %d · 旋风 %d\n妮妮莉特模型动作 %d · 乌云模型动作 %d',b.mentorHits,b.magic.fireHits,b.magic.windHits,b.arena.metrics.modelActions,b.wuyun.metrics.modelActions) or string.format('导师命中 %d · 火焰 %d\n妮妮莉特模型动作 %d · 乌云留下看守',b.mentorHits,b.magic.fireHits,b.arena.metrics.modelActions)
    local supportText=require('Factory.Support').resultText(b.report)
    if supportText then reportText=reportText..'\n'..supportText end
    if saveError then reportText=(presentation.saveFailure or '行动记录尚未保存，请重试保存后继续。此前进度会保留。')..'\n'..reportText end
    local view=require('UI.Settlement')({missionMode=true,economy=b.report.economy or (b.supplies and b.supplies.isVirtual and assert(b.supplies:closeVirtual(b.phase)) or nil),economyMode=b.supplies and b.supplies.isVirtual and 'virtual' or nil,missionCategory=presentation.category,missionTitle=presentation.title or '工厂潜入 · 巡逻队',resultTitle=saveError and '记录尚未保存' or b.phase=='won' and (presentation.won or '守卫已制服') or (presentation.failed or '潜入中止'),resultStatus=saveError and 'Pending' or b.phase=='won' and 'Complete' or 'Failed',reportText=reportText,storyText=saveError and '' or b.reason,againText=saveError and '重试保存' or b.phase=='won' and options.onSettledAsync and (presentation.continueText or '继续潜入') or '再次行动',baseText=saveError and presentation.unsavedBaseText or presentation.baseText or '返回指挥室'})
    if presentation.singleExitOnFailure and not saveError and b.phase~='won'then view.againButton.visible=false end
    if saveError and options.requireSavedExit then view.baseButton.visible=false end
    c.result=view;view.tag='patrol-battle-result';view:addTo(D.Director.ui3D)
    local function leave(action)
     if c.leaving or c.phase=='saving-result'then return end
     if saveError and action=='again'then c.phase='saving-result';D.thread(saveResult);return end
     c.leaving=true;D.thread(function()
      local ok,err
      if onResult then ok,err=onResult(b.phase,b.report,action)
      elseif action=='again'then Level.openAsync(models,onResult,options);ok=true
      else require('Academy.Navigation').returnToOperationAsync();ok=true end
      if ok==false then c.leaving=false;showResult(err or 'SAVE_FAILED')end
     end)
    end
    view.againButton:slot('Tapped',function()leave('again')end);view.baseButton:slot('Tapped',function()leave('base')end)
    c.phase=saveError and 'save-error' or 'result'
   end
   saveResult=function()
    local ok,err=true,nil;if options.onSettledAsync then ok,err=options.onSettledAsync(b.phase,b.report)end
    c.checkpointSaved=ok;if ok then showResult(nil)else showResult(err or 'SAVE_FAILED')end
   end
   D.thread(saveResult);return true
  end
  pendingFire,pendingWind,pendingMelee=false,false,false
  return false
 end)
 return c
end
return Level
