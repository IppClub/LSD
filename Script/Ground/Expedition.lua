local D=require("Dora")
local Expedition={}
function Expedition.attach(world)
 local support=world.groundSupport or require("Ground.LifeSupport").new(nil,world.auxiliaryVariant)
 if world.energySquad then support.hp[3]=support.hp[3] or 100; require("Ground.EnergySite").attach(world,support); require("Ground.DisarmGate").attach(world,support) end
 local controller={support=support,phase="exploring",collected=0}; world.groundExpedition=controller
 local supportView=require("Ground.SupportView").create(world)
 local machine=supportView.machine
 local supplies={}
 for i,x in ipairs({1150,1700,2200,3000}) do
  local node=D.DrawNode(); node:drawDot(D.Vec2.zero,14,D.Color(0xffffd279)); node.position=D.Vec2(x,world.offset+35); node:addTo(world)
  supplies[#supplies+1]={id="survey-gold-"..i,x=x,node=node}
 end
 local hud=D.Director.ui3D:getChildByTag("ground-hud")
 local gather=require("UI.Skill")({visible=true,text="集合 K"}); gather.tag="ground-gather"; gather.position=hud.weapon.position-D.Vec2(296,0); gather:addTo(hud.skillArea)
 local gathering=false; gather:slot("TapBegan",function() gathering=true end); gather:slot("TapEnded",function() gathering=false end)
 local ui=D.Node(); ui.size=D.App.bufferSize; ui:addTo(D.Director.ui3D)
 local backdrop=D.DrawNode(); backdrop:addTo(ui)
 local label=D.Label("SourceHanSansCN-Regular",24); label.tag="ground-support-status"; label.anchor=D.Vec2(0,1); label.alignment="Left"; label.textWidth=1250; label:addTo(ui)
 local function layout()
  ui.size=D.App.bufferSize; label.position=D.Vec2(30,ui.height-155); label.textWidth=math.min(1250,ui.width-60)
  backdrop:clear(); backdrop:drawPolygon({D.Vec2(0,0),D.Vec2(math.min(1340,ui.width-30),0),D.Vec2(math.min(1340,ui.width-30),world.energySquad and 170 or 120),D.Vec2(0,world.energySquad and 170 or 120)},D.Color(0xbb101b28)); backdrop.position=D.Vec2(15,ui.height-155-(world.energySquad and 170 or 120))
 end
 layout(); ui:gslot("AppChange",function(name) if name=="Size" then layout() end end)
 local function entities()
  local p,n,w
  D.Group({"name","unit"}):each(function(e) if e.unit.world==world then if e.player then p=e elseif e.name=="ninilite" then n=e elseif e.name=="wuyun" then w=e end end end)
  return p,n,w
 end
 local last=D.App.runningTime
 if not world.energySquad then
 local boss=D.Spine("dataotie"); boss.recovery=0.2; boss:play("idle",true); boss.position=D.Vec2(3100,world.offset); boss.scaleX=-0.65; boss.scaleY=0.65; boss:addTo(world); boss.tag="ground-boss"
 end
 local terminal=D.Node(); terminal.position=D.Vec2(2450,world.offset+150); terminal:addTo(world)
 local interaction=require("UI.Interaction")({text="前沿侦察",buttons={{"观察强敌",""},{"守住退路",""}},fliped=false}); interaction.tag="ground-contact"; interaction.transformTarget=terminal; interaction.scaleX=0.325; interaction.scaleY=0.325; interaction.visible=false; interaction.menu.enabled=false; interaction:addTo(world)
 local near=false; local busy=false
 interaction:slot("Tapped",function(index)
  if not near or busy then return end
  busy=true; D.thread(function()
   if index==2 then
    local progress=require("Training.Progress"); local loaded=progress.load()
    local service=assert(require("Mission.Service").open()); local formation=assert(service:formation())
    if support.machineHP<=0 or support.gold<=0 then busy=false; controller.message="先返回列车补给辅助机。"; return end
    local panel,err=require('Ground.Preparation').openAsync(world,'c0-m02',loaded and progress.adopted,support,function()controller.supplyPanel=nil;busy=false end)
    controller.supplyPanel=panel
    if not panel then busy=false;controller.message='补给准备暂不可用：'..tostring(err)end
    return
   end
   local opened,err=require("Story.Flow").openAsync("ground-contact",world,function() busy=false end)
   if not opened then busy=false; controller.message="先在下车处确认地面情况："..tostring(err) end
  end)
 end)
 machine:schedule(function()
  local now=D.App.runningTime; local dt=math.min(1,now-last); last=now
  local p,n,w=entities(); if not p or not n then return false end
  local paused=p.busy or world.data.storyBusy or world.data.journalOpen
  if not paused then
   local target=p.unit.x+((gathering or D.Keyboard:isKeyDown("K")) and -80 or 200)
   -- Formation following is an explicit squad protocol, separate from learned combat actions.
   n.keyLeft=n.unit.x>target+35; n.keyRight=n.unit.x<target-35
   if w then
    local wx=p.unit.x-((gathering or D.Keyboard:isKeyDown("K")) and 80 or 200)
    w.keyLeft=w.unit.x>wx+35; w.keyRight=w.unit.x<wx-35
    support:update(dt,{p.unit.x,n.unit.x,w.unit.x})
   else support:update(dt,p.unit.x,n.unit.x) end
   for _,drop in ipairs(supplies) do if support:collect(drop.id,12,drop.x,p.unit.x,n.unit.x) then drop.node.visible=false; controller.collected=controller.collected+1 end end
   if support.hp[1]<=0 or support.hp[2]<=0 or (w and support.hp[3]<=0) then
    controller.phase="evacuating"; p.keyLeft=false; p.keyRight=false; n.keyLeft=false; n.keyRight=false
    D.thread(function() require("Academy.Navigation").returnToRoomAsync("TrainA") end); return true
   end
  else n.keyLeft=false; n.keyRight=false; if w then w.keyLeft=false; w.keyRight=false end end
  supportView:update(support,math.min(p.unit.x,n.unit.x,w and w.unit.x or p.unit.x),math.max(p.unit.x,n.unit.x,w and w.unit.x or p.unit.x))
  local target=world.nightLensTarget
  local route=target and string.format("\n夜光镜：%s · %s · 距离 %.0f",target.title,p.unit.x<target.x and "向右" or "向左",math.abs(p.unit.x-target.x)) or ""
  label.text=string.format("采集辅助机 %d · 金粉 %.1f · 导师 %.0f / 妮妮莉特 %.0f\n集合 K / 技能按钮靠拢恢复；相距越远，金粉消耗越快。沿路金色物资自动采集。%s",support.machineHP,support.gold,support.hp[1],support.hp[2],(controller.message or "")..route)
  if w then
   local site=world.energySite
   local objective=site and site.recovered and "能源已回收。向左返回列车与学院，再到训练室报告进展。"
    or site and site.secured and "伏击已清理。靠近中央能源箱，选择收取能源。"
    or "前往中央能源箱清理伏击，使用夜光镜确认定位。"
   label.text=label.text..string.format("\n乌云 %.0f · %s",support.hp[3],objective)
  end
  ui.visible=not paused
  local value=not world.energySquad and not paused and math.abs(p.unit.x-terminal.x)<180
  if value~=near then near=value; if near then interaction.visible=true; interaction:show() else interaction:hide(false) end end
  return false
 end)
 world:slot("Cleanup",function() ui:removeFromParent() end)
 return controller
end
return Expedition
