local D=require("Dora")
local Level={}
function Level.openAsync(service,attempt,loadout)
 local battle=require("Ground.Battle").createAsync(service,attempt,loadout)
 local controller={battle=battle,phase="playing"}; battle.arena.world.groundBattle=controller
 require('System.Music').battle(battle.arena.world,battle,'Music/战斗1.mp3')
 local hud=require("UI.HUDControl")({weaponIcon="kineticgun"}); hud.tag="ground-battle-hud"; hud.weapon.visible=true; hud.topControl.visible=false; hud.message.visible=false; hud:addTo(D.Director.ui3D); D.emit("HUD.DisplayMove",true)
 local gather=require("UI.Skill")({visible=true,text="集合 K"}); gather.tag="ground-battle-gather"; gather.position=hud.weapon.position-D.Vec2(296,0); gather:addTo(hud.skillArea)
 local inputActive=function()return true end
 gather:slot("TapBegan",function() if inputActive()then battle:command("gather") end end)
 local held={left=false,right=false}
 hud.move.onMove=function(key,down)
  local side=key=="keyLeft" and "left" or "right"; held[side]=down and inputActive()
  if held[side] then battle:command(side) elseif not held.left and not held.right then battle:command("stop") end
 end
 require("Ground.Mentor").bindAim(hud,battle)
 local partView=require('Combat.StatusView').new(battle.partCombat.target.damage,'大饕餮',{head='头部',['head-gem']='头部宝石',['back-front']='前背甲',['back-rear']='后背甲',['front-leg']='前腿',['rear-leg']='后腿',tail='尾部'})
 battle.partCombat.view=partView;partView.node:addTo(D.Director.ui3D)
 local ui=D.Node(); ui.size=D.App.bufferSize; ui:addTo(D.Director.ui3D)
 local function clearInput()
  held.left,held.right=false,false
  if not battle.arena.closed then battle:command("stop")end -- Finite shots complete normally.
 end
 local controlsActive=require('UI.InputAvailability').bind(ui,clearInput)
 inputActive=function()return controlsActive()and hud.visible end
 ui:slot('Cleanup',clearInput)
 local bg=D.DrawNode(); bg:addTo(ui)
 local status=D.Label("SourceHanSansCN-Regular",24); status.alignment="Left"; status.anchor=D.Vec2(0,1); status.textWidth=1300; status.tag="ground-battle-status"; status:addTo(ui)
 local withdraw=require("UI.InputButton")({text="撤回列车",textBG=""}); withdraw.tag="ground-battle-withdraw"; withdraw.scaleX=0.5; withdraw.scaleY=0.5; withdraw:slot("Tapped"):clear(); withdraw:addTo(ui)
 withdraw:slot("Tapped",function()
  if battle.phase=="playing" then battle:finish("aborted","已安全中止调查，未记录救援成果。")
  elseif battle.phase=="save-error" then battle:saveResult() end
 end)
 local function layout()
  ui.size=D.App.bufferSize; partView.node.position=D.Vec2(ui.width/2,ui.height-245); status.position=D.Vec2(30,ui.height-25); status.textWidth=math.min(1300,ui.width-280); withdraw.position=D.Vec2(ui.width-125,ui.height-205)
  bg:clear(); bg:drawPolygon({D.Vec2(0,0),D.Vec2(ui.width,0),D.Vec2(ui.width,215),D.Vec2(0,215)},D.Color(0xcc101b28)); bg.position=D.Vec2(0,ui.height-215)
 end
 layout(); ui:gslot("AppChange",function(name) if name=="Size" then layout() end end)
 local function result()
  controller.phase="result"; hud:removeFromParent(); ui:removeFromParent()
  local won=battle.phase=="won"
  local view=require("UI.Settlement")({missionMode=true,economy=battle.report.economy,missionTitle="遗弃城市 · 守住退路",resultTitle=won and "退路已守住" or "调查中止",
   resultStatus=won and "Complete" or battle.phase=="failed" and "Failed" or "已撤离",againText="返回调查点",baseText=won and "继续交谈" or "返回列车",
   reportText=battle.reason.."\n学员命中 "..battle.arena.metrics.hits.." · 导师命中 "..battle.mentorHits.." · 乌云命中 "..battle.rescueHits.."\n辅助机 "..battle.support.machineHP.." · 学员生命 "..math.floor(battle.arena.studentHP).." · 金粉 "..math.floor(battle.support.gold),
   storyText=won and "乌云：这里还不安全。先让小扎西们休息，我们回去再仔细商谈。" or "先返回补给；已采用的训练成果与此前调查记录仍保留。"})
  controller.result=view; view.tag="ground-battle-result"; view:addTo(D.Director.ui3D)
  local leaving=false
  view.againButton:slot("Tapped",function()
   if leaving then return end; leaving=true
   D.thread(function() require("Academy.Navigation").returnToRoomAsync("AbandonedCity") end)
  end)
  view.baseButton:slot("Tapped",function()
   if leaving then return end; leaving=true
   D.thread(function()
    if not won then require("Academy.Navigation").returnToRoomAsync("TrainA"); return end
    view:removeFromParent()
    local opened,err=require("Story.Flow").openAsync("ground-rescue",battle.arena.world,function()
     D.thread(function() require("Academy.Navigation").returnToRoomAsync("RestRoom") end)
    end)
    if not opened then leaving=false; view:addTo(D.Director.ui3D); battle.message=tostring(err) end
   end)
  end)
 end
 ui:schedule(function()
  if battle.arena.closed then return true end
  local a=battle.arena; local strike=a.enemyStrike; local enemy=a.enemyPhase=="attack" and require("Ground.BossCombat").specs[strike.kind].label or a.enemyPhase=="recover" and "收招恢复" or "接近观察"
  local active=inputActive();if not active then clearInput()end
  local text=string.format("遗弃城市 · 大饕餮 %d / 480 · %s\n导师 %.0f / 妮妮莉特 %.0f · 驱动能量 %d · 辅助机 %d · 金粉 %.1f\n摇杆 / A、D 移动 · J 轻点射击 / 长按瞄准 · 集合 K 保留生命场\n%s",a.enemyHP,enemy,battle.mentorHP,a.studentHP,a.studentEnergy,battle.support.machineHP,battle.support.gold,battle.message or "")
  if battle.supplies then text=text..'\n'..battle.supplies:statusText()end
  if battle.phase=="save-error"then text=text.."\n结算未保存，请重试。"end
  if status.text~=text then status.text=text end
  if battle.phase=="playing" then
   if active then
    if D.Keyboard:isKeyDown("K") then battle:command("gather") end
    if held.left~=held.right then battle:command(held.right and "right" or "left") end
   end
  elseif battle.phase=="save-error" then if withdraw.children.last.text~="重试保存"then withdraw.children.last.text="重试保存"end
  elseif battle.phase=="won" or battle.phase=="failed" or battle.phase=="aborted" then result(); return true end
  return false
 end)
 return controller
end
return Level
