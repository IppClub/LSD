-- Physical academy routes already belong to Map + door sensors in each scene.
-- The training terminal is only accessible by walking into TrainingRoom.
local D=require("Dora")
local Navigation={}
local hints={
 PreparationRoom="备战室 · 右侧门→训练室；左侧门→A区电梯→C区指挥室",
 PassageA="A区走廊 · 电梯→C区；右侧门→备战室",
 PassageB="B区走廊 · 右侧门→训练室；电梯可往A/C区",
 PassageC="C区走廊 · 右门→指挥室；电梯→A/D区；调查暗格后左侧通道→站台",
 PassageD="D区走廊 · 左门→资料室；右门→研发室；电梯→C区",
 LibraryRoom="资料室 · 靠近最里侧书柜，调查第二层暗格",
 RDRoom="研发室 · 靠近中央设施，了解外骨骼与示范训练",
 TrainA="地铁车厢 · 中央交谈并读第二封邮件；右侧出口部署地面调查；左侧车门返回站台",
 OuterHeaven="桃源谷 · 走近吊床旁的万薇莉，了解谷中的人和怪物",
 Factory="废弃工厂 · 向右到沼泽道路，清理花妖后采集材料；左侧返回列车",
 AbandonedCity="遗弃城市 · 下车处确认情况；沿路采集，前往右侧侦察；左侧可返回列车",
 RestRoom="休息室 · 中央交谈：询问乌云、会见来访者、讨论地面计划；右门返回A区",
 Station="地铁站台 · 集合点了解部署；向左到登车处乘车；右侧通道返回C区",
 TrainingRoom="训练室 · 靠近左侧发光终端，进入虚拟训练场",
 OperationRoom="指挥室 · 靠近中央控制台，查看任务和编队",
}
function Navigation.refreshStoryActors(world)
 if world.tag~="RestRoom" then return end
 local service=require("Story.Service").open(); local facts=service and service:summary()
 if not facts then return end
 local function find(name) return D.Group({"name","unit"}):find(function(e) return e.name==name and e.unit.world==world end) end
 D.thread(function()
  for _,role in ipairs({{name="wuyun",enabled=facts.completed["ground-rescue"] and not facts.completed["roof-aftermath"],offset=-290},{name="sunborn",enabled=facts.completed["wuyun-rest"] and not facts.completed["underground-cooperation"],offset=-620},{name="ninilite",enabled=facts.completed["ground-rescue"],offset=360}}) do
   local actor=find(role.name)
   if role.enabled and not actor then
    D.Cache:loadAsync("spine:"..role.name)
    if world.parent then D.Entity({player=false,name=role.name,faceRight=true,position=D.Vec2(world.sceneWidth/2+role.offset,world.offset),base=true,storyCompanion=true}) end
   elseif not role.enabled and actor and (role.name=="sunborn" or role.name=="wuyun") then actor.unit:removeFromParent(); actor:destroy() end
  end
 end)
end
function Navigation.attachDamaged(world)
 local ui=D.Node();ui:addTo(D.Director.ui3D)
 local bg=D.DrawNode();bg:addTo(ui)
 local text=D.Label('SourceHanSansCN-Regular',24);text.alignment='Left';text.anchor=D.Vec2(0,1);text:addTo(ui)
 local function refresh()
  local service=require('Story.Service').open();local facts=service and service:summary()
  text.text=(require('Academy.Map').getName(world.tag)or '学院')..' · 区域受损\n'..(facts and facts.objective or '走近终端可查看人员记录。')
 end
 refresh();ui:gslot('Story.Recorded',function(_,recordedWorld)if recordedWorld==world then refresh()end end)
 local function layout()local size=D.App.bufferSize;ui.size=size;text.position=D.Vec2(30,size.height-25);text.textWidth=size.width-60;bg:clear();bg:drawPolygon({D.Vec2(15,size.height-135),D.Vec2(size.width-15,size.height-135),D.Vec2(size.width-15,size.height-15),D.Vec2(15,size.height-15)},D.Color(0xdd101b28))end
 layout();ui:gslot('AppChange',function(name)if name=='Size'then layout()end end)
 ui:gslot('Story.Display',function(shown)ui.visible=not shown end)
 world:slot('Cleanup',function()ui:removeFromParent()end)
