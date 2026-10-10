-- Public academy trial flow: actual cooperation, then actual duel, then original acknowledgement.
local D=require("Dora")
local Level={}
local function returnRoom() return require("Academy.Navigation").returnToTrainingAsync() end
local start,dialogue
local function mark(world,id)
 local catalog=require("Story.Catalog")[id]
 local old=world:getChildByTag(catalog.discoveryTag); if old then old:removeFromParent() end
 local player=D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world end)
 local node=D.Node(); node.tag=catalog.discoveryTag; node.x=assert(player).unit.x; node:addTo(world)
end
dialogue=function(service,id,onClosed)
 local b=require("Trial.Battle").createAsync(service)
 b.world.trialBattle={battle=b,phase="dialogue"}
 mark(b.world,id)
 local flow,err=require("Story.Flow").openAsync(id,b.world,function() D.thread(onClosed) end)
 if not flow then returnRoom(); return nil,err end
 return b.world.trialBattle
end
start=function(service,mission)
 local attempt,err=service:beginAsync(mission,nil,{mentor=true})
 if not attempt then return nil,err end
 local created,b=xpcall(function() return require("Trial.Battle").createAsync(service,attempt) end,debug.traceback)
 if not created then
  print("Trial scene creation failed: "..tostring(b))
  local saved=service:finishAsync(attempt,"aborted",{reason="训练场加载失败，未记录胜利。"})
  if saved then returnRoom() end
  return nil,"SCENE_LOAD_FAILED"
 end
 local c={battle=b,phase="ready"}; b.world.trialBattle=c
 local hud=require("UI.HUDControl")({weaponIcon="kineticgun"}); c.hud=hud; hud.tag="trial-hud"; hud.weapon.visible=true; hud.topControl.visible=false; hud.message.visible=false; hud:addTo(D.Director.ui3D); D.emit("HUD.DisplayMove",true)
 local held={left=false,right=false}
 local inputActive=function()return true end
 hud.move.onMove=function(key,down)
  local side=key=="keyLeft" and "left" or "right"; held[side]=down and inputActive()
  if held.left~=held.right then b:command(held.right and "right" or "left") else b:command("stop") end
 end
 hud:gslot("Skill.Began",function()b.heroAim:begin()end)
 hud:gslot("Skill.Ended",function(cancelled)if cancelled then b.heroAim:cancel()else b.heroAim:release()end end)
 hud:slot("Cleanup",function()b.heroAim:cancel()end)
 local function skill(text,tag,x,action)
  local s=require("UI.Skill")({visible=true,text=text}); s.tag=tag; s.position=hud.weapon.position-D.Vec2(x,0); s:addTo(hud.skillArea); s:slot("TapBegan",function() if inputActive()then b:command(action) end end); return s
 end
 c.melee=skill("刀击 K","trial-melee",296,"melee"); c.guard=skill("防御 E","trial-guard",592,"guard")
 local ui=D.Node(); ui.tag="trial-controls"; ui.size=D.App.bufferSize; ui:addTo(D.Director.ui3D); c.ui=ui
 local function clearInput()
  held.left,held.right=false,false
  if not b.closed then b:command('stop')end
 end
 local controlsActive=require('UI.InputAvailability').bind(ui,clearInput)
 inputActive=function()return controlsActive()and hud.visible end
 ui:slot('Cleanup',clearInput)
 local bg=D.DrawNode(); bg:addTo(ui)
 local status=D.Label("SourceHanSansCN-Regular",24); status.alignment="Left"; status.anchor=D.Vec2(0,1); status:addTo(ui); c.status=status
 local withdraw=require("UI.InputButton")({text="中止训练",textBG=""}); withdraw.tag="trial-withdraw"; withdraw.scaleX=0.5; withdraw.scaleY=0.5; withdraw:slot("Tapped"):clear(); withdraw:addTo(ui); c.withdraw=withdraw
 withdraw:slot("Tapped",function() if b.phase=="playing" or b.phase=="ready" then b:finish("aborted","训练已中止，未记录本场胜利。") elseif b.phase=="save-error" then b:saveResult() end end)
 local begin=require("UI.InputButton")({text="开始训练",textBG=""}); begin.tag="trial-begin"; begin.scaleX=0.6; begin.scaleY=0.6; begin:slot("Tapped"):clear(); begin:addTo(ui); c.beginButton=begin
 begin:slot("Tapped",function() if b:begin() then c.phase="playing"; begin.visible=false end end)
 local function layout()
  ui.size=D.App.bufferSize; status.position=D.Vec2(30,ui.height-25); status.textWidth=math.min(1300,ui.width-300); withdraw.position=D.Vec2(ui.width-150,ui.height-205); begin.position=D.Vec2(ui.width/2-95,ui.height/2+150)
  bg:clear(); bg:drawPolygon({D.Vec2(0,0),D.Vec2(ui.width,0),D.Vec2(ui.width,215),D.Vec2(0,215)},D.Color(0xcc101b28)); bg.position=D.Vec2(0,ui.height-215)
 end
 layout(); ui:gslot("AppChange",function(name) if name=="Size" then layout() end end)
 local function result()
  c.phase="result"; hud:removeFromParent(); ui:removeFromParent()
  local won=b.phase=="won"
  local view=require("UI.Settlement")({missionMode=true,missionTitle=b.duel and "李叶娜 · 对打训练" or "李叶娜 · 合作训练",resultTitle=won and "训练完成" or "训练中止",resultStatus=won and "Complete" or b.phase=="failed" and "Failed" or "已中止",
   reportText=string.format("%s\n导师命中 %d · 李叶娜命中 %d · 防御 %d\n导师生命 %.0f · 李叶娜生命 %.0f · %.1f 秒",b.reason,b.heroHits,b.npcHits,b.blocks,b.heroHP,b.npcHP,b.report.seconds),
   storyText=won and (b.duel and "对打已获胜。继续听取李叶娜的回应。" or "合作完成。继续与李叶娜交谈，再进入对打。") or "胜利后才继续下一段；已保存的训练成果和此前剧情保留。",againText=won and "继续" or "重新训练",baseText="返回训练室"})
  c.result=view; view.tag="trial-result"; view:addTo(D.Director.ui3D)
  local leaving=false
  view.baseButton:slot("Tapped",function() if leaving then return end; leaving=true; D.thread(returnRoom) end)
  view.againButton:slot("Tapped",function()
   if leaving then return end; leaving=true
   D.thread(function()
    if not won then local opened,why=start(service,mission); if not opened then leaving=false; c.error=why end; return end
    view:removeFromParent()
    local id=b.duel and "liyena-recognition" or "liyena-challenge"
    local opened,why=dialogue(service,id,function()
     if b.duel then returnRoom() else local nextTrial,e=start(service,"c0-m04-duel"); if not nextTrial then print("Trial continuation failed: "..tostring(e)); returnRoom() end end
    end)
    if not opened then c.error=why end
   end)
  end)
 end
 ui:schedule(function()
  if b.closed then return true end
  local hp={}; for _,e in ipairs(b.enemies) do hp[#hp+1]=tostring(e.enemyHP) end
  local active=inputActive();if not active then clearInput()end
  local text=string.format("李叶娜 · %s\n导师 %.0f / 100 · 李叶娜 %.0f / 100%s\n摇杆 / A、D 移动 · 按住J瞄准、松开发射 · K 刀击 · E 防御\n%s",b.duel and "对打训练" or "合作训练",b.heroHP,b.npcHP,b.duel and "" or (" · 怪物 "..table.concat(hp," / ")),b.phase=="ready" and "准备好后点击开始训练。合作场需要双方出手；对打场击败李叶娜。" or b.phase=="save-error" and "结算尚未保存，请点击重试保存。" or "按攻击时点出手，利用防御避免受伤。")
  if status.text~=text then status.text=text end
  begin.visible=b.phase=="ready"
  if b.phase=="playing" then
   if active then
    if D.Keyboard:isKeyDown("K") then b:command("melee") elseif D.Keyboard:isKeyDown("E") then b:command("guard") end
    if held.left~=held.right then b:command(held.right and "right" or "left") end
   end
  elseif b.phase=="save-error" then if withdraw.children.last.text~="重试保存"then withdraw.children.last.text="重试保存"end
  elseif b.phase=="won" or b.phase=="failed" or b.phase=="aborted" then result(); return true end
  return false
 end)
 return c
end
function Level.openAsync(world,duel)
 local player=D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world end)
 if world.tag~="TrainingRoom" or not player or math.abs(player.unit.x-935)>=230 then return nil,"TRAINING_TERMINAL_REQUIRED" end
 local story,err=require("Story.Service").open(); if not story then return nil,err end
 local facts=story:summary(); if not facts or not facts.completed["ayan-tour"] then return nil,"STORY_LOCKED" end
 local service,e=require("Mission.Service").open(); if not service then return nil,e end
 if not duel then return start(service,"c0-m04-coop") end
 if not facts.mission.unlocks["liyena-coop-complete"] then return nil,"COOP_REQUIRED" end
 if facts.mission.unlocks["liyena-duel-complete"] and not facts.completed["liyena-recognition"] then return dialogue(service,"liyena-recognition",returnRoom) end
 if not facts.completed["liyena-challenge"] then return dialogue(service,"liyena-challenge",function() local opened,why=start(service,"c0-m04-duel"); if not opened then print(tostring(why)); returnRoom() end end) end
 return start(service,"c0-m04-duel")
end
return Level
