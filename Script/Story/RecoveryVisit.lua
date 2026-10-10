-- Original treatment, doctor departure, explicit overnight and next-day briefing.
local D=require("Dora")
local Animation=require("CombatAnimation")
local Visit={}
local stages={
 {id="medical-treatment",text="接受治疗"},
 {id="medical-recovery",text="休息至翌日"},
 {id="ruins-preparation",text="讨论消息"},
}
function Visit.attach(world)
 if world.tag~="RestRoom" then return end
 if world.recoveryVisit then return world.recoveryVisit end
 local service=require("Story.Service").open(); local facts=service and service:summary()
 if not facts or not facts.completed["medical-notify"] then return end
 local x=world.sceneWidth/2+850
 local c={phase="loading",stage=1,logs={},pending=0,doctors={},departed={}}; world.recoveryVisit=c
 -- Global action definitions outlive the room; only an active action owns the visit.
 local visitRef=setmetatable({c},{__mode="v"})
 local function find(name) return D.Group({"name","unit"}):find(function(e) return e.name==name and not e.player and e.unit.world==world end) end
 local function stage(f)
  if not f.completed["medical-treatment"] then return 1 end
  if not f.completed["medical-recovery"] then return 2 end
  if not f.completed["ruins-preparation"] then return 3 end
  return 4
 end
 local marker=D.Node(); marker.position=D.Vec2(x,world.offset+150); marker:addTo(world); c.marker=marker
 local function refresh(f)
  c.stage=stage(f); c.hp=require("Factory.Health").load()
  if c.view then c.view:removeFromParent() end
  local v=stages[c.stage]
  marker.tag=v and require("Story.Catalog")[v.id].discoveryTag or "recovery-completed"
  local view=require("UI.Interaction")({text="诊疗与休息",buttons={{v and v.text or "行动已备妥",""}},fliped=false})
  view.tag="recovery-terminal"; view.scaleX=0.325; view.scaleY=0.325; view.transformTarget=marker; view.order=100; view.visible=false; view.menu.enabled=false; view:addTo(world); c.view=view; c.near=false
  view:slot("Tapped",function()
   if not c.near or c.busy or not v then return end
   c.busy=true
   D.thread(function()
    local opened,err=require("Story.Flow").openAsync(v.id,world,function() c.busy=false; refresh(assert(service:summary())) end)
    if not opened then c.busy=false; c.message=tostring(err); return end
    if v.id=="medical-treatment" then
     for _,doctor in ipairs(c.doctors) do
      local action="medical-device-"..doctor.name; local log={name=doctor.name,animation="comp"}; c.logs[#c.logs+1]=log
      Animation.configure(doctor.unit,doctor.name)
      D.Platformer.UnitAction:add(action,{priority=4,reaction=0,recovery=0.2,available=function(u) return visitRef[1]~=nil and u.onSurface end,
       create=function(u)
        local c=visitRef[1]; if not c then return function() return true end end
        c.pending=c.pending+1; log.startedAt=D.App.runningTime
        return D.once(function() log.duration=Animation.playOnceAsync(u,"comp"); log.completedAt=D.App.runningTime; c.pending=c.pending-1; Animation.rest(u); return true end)
       end,
       stop=function(u) local c=visitRef[1]; if not c then return end; if log.startedAt and not log.completedAt and not log.interruptedAt then log.interruptedAt=D.App.runningTime; c.pending=c.pending-1 end end})
      doctor.unit:attachAction(action); assert(doctor.unit:start(action),"Medical device action unavailable")
     end
    end
   end)
  end)
 end
 refresh(facts)
 D.thread(function()
  local deadline=D.App.runningTime+10
  while (world.medicalVisit and world.medicalVisit.phase~="ready") or not find("ninilite") or not find("wuyun") do
   if not world.parent then return end
   -- The engine swallows thread errors; abort instead of hanging or nil-dereferencing below.
   if D.App.runningTime>=deadline then print("RecoveryVisit: actors unavailable, aborted")return end
   D.sleep(0.05)
  end
  for i,name in ipairs({"ninilite","wuyun"}) do
   local e=assert(find(name)); e.keyLeft=false; e.keyRight=false; e.storyCompanion=true; e.unit:stop(); e.unit.position=D.Vec2(x-(i==1 and 340 or 540),world.offset+155); e.unit.velocity=D.Vec2.zero; e.unit.decisionTree="AI:PlayerControl"
  end
  for _,name in ipairs({"moyu","moling"}) do local e=find(name); if e then if name=="moyu" then e.unit.position=D.Vec2(x-170,world.offset+155) end; c.doctors[#c.doctors+1]=e; c.departed[name]={startedX=e.unit.x,walked=0,lastX=e.unit.x} end end
  c.phase="ready"
 end)
 local ui=D.Node(); ui.tag="medical-recovery-status"; ui:addTo(D.Director.ui3D)
 local bg=D.DrawNode(); bg:addTo(ui)
 local label=D.Label("SourceHanSansCN-Regular",24); label.anchor=D.Vec2(0,1); label.alignment="Left"; label:addTo(ui); c.hint=label
 local nextCheck=0
 marker:schedule(function()
  if c.phase~="ready" then return false end
  local p=D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world end)
  if not p then return false end
  if D.App.runningTime>=nextCheck then
   facts=assert(service:summary()); local value=stage(facts); if value~=c.stage then refresh(facts) end
   nextCheck=D.App.runningTime+0.3
  end
  local paused=world.data.storyBusy or world.data.journalOpen or p.busy
  if facts.completed["medical-treatment"] and c.pending==0 then
   for i=#c.doctors,1,-1 do
    local e=c.doctors[i]; local trace=c.departed[e.name]
    trace.walked=trace.walked+math.abs(e.unit.x-trace.lastX); trace.lastX=e.unit.x
    e.busy=paused; e.keyLeft=false; e.keyRight=not paused and e.unit.x<world.sceneWidth-100
    if e.unit.x>=world.sceneWidth-100 then e.keyRight=false; e.unit:removeFromParent(); e:destroy(); trace.completedAt=D.App.runningTime; table.remove(c.doctors,i) end
   end
  end
  local allowed=not paused and not c.busy and c.pending==0 and math.abs(p.unit.x-x)<180 and stages[c.stage]
  if c.stage==2 then allowed=allowed and #c.doctors==0 end
  if c.stage==3 then allowed=allowed and facts.completed["lin-investigation"] end
  local near=not not allowed
  if near~=c.near then c.near=near; if near then c.view.visible=true; c.view:show() else c.view:hide(false) end end
  ui.size=D.App.bufferSize; ui.visible=not paused
  local width=math.max(300,math.min(1340,D.App.bufferSize.width-420)); label.position=D.Vec2(30,D.App.bufferSize.height-165); label.textWidth=width-30
  bg:clear(); bg:drawPolygon({D.Vec2.zero,D.Vec2(width,0),D.Vec2(width,150),D.Vec2(0,150)},D.Color(0xcc101b28)); bg.position=D.Vec2(15,D.App.bufferSize.height-300)
  local hint=c.stage==1 and "走近诊疗区接受治疗。伤后生命将保留至翌日康复。" or c.stage==2 and (#c.doctors>0 and "医师正在离开；稍后选择休息至翌日。" or "医师已处理毒伤，选择休息至翌日恢复。") or c.stage==3 and (facts.completed["lin-investigation"] and "走近同伴，讨论阿岩失踪与地面调查。" or "打开通讯第八页，明确点击林睿哲的新消息。") or "调查计划已确认。经A区电梯到C区左侧站台，与同伴集合。"
  label.text=string.format("导师 %.0f · 妮妮莉特 %.0f · 乌云 %.0f\n",c.hp[1],c.hp[2],c.hp[3])..(c.message or hint)
  return false
 end)
 world:slot("Cleanup",function() ui:removeFromParent() end)
 return c
end
return Visit
