-- Physical landings plus an explicit helical traversal action; checkpoints only at safe landings.
local Fox=require('Story.FoxCompanion');local D=require('Dora');local P=D.Platformer;local G=require('Factory.ControlPodGeometry');local Art=require('Factory.ControlPodArt');local Pod={}
function Pod.openAsync(options)
 options=options or {}
 local store,why=require('Story.ControlPodStore').open();if not store then return nil,why end
 local saved,err=store:writeAsync('enter');if not saved then return nil,err end
 local state=assert(store:load())
 local mentor=require('Data.Config').char=='charF' and 'charF' or 'charM'
 D.Cache:loadAsync({'spine:Spine/ControlPod/'..mentor..'.json|Spine/'..mentor..'.atlas','spine:Spine/ControlPod/ninilite.json|Spine/ninilite.atlas','spine:shujuyuan',Art.file,'Sound/control-pod-hatch.wav'});require('Story.FoxCompanion').loadAnimatedAsync()
 D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();P.Data.store:clear()
 local world=P.PlatformWorld();world.tag='ControlPod';world.sceneWidth=4000;world.offset=G.base;world:addTo(D.Director.entry);P.Data.store.world=world
 world.camera.boundary=D.Rect(0,0,4000,4700);world.camera.zoom=.83
 local c={world=world,store=store,state=state,floor=state.floor,phase='loading',actors={},held={},closed=false};world.controlPod=c
 local art=Art.build(world);c.art=art
 world:getLayer(-10);world:getLayer(20)
 local barrierDef=D.BodyDef();barrierDef.type='Static';barrierDef:attachPolygon(35,420,1,1,0)
 c.barrier=D.Body(barrierDef,world,D.Vec2(G.doorX-200,G.floorY(7)+210));c.barrier.group=4;c.barrier.tag='control-pod-sealed-hatch';c.barrier:addTo(world)
 local function actor(name,x)
  local marker=D.Node();D.Entity({name=name,controlPodActor=true,spawnMarker=marker});local entity=assert(D.Group({'controlPodActor','spawnMarker'}):find(function(e)return e.spawnMarker==marker end))
  local def=D.Dictionary();def.playable='spine:Spine/ControlPod/'..name..'.json|Spine/'..name..'.atlas';def.bodyType='Kinematic';def.size=D.Size(80,300);def.scale=1;def.defaultFaceRight=true;def.linearAcceleration=D.Vec2.zero;def.actions=D.Array({})
  local u=assert(P.Unit(def,world,entity,D.Vec2(x,G.floorY(c.floor)+150)));u.group=1;u.playable.y=-150;u.playable.recovery=.2;u.faceRight=true;u:addTo(world);entity.unit=u;u.playable:play('idle',true)
  local a={unit=u,model=u.playable,footOffset=150,animation='idle'};c.actors[#c.actors+1]=a;return a
 end
 c.player=actor(mentor,520);c.nini=actor('ninilite',360)
 local fox=require('Story.FoxCompanion').createAnimated();fox.fliped=true;fox.position=D.Vec2(220,G.floorY(c.floor));fox:addTo(world)
 c.fox={unit=fox,model=fox,footOffset=0,isFox=true};c.actors[#c.actors+1]=c.fox
 c.researchers={};local completed=require('Story.Service').open():summary().completed;c.dialogueComplete=completed['control-pod-researchers'] or false;c.aftermathComplete=completed['roof-aftermath'] or false
 for i=1,3 do
  local m=assert(D.Spine('shujuyuan'));m.position=D.Vec2(2510+(i-1)*220,G.floorY(7));m.fliped=i~=2;m.recovery=.2;m:play('idle1',true);m:addTo(world,20)
  local label=D.Label('SourceHanSansCN-Regular',18);label.text='研发人员 '..i;label.position=m.position+D.Vec2(0,330);label:addTo(world,21)
  c.researchers[i]={model=m,label=label}
 end
 local function pose(a,x,y,depth,walking,right)
  a.unit.position=D.Vec2(x,y+a.footOffset);local order=depth and depth>0 and 20 or depth and -10 or 20;a.unit.order=order;world:moveChild(a.unit,order)
  if a.isFox then a.model.fliped=right else a.unit.faceRight=right end
  local animation=walking and 'fmove' or 'idle'
  if a.isFox then
   require('Story.FoxMovement').setVelocity(a.model,walking and (right and Fox.walkSpeed or -Fox.walkSpeed)or 0)
   a.animation=animation
  elseif a.animation~=animation then a.model.recovery=.2;a.model:play(animation,true);a.animation=animation end
 end
 local function rest()
  for _,a in ipairs(c.actors)do local right;if a.isFox then right=a.model.fliped else right=a.unit.faceRight end;pose(a,a.unit.x,a.unit.y-a.footOffset,nil,false,right)end
 end
 local function openedPose()
  art.door.angleY=-105
  if c.barrier then c.barrier:removeFromParent();c.barrier=nil end
 end
 if state.doorOpen then openedPose()end
 local hud=require('UI.HUDControl')();hud.topControl.visible=false;hud.message.visible=false;hud.weapon.visible=false;hud.tag='control-pod-hud';hud:addTo(D.Director.ui3D);D.emit('HUD.DisplayMove',true);c.hud=hud
 hud.move.onMove=function(key,down)c.held[key=='keyLeft' and 'left' or 'right']=down end
 local up=require('UI.Skill')({visible=true,text='上楼 E'});up.position=hud.weapon.position;up:addTo(hud.skillArea);c.up=up
 local down=require('UI.Skill')({visible=true,text='下楼 Q'});down.position=hud.weapon.position-D.Vec2(296,0);down:addTo(hud.skillArea);c.down=down
 local door=require('UI.Skill')({visible=false,text='开门 E'});door.position=hud.weapon.position;door:addTo(hud.skillArea);c.doorButton=door
 local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D);c.ui=ui
 local bg=D.DrawNode();bg:addTo(ui)
 local label=D.Label('SourceHanSansCN-Regular',24);label.anchor=D.Vec2(0,1);label.alignment='Left';label:addTo(ui);c.status=label
 local leave=require('UI.InputButton')({text='返回厂区',textBG=''});leave:slot('Tapped'):clear();leave.scaleX=.5;leave.scaleY=.5;leave:addTo(ui);c.leave=leave
 local retry=require('UI.InputButton')({text='重试保存',textBG=''});retry:slot('Tapped'):clear();retry.scaleX=.5;retry.scaleY=.5;retry.visible=false;retry:addTo(ui);c.retry=retry
 local function layout()
  ui.size=D.App.bufferSize;label.position=D.Vec2(30,ui.height-25);label.textWidth=ui.width-400;leave.position=D.Vec2(ui.width-215,ui.height-75);retry.position=D.Vec2(ui.width-215,ui.height-135)
  bg:clear();bg:drawPolygon({D.Vec2(0,ui.height),D.Vec2(ui.width,ui.height),D.Vec2(ui.width,ui.height-150),D.Vec2(0,ui.height-150)},D.Color(0xdf101b28))
 end
 layout();ui:gslot('AppChange',function(name)if name=='Size'then layout()end end)
 function c:saveAsync(kind,proof)
  self.phase='saving';self.pending={kind,proof};local ok,why=store:writeAsync(kind,proof)
  if self.closed then return false,'CLOSED'end
  if ok then self.pending=nil;self.error=nil;self.state=assert(store:load());self.phase='ready'
  else self.phase='save-error';self.error=why end
  return ok,why
 end
 function c:stairs(direction)
  if self.phase~='ready'then return false,'BUSY'end
  local target=self.floor+direction
  if (direction~=1 and direction~=-1)or target<1 or target>7 then return false,'NO_STAIRS'end
  if math.abs(self.player.unit.x-520)>170 then self.message='走近左侧旋转阶梯，再使用上楼或下楼。';return false,'OUT_OF_RANGE'end
  self.phase='stairs';self.stairDirection=direction;self.message=nil;self.held={}
  D.thread(function()
   local from=self.floor;local start=D.App.runningTime;local proof={from=from,to=target,samples=0,minX=1e9,maxX=-1e9};local previous={};local origins={};local speeds={};local durations={};local total=0
   for i,a in ipairs(self.actors)do origins[i]=a.unit.x;speeds[i]=260;durations[i]=G.duration;total=math.max(total,math.abs(origins[i]-520)/speeds[i]+(i-1)*.2+durations[i]+(i-1)*150/speeds[i])end
   while not self.closed do
    local elapsed=D.App.runningTime-start
    for i,a in ipairs(self.actors)do
     local approach=math.abs(origins[i]-520)/speeds[i];local begin=approach+(i-1)*.2;local duration=durations[i]
     local t=math.max(0,math.min(1,(elapsed-begin)/duration));local p=from-1+direction*t;local x,y,depth=G.point(p)
     if elapsed<begin then x=origins[i]+(520-origins[i])*math.min(1,elapsed/math.max(.001,approach));y=G.floorY(from);depth=nil
     elseif elapsed>begin+duration then x=520-math.min((i-1)*150,(elapsed-begin-duration)*speeds[i]);y=G.floorY(target);depth=nil end
     local right=direction>0;local walking=false;if previous[i] then local dx=x-previous[i].x;local dy=y-previous[i].y;right=math.abs(dx)>.01 and dx>0 or math.abs(dx)<=.01 and previous[i].right;walking=math.abs(dx)+math.abs(dy)>.01 end;pose(a,x,y,depth,walking,right);previous[i]={x=x,y=y,right=right}
     if i==1 then proof.samples=proof.samples+1;proof.minX=math.min(proof.minX,a.unit.x);proof.maxX=math.max(proof.maxX,a.unit.x);proof.endY=a.unit.y-a.footOffset end
    end
    if elapsed>=total then break end;D.sleep()
   end
   if self.closed then return end
   self.floor=target
   for i,a in ipairs(self.actors)do pose(a,520-(i-1)*150,G.floorY(target),nil,false,true)end
   proof.seconds=D.App.runningTime-start;self.lastTraversal=proof;self:saveAsync('floor',proof)
  end)
  return true
 end
 function c:openDoor()
  if self.phase~='ready'then return false,'BUSY'end
  if self.state.doorOpen then
   if self.floor~=7 or self.player.unit.x<2150 then self.message='穿过舱门，走近里面的研发人员，再交谈。';return false,'OUT_OF_RANGE'end
   if self.dialogueComplete then
    if self.player.unit.x<3250 then self.message='沿房间向右走到屋顶通道，再使用屋顶按钮。';return false,'OUT_OF_RANGE'end
    self.phase='leaving';self.held={};D.thread(function()local roof,why=require('Factory.Roof').openAsync();if not roof then self.phase='ready';self.error=why end end);return true
   end
   self.phase='launching';D.thread(function()self.phase='ready';local stage,why=require('Factory.ControlPodDialogue').openAsync(self);if not stage then self.error=why;self.phase='ready'end end);return true
  end
  if self.floor~=7 or math.abs(self.player.unit.x-(G.doorX-340))>210 then self.message='走近第七层门边的控制台。';return false,'OUT_OF_RANGE'end
  self.phase='door';self.held={};rest();self.message=nil
  D.thread(function()
   local started=D.App.runningTime;local proof={playerX=self.player.unit.x,soundHandle=D.Audio:play('Sound/control-pod-hatch.wav')};self.sound=proof.soundHandle
   while not self.closed do
    local elapsed=D.App.runningTime-started;local t=math.max(0,math.min(1,(elapsed-.2)/2.2));local eased=t*t*(3-2*t)
    art.door.angleY=-105*eased
    if elapsed>=2.8 then break end;D.sleep()
   end
   if self.closed then return end
   openedPose();proof.seconds=D.App.runningTime-started;proof.angle=math.abs(art.door.angleY);proof.barrierRemoved=c.barrier==nil;self.lastDoor=proof;self:saveAsync('door',proof)
  end)
  return true
 end
 up:slot('TapBegan',function()c:stairs(1)end);down:slot('TapBegan',function()c:stairs(-1)end);door:slot('TapBegan',function()c:openDoor()end)
 -- Consume key events so a quick tap between two frames is not lost.
 local input=D.Node();input.keyboardEnabled=true;input:addTo(world)
 input:slot('KeyDown',function(key)
  if c.phase~='ready' or world.data.storyBusy then return end
  if key=='E' then if c.floor==7 then c:openDoor()else c:stairs(1)end
  elseif key=='Q' then c:stairs(-1)end
 end)
 retry:slot('Tapped',function()if c.phase=='save-error' and c.pending then D.thread(function()c:saveAsync(table.unpack(c.pending))end)end end)
 leave:slot('Tapped',function()
  if c.phase~='ready'then return end;c.phase='leaving';D.thread(function()
   local ok,why=store:writeAsync('leave');if ok then require('Academy.Navigation').returnToRoomAsync('Factory',{infiltrationRoute=true,spawn=4100})else c.phase='ready';c.error=why end
  end)
 end)
 world:slot('Cleanup',function()c.closed=true;if c.sound then D.Audio:stop(c.sound)end;hud:removeFromParent();ui:removeFromParent()end)
 world:schedule(function(dt)
  local x=c.player.unit.x;local y=c.player.unit.y-c.player.footOffset
  if c.phase=='ready' and not world.data.storyBusy then
   local direction=c.held.left~=c.held.right and (c.held.right and 1 or -1)or 0
   if direction~=0 then
    local nextX=math.max(210,math.min(c.floor==7 and 3500 or 710,x+direction*260*dt))
    if c.barrier and c.floor==7 then world:raycast(D.Vec2(x,y+140),D.Vec2(nextX+direction*42,y+140),false,function(body)if body==c.barrier then nextX=x;return true end;return false end)end
    pose(c.player,nextX,G.floorY(c.floor),nil,nextX~=x,direction>0)
   else pose(c.player,x,y,nil,false,c.player.unit.faceRight)end
   -- Followers finish catching up after input is released, then recover to idle.
   local followDirection=c.player.unit.faceRight and 1 or -1
   for i=2,#c.actors do
    local a=c.actors[i];local target=math.max(150,math.min(c.floor==7 and 3500 or 710,c.player.unit.x-followDirection*(i-1)*150))
    local delta=target-a.unit.x;local walking=math.abs(delta)>5
    local right;if walking then right=delta>=0 elseif a.isFox then right=a.model.fliped else right=a.unit.faceRight end
    local speed=a.isFox and Fox.walkSpeed or 240
    local step=walking and math.max(-speed*dt,math.min(speed*dt,delta))or 0
    pose(a,a.unit.x+step,G.floorY(c.floor),nil,walking,right)
   end
  end
  world.camera.position=D.Vec2(c.floor==7 and math.max(1080,math.min(2920,x+350))or 1080,math.max(400,math.min(4180,y+190)))
  up.visible=c.phase=='ready' and c.floor<7;down.visible=c.phase=='ready' and c.floor>1;door.visible=c.phase=='ready' and c.floor==7;retry.visible=c.phase=='save-error';leave.visible=c.phase=='ready'
  -- Label.setText rebuilds glyph layout even for identical strings.
  local doorText=c.dialogueComplete and '屋顶 E' or c.state.doorOpen and '交谈 E' or '开门 E'
  if door.textLabel.text~=doorText then door.textLabel.text=doorText end
  local text=string.format('控制舱 · 第 %d / 7 层\n%s\n%s',c.floor,c.error and '记录尚未保存，请重试保存后继续。' or c.message or (c.phase=='stairs' and (c.stairDirection==-1 and '沿旋转阶梯下行，同伴正在跟上。' or '沿旋转阶梯上行，同伴正在跟上。') or c.phase=='door' and '门锁解除，金属舱门正在旋转开启。' or c.aftermathComplete and '乌云已进入漩涡。返回厂区，与同伴汇合。' or c.dialogueComplete and '发射炮在顶楼玻璃罩内，沿房间向右走到屋顶通道。' or c.state.doorOpen and '舱门已开启。穿过舱门走近研发人员，再交谈。' or c.floor==7 and '使用摇杆走近右侧控制台，再按开门。' or '走近左侧旋转阶梯，使用上楼；摇杆可在平台移动。'),c.aftermathComplete and '导师、妮妮莉特与狐狸同行' or '乌云留在厂区看守 · 导师、妮妮莉特与狐狸同行')
  if label.text~=text then label.text=text end
  return false
 end)
 c.phase='ready'
 return world
end
return Pod
