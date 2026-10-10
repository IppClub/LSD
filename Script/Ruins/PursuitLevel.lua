local D=require('Dora');local Level={}
function Level.openAsync(service,attempt)
 local b=require('Ruins.Pursuit').createAsync(service,attempt);local c={battle=b,phase='playing'};b.world.pursuitLevel=c
 local hud=require('UI.HUDControl')({weaponIcon='kineticgun'});hud.tag='pursuit-hud';hud.topControl.visible=false;hud.message.visible=false;hud.weapon.visible=true;hud:addTo(D.Director.ui3D);D.emit('HUD.DisplayMove',true)
 local held={left=false,right=false};local keymap={Left='left',A='left',Right='right',D='right',E='smoke',L='flare',H='medicine'}
 local sceneClosed=false;local inputActive=function()return true end
 b.world:slot('Cleanup',function()sceneClosed=true;held.left,held.right=false,false end)
 hud.move.onMove=function(key,down) local side=key=='keyLeft' and 'left' or 'right';held[side]=down and inputActive();if held[side]then b:command(side) elseif not held.left and not held.right and not sceneClosed then b:command('idle') end end
 require('Ground.Mentor').bindAim(hud,b)
 local buttons={}
 for i,tool in ipairs({{'smoke','烟雾 E'},{'flare','火光 L'},{'medicine','药品 H'}}) do
  local button=require('UI.Skill')({visible=true,text=tool[2]});button.position=hud.weapon.position-D.Vec2(296*i,0);button:addTo(hud.skillArea);button:slot('TapBegan',function() if not inputActive()then return end;local ok,err=b:command(tool[1]);if ok then b.message=nil else b.message=err=='NO_SUPPLIES' and '该道具已用尽，请调整战术或撤退。' or err=='COOLDOWN' and '道具正在恢复，请稍后再使用。' or err=='ACTION_BUSY' and '当前动作尚未结束，请稍后使用道具。' or err=='NOT_NEEDED' and '当前无需使用药品，或正在用药。' or '现在无法使用，请稍后重试。' end end);buttons[tool[1]]=button
 end
 c.toolButtons=buttons
 local ui=D.Node();ui.tag='pursuit-controls';ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D);c.controls=ui;c.hud=hud
 local function clearInput()
  held.left,held.right=false,false
  if not sceneClosed then b:command('idle')end -- Only stops walking, not finite tools/shots.
 end
 local controlsActive=require('UI.InputAvailability').bind(ui,clearInput)
 inputActive=function()return not sceneClosed and controlsActive()and hud.visible end
 ui:slot('Cleanup',clearInput)
 local bg=D.DrawNode();bg:addTo(ui);local status=D.Label('SourceHanSansCN-Regular',23);status.anchor=D.Vec2(0,1);status.alignment='Left';status:addTo(ui);c.statusLabel=status;c.statusBackground=bg
 local withdraw=require('UI.InputButton')({text='撤离 / 重试保存',textBG=''});withdraw.scaleX=.5;withdraw.scaleY=.5;withdraw:slot('Tapped'):clear();withdraw:addTo(ui);c.withdraw=withdraw
 withdraw:slot('Tapped',function() if b.phase=='save-error' then b:saveResult() else b:finish('aborted','撤回遗迹安全点，重新制定掩护路线。') end end)
 local function result()
  c.phase='result';hud:removeFromParent();ui:removeFromParent()
  local won=b.phase=='won'
  local view=require('UI.Settlement')({missionMode=true,economy=b.report.economy,againText=won and '继续旅程' or '重试掩护',baseText='返回遗迹',missionTitle='遗迹返程 · 引开追兵',resultTitle=won and '伙伴已撤离' or '掩护未完成',resultStatus=won and 'Complete' or b.phase=='failed' and 'Failed' or '已撤离',reportText=b.reason..string.format('\n导师 %.0f · 射击命中 %d · 火光命中 %d · 烟雾阻断 %d\n撤离 %d/4 · 烟雾/火光完整动作 %d/%d',b.mentorHP,b.mentorHits,b.flareHits,b.smokeBlocks+b.smokeBlockedAttacks,b.escortsSafe,b.toolAnimations.smoke,b.toolAnimations.flare),storyText=won and '导师掉入了与外界隔绝的谷地。' or '伙伴和训练成果保留，重新选择掩护时机。'})
  if won then view.baseButton.visible=false;view.baseButton.touchEnabled=false end
  c.result=view;view.tag='pursuit-result';view:addTo(D.Director.ui3D);local leaving=false
  view.againButton:slot('Tapped',function()
   if leaving then return end;leaving=true
   D.thread(function() if won then require('Academy.Navigation').returnToRoomAsync('OuterHeaven',{spawn=1800,valleyVisit=true}) else
    local panel,err=require('Economy.Preparation').openAsync('c0-m06',nil,function()c.supplyPanel=nil;leaving=false end,function(s,a)c.supplyPanel=nil;Level.openAsync(s,a)end)
    c.supplyPanel=panel;if not panel then leaving=false;b.message=tostring(err)end
   end end)
  end)
  view.baseButton:slot('Tapped',function() if leaving then return end;leaving=true;D.thread(function() require('Academy.Navigation').returnToRoomAsync(won and 'OuterHeaven' or 'AbandonedCity',won and {spawn=1800,valleyVisit=true} or {spawn=8500,energySquad=true,ruinsSearch=true}) end) end)
 end
 ui:slot('KeyDown',function(key) if not inputActive()then return end;local command=keymap[key];if command=='left' or command=='right' then held[command]=true elseif command then b:command(command) end end)
 ui:slot('KeyUp',function(key) local command=keymap[key];if command=='left' or command=='right' then held[command]=false;if not sceneClosed then b:command('idle')end end end);ui.keyboardEnabled=true
 local panelKey
 ui:schedule(function()
  if sceneClosed then return true end
  local active=inputActive();if not active then clearInput()end
  ui.size=D.App.bufferSize;status.position=D.Vec2(30,ui.height-30);status.textWidth=math.max(280,ui.width-460);withdraw.position=D.Vec2(ui.width-225,ui.height-60)
  local nextText=string.format('未知追兵 · 己方战斗力不足，向右沿光路撤退\n导师 %.0f · 体力 %.0f/100 · %s · 伙伴撤离 %d/4 · 烟雾 E / 火光 L / 按住J瞄准、松开发射 / 药品 H\n掩护目标：射击命中 %d/1 · 火光命中 %d/1 · 烟雾 %d/1；经过三段光路到右侧出口\n%s',b.mentorHP,b.stamina.value,b.stamina.down and '倒地起身中' or '可行动',b.escortsSafe,math.min(1,b.mentorHits),math.min(1,b.flareHits),math.min(1,b.toolAnimations.smoke),b.message or '四名伙伴向左撤离；烟雾留在你与追兵之间，后半段仍需掩护，不必击杀全部敌人。')
  if b.ambushActive then nextText=string.format('暗影偷袭 · 离开地面红色预警范围\n导师 %.0f · 体力 %.0f/100 · 伙伴撤离 %d/4',b.mentorHP,b.stamina.value,b.escortsSafe)end
  if b.supplies then nextText=nextText..'\n'..b.supplies:statusText()end
  if b.phase=='save-error'then nextText=nextText..'\n结算未保存，请点击右上角重试。'end
  if status.text~=nextText then status.text=nextText end
  local panelHeight=math.max(b.ambushActive and 90 or 165,status.height+42);c.statusPanelHeight=panelHeight
  bg.position=D.Vec2(15,ui.height-panelHeight-20)
  local key=table.concat({status.textWidth,panelHeight,b.stamina.value,tostring(b.stamina.down)},':')
  if key~=panelKey then
  panelKey=key;bg:clear();bg:drawPolygon({D.Vec2.zero,D.Vec2(status.textWidth+30,0),D.Vec2(status.textWidth+30,panelHeight),D.Vec2(0,panelHeight)},D.Color(0xcc101b28))
  bg:drawSegment(D.Vec2(15,12),D.Vec2(255,12),5,D.Color(0xff283747))
  bg:drawSegment(D.Vec2(15,12),D.Vec2(15+240*b.stamina.value/100,12),5,D.Color(b.stamina.down and 0xffdf755e or 0xff59c9b5))
  end
  if b.phase=='playing' then
   if active then
    for key,command in pairs({E='smoke',L='flare',H='medicine'}) do if D.Keyboard:isKeyDown(key) then b:command(command) end end
    if held.left~=held.right then b:command(held.right and 'right' or 'left') end
   end

  elseif b.phase=='won' or b.phase=='failed' or b.phase=='aborted' then result();return true end
  return false
 end)
 return c
end
return Level
