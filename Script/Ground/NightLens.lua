-- Authored equipment: original Phone UI + a coordinate map of the existing city.
local D=require("Dora")
local Lens={}
Lens.locations={{id="return",title="返程列车",x=170},{id="supply",title="沿街补给",x=1700},{id="frontier",title="前沿侦察",x=2450},{id="energy",title="中央能源定位",x=5760}}
Lens.factoryLocations={{id="return",title="工厂返程列车",x=170},{id="marsh",title="沼泽道路",x=5200},{id="material",title="砗磲贝材料点",x=6400},{id="boundary",title="工厂道路尽头",x=11000}}
Lens.ruinsLocations={{id="return",title="返程列车",x=170},{id="signal",title="红色求救信号",x=6200},{id="ayan",title="双胞胎指向的道路",x=8500},{id="boundary",title="遗迹道路尽头",x=11000}}
function Lens.openAsync(world)
 local service,err=require("Story.Service").open(); if not service then return nil,err end
 local facts=assert(service:summary()); if not facts.unlocks["night-lens"] then return nil,"EQUIPMENT_LOCKED" end
 local infiltration=world.infiltration;local trail=world.foxTrail;local surveying=trail and trail.command=='scan'
 if (world.data.storyBusy and not surveying) or world.data.journalOpen then return nil,"STORY_BUSY" end
 local Flow=require("Story.Flow"); world.data.journalOpen=true; Flow.freeze(world,true)
 local factory=world.tag=="Factory"
 local ruins=world.ruinsSearch
 local locations=infiltration and {{id='base',title='返回指挥室',x=1000},{id='patrol',title='巡逻守卫',x=2200},{id='concealed',title='隐蔽厂区路线',x=3200},{id='researcher',title='研发人员经过处',x=4400}} or trail and {{id='departure',title='进入工厂',x=600},{id='rest',title='路旁休息',x=2600},{id='hideout',title='收集位置资料',x=4100},{id='open',title='开阔撤离点',x=4500}} or ruins and Lens.ruinsLocations or factory and Lens.factoryLocations or Lens.locations
 local c={phase="map",locations=locations}; world.nightLens=c
 local view=require("UI.Phone")({storyMode=true,panelTitle="夜光镜",closeText="关闭地图",pageText="定位 1 / 1",
  row1Title=locations[1].title,row2Title=locations[2].title,row3Title=ruins and not facts.completed["ruins-twins"] and "阿岩去向待确认" or locations[3].title,row4Title=locations[4].title,
  row1Status=infiltration and "安全出发点 · 保留已记录进度" or trail and "狐狸指引的路线起点" or "点击设定返程路标",row2Status=infiltration and "点击定位 · 核对火力两秒" or trail and "使用随身食物 · 万薇莉同行" or ruins and "点击定位求救信号" or factory and "点击定位沼泽道路" or "点击定位已知补给",row3Status=infiltration and "巡逻队制服后 · 跟随狐狸" or trail and "隐蔽侦察 · 点击开始收集" or ruins and (facts.completed["ruins-twins"] and "点击定位阿岩去向" or "先核实求救信号") or factory and "清理花妖后实地采集" or "点击定位侦察点",row4Status=infiltration and "进入厂区后 · 注意隐蔽" or trail and "资料收集后 · 三人撤离" or ruins and "道路边界 · 注意安全" or factory and "道路边界 · 注意安全" or "林睿哲提供 · 尚需核实"})
 view.tag="night-lens-map"; c.view=view; view:addTo(D.Director.ui3D)
 view.previousButton.visible=false; view.nextButton.visible=false
 local map=D.DrawNode(); map.position=D.Vec2(-360,-140); map:addTo(view.detail.parent); c.map=map
 for i,v in ipairs(locations) do
  local caption=D.Label("SourceHanSansCN-Regular",30); caption.text=ruins and i==3 and not facts.completed["ruins-twins"] and "待核实" or (infiltration and {"入口","守卫","隐蔽","厂区"} or trail and {"起点","休息","据点","撤离"} or ruins and {"返程","求救","去向","边界"} or factory and {"返程","沼泽","材料","边界"} or {"返程","补给","前沿","能源"})[i]; caption.position=D.Vec2(v.x/11520*1500,i%2==1 and 85 or -95); caption:addTo(map)
 end
 local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world end) end
 local function render()
  local p=player(); local inCity=world.tag=="AbandonedCity" or factory; local selected=world.nightLensTarget
  c.playerX=inCity and p and p.unit.x or nil
  local description=selected and string.format("当前路标：%s · 已定位",selected.title) or "选择左侧地点，设定调查路标。"
  view.detail.text="林睿哲发来的地面定位图\n"..(facts.completed["energy-recovery"] and "紫色光点：中央能源已回收，可在通讯日志重读。" or "紫色光点：中央能源位置 · 等待实地确认。").."\n蓝色光点：已知返程、补给与侦察位置。\n\n"..description.."\n"..(c.playerX and string.format("当前位置：%.0f · 距路标 %.0f",c.playerX,selected and math.abs(selected.x-c.playerX) or 0) or "进入遗弃城市后，可以追踪队伍位置。").."\n\n已选路标后，关闭地图并沿街道向目标前进。"
  if ruins then view.detail.text="遗迹寻人 · 红色求救信号定位图\n"..description.."\n"..(c.playerX and string.format("当前位置：%.0f · 距路标 %.0f",c.playerX,selected and math.abs(selected.x-c.playerX) or 0) or "进入遗迹城市后追踪队伍位置。").."\n先核实求救信号，再沿双胞胎指出的道路寻找阿岩。" end
  if factory then view.detail.text="废弃工厂定位图 · 沼泽与砗磲贝材料\n"..description.."\n"..(c.playerX and string.format("当前位置：%.0f · 距路标 %.0f",c.playerX,selected and math.abs(selected.x-c.playerX) or 0) or "正在确认位置。").."\n先清理花妖，再到材料点采集；左侧列车可返程。" end
  if trail then view.detail.text=trail.scanDone and "收集完毕\n据点入口与道路已记录。关闭夜光镜后撤离。" or "狐狸的隐蔽路线\n"..description.."\n"..(c.playerX and string.format("当前位置：%.0f · 据点附近可收集位置资料",c.playerX) or "正在确认位置。").."\n点击收集位置资料，保持隐蔽三秒。" end
  if infiltration then view.detail.text="断网组织工厂 · 隐蔽行动\n"..description.."\n点击巡逻守卫，保持隐蔽两秒核对火力；随后关闭地图，三人协同制服守卫。" end
  map:clear(); map:drawSegment(D.Vec2(0,0),D.Vec2(1500,0),5,D.Color(0xff67788c))
  for _,v in ipairs(locations) do local x=v.x/11520*1500; map:drawDot(D.Vec2(x,0),v.id=="energy" and 18 or 12,D.Color(v.id=="energy" and 0xffb376ff or 0xff55d9ff)); if selected and selected.id==v.id then map:drawDot(D.Vec2(x,55),10,D.Color(0xffffd279)) end end
  if c.playerX then map:drawDot(D.Vec2(math.max(0,math.min(1500,c.playerX/11520*1500)),-50),14,D.Color(0xffffffff)) end
 end
 for i,button in ipairs({view.mailButton,view.researchButton,view.archiveButton,view.stationButton}) do
  button:slot("Tapped"):clear(); button:slot("Tapped",function() if ruins and i==3 and not facts.completed["ruins-twins"] then view.detail.text="阿岩的去向尚未确认。先沿红色求救信号实地调查。"; return end; world.nightLensTarget=locations[i]; c.selected=locations[i]; render();if infiltration and i==2 then local ok,why=infiltration:locateFromLens(c);if not ok then view.detail.text='暂未定位：先走近狐狸确认隐蔽行动。'end end;if trail and i==3 then local ok,why=trail:scanFromLens(c);if not ok then view.detail.text='尚未开始收集：'..tostring(why)..'\n先跟随狐狸到据点附近。' end end end)
 end
 view.closeButton:slot("Tapped",function() if c.phase~="map" then return end; c.phase="closed"; world.data.journalOpen=false; view:removeFromParent(); Flow.freeze(world,world.data.storyBusy==true) end)
 render(); return c
end
return Lens
