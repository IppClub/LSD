-- Both original 2-6 scenes, reached through actual academy doors.
local D=require("Dora")
local Visit={}
function Visit.attach(world)
 if world.medicalVisit then return world.medicalVisit end
 local service=require("Story.Service").open(); local facts=service and service:summary()
 if not facts or not facts.completed["ayan-sharing"] then return end
 local medical=world.tag=="RestRoom"
 if medical and facts.completed["medical-treatment"] then return end
 if not medical and (world.tag~="PreparationRoom" or not facts.completed["translator-request"]) then return end
 local id=medical and "medical-meeting" or "translator-preparation"
 local x=world.sceneWidth/2+(medical and 850 or 0)
 local c={phase="loading",id=id,actors={}}; world.medicalVisit=c
 local function find(name) return D.Group({"name","unit"}):find(function(e) return e.name==name and not e.player and e.unit.world==world end) end
 D.thread(function()
  local roles=medical and {{"moyu",-210},{"moling",210}} or {{"ninilite",-310},{"wuyun",310}}
  for _,role in ipairs(roles) do
   D.Cache:loadAsync("spine:"..role[1])
   if not world.parent or D.Platformer.Data.store.world~=world then return end
   local e=find(role[1])
   if not e then D.Entity({player=false,name=role[1],position=D.Vec2(x+role[2],world.offset),faceRight=role[2]<0,base=true,storyCompanion=true,decisionTree="AI:PlayerControl"})
   else e.storyCompanion=true; e.keyLeft=false; e.keyRight=false; e.unit:stop(); e.unit.position=D.Vec2(x+role[2],world.offset+155); e.unit.velocity=D.Vec2.zero; e.unit.decisionTree="AI:PlayerControl" end
  end
  local untilTime=D.App.runningTime+5
  -- The engine swallows thread errors; abort instead of hanging or nil-dereferencing below.
  while not (find(roles[1][1]) and find(roles[2][1])) do
   if D.App.runningTime>=untilTime then print("MedicalVisit: story pair failed to spawn, aborted")return end
   D.sleep(0.02)
  end
  c.actors={find(roles[1][1]),find(roles[2][1])}; c.phase="ready"
 end)
 local marker=D.Node(); marker.tag=require("Story.Catalog")[id].discoveryTag; marker.position=D.Vec2(x,world.offset+150); marker:addTo(world)
 local view=require("UI.Interaction")({text=medical and "医师姐弟" or "行动准备",buttons={{medical and "拜访医师" or "确认行动",""}},fliped=false})
 view.tag=medical and "medical-meeting-terminal" or "translator-preparation-terminal"; view.scaleX=0.325; view.scaleY=0.325; view.transformTarget=marker; view.order=100; view.visible=false; view.menu.enabled=false; view:addTo(world); c.view=view
 if medical then
  -- Detached surgery furniture/medicine art is absent; visible station prototype.
  local tools=D.DrawNode(); tools.tag="medical-station-prototype"; tools.position=D.Vec2(x+450,world.offset); tools:addTo(world); c.station=tools
  tools:drawPolygon({D.Vec2(-120,105),D.Vec2(120,105),D.Vec2(120,125),D.Vec2(-120,125)},D.Color(0xffb8c7d2))
  tools:drawSegment(D.Vec2(-90,105),D.Vec2(-90,10),9,D.Color(0xff617386)); tools:drawSegment(D.Vec2(90,105),D.Vec2(90,10),9,D.Color(0xff617386))
  tools:drawPolygon({D.Vec2(-104,126),D.Vec2(45,126),D.Vec2(45,139),D.Vec2(-104,139)},D.Color(0xffe1eced))
  for i,color in ipairs({0xff63bdc6,0xff957cc7}) do
   local bx=55+(i-1)*37
   tools:drawPolygon({D.Vec2(bx,125),D.Vec2(bx+25,125),D.Vec2(bx+25,166),D.Vec2(bx,166)},D.Color(color))
   tools:drawSegment(D.Vec2(bx+4,171),D.Vec2(bx+21,171),8,D.Color(0xffc9dde2))
   tools:drawSegment(D.Vec2(bx+6,144),D.Vec2(bx+19,144),4,D.Color(0xffeaf3ed))
  end
  local label=D.Label("SourceHanSansCN-Regular",24); label.text="诊疗区"; label.position=D.Vec2(0,205); label:addTo(tools)
 end
 local near=false; local busy=false
 marker:schedule(function()
  local p=D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world end)
  local now=not world.recoveryVisit and c.phase=="ready" and p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-x)<180
  if (not not now)~=near then near=not not now; if near then view.visible=true; view:show() else view:hide(false) end end
  if p and not world.recoveryVisit and not world.data.storyBusy and not world.data.journalOpen then for _,a in ipairs(c.actors) do a.unit.faceRight=p.unit.x>=a.unit.x end end
  return false
 end)
 view:slot("Tapped",function()
  if not near or busy then return end; busy=true
  D.thread(function()
   local opened,err=require("Story.Flow").openAsync(id,world,function() busy=false end)
   if not opened then busy=false; print("Medical visit: "..tostring(err)) end
  end)
 end)
 return c
end
return Visit
