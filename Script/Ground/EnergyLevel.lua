local D=require("Dora")
local Level={}
function Level.openAsync(service,attempt,support)
 local b=require("Ground.EnergyBattle").createAsync(service,attempt,support)
 local c={battle=b,phase="playing"}; b.arena.world.energyBattle=c
 local hud=require("UI.HUDControl")({weaponIcon="kineticgun"}); hud.tag="energy-battle-hud"; hud.weapon.visible=true; hud.topControl.visible=false; hud.message.visible=false; hud:addTo(D.Director.ui3D); D.emit("HUD.DisplayMove",true)
 local gather=require("UI.Skill")({visible=true,text="集合 K"}); gather.tag="energy-gather"; gather.position=hud.weapon.position-D.Vec2(296,0); gather:addTo(hud.skillArea)
 local inputActive=function()return true end
 gather:slot("TapBegan",function() if inputActive()then b:command("gather") end end)
 local fire=require("UI.Skill")({visible=true,text="焰火 E"}); fire.tag="energy-fire"; fire.position=hud.weapon.position-D.Vec2(592,0); fire:addTo(hud.skillArea)
 local wind=require("UI.Skill")({visible=true,text="寒风 L"}); wind.tag="energy-wind"; wind.position=hud.weapon.position+D.Vec2(0,296); wind:addTo(hud.skillArea)
 local function cast(name) if not inputActive()then return end;local ok,why=b:command(name); b.message=ok and (why=="QUEUED_AFTER_ATTACK" and "当前动作结束后施放。" or "已施放，注意朝向与石柱掩护。") or (why=="COOLDOWN" and "技能正在恢复，稍后再试。" or "先站稳，再施放技能。") end
 fire:slot("TapBegan",function() cast("fire") end); wind:slot("TapBegan",function() cast("wind") end)
 local held={left=false,right=false}
 hud.move.onMove=function(key,down) local side=key=="keyLeft" and "left" or "right"; held[side]=down and inputActive(); if held[side] then b:command(side) elseif not held.left and not held.right then b:command("stop") end end
 require('Ground.Mentor').bindAim(hud,b)
 local ui=D.Node(); ui.tag="energy-battle-controls"; ui:addTo(D.Director.ui3D)
 local function clearInput()
  held.left,held.right=false,false
  if not b.arena.closed then b:command("stop")end -- Keep issued orders and finite attacks.
 end
 local controlsActive=require('UI.InputAvailability').bind(ui,clearInput)
 inputActive=function()return controlsActive()and hud.visible end
 ui:slot('Cleanup',clearInput)
 local bg=D.DrawNode(); bg:addTo(ui)
 local status=D.Label("SourceHanSansCN-Regular",24); status.anchor=D.Vec2(0,1); status.alignment="Left"; status:addTo(ui); c.status=status
 local withdraw=require("UI.InputButton")({text="撤回列车",textBG=""}); withdraw.scaleX=0.5; withdraw.scaleY=0.5; withdraw:slot("Tapped"):clear(); withdraw:addTo(ui); c.withdraw=withdraw
 withdraw:slot("Tapped",function() if b.phase=="playing" then b:finish("aborted","已撤离，尚未取得能源。") elseif b.phase=="save-error" then b:saveResult() end end)
 local function layout()
  ui.size=D.App.bufferSize; status.position=D.Vec2(30,ui.height-25); status.textWidth=ui.width-330; withdraw.position=D.Vec2(ui.width-150,ui.height-95)
  bg:clear(); bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,250),D.Vec2(0,250)},D.Color(0xcc101b28)); bg.position=D.Vec2(0,ui.height-250)
 end
 layout(); ui:gslot("AppChange",function(n) if n=="Size" then layout() end end)
 local function result()
  c.phase="result"; hud:removeFromParent(); ui:removeFromParent()
  local won=b.phase=="won"
  local awarded=b.service:summary().rewards["energy-site-secured"]
  local rewardText=won and ("已记入能源 "..tostring(awarded or 1).." 份（首次奖励，重打不重复发放）") or "本次未获得能源奖励"
  local v=require("UI.Settlement")({missionMode=true,economy=b.report.economy,missionTitle="遗弃城市 · 能源伏击",resultTitle=won and "中央道路已清理" or "调查中止",resultStatus=won and "Complete" or "Failed",baseText=won and "继续调查" or "返回列车",
   reportText=(b.reason or "").."\n"..string.format("妮妮莉特命中 %d · 乌云命中 %d · 导师命中 %d\n辅助机 %d · 金粉 %.1f",b.arena.metrics.hits,b.wuyun.metrics.hits,b.mentorHits,b.support.machineHP,b.support.gold).."\n风火协同 "..b.magic.synergyHits.." · 石柱挡击 "..b.coverBlocks.." · 本次配合 ×"..b.report.rewardMultiplier.."\n"..rewardText,
   storyText=won and "怪物已退去。按夜光镜定位打开中央能源箱，再回学院报告。" or "返回补给与训练；此前采用的两份训练成果仍保留。"})
  v.againButton.visible=false; v.againButton.touchEnabled=false
  c.result=v; v.tag="energy-battle-result"; v:addTo(D.Director.ui3D)
  local leaving=false
  local function leave(city)
   if leaving then return end; leaving=true
   D.thread(function() require("Academy.Navigation").returnToRoomAsync(city and "AbandonedCity" or "TrainA",city and {energySquad=true,spawn=5610,support=b.support} or nil) end)
  end
  v.baseButton:slot("Tapped",function() leave(won) end)
 end
 ui:schedule(function()
  if b.arena.closed then return true end
  local active=inputActive();if not active then clearInput()end
  local text=string.format("能源点伏击 · 左侧 %d / 中央 %d / 右侧 %d\n导师 %.0f · 妮妮莉特 %.0f（%s）· 乌云 %.0f（%s）\n辅助机 %d · 金粉 %.1f · 摇杆/A、D移动 · J射击 · K集合\nE 鸿鹄焰火 / L 藏银寒风：面向目标，在柱后引导风火。",b.arena.enemyHP,b.central.enemyHP,b.wuyun.enemyHP,b.mentorHP,b.arena.studentHP,require("Training.Summary").short(b.attempt.models.ninilite),b.wuyun.studentHP,require("Training.Summary").short(b.attempt.models.wuyun),b.support.machineHP,b.support.gold).."\n"..(b.message or ("石柱挡击 "..b.coverBlocks.." · 风火协同 "..b.magic.synergyHits))
  if b.supplies then text=text..'\n'..b.supplies:statusText()end
  if b.phase=="save-error"then text=text.."\n结算尚未保存，点击撤回列车按钮重试保存。"end
  if status.text~=text then status.text=text end
  if b.phase=="playing" then if active then if D.Keyboard:isKeyDown("E") then cast("fire") end; if D.Keyboard:isKeyDown("L") then cast("wind") end; if held.left~=held.right then b:command(held.right and "right" or "left") end; if D.Keyboard:isKeyDown("K") then b:command("gather") end end
  elseif b.phase=="won" or b.phase=="failed" or b.phase=="aborted" then result(); return true end
  return false
 end)
 return c
end
return Level
