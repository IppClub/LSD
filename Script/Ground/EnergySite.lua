local D=require("Dora")
local Site={}
function Site.attach(world,support)
 local facts=assert(require("Story.Service").open():summary())
 local controller={phase="idle",recovered=not not facts.completed["energy-recovery"],secured=not not facts.mission.unlocks["energy-site-secured"]}; world.energySite=controller
 local box=D.DrawNode(); box.tag="central-energy-box"; box.order=30; box.position=D.Vec2(5760,world.offset+35); box:addTo(world)
 box:drawPolygon({D.Vec2(-55,0),D.Vec2(55,0),D.Vec2(55,75),D.Vec2(-55,75)},D.Color(0xff465269))
 box:drawSegment(D.Vec2(-55,0),D.Vec2(55,0),5,D.Color(0xffb376ff)); box:drawSegment(D.Vec2(-55,0),D.Vec2(-55,75),5,D.Color(0xffb376ff)); box:drawSegment(D.Vec2(55,0),D.Vec2(55,75),5,D.Color(0xffb376ff));
 box:drawSegment(D.Vec2(-55,75),D.Vec2(55,75),8,D.Color(0xffd9dff2)); box:drawDot(D.Vec2(0,38),19,D.Color(0xffb376ff))
 local terminal=D.Node(); terminal.position=D.Vec2(5760,world.offset+150); terminal:addTo(world)
 local menu=require("UI.Interaction")({text="中央能源箱",buttons={{"清理伏击",""},{"收取能源",""}},fliped=false})
 menu.tag="energy-terminal"; menu.transformTarget=terminal; menu.scaleX=0.325; menu.scaleY=0.325; menu.visible=false; menu.menu.enabled=false; menu:addTo(world); controller.view=menu
 local message=D.Label("SourceHanSansCN-Regular",23); message.textWidth=900; message.position=D.Vec2(0,300); message:addTo(terminal); message.visible=false
 local near=false
 terminal:schedule(function()
  local p=D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world end)
  local value=p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-5760)<180
  if (not not value)~=near then near=not not value; if near then menu.visible=true; menu:show() else menu:hide(false) end end
  return false
 end)
 menu:slot("Tapped",function(index)
  if not near or controller.phase~="idle" then return end
  controller.phase="opening"
  D.thread(function()
   local service=assert(require("Mission.Service").open())
   if index==1 then
    local progress=require("Training.Progress"); local wp=progress.forCharacter("wuyun")
    local models={ninilite=progress.load() and progress.adopted,wuyun=wp.load() and wp.adopted}
    local panel,err=require('Ground.Preparation').openAsync(world,'c0-m03',models,support,function()controller.supplyPanel=nil;controller.phase='idle' end)
    controller.supplyPanel=panel
    if not panel then message.text='补给准备暂不可用：'..tostring(err);message.visible=true;controller.phase='idle'end
    return
   end
   local facts=assert(require("Story.Service").open():summary())
   if not facts.mission.unlocks["energy-site-secured"] then message.text="三只怪物仍在附近，先让队伍清理伏击。"; message.visible=true; controller.phase="idle"; return end
   local opened,err=require("Story.Flow").openAsync("energy-recovery",world,function()
    controller.phase="idle"
    controller.recovered=not not require("Story.Service").open():summary().completed["energy-recovery"]
    if controller.recovered then
     box.opacity=0.5; message.text="能源 "..tostring(service:summary().rewards["energy-site-secured"] or 1).." 份已进入手环。可继续探索；准备好后向左返回列车。"; message.visible=true
    end
   end)
   if not opened then message.text=tostring(err); message.visible=true; controller.phase="idle"; return end
   if not facts.completed["energy-recovery"] then
    local particles=D.DrawNode(); particles.tag="energy-data-stream"; particles.position=box.position; particles:addTo(world)
    local start=D.App.runningTime
    particles:schedule(function()
     local t=D.App.runningTime-start; particles:clear()
     for i=1,12 do local y=(t*170+i*23)%280; particles:drawDot(D.Vec2(math.sin(i+t*2)*35,y),4,D.Color(0xffd6c2ff)) end
     if t>=3 then particles:removeFromParent(); return true end; return false
    end)
   end
  end)
 end)
 return controller
end
return Site
