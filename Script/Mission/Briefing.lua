-- The existing Formation design now shows real available members and mission facts.
local D=require("Dora")
local Progress=require("Training.Progress")
local Catalog=require("Mission.Catalog")
local Briefing={}
function Briefing.openAsync()
 local service,err=require("Mission.Service").open()
 if not service then return nil,err end
 if not service:recoverAsync() then return nil,"WRITE_FAILED" end
 local formation,formationError=service:formation()
 if not formation then return nil,formationError end
 local config=require("Data.Config")
 local mentor=config.char=="charF" and "charF" or "charM"
 D.Cache:loadAsync("spine:"..mentor.."Figure");D.Cache:loadAsync("spine:niniliteFigure")
 -- DragonBones' shared JSON parser is not safe for parallel skeleton loads.
 D.Cache:loadAsync("bone:formationRole")
 D.Cache:loadAsync("bone:lsdOSBack")
 local story=assert(require('Story.Service').open());local storyFacts=assert(story:summary())
 local defense=storyFacts.completed['network-warning']
 local controller={service=service,formation=formation,mentor=mentor,mission=defense and 'c0-m07'or "c0-m01",phase="briefing"}
 local mission=Catalog[controller.mission]
 D.Group({"player","unit"}):each(function(e) e.keyLeft=false; e.keyRight=false; e.busy=true end)
 local function render(message)
  D.Director.ui3D:removeAllChildren()
  local loaded,loadStatus=Progress.load()
  local facts=service:summary()
  local model=loaded and Progress.adopted or nil
  local trained=model and ("已采用 "..require("Training.Summary").short(model)) or "尚未采用训练成果：请经学院走廊前往训练室补练。"
  if not loaded then trained=loadStatus=="INCOMPATIBLE_SAVE_READ_ONLY" and "训练记录来自其他版本，已保留原文，暂不能出战。" or "训练记录暂不可用，请返回训练室检查。" end
  local note=message or (defense and (facts and facts.unlocks[mission.reward]and '学院防卫已完成；A区防线可查看已保存记录。'or '在此调整编队。返回指挥室后，经左门→C区电梯→A区，走近防线标记开始。')or facts and facts.unlocks[mission.reward] and "资料室线索已记录；再次行动不会重复发放。" or mission.objective)
  controller.view=require("UI.Formation")({missionMode=true,missionTitle=mission.title,mentorRole=mentor,
   learnerIncluded=formation.learner~=nil,squadStatus="导师 · "..(config.charName or "导师").."  /  妮妮莉特 · "..(formation.learner and "已编入" or "未编入").."\n"..trained.."\n"..note})
  local view=controller.view; view.controller=controller; view.tag="mission-briefing"; view:addTo(D.Director.ui3D)
  view.startButton.visible=not defense
  local function toggle()
   if controller.phase~="briefing" then return end
   controller.phase="saving-formation"
   local nextFormation={mentor=true,wuyun=formation.wuyun}
   if not formation.learner then nextFormation.learner="ninilite" end
   D.thread(function()
    local saved=service:saveFormationAsync(nextFormation)
    if saved then formation.learner=nextFormation.learner end
    controller.phase="briefing"; render(saved and nil or "编队未保存，请重试。")
   end)
  end
  view.rosterButton:slot("Tapped",toggle); view.learnerCard:slot("Tapped",toggle)
  if not formation.learner then view.learnerCard.children.first:slot("Tapped",toggle) end
  view.backButton:slot("Tapped",function()
   if controller.phase~="briefing" then return end
   controller.phase="leaving"; D.thread(function() require("Academy.Navigation").returnToOperationAsync() end)
  end)
  view.startButton:slot("Tapped",function()
   if defense then return end
   if controller.phase~="briefing" then return end
   controller.phase="launching"
   D.thread(function()
    controller.view.visible=false
    local panel,why=require('Economy.Preparation').openAsync(controller.mission,model,function()
     controller.supplyPanel=nil;controller.phase='briefing';render()
    end,function(missionService,attempt)
     controller.phase='battle';controller.supplyPanel=nil
     controller.level=require('Mission.Level').openAsync(missionService,attempt,mentor)
    end)
    controller.supplyPanel=panel
    if not panel then controller.phase='briefing';render('补给准备暂不可用：'..tostring(why))end
   end)
  end)
 end
 render(); return controller
end
return Briefing
