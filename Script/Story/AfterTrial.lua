-- Original 2-5: mail/forward first, then a physical meeting and a recorded story fragment.
local D=require("Dora")
local After={}
local steps={
 [5]={id="ayan-refreshment",text="领取食物"},
 [6]={id="ayan-fragment",text="聆听往事"},
 [7]={id="ayan-sharing",text="继续交谈"},
 [8]={id="ayan-sharing",text="回顾交谈"},
}
function After.attach(world)
 if world.afterTrial then return world.afterTrial end
 local service=require("Story.Service").open(); local facts=service and service:summary()
 if not facts or not facts.completed["liyena-recognition"] or facts.completed["lin-investigation"] then return end
 local c={phase="loading",stage=5,walked=0}; world.afterTrial=c; world.academyVisit=c
 local x=2050
 local function actor() return D.Group({"name","unit"}):find(function(e) return e.name=="ayan" and e.unit.world==world and e.afterTrialActor end) end
 D.thread(function()
  D.Cache:loadAsync("spine:ayan")
  if not world.parent or D.Platformer.Data.store.world~=world then return end
  D.Entity({player=false,name="ayan",position=D.Vec2(x,world.offset),faceRight=true,base=true,storyCompanion=true,afterTrialActor=true,decisionTree="AI:PlayerControl"})
  c.phase="waiting"
 end)
 local anchor=D.Node(); anchor.position=D.Vec2(x,world.offset+150); anchor:addTo(world)
 local menu=require("UI.Interaction")({text="阿岩 · 训练之后",buttons={{"领取食物",""},{"人物故事",""}},fliped=false})
 menu.tag="ayan-after-terminal"; menu.scaleX=0.325; menu.scaleY=0.325; menu.transformTarget=anchor; menu.order=100; menu.visible=false; menu.menu.enabled=false; menu:addTo(world); c.view=menu
 -- No detached meal art exists in the current atlas: a small visible tray accompanies the handover.
 local tray=D.DrawNode(); tray.tag="ayan-food-tray"; tray.position=D.Vec2(x+110,world.offset+50); tray:addTo(world); c.tray=tray
 tray:drawPolygon({D.Vec2(-55,-12),D.Vec2(55,-12),D.Vec2(65,12),D.Vec2(-65,12)},D.Color(0xff9faebc))
 tray:drawSegment(D.Vec2(-50,8),D.Vec2(50,8),3,D.Color(0xffdce6ed))
 tray:drawDot(D.Vec2(-22,18),20,D.Color(0xffc58b4e)); tray:drawSegment(D.Vec2(-31,28),D.Vec2(-23,13),2,D.Color(0xffffd394)); tray:drawSegment(D.Vec2(-20,31),D.Vec2(-12,16),2,D.Color(0xffffd394))
 tray:drawDot(D.Vec2(30,18),13,D.Color(0xffa92e49)); tray:drawSegment(D.Vec2(30,32),D.Vec2(36,38),3,D.Color(0xff759d66))
 local ui=D.Node(); ui.tag="ayan-visit-guidance"; ui:addTo(D.Director.ui3D)
 local bg=D.DrawNode(); bg:addTo(ui)
 local hint=D.Label("SourceHanSansCN-Regular",23); hint.anchor=D.Vec2(0,1); hint.alignment="Left"; hint:addTo(ui); c.hint=hint
 local function layout()
  ui.size=D.App.bufferSize; hint.position=D.Vec2(30,ui.height-180); hint.textWidth=math.min(1300,ui.width-60); bg.position=D.Vec2(15,ui.height-270)
  bg:clear(); bg:drawPolygon({D.Vec2.zero,D.Vec2(hint.textWidth+30,0),D.Vec2(hint.textWidth+30,110),D.Vec2(0,110)},D.Color(0xcc101b28))
 end
 layout(); ui:gslot("AppChange",function(n) if n=="Size" then layout() end end)
 world:slot("Cleanup",function() ui:removeFromParent() end)
 local near=false; local busy=false; local marker; local nextRead=-1
 anchor:schedule(function()
  if c.phase=="loading" then return false end
  local a=actor(); local p=D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world end)
  if not a or not p then return false end; c.actor=a
  if D.App.runningTime>=nextRead then
   facts=assert(service:summary()); nextRead=D.App.runningTime+0.5
   c.stage=not facts.completed["ayan-refreshment"] and 5 or not facts.completed["ayan-fragment"] and 6 or not facts.completed["ayan-sharing"] and 7 or 8
   menu.menu.children.first.children.last.text=steps[c.stage].text
   hint.text=facts.objective
   tray.visible=not facts.completed["ayan-refreshment"]
  end
  local paused=world.data.storyBusy or world.data.journalOpen or p.busy; ui.visible=not paused
  if not paused then a.unit.faceRight=p.unit.x>=a.unit.x end
  local can=not paused and math.abs(p.unit.x-a.unit.x)<180
  if (not not can)~=near then near=not not can; if near then menu.visible=true; menu:show() else menu:hide(false) end end
  local tag=require("Story.Catalog")[steps[c.stage].id].discoveryTag
  if marker and marker.tag~=tag then marker:removeFromParent(); marker=nil end
  if not marker then marker=D.Node(); marker.tag=tag; marker.x=a.unit.x; marker:addTo(world) end
  return false
 end)
 menu:slot("Tapped",function(index)
  if not near or busy then return end; busy=true
  D.thread(function()
   if index==2 then
    local opened,err=require("Academy.Companion").openAsync("ayan",world,"information"); busy=false
    if not opened then hint.text="人物资料暂不可用，请稍后再试。"; print("Ayan profile: "..tostring(err)) end
    return
   end
   local id=steps[c.stage].id
   local opened,err=require("Story.Flow").openAsync(id,world,function() busy=false end,facts.completed[id] or false)
   if not opened then
    busy=false; hint.text=err=="STORY_LOCKED" and "先打开通讯第五页，阅读第三封邮件，并点击转告妮妮莉特；阿岩会在这里等你。" or "交谈暂未开始，请重试。"
    print("Ayan after trial: "..tostring(err))
   end
  end)
 end)
 return c
end
return After
