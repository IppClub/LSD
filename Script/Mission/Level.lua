-- Public mission play uses the game's original HUD and Settlement designs.
local D=require("Dora")
local Catalog=require("Mission.Catalog")
local Level={}
function Level.openAsync(service,attempt,mentor)
 local battle=require("Mission.Battle").createAsync(service,attempt,mentor)
 local mission=Catalog[attempt.mission]
 require('System.Music').battle(battle.arena.world,battle,'Music/战斗1.mp3')
 local controller={battle=battle,phase="playing"}
 local hud=require("UI.HUDControl")({weaponIcon="kineticgun"}); hud.tag="mission-hud"; hud:addTo(D.Director.ui3D)
 hud.weapon.visible=true; hud.topControl.visible=false; hud.message.visible=false; D.emit("HUD.DisplayMove",true)
 local ui=D.Node(); ui.tag="mission-controls"; ui.size=D.App.bufferSize; ui:addTo(D.Director.ui3D)
 local title=D.Label("SourceHanSansCN-Regular",25); title.tag="mission-status"; title.anchor=D.Vec2(0,1); title.alignment="Left"; title.textWidth=1300; title:addTo(ui)
 local withdraw=require("UI.InputButton")({text="撤离行动",textBG=""}); withdraw.scaleX=0.5; withdraw.scaleY=0.5
 withdraw:slot("Tapped"):clear(); withdraw:addTo(ui); withdraw.tag="mission-withdraw"
 local held={left=false,right=false}
 local function clearInput()
  held.left,held.right=false,false
  if not battle.arena.closed then battle:command('stop')end
 end
 local controlsActive=require('UI.InputAvailability').bind(ui,clearInput)
 local function inputActive()return controlsActive()and hud.visible end
 ui:slot('Cleanup',clearInput)
 hud.move.onMove=function(key,down)
  local side=key=="keyLeft" and "left" or "right"; held[side]=down and inputActive()
  if battle.phase~="playing" then return end
  if held[side] then battle:command(side) elseif not held.left and not held.right then battle:command("stop") end
 end
 require('Ground.Mentor').bindAim(hud,battle)
 local repair=require("UI.Skill")({visible=true,text="修复 K"}); repair.tag="mission-repair"; repair.position=hud.weapon.position-D.Vec2(296,0); repair:addTo(hud.skillArea)
 repair:slot("TapBegan",function() if inputActive()then battle:command("repair") end end)
 withdraw:slot("Tapped",function()
  if battle.phase=="playing" then held.left=false; held.right=false; battle:finish("aborted","已撤离警戒行动；本次不发放任务奖励。")
  elseif battle.phase=="save-error" then battle:saveResult() end
 end)
 local function layout() ui.size=D.App.bufferSize; title.position=D.Vec2(30,ui.height-25); withdraw.position=D.Vec2(ui.width-125,ui.height-225) end
 layout(); ui:gslot("AppChange",function(name) if name=="Size" then layout() end end)
 local function settlement()
  controller.phase="result"
  hud:removeFromParent(); ui:removeFromParent()
  local hits,wins=0,0; for _,round in ipairs(battle.rounds) do hits=hits+round.metrics.hits; if round.won then wins=wins+1 end end
  local won=battle.phase=="won"
  local result=require("UI.Settlement")({missionMode=true,economy=battle.report.economy,missionTitle=mission.title,
   resultTitle=won and "警戒完成" or battle.phase=="aborted" and "安全撤离" or "行动未完成",
   resultStatus=won and "Complete" or battle.phase=="failed" and "Failed" or "已撤离",againText="重新配装",baseText="返回指挥室",
   reportText=battle.reason.."\n击退波次 "..wins.." / "..#mission.waves.."  · 学员命中 "..hits.."  · 导师命中 "..battle.mentorHits.."\n通讯节点 "..battle.relayHP.." / 100  · 导师生命 "..battle.mentorHP.."  · 用时 "..math.floor(battle.report.seconds).." 秒",
   storyText=won and (mission.rewardText.."\n"..mission.debrief) or "妮妮莉特：回学院检查编队、补给和训练成果。走廊连着训练室，我们可以补练后再次出战。"})
  result.tag="mission-result"; result:addTo(D.Director.ui3D); controller.result=result
  local leaving=false
  local originalReport=result.reportLabel.text
  result.againButton:slot("Tapped",function()
   if leaving then return end; leaving=true
   D.thread(function()
    local opened,why=require("Mission.Briefing").openAsync()
    if not opened then
     leaving=false;controller.retryError=why or "READ_FAILED"
     local text="配装记录暂时无法打开，请重试或返回指挥室。\n"..originalReport
     if result.setReportText then result:setReportText(text)
     else
      result.reportLabel.text=text
      local area=result.reportArea
      if area then local size=area.contentSize;area.viewSize=D.Size(size.width,math.max(size.height,result.reportLabel.height+20));area:scrollTo(D.Vec2.zero)end
     end
    else controller.retryError=nil end
   end)
  end)
  result.baseButton:slot("Tapped",function()
   if leaving then return end; leaving=true
   D.thread(function() require("Academy.Navigation").returnToOperationAsync() end)
  end)
 end
 ui:schedule(function()
  if battle.arena.closed then return true end
  local active=inputActive();if not active then clearInput()end
  local text=mission.title.." · 波次 "..battle.wave.." / "..#mission.waves.."\n导师 "..battle.mentorHP.." / 学员 "..battle.arena.studentHP.." / 对手 "..battle.arena.enemyHP.." · 通讯 "..battle.relayHP.." · 修复包 "..battle.repairs.."\n摇杆 / A、D 移动 · 按住J瞄准、松开发射 · K 修复节点\n"..(battle.message or mission.objective)
  if battle.supplies then text=text..'\n'..battle.supplies:statusText()end
  if battle.phase=="save-error"then text=text.."\n结算未保存，请点击右侧按钮重试。"end
  if title.text~=text then title.text=text end
  if battle.phase=="playing" then
   if active then
    if D.Keyboard:isKeyDown("K") then battle:command("repair") end
    if held.left~=held.right then battle:command(held.right and "right" or "left") end
   end
  elseif battle.phase=="save-error" then
   if withdraw.children.last.text~="重试保存"then withdraw.children.last.text="重试保存"end
  elseif battle.phase=="won" or battle.phase=="failed" or battle.phase=="aborted" then settlement(); return true end
  return false
 end)
 return controller
end
return Level