end
function Navigation.attach(world)
	if world.data.navigationAttached then return end
	world.data.navigationAttached=true
 -- 每帧终端检测共享的组与谓词，避免逐帧重建闭包。
 local playerGroup=D.Group({"player","unit"})
 local function isLocalPlayer(e) return e.player and e.unit.world==world end
 local loss=require("Story.AcademyLoss").attach(world)
 local music=require('System.Music')
 if loss and loss.recorded then music.stop(.6)
 elseif world.tag=='TrainingRoom' then music.play(world,'Music/训练场.mp3')
 elseif world.tag=='Factory' or world.tag=='AbandonedCity' or world.tag=='OuterHeaven' or world.tag=='TrainA' then music.play(world,'Music/探索.mp3')
 else music.play(world,'Music/军事学园.mp3') end
 if loss and loss.recorded then Navigation.attachDamaged(world);require("Rescue.Arrival").attach(world);require("Final.Gate").attach(world);return end
 if world.tag=="OuterHeaven" then require("Story.ValleyVisit").attach(world);require("Story.ValleyActivities").attach(world) end
 require("Story.Reconnection").attach(world)
 require("Academy.DefenseGate").attach(world)
 if world.tag=="OperationRoom" and not world.reconnection then require("Story.CommandAssembly").attach(world) end
 require("Story.MedicalVisit").attach(world)
 local rescued=false
 if world.tag=="RestRoom" then
  local service=require("Story.Service").open(); local facts=service and service:summary()
  rescued=facts and facts.completed["ground-rescue"] or false
  Navigation.refreshStoryActors(world)
  require("Story.RecoveryVisit").attach(world)
 end
 if world.tag=="Station" or world.tag=="TrainA" then
  local companion=D.Group({"name","unit"}):find(function(e) return e.name=="ninilite" and e.unit.world==world end)
  if not companion then D.Entity({player=false,name="ninilite",faceRight=true,position=D.Vec2(world.tag=="Station" and world.sceneWidth-800 or world.sceneWidth/2+280,world.offset),base=true,storyCompanion=true}) end
 end
 if world.tag=="TrainA" then
  D.Entity({player=false,name="liyena",faceRight=true,position=D.Vec2(world.sceneWidth/2-320,world.offset),base=true,storyCompanion=true})
 end
 local function travelTerminal(tag,x,text,target,required)
  local node=D.Node(); node.position=D.Vec2(x,world.offset+150); node:addTo(world)
  local button=require("UI.Interaction")({text=text,buttons=target=="AbandonedCity" and {{"城市调查",""},{"工厂取材",""},{"遗迹寻人",""}} or {{target=="AbandonedCity" and "调查编队" or target=="TrainA" and (world.tag=="AbandonedCity" and "返回列车" or "进入列车") or "返回站台",""}},fliped=x>world.sceneWidth/2})
  if world.tag=="TrainA" then button.scaleX=0.325; button.scaleY=0.325 end
  button.tag=tag; button.transformTarget=node; button.order=100; button.visible=false; button.menu.enabled=false; button:addTo(world)
  local near=false; local busy=false
  node:schedule(function()
   local e=playerGroup:find(isLocalPlayer)
   local now=e and not e.busy and not world.data.journalOpen and not world.data.storyBusy and math.abs(e.unit.x-x)<180
   if (not not now)~=near then near=not not now; if near then button.visible=true; button:show() else button:hide(false) end end
   return false
  end)
  local gateHint=D.Label("SourceHanSansCN-Regular",24); gateHint.text=target=="AbandonedCity" and "先讨论计划并阅读第二封邮件" or "先在右侧集合点了解部署准备"; gateHint.position=D.Vec2(0,280); gateHint.visible=false; gateHint:addTo(node)
  button:slot("Tapped",function(index)
   if not near or busy then return end
   local service=require("Story.Service").open(); local facts=service and service:summary()
   if required and not (facts and facts.completed[required]) then
    gateHint.visible=true; return
   end
   busy=true
   D.thread(function()
    if target=="AbandonedCity" then
     local opened,err=require("Ground.Deployment").openAsync(world,index==3 and "Ruins" or index==2 and "Factory" or nil)
     busy=false; if not opened then gateHint.text="部署暂不可用："..tostring(err); gateHint.visible=true end
    elseif world.ruinsSearch and target=="TrainA" and facts and facts.completed["ayan-recovery"] then
     local opened,err=require("Ruins.Return").openAsync(world);busy=false;if not opened then gateHint.text=tostring(err);gateHint.visible=true end
    else Navigation.returnToRoomAsync(target) end
   end)
  end)
 end
 if world.tag=="Station" then travelTerminal("boardingTerminal",world.sceneWidth-1800,"列车登车处","TrainA","station-brief")
 elseif world.tag=="TrainA" then
  travelTerminal("stationReturnTerminal",170,"站台侧车门","Station")
  travelTerminal("groundDeploymentTerminal",world.sceneWidth-170,"地面调查出口","AbandonedCity","mail-two")
 elseif world.tag=="Factory" then
  if world.infiltrationRoute then require("Story.Infiltration").attach(world)
  elseif world.foxTrailRoute then require("Story.FoxTrail").attach(world)
  else travelTerminal("factoryReturnTerminal",170,"返程列车","TrainA");require("Factory.Expedition").attach(world) end
 elseif world.tag=="AbandonedCity" then
  travelTerminal("groundReturnTerminal",170,"返程列车","TrainA")
  if world.ruinsSearch then require("Ruins.Expedition").attach(world) else require("Ground.Expedition").attach(world) end
 end
	local ui=D.Node(); ui.tag="academy-navigation"; ui:addTo(D.Director.ui3D)
 ui:gslot("Story.Display",function(visible) ui.visible=not visible end)
	local backdrop=D.DrawNode(); backdrop:addTo(ui)
	local label=D.Label("SourceHanSansCN-Regular",24)
	label.tag="academy-navigation-hint"
	label.alignment="Left"; label.anchor=D.Vec2(0,1); label.textWidth=1300
	label.text=(hints[world.tag] or require("Academy.Map").getName(world.tag) or "学院").."\n使用摇杆或 A/D 漫游；走近房门选择目标。"
 local function refreshMeetingHint()
  if world.tag=="OuterHeaven" and world.valleyEncounter then
   local service=require("Story.Service").open()
   local facts=service and service:summary()
   if facts and facts.completed["valley-awakening"] then
    label.text=facts.objective.."\n使用摇杆或 A/D 漫游；走近活动地点选择行动。"
    return
   end
  end
  if world.tag=="Factory" and world.factoryExpedition then
   local service=require("Story.Service").open()
   local facts=service and service:summary()
   if facts and facts.completed["factory-encounter"] then
    label.text=facts.objective.."\n使用摇杆或 A/D 漫游；左侧可返回列车。"
    return
   end
  end
  if world.academyLoss then label.text="A区主通道已守住 · 走近右侧通讯点，确认其他小组的位置。\n原摇杆 / A、D 漫游；中部标记保留防卫记录。";return end
  if world.defenseGate then label.text="A区防线 · 走近走廊中央标记，准备学院防卫或查看已保存记录。\n原摇杆 / A、D 漫游；电梯与两侧房门仍可通行。";return end
  if world.reconnection then
   local facts=world.reconnection.service:summary()
   label.text=(world.tag=="OperationRoom"and "指挥室 · 中央通讯与编队终端"or "研发室 · 中央信道监测台").."\n"..(facts and facts.objective or '通讯暂不可读取，请重试。');return
  end
  if world.commandAssembly then
   local facts=world.commandAssembly.service:summary()
   label.text=(facts and facts.completed['command-assembly'] and facts.objective or "指挥室集合 · 走近中央向林睿哲汇报；记录后查看行动分工").."\n使用原摇杆或 A/D 漫游；控制台保留任务与编队入口。"
   return
  end
  if world.infiltrationRoute then label.text="工厂潜入 · 与狐狸和同伴一起行动".."\n使用原摇杆与统一技能；返回指挥室保留已记录的进度。";return end
  if world.foxTrailRoute then label.text="狐狸的路线 · 跟随狐狸，使用食物并以夜光镜隐蔽侦察".."\n摇杆或 A/D 移动；走近停步处交谈，行动按钮或 E 继续。";return end
  if world.ruinsSearch then label.text="遗迹城市 · 沿红色求救信号寻找阿岩；左侧可返回列车".."\n使用摇杆或 A/D 前行；沿路金粉补给维生场，集合K可靠拢。"; return end
  if world.recoveryVisit then label.text="休息室 · 右侧诊疗区治疗、休息与讨论；右门返回A区电梯".."\n使用摇杆或 A/D 漫游；走近房门选择目标。"; return end
  if world.medicalVisit then
   local service=require("Story.Service").open()
   local facts=service and service:summary()
   local hint=world.tag=="RestRoom" and "休息室 · 走近右侧诊疗区拜访医师姐弟；右门返回A区" or "备战室 · 走近中央，与妮妮莉特和乌云确认行动；两侧门继续学院漫游"
   if facts and facts.completed[world.medicalVisit.id] then hint=facts.objective end
   label.text=hint.."\n使用摇杆或 A/D 漫游；走近房门选择目标。"
  end
 end
 refreshMeetingHint()
 ui:gslot("Story.Recorded",function(_,recordWorld) if recordWorld==world then if world.tag=="OuterHeaven" then require("Story.ValleyVisit").attach(world);require("Story.ValleyActivities").attach(world) end
 require("Story.MedicalVisit").attach(world); require("Story.RecoveryVisit").attach(world); refreshMeetingHint() end end)
	label:addTo(ui)
	local journal=require("UI.InputButton")({text="通讯与日志",textBG=""}); journal.scaleX=0.55; journal.scaleY=0.55; journal:slot("Tapped"):clear(); journal.tag="academy-journal"; journal:addTo(ui)
 journal:slot("Tapped",function()
  D.thread(function()
   local opened,err=require("Story.Journal").openAsync(world)
   if not opened then label.text="通讯记录暂不可用："..tostring(err) end
  end)
 end)
 local function layout()
  ui.size=D.App.bufferSize
  local width=math.max(280,math.min(1340,ui.width-400))
  backdrop:clear(); backdrop:drawPolygon({D.Vec2(0,0),D.Vec2(width,0),D.Vec2(width,112),D.Vec2(0,112)},D.Color(0xbb101b28))
  backdrop.position=D.Vec2(15,ui.height-130); label.textWidth=width-30
  label.position=D.Vec2(30,ui.height-25); journal.position=D.Vec2(ui.width-210,ui.height-75)
 end
 local lens=require("UI.InputButton")({text="夜光镜",textBG=""}); lens.tag="night-lens-button"; lens.visible=false; lens.scaleX=0.55; lens.scaleY=0.55; lens:slot("Tapped"):clear(); lens:addTo(ui)
 lens:slot("Tapped",function() D.thread(function() local opened,err=require("Ground.NightLens").openAsync(world); if not opened then label.text="夜光镜暂不可用："..tostring(err) end end) end)
 local lensCheckedAt=-1
 lens:schedule(function()
  lens.position=D.Vec2(D.App.bufferSize.width-210,D.App.bufferSize.height-150)
  if D.App.runningTime-lensCheckedAt<1 then return false end; lensCheckedAt=D.App.runningTime
  local service=require("Story.Service").open(); local facts=service and service:summary()
  lens.visible=not not (facts and facts.unlocks["night-lens"]); return false
 end)
	layout(); label:gslot("AppChange",function(name) if name=="Size" then layout() end end)
	world:slot("Cleanup",function() ui:removeFromParent() end)
	if world.commandAssembly or world.reconnection then return end
	local training=world.tag=="TrainingRoom"
 if training then require("Story.AcademyVisit").attach(world) end
 local storyId=rescued and "wuyun-rest" or world.tag=="AbandonedCity" and "ground-arrival" or world.tag=="TrainA" and "train-conflict" or world.tag=="LibraryRoom" and "archive-discovery" or world.tag=="RDRoom" and "academy-research" or world.tag=="Station" and "station-brief" or nil
 if world.tag=="RestRoom" then storyId="wuyun-rest" end
 if world.ruinsSearch then storyId=nil end
 if world.tag=="Station" then
  local service=require("Story.Service").open(); local facts=service and service:summary()
  if facts and facts.completed["ruins-preparation"] and not facts.completed["roof-aftermath"] then
   storyId="ruins-station"
   D.thread(function() D.Cache:loadAsync("spine:wuyun"); if not world.parent then return end; D.Entity({player=false,name="wuyun",faceRight=true,position=D.Vec2(world.sceneWidth-1070,world.offset),base=true,storyCompanion=true}) end)
  end
 end
 if not training and world.tag~="OperationRoom" and not storyId then return end
 local terminal=D.Node(); terminal.position=D.Vec2(training and 935 or world.tag=="AbandonedCity" and 900 or world.tag=="LibraryRoom" and 2690 or world.tag=="Station" and world.sceneWidth-650 or world.sceneWidth/2,world.offset+150); terminal:addTo(world)
 local interaction=require("UI.Interaction")({text=training and "训练终端" or storyId and (world.tag=="RestRoom" and "休息室交谈" or world.tag=="AbandonedCity" and "下车集合点" or world.tag=="LibraryRoom" and "第二层书柜" or world.tag=="Station" and "地面部署集合点" or world.tag=="TrainA" and "车厢交谈" or "研发设施") or "任务控制台",buttons=training and {{"进入训练",""},{"李叶娜合作",""},{"李叶娜对打",""}} or {{training and "进入训练" or storyId and (world.tag=="RestRoom" and "询问乌云" or world.tag=="AbandonedCity" and "确认维生场" or world.tag=="LibraryRoom" and "调查暗格" or world.tag=="Station" and "了解部署准备" or world.tag=="TrainA" and "讨论计划" or "了解研发设施") or "任务与编队",""}},fliped=false})
 if storyId=="ruins-station" then terminal.tag="ruins-station-ready"; interaction:removeFromParent(); interaction=require("UI.Interaction")({text="遗迹调查集合",buttons={{"出发讨论",""}},fliped=false}); interaction.scaleX=0.325; interaction.scaleY=0.325 end
 if world.tag=="RestRoom" then interaction:removeFromParent(); interaction=require("UI.Interaction")({text="休息室交谈",buttons={{"询问乌云",""},{"会见来访者",""},{"地面计划",""}},fliped=false}); interaction.scaleX=0.325; interaction.scaleY=0.325 end
 interaction.tag=training and "trainingTerminal" or storyId and "storyTerminal" or "missionTerminal"
	if world.tag=="TrainA" then interaction.scaleX=0.325; interaction.scaleY=0.325 end
	interaction.transformTarget=terminal; interaction.order=world.children.last.order; interaction.visible=false; interaction.menu.enabled=false; interaction:addTo(world)
	local inside=false; local entering=false
	world:schedule(function()
		local player=playerGroup:find(isLocalPlayer)
		local near=player and not player.busy and not world.data.journalOpen and not world.data.storyBusy and math.abs(player.unit.x-terminal.x)<230
		if near~=inside then
			inside=not not near
			if inside then interaction.visible=true; interaction:show() else interaction:hide(false) end
		end
		return false
	end)
	interaction:slot("Tapped",function(index)
		if not inside or entering then return end
		entering=true
		D.thread(function()
   if training then
    if index==2 or index==3 then
     local opened,err=require("Trial.Level").openAsync(world,index==3)
     if not opened then entering=false; label.text=err=="STORY_LOCKED" and "先跟随阿岩参观，听取林睿哲的训练安排。" or err=="COOP_REQUIRED" and "先完成李叶娜合作训练，再进入对打。" or "训练暂未开始，请重试。"; print("Trial open: "..tostring(err)) end
    else require("Training.Level")(function() Navigation.returnToTrainingAsync() end) end
   elseif storyId then
    local opened,err=require("Story.Flow").openAsync(world.tag=="RestRoom" and (index==2 and "underground-cooperation" or index==3 and "energy-plan" or "wuyun-rest") or storyId,world,function() entering=false; Navigation.refreshStoryActors(world) end)
    if not opened then entering=false; label.text=err=="STORY_LOCKED" and "先完成前置记录，再到对应设施继续交谈；通讯与日志可查看当前目标。" or "调查暂不可用："..tostring(err) end
   else
    local opened,err=require("Mission.Briefing").openAsync()
    world.missionBriefing=opened
    if not opened then entering=false; label.text="任务记录暂不可用，请重试："..tostring(err) end
   end
  end)
	end)
