-- Ayan escorts a walking player through the original room; safe Yarn checkpoints.
local D=require("Dora")
local Visit={}
local stages={
 {id="ayan-arrival",x=2600,tag="ayan-greeting",title="认识阿岩"},
 {id="ayan-detour",x=3100,tag="ayan-wrong-way",title="询问地面往事"},
 {id="ayan-tour",x=2200,tag="ayan-training-tour",title="听取训练安排"},
 {x=790,title="训练场入口"},
}
function Visit.attach(world)
 if world.academyVisit then return world.academyVisit end
 local service=require("Story.Service").open(); local facts=service and service:summary()
 if not facts or not facts.completed["energy-recovery"] then return end
 if facts.completed["liyena-recognition"] then return require("Story.AfterTrial").attach(world) end
 local c={phase="loading",stage=1,walked=0}; world.academyVisit=c
 local function find(name) return D.Group({"name","unit"}):find(function(e) return e.name==name and e.unit.world==world end) end
 local function stage()
  local f=assert(service:summary()); for i,v in ipairs(stages) do if not v.id or not f.completed[v.id] then return i end end
 end
 c.stage=stage()
 D.thread(function()
  for _,name in ipairs({"ayan","sunborn","liyena"}) do
   D.Cache:loadAsync("spine:"..name)
   if not world.parent or D.Platformer.Data.store.world~=world then return end
   local x=name=="ayan" and (c.stage==1 and 2600 or stages[c.stage-1].x) or name=="sunborn" and 2160 or 1250
   D.Entity({player=false,name=name,position=D.Vec2(x,world.offset),faceRight=false,base=true,storyCompanion=true,decisionTree="AI:PlayerControl"})
  end
  c.phase="walking"
 end)
 local anchor=D.Node(); anchor:addTo(world)
 local menu=require("UI.Interaction")({text="阿岩 · 训练场接引",buttons={{"交谈",""}},fliped=false})
 menu.order=100; menu.tag="ayan-visit-terminal"; menu.scaleX=0.325; menu.scaleY=0.325; menu.transformTarget=anchor; menu.visible=false; menu.menu.enabled=false; menu:addTo(world); c.view=menu
 local ui=D.Node(); ui.tag="ayan-visit-guidance"; ui:addTo(D.Director.ui3D)
 local bg=D.DrawNode(); bg:addTo(ui)
 local hint=D.Label("SourceHanSansCN-Regular",23); hint.anchor=D.Vec2(0,1); hint.alignment="Left"; hint:addTo(ui); c.hint=hint
 local function layout() ui.size=D.App.bufferSize; hint.position=D.Vec2(30,D.App.bufferSize.height-180); hint.textWidth=math.min(1300,D.App.bufferSize.width-60); bg.position=D.Vec2(15,D.App.bufferSize.height-270); bg:clear(); bg:drawPolygon({D.Vec2.zero,D.Vec2(hint.textWidth+30,0),D.Vec2(hint.textWidth+30,110),D.Vec2(0,110)},D.Color(0xcc101b28)) end
 layout(); ui:gslot("AppChange",function(n) if n=="Size" then layout() end end)
 ui:gslot("Story.Display",function(visible) ui.visible=not visible end)
 world:slot("Cleanup",function() ui:removeFromParent() end)
 local near=false; local previousX; local marker; local busy=false; local nextCheck=0
 anchor:schedule(function()
  if c.phase=="loading" then return false end
  local a=find("ayan"); local p=D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world end)
  if not a or not p then return false end
  c.actor=a
  if D.App.runningTime>=nextCheck then c.stage=stage(); nextCheck=D.App.runningTime+0.5 end
  local v=stages[c.stage]
  for _,name in ipairs({"sunborn","liyena"}) do local actor=find(name); if actor then actor.unit.visible=c.stage>=3 end end
  if previousX then c.walked=c.walked+math.abs(a.unit.x-previousX) end; previousX=a.unit.x
  anchor.position=D.Vec2(a.unit.x,world.offset+150)
  local paused=world.data.storyBusy or world.data.journalOpen or p.busy
  ui.visible=not paused
  local arrived=math.abs(a.unit.x-v.x)<30
  local delta=p.unit.x-a.unit.x
  local waitForPlayer=math.abs(delta)>420
  local move=not paused and not arrived and not waitForPlayer
  a.keyLeft=move and a.unit.x>v.x; a.keyRight=move and a.unit.x<v.x
  if not move then
   if a.unit:isDoing("fmove") or a.unit:isDoing("bmove") then a.unit:stop(); a.unit:start("idle") end
   a.unit.velocityX=0
  end
  local can=not paused and arrived and math.abs(delta)<180 and v.id
  if (not not can)~=near then near=not not can; if near then menu.visible=true; menu:show() else menu:hide(false) end end
  if marker and (not arrived or marker.tag~=v.tag) then marker:removeFromParent(); marker=nil end
  if arrived and v.id and not marker then marker=D.Node(); marker.tag=v.tag; marker.x=v.x; marker:addTo(world) end
  hint.text=c.stage==1 and "林睿哲安排的接引人阿岩正在训练室右侧等你，走近后交谈。" or c.stage==4 and "接引参观已记录。到左侧发光终端选择李叶娜合作或对打训练；平日示范训练仍可使用。" or waitForPlayer and "阿岩在等你。用摇杆或 A/D 跟上；走近停下的阿岩继续交谈。" or arrived and "阿岩停下了。走近他，继续了解训练场。" or "跟随阿岩参观训练场。人物会等你；打开通讯时暂停带路。"
  return false
 end)
 menu:slot("Tapped",function()
  if not near or busy then return end; busy=true
  D.thread(function()
   local opened,err=require("Story.Flow").openAsync(stages[c.stage].id,world,function() busy=false end)
   if not opened then busy=false; hint.text="交谈暂时无法打开，请稍后再试；通讯记录会保留已完成的进度。"; print("Ayan dialogue unavailable: "..tostring(err)) end
  end)
 end)
 return c
end
return Visit
