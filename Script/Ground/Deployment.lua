-- Ground entry reuses Formation and checks actual story, formation and adopted model.
local D=require("Dora")
local Deployment={}
function Deployment.openAsync(world,destination)
 if world.tag~="TrainA" then return nil,"WRONG_SCENE" end
 local story=assert(require("Story.Service").open()); local facts=assert(story:summary())
 if not facts.completed["mail-two"] then return nil,"STORY_LOCKED" end
 local factory=destination=="Factory"
 local ruins=destination=="Ruins"
 if ruins and not facts.completed["ruins-station"] then return nil,"STORY_LOCKED" end
 if factory and not facts.completed["translator-preparation"] then return nil,"STORY_LOCKED" end
 local selection,why=require('Ground.AuxiliarySelection').open();if not selection then return nil,why end
 local selected,why=selection:load();if not selected then return nil,why end
 local departed=not require("Story.Availability").canDeploy("wuyun")
 local team=not not facts.completed["energy-plan"]
 local service=assert(require("Mission.Service").open()); local formation=assert(service:formation())
 local config=require("Data.Config"); local mentor=config.char=="charF" and "charF" or "charM"
 D.Cache:loadAsync("spine:"..mentor.."Figure"); D.Cache:loadAsync("spine:niniliteFigure")
 if team then D.Cache:loadAsync("spine:wuyunFigure") end
 D.Cache:loadAsync("bone:formationRole"); D.Cache:loadAsync("bone:lsdOSBack")
 require("Story.Flow").freeze(world,true)
 local controller={phase="briefing",formation=formation,team=team,auxiliaryVariant=selected.variant or "defence",auxiliaryRecorded=selected.recorded,auxiliaryButtons={}}; world.groundDeployment=controller
 local function render(message)
  if controller.view then controller.view:removeFromParent() end
  local progress=require("Training.Progress"); local loaded=progress.load(); local model=loaded and progress.adopted
  local wp=team and progress.forCharacter("wuyun"); local wm=wp and wp.load() and wp.adopted
  local view=require("UI.Formation")({missionMode=true,missionTitle=ruins and "遗迹城市 · 求救寻人编队" or factory and "废弃工厂 · 材料调查编队" or team and "遗弃城市 · 能源回收编队" or "遗弃城市 · 首次地面调查",secondLearner=team,secondIncluded=formation.wuyun,mentorRole=mentor,learnerIncluded=formation.learner~=nil,
   squadStatus="导师 / 妮妮莉特 · "..(formation.learner and "已编入" or "未编入").."\n"..(model and "采用 "..require("Training.Summary").short(model) or "先回训练室采用成果")..(team and ("\n乌云 · "..(departed and "已离队 · 训练记录保留" or formation.wuyun and "已编入" or "未编入").." · "..(wm and require("Training.Summary").short(wm) or "尚无采用成果")) or "").."\n"..(message or (ruins and "沿夜光镜的红色求救信号调查阿岩去向。两位学员随行，保留各自训练成果。" or factory and "按夜光镜前往沼泽道路。警惕花妖藤蔓和歌声；乌云的歌谣可让队伍清醒。" or "携带采集辅助机与45份金粉。靠拢恢复生命，队伍过远会加快金粉消耗；沿路自动采集。"))})
  controller.view=view; view.tag="ground-deployment"; view.controller=controller; view:addTo(D.Director.ui3D)
  local suppliesButton=require('UI.PropButton')({text='武器补给',x=-1280,y=470});suppliesButton:addTo(view.figure);controller.suppliesButton=suppliesButton
  suppliesButton:slot('Tapped',function()
   if controller.phase~='briefing'then return end
   local values,why=require('Economy.Loadout').load()
   local store=require('Economy.Store');local ready=store.open();local wallet=ready and store.wallet()
   if not values or not wallet then render('补给配置读取失败，请重试。');return end
   controller.phase='supplies';view.visible=false
   local panel=require('UI.SupplyLoadout')({values=values,formation=formation,balance=wallet.available,closed=function(saved)
    controller.phase='briefing';render(saved and '补给配置已保存。' or nil)
   end});controller.supplyPanel=panel;panel:addTo(D.Director.ui3D);panel:alignLayout()
  end)
  local auxiliary=D.Node(); auxiliary.position=D.Vec2(1090,130); auxiliary:addTo(view.figure)
  local preview=require("Ground.AuxiliaryModel").create(controller.auxiliaryVariant); preview.scaleX=.8; preview.scaleY=.8; preview.position=D.Vec2(0,80); preview:play("idle",true); preview:addTo(auxiliary)
  controller.auxiliaryPreview=preview; controller.auxiliaryButtons={}
  for i,variant in ipairs(require("Ground.AuxiliaryActor").variants) do
   local button=require("UI.Button")({text=(controller.auxiliaryVariant==variant.id and "✓ " or "")..variant.name}); button.position=D.Vec2(-182,-170-(i-1)*105); button:addTo(auxiliary)
   controller.auxiliaryButtons[variant.id]=button
   button:slot("Tapped",function() if controller.phase=="briefing" then controller.auxiliaryVariant=variant.id; render("已选择"..variant.name.."。辅助机负责跟随、采集与维生；点击机体可暂时显形。") end end)
  end
  local function toggle(second)
   if controller.phase~="briefing" then return end
   if second and departed then render("乌云已进入后世界，无法再编入出战队伍。训练记录仍可查看。") return end
   controller.phase="saving"
   local nextFormation={mentor=true,learner=formation.learner,wuyun=formation.wuyun}
   if second then nextFormation.wuyun=not formation.wuyun or nil else nextFormation.learner=not formation.learner and "ninilite" or nil end
   D.thread(function()
    local ok=service:saveFormationAsync(nextFormation); if ok then formation=nextFormation; controller.formation=formation end
    controller.phase="briefing"; render(ok and nil or "编队保存失败，请重试。")
   end)
  end
  view.rosterButton:slot("Tapped",function() toggle(false) end); view.learnerCard:slot("Tapped",function() toggle(false) end)
  if not formation.learner then view.learnerCard.children.first:slot("Tapped",function() toggle(false) end) end
  if team then
   view.secondCard:slot("Tapped",function() toggle(true) end)
   if not formation.wuyun then view.secondCard.children.first:slot("Tapped",function() toggle(true) end) end
  end
  view.backButton:slot("Tapped",function()
   if controller.phase~="briefing" then return end
   controller.phase="closed"; view:removeFromParent(); require("Story.Flow").freeze(world,false)
  end)
  view.startButton:slot("Tapped",function()
   if controller.phase~="briefing" then return end
   if team and departed then render("这条历史调查路线需要乌云参与，现已结束。请返回指挥室继续当前剧情。") return end
   if not formation.learner then render("先将妮妮莉特编入调查队伍。") return end
   if not model or not require("Training.Model").validate(model,"ninilite",{laser=true,fmove=true,bmove=true,idle=true}) then render("先回训练室完成示范、试战并采用成果。") return end
   if team and (not formation.wuyun or not wm or not require("Training.Model").validate(wm,"wuyun",require("Training.Characters").wuyun.legal)) then render("把乌云编入队伍，并先在虚拟训练场采用他的成果。") return end
   controller.phase="deploying"
   D.thread(function()
    local destination=factory and "Factory" or "AbandonedCity"
    local saved,why=selection:saveAsync(controller.auxiliaryVariant,destination)
    if not saved then controller.phase="briefing";controller.error=why;render("辅助机选择尚未保存，请重试出发。")return end
    controller.auxiliaryRecorded=true;controller.error=nil
    require("Academy.Navigation").returnToRoomAsync(destination,{energySquad=team,ruinsSearch=ruins,auxiliaryVariant=controller.auxiliaryVariant})
   end)
  end)
 end
 render(); return controller
end
return Deployment
