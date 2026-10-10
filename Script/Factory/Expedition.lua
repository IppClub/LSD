-- Physical factory route; first discovery is local, material requires a real win.
local D=require("Dora")
local Expedition={}
function Expedition.attach(world)
 local c={phase="exploring",hp=require("Factory.Health").load()}; world.factoryExpedition=c
 local support,supportView=require("Factory.Support").create(world,c.hp,world.groundSupport);c.support=support;c.hp=support.hp
 local playerGroup=D.Group({"player","unit"})
 local function isLocalPlayer(e) return e.player and e.unit.world==world end
 local function terminal(tag,x,title,buttons,callback)
  local node=D.Node(); node.tag=tag.."-ready"; node.position=D.Vec2(x,world.offset+150); node:addTo(world)
  local menu=require("UI.Interaction")({text=title,buttons=buttons,fliped=false}); menu.tag=tag; menu.transformTarget=node; menu.scaleX=0.325; menu.scaleY=0.325; menu.visible=false; menu.menu.enabled=false; menu:addTo(world)
  local near=false; local busy=false
  node:schedule(function()
   local p=playerGroup:find(isLocalPlayer)
   local value=p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-x)<180
   if (not not value)~=near then near=not not value; if near then menu.visible=true; menu:show() else menu:hide(false) end end
   return false
  end)
  menu:slot("Tapped",function(index) if not near or busy then return end; busy=true; D.thread(function()
   -- The engine swallows thread errors, so guard busy here to keep the terminal usable.
   local ok,err=xpcall(function() callback(index,function() busy=false end) end,debug.traceback)
   if not ok then busy=false; print(err) end
  end) end)
  return menu
 end
 c.encounter=terminal("factory-encounter",5200,"沼泽道路",{{"观察歌声",""},{"准备战斗",""}},function(index,done)
  if index==1 then local opened,err=require("Story.Flow").openAsync("factory-encounter",world,done); if not opened then c.message=tostring(err); done() end; return end
  if require("Story.Service").open():summary().mission.unlocks["factory-site-secured"] then c.message="道路已经清理，继续向右采集材料；通讯可重读遭遇记录。"; done(); return end
  local story=require('Story.Service').open()
  local facts=story and story:summary()
  if not (facts and facts.completed['factory-encounter'])then
   c.message='先观察歌声，确认道路上的威胁，再准备战斗。';done();return
  end
  local progress=require("Training.Progress"); local wp=progress.forCharacter("wuyun")
  local models={ninilite=progress.load() and progress.adopted,wuyun=wp.load() and wp.adopted}
  require('Story.Flow').freeze(world,true)
  local panel,why=require('Factory.Preparation').openAsync(models,support,function()
   require('Story.Flow').freeze(world,false);done()
  end)
  if not panel then c.message=why;require('Story.Flow').freeze(world,false);done()end
 end)
 c.material=terminal("factory-material",6400,"砗磲贝材料",{{"采集材料",""}},function(_,done)
  local opened,err=require("Story.Flow").openAsync("factory-material",world,done)
  if not opened then c.message=err=="STORY_LOCKED" and "花妖仍威胁这片道路，先清理沼泽。" or tostring(err); done() end
 end)
 local shell=D.DrawNode(); shell.tag="factory-clam-prototype"; shell.position=D.Vec2(6400,world.offset+25); shell:addTo(world)
 shell:drawPolygon({D.Vec2(-60,0),D.Vec2(-45,45),D.Vec2(0,70),D.Vec2(45,45),D.Vec2(60,0)},D.Color(0xffe2d8bc))
 for _,x in ipairs({-45,-25,0,25,45}) do shell:drawSegment(D.Vec2(0,0),D.Vec2(x,55-math.abs(x)*0.35),3,D.Color(0xff998584)) end
 local hud=D.Director.ui3D:getChildByTag("ground-hud")
 local gather=require("UI.Skill")({visible=true,text="集合 K"}); gather.tag="factory-explore-gather"; gather.position=hud.weapon.position-D.Vec2(296,0); gather:addTo(hud.skillArea)
 local gathering=false; gather:slot("TapBegan",function() gathering=true end); gather:slot("TapEnded",function() gathering=false end)
 local ui=D.Node(); ui.tag="factory-explore-status"; ui:addTo(D.Director.ui3D)
 local function refreshObjective()
  local service=require("Story.Service").open()
  local facts=service and service:summary()
  c.objective=facts and facts.objective
  c.materialCollected=facts and facts.completed["factory-material"] or false
  c.message=nil
 end
 refreshObjective()
 ui:gslot("Story.Recorded",function(_,recordWorld) if recordWorld==world then refreshObjective() end end)
 local bg=D.DrawNode(); bg:addTo(ui)
 local label=D.Label("SourceHanSansCN-Regular",24); label.tag="factory-objective-status"; label.anchor=D.Vec2(0,1); label.alignment="Left"; label.textWidth=1000; label:addTo(ui)
 local supplies={}
 for i,x in ipairs({2100,4050,6200})do
  local node=D.DrawNode();node.position=D.Vec2(x,world.offset+30);node:addTo(world)
  node:drawPolygon({D.Vec2(-15,0),D.Vec2(0,24),D.Vec2(15,0),D.Vec2(0,-8)},D.Color(0xffffce52))
  node.visible=not support.collected['factory-gold-'..i]
  supplies[#supplies+1]={id='factory-gold-'..i,x=x,node=node}
 end
 -- 每帧扫描共享的组与谓词，避免逐帧重建闭包。
 local unitGroup=D.Group({"name","unit"})
 local scanP,scanN,scanW
 local function scanUnit(e) if e.unit.world==world then if e.player then scanP=e elseif e.name=="ninilite" then scanN=e elseif e.name=="wuyun" then scanW=e end end end
 local last=D.App.runningTime
 local tick=D.Node(); tick:addTo(world)
 tick:schedule(function()
  scanP,scanN,scanW=nil,nil,nil
  unitGroup:each(scanUnit)
  local p,n,w=scanP,scanN,scanW
  if not p or not n or not w then return false end
  local now=D.App.runningTime;local dt=math.min(1,now-last);last=now
  local paused=p.busy or world.data.storyBusy or world.data.journalOpen
  if not paused then
   support:update(dt,{p.unit.x,n.unit.x,w.unit.x})
   for _,drop in ipairs(supplies)do if support:collect(drop.id,12,drop.x,p.unit.x,n.unit.x)then drop.node.visible=false end end
   if support.hp[1]<=0 or support.hp[2]<=0 or support.hp[3]<=0 then
    c.phase='evacuating';for _,e in ipairs({p,n,w})do e.keyLeft=false;e.keyRight=false end
    D.thread(function()require('Academy.Navigation').returnToRoomAsync('TrainA')end);return true
   end
  end
  supportView:update(support,math.min(p.unit.x,n.unit.x,w.unit.x),math.max(p.unit.x,n.unit.x,w.unit.x))
  local spacing=(gathering or D.Keyboard:isKeyDown("K")) and 80 or 190
  for i,e in ipairs({n,w}) do local x=p.unit.x+(i==1 and spacing or -spacing); e.keyLeft=not paused and e.unit.x>x+35; e.keyRight=not paused and e.unit.x<x-35 end
  ui.size=D.App.bufferSize; label.position=D.Vec2(30,D.App.bufferSize.height-165); label.textWidth=math.max(280,D.App.bufferSize.width-450); ui.visible=not paused
  local width=math.max(300,math.min(1340,D.App.bufferSize.width-420))
  if c.hudWidth~=width or c.hudHeight~=D.App.bufferSize.height then
   c.hudWidth=width;c.hudHeight=D.App.bufferSize.height
   bg:clear(); bg:drawPolygon({D.Vec2.zero,D.Vec2(width,0),D.Vec2(width,135),D.Vec2(0,135)},D.Color(0xbb101b28)); bg.position=D.Vec2(15,D.App.bufferSize.height-285)
  end
  local target=world.nightLensTarget
  -- Label.setText rebuilds glyph layout even for identical strings.
  local text=string.format("导师 %.0f · 妮妮莉特 %.0f · 乌云 %.0f\n辅助机 %.0f · 金粉 %.1f · 集合靠拢可维生，受伤后仍需就医。\n",c.hp[1],c.hp[2],c.hp[3],support.machineHP,support.gold)..(c.message or (c.materialCollected and c.objective) or (target and string.format("路标：%s · %s · 距离 %.0f",target.title,p.unit.x<target.x and "向右" or "向左",math.abs(p.unit.x-target.x)) or c.objective or "清理花妖后向右采集砗磲贝，再点击通讯通知医师。"))
  if label.text~=text then label.text=text end
  return false
 end)
 world:slot("Cleanup",function() ui:removeFromParent() end)
 return c
end
return Expedition
