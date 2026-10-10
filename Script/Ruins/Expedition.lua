-- Original 2-10: physical signal, authored twins, escort, diary and data recovery.
local D=require("Dora")
local P=D.Platformer
local Animation=require("CombatAnimation")
local Expedition={signalX=6200,ayanX=8500}
function Expedition.attach(world)
 local service=assert(require("Story.Service").open()); local facts=assert(service:summary())
 local c={phase="loading",logs={},escorted={},hp=require("Factory.Health").load(),stage=1}; world.ruinsExpedition=c
 local support=require("Ground.LifeSupport").new(nil,world.auxiliaryVariant); support.hp=c.hp; c.support=support
 local supportView=require("Ground.SupportView").create(world)
 local supplies={}
 for i,x in ipairs({2000,4000,6800,8000}) do local node=D.DrawNode(); node:drawDot(D.Vec2.zero,14,D.Color(0xffffd279)); node.position=D.Vec2(x,world.offset+35); node:addTo(world); supplies[#supplies+1]={id="ruins-gold-"..i,x=x,node=node} end
 local function find(name) return D.Group({"name","unit"}):find(function(e) return e.unit.world==world and e.name==name end) end
 local function player() return D.Group({"player","unit"}):find(function(e) return e.unit.world==world and e.player end) end
 local function stage() return not facts.completed["ruins-twins"] and 1 or not facts.completed["ayan-found"] and 2 or not facts.completed["ayan-recovery"] and 3 or 4 end
 local markers={}
 for id,x in pairs({["ruins-twins"]=Expedition.signalX,["ayan-found"]=Expedition.ayanX,["ayan-recovery"]=Expedition.ayanX}) do local m=D.Node(); m.tag=require("Story.Catalog")[id].discoveryTag; m.position=D.Vec2(x,world.offset+150); m:addTo(world); markers[id]=m end
 local beacon=D.DrawNode(); beacon.position=D.Vec2(Expedition.signalX+90,world.offset+55); beacon:addTo(world); c.beacon=beacon
 beacon:drawPolygon({D.Vec2(-25,-20),D.Vec2(25,-20),D.Vec2(25,20),D.Vec2(-25,20)},D.Color(0xff596776)); beacon:drawDot(D.Vec2.zero,12,D.Color(0xffff5353))
 local ray=D.DrawNode(); ray:addTo(beacon)
 ray:schedule(function() ray:clear(); ray:drawSegment(D.Vec2(0,25),D.Vec2(0,100+math.sin(D.App.runningTime*4)*20),4,D.Color(0x99ff5353)); return false end)
 local ui=D.Node(); ui.tag="ruins-explore-status"; ui:addTo(D.Director.ui3D)
 local bg=D.DrawNode(); bg:addTo(ui)
 local hint=D.Label("SourceHanSansCN-Regular",24); hint.anchor=D.Vec2(0,1); hint.alignment="Left"; hint:addTo(ui); c.hint=hint
 local arrow=D.DrawNode(); arrow:addTo(ui)
 local function terminal(tag,x,title,buttons,callback)
  local m=D.Node(); m.position=D.Vec2(x,world.offset+150); m:addTo(world)
  local v=require("UI.Interaction")({text=title,buttons=buttons,fliped=false}); v.tag=tag; v.transformTarget=m; v.scaleX=0.325; v.scaleY=0.325; v.visible=false; v.menu.enabled=false; v:addTo(world)
  local near=false
  m:schedule(function()
   local p=player(); local eligible=tag=="ruins-twins-terminal" and c.stage==1 or tag=="ayan-found-terminal" and c.stage==2 or tag=="ayan-recovery-terminal" and c.stage==3
   if tag=="ruins-return-route" then eligible=c.stage==4 end
   local value=c.phase=="exploring" and not c.busy and p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-x)<180 and eligible
   if (c.stage==2 or c.stage==3) and math.abs(x-Expedition.ayanX)<1 then value=value and c.readyAtBody end
   if c.stage>=2 then for _,name in ipairs({"vika","vivi"}) do local e=find(name); value=value and e and math.abs(e.unit.x-p.unit.x)<700 end end
   value=not not value
   if near~=value then near=value; if near then v.visible=true; v:show() else v:hide(false) end end
   return false
  end)
  v:slot("Tapped",function(i) if not near then return end; callback(i) end); return v
 end
 c.returnRoute=terminal("ruins-return-route",Expedition.ayanX+300,"返回路线",{{"带孩子返回",""}},function()
  if c.stage~=4 or c.busy then return end
  D.thread(function() local opened,err=require("Ruins.Return").openAsync(world);if not opened then c.message=tostring(err) end end)
 end)
 local function refresh() facts=assert(service:summary()); c.stage=stage() end
 local function dataRecoveryAsync()
  c.phase="recovering"; c.busy=true; require("Story.Flow").freeze(world,true)
  local log={startedAt=D.App.runningTime}; c.dataRecovery=log
  local particles=D.DrawNode(); particles:addTo(world)
  local began=D.App.runningTime
  while D.App.runningTime-began<1.4 do
   local t=(D.App.runningTime-began)/1.4; particles:clear(); local p=assert(player())
   for i=1,18 do local k=math.min(1,t+i/50); local x=(Expedition.ayanX+230)*(1-k)+p.unit.x*k; local y=(world.offset+70)*(1-k)+(p.unit.y+35)*k+math.sin(k*math.pi)*120; particles:drawDot(D.Vec2(x,y),4,D.Color(0xff8bdcfc)) end
   D.sleep(0.02)
  end
  particles:removeFromParent(); if c.body then c.body:removeFromParent(); c.body=nil end; if c.diary then c.diary.visible=false end
  log.completedAt=D.App.runningTime; c.phase="exploring"; c.busy=false; require("Story.Flow").freeze(world,false)
 end
 local function read(id)
  if c.busy then return end; c.busy=true
  D.thread(function()
   local opened,err=require("Story.Flow").openAsync(id,world,function()
    refresh(); c.busy=false
    if id=="ayan-recovery" then D.thread(dataRecoveryAsync) end
   end)
   if not opened then c.busy=false; c.message=tostring(err) end
  end)
 end
 local function confrontAsync()
  if c.busy then return end; c.busy=true; require("Story.Flow").freeze(world,true)
  local p=assert(player()); local n=assert(find("ninilite")); local w=assert(find("wuyun")); local a=assert(find("vika")); local b=assert(find("vivi"))
  for _,row in ipairs({{n,-200},{w,-400},{a,220},{b,430}}) do row[1].unit:stop(); row[1].unit.position=D.Vec2(p.unit.x+row[2],world.offset+155); row[1].unit.velocity=D.Vec2.zero end
  a.unit.faceRight=false; n.unit.faceRight=true; a.unit.group=2; P.Data:setRelation(1,2,"Enemy")
  local log={startedAt=D.App.runningTime,hpBefore=support.hp[1],authoredTwinAttack=false}; c.confrontation=log
  local shield=D.DrawNode(); shield:addTo(world); c.shield=shield
  local protected=false; local projectileHit=false
  local guard="ruinsFireGuard"; Animation.configure(n.unit,"ninilite")
  n.unit.playable:slot("attack"):set(function()
   if n.unit:isDoing(guard) and not protected then protected=true; log.guardAt=D.App.runningTime; shield:drawDot(D.Vec2.zero,170,D.Color(0x44ff9a38)); shield.position=p.unit.position end
  end)
  P.UnitAction:add(guard,{priority=5,reaction=0,recovery=0.2,available=function() return true end,create=function(u) return D.once(function() log.guardDuration=Animation.playOnceAsync(u,"throw"); log.guardCompletedAt=D.App.runningTime; Animation.rest(u); return true end) end})
  n.unit:attachAction(guard); assert(n.unit:start(guard))
  -- Twins have no authored attack track. This complete procedural pulse has
  -- explicit windup, a real projectile release, recoil and rest mixing.
  local attack="ruinsTwinPulse"; a.unit.data.combatRest="idle"
  -- Registered actions outlive this scene; retain their context only while executing.
  local pulseRef=setmetatable({c,world,p,support},{__mode="v"})
  P.UnitAction:add(attack,{priority=5,reaction=0,recovery=0.2,available=function() return pulseRef[1]~=nil and pulseRef[2]~=nil end,create=function(u)
   local c,world,p,support=pulseRef[1],pulseRef[2],pulseRef[3],pulseRef[4]
   if not c or not world or not p or not support then return function() return true end end
   return D.once(function()
   local began=D.App.runningTime; local fired=false
   while D.App.runningTime-began<1.2 do
    local t=D.App.runningTime-began; u.playable.angle=t<0.55 and -12*t/0.55 or -12*math.max(0,(1.2-t)/0.65)
    if t>=0.55 and not fired then
     fired=true; log.attackAt=D.App.runningTime
     local def=P.BulletDef(); def.lifeTime=2; def.highSpeedFix=true; def.gravity=D.Vec2.zero; def:setAsCircle(14); def:setVelocity(0,500)
     def.face=P.Face(function() local node=D.DrawNode(); node:drawDot(D.Vec2.zero,18,D.Color(0xffc66bff)); node:drawDot(D.Vec2.zero,9,D.Color(0xfff6d8ff)); return node end)
     local bullet=P.Bullet(def,u); local allow=P.TargetAllow(); allow:allow("Enemy",true); allow.terrainAllowed=false; bullet.targetAllow=allow:toValue()
     bullet.position=D.Vec2(u.x-60,p.unit.y); bullet:addTo(world); c.projectile=bullet
     bullet:slot("HitTarget",function(projectile,target)
      if projectileHit then return end; projectileHit=true; log.hitAt=D.App.runningTime; log.blocked=protected; log.actualTarget=target==p.unit and "mentor" or "party"
      if not protected then support.hp[1]=math.max(0,support.hp[1]-12) end
      projectile.hitStop=true
     end)
    end
    D.sleep(0.01)
   end
   u.playable.angle=0; log.completedAt=D.App.runningTime; Animation.rest(u); return true
  end) end})
  a.unit:attachAction(attack); assert(a.unit:start(attack)); local deadline=D.App.runningTime+5
  -- The engine swallows thread errors; continue the cleanup instead of a silent stall.
  while not log.completedAt or not log.guardCompletedAt or not projectileHit do
   if D.App.runningTime>=deadline then print("RuinsExpedition: confrontation did not complete, continuing")break end
   D.sleep(0.01)
  end
  a.unit.group=1; shield:removeFromParent(); log.hpAfter=support.hp[1]
  c.busy=false; read("ruins-twins")
 end
 c.twins=terminal("ruins-twins-terminal",Expedition.signalX,"求救信号",{{"查看情况",""}},function() D.thread(confrontAsync) end)
 c.found=terminal("ayan-found-terminal",Expedition.ayanX,"阿岩的去向",{{"检查阿岩",""}},function() read("ayan-found") end)
 c.recovery=terminal("ayan-recovery-terminal",Expedition.ayanX,"阿岩的记录",{{"阅读日记",""},{"回收数据",""}},function(i)
  if i==1 then D.thread(function() local opened,err=require("Academy.Companion").openAsync("ayan",world,"information"); if not opened then c.message=tostring(err) end end)
  else read("ayan-recovery") end
 end)
 D.thread(function()
  for _,name in ipairs({"vika","vivi"}) do
   D.Cache:loadAsync("spine:"..name); if not world.parent then return end
   D.Entity({player=false,name=name,position=D.Vec2(Expedition.signalX+(name=="vika" and 220 or 430),world.offset),faceRight=false,base=true,storyCompanion=true,decisionTree="AI:PlayerControl"})
  end
  if not facts.completed["ayan-recovery"] then
   D.Cache:loadAsync("spine:ayan"); if not world.parent then return end
   local body=assert(D.Spine("ayan")); c.body=body; body.position=D.Vec2(Expedition.ayanX+230,world.offset); body.recovery=0.2; body:addTo(world)
   local log={startedAt=D.App.runningTime}; c.bodyPose=log; local ended=false
   body:slot("AnimationEnd",function(name) if name=="lose" then ended=true; log.completedAt=D.App.runningTime; body.speed=0 end end)
   log.duration=body:play("lose",false); local deadline=D.App.runningTime+log.duration+2
   -- The engine swallows thread errors; continue the scene instead of a silent stall.
   while not ended do
    if D.App.runningTime>=deadline then print("RuinsExpedition: ayan lose did not complete, continuing")break end
    D.sleep(0.02)
   end
   -- The authored lose fades every attachment to zero at its final frame.
   -- Keep its actual full completion above; construct a separate, held corpse
   -- from the inspected opaque kneeling pose for the persistent search scene.
   body:removeFromParent()
   body=assert(D.Spine("ayan")); c.body=body; body.position=D.Vec2(Expedition.ayanX+230,world.offset); body.visible=false; body.recovery=0; body:addTo(world)
   body:play("lose",false); local poseBegan=D.App.runningTime
   D.sleep(0.6); body.speed=0; body.visible=true; body.recovery=0.2
   c.bodyHeldPose={sampleSeconds=D.App.runningTime-poseBegan,opaquePoseSeconds=0.6,originalDeathCompleted=true}
   local diary=D.DrawNode(); c.diary=diary; diary.position=D.Vec2(Expedition.ayanX+140,world.offset+30); diary:addTo(world)
   diary:drawPolygon({D.Vec2(-18,-22),D.Vec2(18,-22),D.Vec2(18,22),D.Vec2(-18,22)},D.Color(0xffd0b48c)); diary:drawSegment(D.Vec2(-12,12),D.Vec2(12,12),3,D.Color(0xff785b45))
  end
  refresh(); c.phase="exploring"
 end)
 local gather=require("UI.Skill")({visible=true,text="集合 K"}); local hud=D.Director.ui3D:getChildByTag("ground-hud"); gather.position=hud.weapon.position-D.Vec2(296,0); gather:addTo(hud.skillArea)
 local gathering=false; gather:slot("TapBegan",function() gathering=true end); gather:slot("TapEnded",function() gathering=false end)
 local tick=D.Node(); tick:addTo(world); local last=D.App.runningTime; local nextRead=0
 tick:schedule(function()
  local p,n,w=player(),find("ninilite"),find("wuyun"); if c.phase=="loading" or not p or not n or not w then last=D.App.runningTime; return false end
  local now=D.App.runningTime; local dt=math.min(1,now-last); last=now
  if now>=nextRead then refresh(); nextRead=now+0.4 end
  local paused=c.busy or p.busy or world.data.storyBusy or world.data.journalOpen
  local positions={p.unit.x,n.unit.x,w.unit.x}; local offsets=c.stage==1 and {ninilite=-180,wuyun=-400} or {ninilite=180,wuyun=-180,vika=330,vivi=-330}
  local atBody=(c.stage==2 or c.stage==3) and math.abs(p.unit.x-Expedition.ayanX)<250
  if atBody then offsets={ninilite=-220,wuyun=-440,vika=420,vivi=560} end
  c.readyAtBody=atBody
  for _,name in ipairs({"ninilite","wuyun","vika","vivi"}) do local e=find(name); if e then
   -- Academy roaming actions normally recheck their decision tree every two
   -- seconds. A close formation needs prompt braking and turning instead of
   -- oscillating hundreds of pixels past the target on every recheck.
   if not e.ruinsFollowResponsive then
    for _,action in ipairs({"fmove","idle","turn"}) do local a=e.unit:getAction(action); if a then a.reaction=0.05 end end
    e.ruinsFollowResponsive=true
   end
   local offset=offsets[name]; if offset then
    if atBody and math.abs(e.unit.x-(p.unit.x+offset))>45 then c.readyAtBody=false end
    local target=p.unit.x+((gathering or D.Keyboard:isKeyDown("K")) and offset*0.4 or offset)
    e.keyLeft=not paused and e.unit.x>target+30; e.keyRight=not paused and e.unit.x<target-30
    if name=="vika" or name=="vivi" then local trace=c.escorted[name] or {walked=0,lastX=e.unit.x}; trace.walked=trace.walked+math.abs(e.unit.x-trace.lastX); trace.lastX=e.unit.x; c.escorted[name]=trace end
   else e.keyLeft=false; e.keyRight=false end
  end end
  if not paused then
   support:update(dt,positions)
   for _,drop in ipairs(supplies) do if support:collect(drop.id,12,drop.x,p.unit.x,n.unit.x) then drop.node.visible=false end end
   if support.hp[1]<=0 or support.hp[2]<=0 or support.hp[3]<=0 then
    c.phase="evacuating"; require("Story.Flow").freeze(world,true)
    D.thread(function() require("Academy.Navigation").returnToRoomAsync("TrainA") end); return true
   end
  end
  supportView:update(support,math.min(table.unpack(positions)),math.max(table.unpack(positions)))
  ui.size=D.App.bufferSize; ui.visible=not paused; hint.position=D.Vec2(30,ui.height-165); hint.textWidth=math.min(1310,ui.width-450)
  bg:clear(); bg:drawPolygon({D.Vec2.zero,D.Vec2(hint.textWidth+30,0),D.Vec2(hint.textWidth+30,150),D.Vec2(0,150)},D.Color(0xcc101b28)); bg.position=D.Vec2(15,ui.height-300)
  local target=c.stage==1 and Expedition.signalX or c.stage<4 and Expedition.ayanX or Expedition.ayanX+300
  hint.text=string.format("求救调查 · 辅助机 %d · 金粉 %.1f · 导师 %.0f / 妮妮莉特 %.0f / 乌云 %.0f\n%s\n%s · 距离 %.0f",support.machineHP,support.gold,support.hp[1],support.hp[2],support.hp[3],c.message or (c.stage==1 and "沿红色求救信号前行，走近发信器查看情况。" or c.stage==2 and "双胞胎已指出方向；带着她们继续向右寻找阿岩。" or c.stage==3 and "阿岩的日记已经找到。阅读记录，再回收手环数据。" or "阿岩的数据已进入手环。向右300步走到返回路线，护送孩子返回。"),p.unit.x<target and "向右" or "向左",math.abs(p.unit.x-target))
  arrow.position=D.Vec2(ui.width-230,ui.height-220); arrow:clear(); local sign=p.unit.x<target and 1 or -1
  arrow:drawSegment(D.Vec2(-50*sign,0),D.Vec2(50*sign,0),7,D.Color(0xffff7777)); arrow:drawSegment(D.Vec2(50*sign,0),D.Vec2(18*sign,28),7,D.Color(0xffff7777)); arrow:drawSegment(D.Vec2(50*sign,0),D.Vec2(18*sign,-28),7,D.Color(0xffff7777))
  return false
 end)
 world:slot("Cleanup",function() ui:removeFromParent() end)
 return c
end
return Expedition
