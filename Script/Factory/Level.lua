local D=require("Dora")
local Level={}
local Text=require("Factory.BattleText")
local poem=Text.poem
function Level.openAsync(service,attempt,support)
 local b=require("Factory.Battle").createAsync(service,attempt,support)
 local Result=require("Factory.ResultView")
 Result.prepareAsync()
 local c={battle=b,phase="ready"}; b.arena.world.factoryBattle=c
 require('System.Music').battle(b.arena.world,b,'Music/战斗1.mp3')
 local hud=require("UI.HUDControl")({weaponIcon="kineticgun"}); hud.tag="factory-battle-hud"; hud.weapon.visible=true; hud.topControl.visible=false; hud.message.visible=false; hud:addTo(D.Director.ui3D); D.emit("HUD.DisplayMove",true)
 local gather=require("UI.Skill")({visible=true,text="集合 K"}); gather.tag="factory-gather"; gather.position=hud.weapon.position-D.Vec2(296,0); gather:addTo(hud.skillArea)
 local song=require("UI.Skill")({visible=true,text="歌谣 R"}); song.tag="factory-song"; song.position=hud.weapon.position-D.Vec2(592,0); song:addTo(hud.skillArea)
 local inputActive=function()return true end
 local function chant() if not inputActive()then return end;local ok,why=b:command("song"); if ok then b.message="乌云："..poem elseif not b.wuyun.student:isDoing(b.song.action) then b.message=why=="COOLDOWN" and "乌云正在恢复，稍后再吟唱。" or why=="EQUIPMENT_DISABLED" and "通讯被病毒干扰，暂时不能传唱。" or "先开始战斗，站稳后吟唱。" end end
 song:slot("TapBegan",chant); gather:slot("TapBegan",function() if inputActive()then b:command("gather") end end)
 local held={left=false,right=false}
 hud.move.onMove=function(key,down) local side=key=="keyLeft" and "left" or "right"; held[side]=down and inputActive(); if held[side] then b:command(side) elseif not held.left and not held.right then b:command("stop") end end
 require("Ground.Mentor").bindAim(hud,b);c.hud=hud
 local ui=D.Node(); ui.tag="factory-battle-controls"; ui:addTo(D.Director.ui3D)
 local function clearInput()
  held.left,held.right=false,false
  if not b.arena.closed then b:command('stop')end
 end
 local controlsActive=require('UI.InputAvailability').bind(ui,clearInput)
 inputActive=function()return controlsActive()and hud.visible end
 ui:slot('Cleanup',clearInput)
 local bg=D.DrawNode(); bg:addTo(ui)
 local status=D.Label("SourceHanSansCN-Regular",20); status.anchor=D.Vec2(0,1); status.alignment="Left"; status:addTo(ui); c.status=status
 -- Populate the shared font atlas while the encounter is still preparing.
 -- Keep the actual message unchanged; no hidden node or per-frame warmup.
 status.text=Text.poem..Text.injury..Text.chantReleased.."乌云正在恢复，稍后再吟唱。通讯被病毒干扰，暂时不能传唱。先开始战斗，站稳后吟唱。繁殖期优先压制新花蕾；留意病毒前摇，用歌谣解除蛊惑。已破甲无护甲即将转入结算尚未保存，点击撤回列车重试。0123456789"
 status.text=""
 local bossBar=D.DrawNode();bossBar:addTo(ui);c.bossBar=bossBar
 local armorBar=D.DrawNode();armorBar:addTo(ui);c.armorBar=armorBar
 local partNames={['flower-head']='头部',['flower-core']='躯干',['petal-left']='左花瓣',['petal-right']='右花瓣',roots='根部'}
 local partView=require('Combat.StatusView').new(b.partCombat.target.damage,'沼泽花妖',partNames);partView.node.visible=false;b.partCombat.view=partView

 local start=require("UI.InputButton")({text="开始战斗",textBG=""}); start.tag="factory-start"; start.scaleX=0.5; start.scaleY=0.5; start:slot("Tapped"):clear(); start:addTo(ui); c.start=start
 start:slot("Tapped",function() if b:start() then start.visible=false; c.phase="playing" end end)
 local withdraw=require("UI.InputButton")({text="撤回列车",textBG=""}); withdraw.scaleX=0.5; withdraw.scaleY=0.5; withdraw:slot("Tapped"):clear(); withdraw:addTo(ui); c.withdraw=withdraw
 withdraw:slot("Tapped",function() if b.phase=="ready" or b.phase=="playing" then b:finish("aborted",Text.withdraw) elseif b.phase=="save-error" then b:saveResult() end end)
 local panelKey,hpKey,apKey
 local function layout()
  panelKey=nil;hpKey=nil;apKey=nil
  ui.size=D.App.bufferSize; status.position=D.Vec2(30,ui.height-25); status.textWidth=ui.width-340; withdraw.position=D.Vec2(ui.width-150,ui.height-95); start.position=D.Vec2(ui.width-150,ui.height-170)
  bg:clear(); bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,310),D.Vec2(0,310)},D.Color(0xdd101b28)); bg.position=D.Vec2(0,ui.height-310)
 end
 layout(); ui:gslot("AppChange",function(n) if n=="Size" then layout() end end)
 local function result()
  c.phase="result"; hud:removeFromParent(); ui:removeFromParent()
  local won=b.phase=="won"
  local v=Result.create(b)
  c.result=v; v.tag="factory-battle-result"; v:addTo(D.Director.ui3D)
  local leaving=false
  local function leave() if leaving then return end; leaving=true; D.thread(function() require("Academy.Navigation").returnToRoomAsync(won and "Factory" or "TrainA",won and {spawn=6050,support=b.support,auxiliaryVariant=b.support.variant} or nil) end) end
  v.againButton:slot("Tapped",leave); v.baseButton:slot("Tapped",leave)
 end
 function c.updateUI()
  if b.arena.closed then return true end
  local alive=0; for _,e in ipairs(b.enemies) do if e.enemyHP>0 then alive=alive+1 end end
  local boss=b.roots[3];local combat=boss.enemyCombat
  local phase=combat.bossPhase==2 and "繁殖期" or "盘踞期"
  local warning=combat.phasePending and " · 即将转入繁殖期" or ""
  local hint=combat.bossPhase==2 and "优先压制新花蕾；留意病毒前摇，用歌谣解除蛊惑。" or "藤蔓蛊惑时及时吟唱；毒素仍持续。"
  local hit=b.partCombat.events[#b.partCombat.events];local part=hit and b.partCombat.target.damage.parts[hit.part]
  local armorText=part and (partNames[hit.part]..(part.maxAP==0 and ' · 无护甲' or part.ap<=0 and ' · 已破甲' or string.format(' · 护甲 %.0f / %.0f',part.ap,part.maxAP))) or '命中后显示局部护甲；EMP削甲，实弹伤害生命'
  if boss.enemyHP<=0 or combat.dead then
   phase='已击败';warning='';hint='继续清理剩余花妖；EMP不能伤害无护甲敌人的生命。'
   local enemy=b:target(b.mentor)
   if enemy then
    local dx=enemy.enemy.x-b.mentor.x
    armorText=string.format('最近残敌：%s · 生命 %.0f/%.0f · 导师%s %.0f',
     enemy.combatSource:find('summon',1,true) and '召唤花妖' or '小花妖',enemy.enemyHP,enemy.enemyMaxHP,dx>=0 and '右侧' or '左侧',math.abs(dx))
   else armorText='道路已清理，正在等待动作结束与结算。'end
  end
  local statusText=string.format("沼泽花妖 %.0f/%.0f · %s%s · 存活 %d\n导师 %.0f · 妮妮莉特 %.0f · 乌云 %.0f · 辅助机 %.0f · 金粉 %.1f\n按住J瞄准，松开发射 · K集合 · R歌谣：%s\n%s\n%s",boss.enemyHP,boss.enemyMaxHP,phase,warning,alive,b.mentorHP,b.arena.studentHP,b.wuyun.studentHP,b.support.machineHP,b.support.gold,hint,armorText,b.phase=="ready" and "确认操作后点击开始；准备期间队伍与怪物均不行动。" or b.message or "保护队伍，清理沼泽道路。")
  local controllerText=require('Training.FlowerController').text(b);if controllerText~=''then statusText=statusText..'\n'..controllerText end
  if b.phase=="save-error" then statusText=statusText.."\n结算尚未保存，点击撤回列车重试。" end
  if b.supplies then statusText=statusText..'\n'..b.supplies:statusText()end
  if status.text~=statusText then status.text=statusText end
  local panelHeight=math.max(180,status.height+70)
  b.cameraTopInset=(panelHeight+20)*D.View.size.height/ui.height
  if panelKey~=panelHeight then
  panelKey=panelHeight
  bg:clear();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,panelHeight),D.Vec2(0,panelHeight)},D.Color(0xdd101b28));bg.position=D.Vec2(0,ui.height-panelHeight)
  bossBar.position=D.Vec2(30,ui.height-panelHeight+26)
  armorBar.position=D.Vec2(30,ui.height-panelHeight+9)
  end
  local width=math.max(120,ui.width-370)
  local nextHP=string.format('%s:%s:%s',boss.enemyHP,boss.enemyMaxHP,combat.bossPhase)
  if hpKey~=nextHP then
  hpKey=nextHP;bossBar:clear()
  bossBar:drawSegment(D.Vec2.zero,D.Vec2(width,0),6,D.Color(0xff283747))
  bossBar:drawSegment(D.Vec2.zero,D.Vec2(width*math.max(0,boss.enemyHP)/boss.enemyMaxHP,0),6,D.Color(combat.bossPhase==2 and 0xffd06e95 or 0xff8eb76c))
  end
  local nextAP=part and tostring(part.ap)..':'..tostring(part.maxAP) or ''
  if apKey~=nextAP then
  apKey=nextAP;armorBar:clear()
  if part and part.maxAP>0 then
   armorBar:drawSegment(D.Vec2.zero,D.Vec2(width,0),3,D.Color(0xff283747))
   armorBar:drawSegment(D.Vec2.zero,D.Vec2(width*part.ap/part.maxAP,0),3,D.Color(0xff8dbef3))
  end
  end
  local active=inputActive();if not active then clearInput()end
  if b.phase=="playing" then if active then if D.Keyboard:isKeyDown("R") then chant() end; if held.left~=held.right then b:command(held.right and "right" or "left") end; if D.Keyboard:isKeyDown("K") then b:command("gather") end end

  elseif b.phase=="won" or b.phase=="failed" or b.phase=="aborted" then result(); return true end
  return false
 end
 ui:schedule(function()return c.updateUI()end)
 return c
end
return Level