end
function Navigation.returnToRoomAsync(name,options)
 if name=='FactoryRoof'then return require('Factory.Roof').openAsync(options)end
 if name=='ControlPod'then return require('Factory.ControlPod').openAsync(options)end
 options=options or {}
 local previous=D.Platformer.Data.store.world
 local returningFromTrain=name=="Station" and previous and previous.tag=="TrainA"
	local Scene=require("Scene."..name); Scene:loadAsync()
 if name=="TrainA" then D.Cache:loadAsync("spine:ninilite"); D.Cache:loadAsync("spine:liyena") end
 if name=="AbandonedCity" and options.energySquad then D.Cache:loadAsync("spine:wuyun") end
 if name=="AbandonedCity" and options.ruinsSearch then D.Cache:loadAsync("spine:vika"); D.Cache:loadAsync("spine:vivi"); D.Cache:loadAsync("spine:ayan") end
 if name=="AbandonedCity" then D.Cache:loadAsync("spine:ninilite"); D.Cache:loadAsync("spine:dataotie") end
 if name=="Factory" and not options.foxTrail then D.Cache:loadAsync("spine:ninilite"); D.Cache:loadAsync("spine:wuyun") end
 if options.foxTrail or options.foxParty then require('Story.FoxCompanion').loadAnimatedAsync();D.Cache:loadAsync("spine:villywan") end
 if name=="OuterHeaven" then D.Cache:loadAsync("spine:villywan");D.Cache:loadAsync("spine:xiaoshanxiao") end
 if name=="RestRoom" then D.Cache:loadAsync("spine:wuyun") end
	D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren()
	D.Entity:clear(); D.Platformer.Data.store:clear()
	local world=Scene(); world.infiltrationRoute=options.infiltrationRoute; world.foxTrailRoute=options.foxTrail; world.valleyVisit=options.valleyVisit; world.auxiliaryVariant=options.auxiliaryVariant or (options.support and options.support.variant); world.energySquad=options.energySquad; world.ruinsSearch=options.ruinsSearch; world.groundSupport=options.support; world:addTo(D.Director.entry); D.Platformer.Data.store.world=world
	require("Academy.Action")(); require("Academy.AI")(); require("Academy.System")()
	local config=require("Data.Config")
	local spawn=name=="TrainingRoom" and 1180 or name=="Station" and world.sceneWidth-220 or world.sceneWidth/2+280
	if name=="TrainA" then spawn=world.sceneWidth/2 end
	if name=="AbandonedCity" or name=="Factory" or name=="OuterHeaven" then spawn=options.spawn or 600 end
	if returningFromTrain then spawn=world.sceneWidth-1800 end
 if name=="OperationRoom" and previous and previous.missionBriefing then
  local service=require("Story.Service").open()
  local facts=service and service:summary()
  if facts and facts.completed['fox-trail-return'] then spawn=world.sceneWidth/2 end
 end
	D.Entity({player=true,name=config.char or "charM",faceRight=true,position=D.Vec2(spawn,world.offset),base=true})
	if not options.foxTrail and name~="Station" and name~="TrainA" and name~="OuterHeaven" then D.Entity({player=false,name="ninilite",faceRight=false,position=D.Vec2(spawn+200,world.offset),base=true,storyCompanion=name=="AbandonedCity" or name=="Factory" or name=="RestRoom",decisionTree=(name=="AbandonedCity" or name=="Factory") and "AI:PlayerControl" or nil}) end
	if require("Story.Availability").canDeploy("wuyun") and ((name=="AbandonedCity" and options.energySquad) or (name=="Factory" and not options.foxTrail)) then D.Entity({player=false,name="wuyun",faceRight=true,position=D.Vec2(spawn-180,world.offset),base=true,storyCompanion=true,decisionTree="AI:PlayerControl"}) end
 if options.foxParty then
  D.Entity({player=false,name="villywan",faceRight=true,position=D.Vec2(spawn-170,world.offset),base=true,storyCompanion=true})
  local fox=require('Story.FoxCompanion').createAnimated();fox.recovery=.2;fox.position=D.Vec2(spawn+500,world.offset);fox:play("idle",true);fox:addTo(world);world.foxParty=fox
 end
	local hud=require("UI.HUDControl")(); if name=="AbandonedCity" or name=="Factory" then hud.tag="ground-hud" end; hud.topControl.visible=false; hud.message.visible=false; hud:addTo(D.Director.ui3D); D.emit("HUD.DisplayMove",true)
	D.sleep() -- Entity observers construct units on the next engine frame.
	Navigation.attach(world)
	return world
end
function Navigation.returnToTrainingAsync() return Navigation.returnToRoomAsync("TrainingRoom") end
function Navigation.returnToOperationAsync() return Navigation.returnToRoomAsync("OperationRoom") end
return Navigation
