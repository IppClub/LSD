local D=require('Dora');local G=require('Factory.RoofGeometry');local Art=require('Factory.RoofArt');local Roof={}
function Roof.openAsync(options)
 local store,why=require('Story.RoofStore').open();if not store then return nil,why end
 local ok,err=store:writeAsync('enter');if not ok then return nil,err end;local state=assert(store:load())
 local mentor=require('Data.Config').char=='charF' and 'charF' or 'charM'
 D.Cache:loadAsync({Art.file,'spine:Spine/Roof/wuyun.json|Spine/wuyun.atlas','spine:Spine/Roof/'..mentor..'.json|Spine/'..mentor..'.atlas','spine:Spine/Roof/ninilite.json|Spine/ninilite.atlas'})
 D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear()
 local world=D.Platformer.PlatformWorld();world.tag='FactoryRoof';world.sceneWidth=G.width;world:addTo(D.Director.entry);D.Platformer.Data.store.world=world
 world.camera.boundary=D.Rect(-650,-320,G.width+650,2520);world.camera.zoom=.9
 local c={world=world,store=store,state=state,stage=state.stage,phase='ready',held={},actors={},closed=false};world.roof=c
 local backdrop=D.DrawNode();backdrop:drawPolygon({D.Vec2(-650,-320),D.Vec2(G.width,-320),D.Vec2(G.width,2200),D.Vec2(-650,2200)},D.Color(0xff1b2e3d));backdrop:addTo(world,-100)
 Art.sprite('catwalk',world,260,G.base-95,650,115,-20);Art.sprite('stairs',world,690,G.base-25,780,510,-20)
 Art.sprite('catwalk',world,1100,G.stairY-100,470,120,-20);Art.sprite('climbWall',world,1430,G.stairY,320,G.top-G.stairY,-15)
 for x=1610,3800,600 do Art.sprite('catwalk',world,x,G.top-100,720,120,-20)end
 c.dome=Art.dome(world,2820,G.top,1220)
 c.holds=require('Factory.RoofHolds').build(world,{mentor,'ninilite'})
 local terrain=D.BodyDef();terrain.type='Static';terrain:attachPolygon(D.Vec2(250,G.base-6),500,12,0,1,1,0);terrain:attachPolygon(D.Vec2(1070,G.stairY-6),440,12,0,1,1,0);terrain:attachPolygon(D.Vec2(2590,G.top-6),2620,12,0,1,1,0)
 for i=0,14 do local x,y=G.stairPoint(i/14);terrain:attachPolygon(D.Vec2(x,y-6),60,12,0,1,1,0)end
 c.floorBody=D.Body(terrain,world,D.Vec2.zero);c.floorBody.group=D.Platformer.Data.groupTerrain;c.floorBody:addTo(world)
 local wallDef=D.BodyDef();wallDef.type='Static';wallDef:attachPolygon(20,G.top-G.stairY,1,1,0)
 c.wallBody=D.Body(wallDef,world,D.Vec2(G.wallX+10,(G.top+G.stairY)/2));c.wallBody.group=D.Platformer.Data.groupTerrain;c.wallBody:addTo(world)
 for i,name in ipairs({mentor,'ninilite'})do
  local model=assert(D.Spine('Spine/Roof/'..name..'.json|Spine/'..name..'.atlas'));model.position=D.Vec2((c.stage==2 and G.landingX+160 or c.stage==1 and G.stairEnd+100 or 280)-(i-1)*150,G.floorY(c.stage));model.recovery=.2;model:play('idle',true);model:addTo(world,20)
  c.actors[i]={model=model,name=name,animation='idle'}
 end
 c.player=c.actors[1];c.nini=c.actors[2]
 c.wuyun=assert(D.Spine('Spine/Roof/wuyun.json|Spine/wuyun.atlas'));c.wuyun.position=D.Vec2(3160,G.top);c.wuyun.fliped=true;c.wuyun.recovery=.2;c.wuyun:play('idle',true);c.wuyun:addTo(world,20)
 c.beacon=require('Factory.RoofBeacon').attach(world,c.wuyun);c.vortex=require('Factory.RoofVortex').attach(world)
 c.confrontationComplete=require('Story.Service').open():summary().completed['roof-confrontation'] or false
 if c.confrontationComplete then
  local duel,why=require('Story.RoofDuelStore').open();if not duel then return nil,why end;c.duelComplete=assert(duel:load()).completed
  c.beacon:activate();c.wuyun:play('prepare',true)
  c.player.model.x=2490;c.nini.model.x=2340
  c.aftermathComplete=require('Story.Service').open():summary().completed['roof-aftermath'] or false
  if c.aftermathComplete then c.wuyun.visible=false;c.beacon.mark.visible=false;c.vortex:open();c.beacon.beam.scaleX=2 end
 end
 local function pose(a,x,y,walking,right)
  a.model.position=D.Vec2(x,y);a.model.fliped=not right
  local animation=walking and 'fmove' or 'idle';if a.animation~=animation then a.model.speed=1;a.model.recovery=.2;a.model:play(animation,true);a.animation=animation end
 end
 function c:landingCollision(a)
  local hit=false;world:raycast(D.Vec2(a.model.x,a.model.y+8),D.Vec2(a.model.x,a.model.y-16),false,function(body)if body==self.floorBody then hit=true;return true end;return false end);return hit
 end
 local hud=require('UI.HUDControl')();hud.topControl.visible=false;hud.message.visible=false;hud.weapon.visible=false;hud:addTo(D.Director.ui3D);D.emit('HUD.DisplayMove',true);c.hud=hud
 hud.move.onMove=function(key,down)c.held[key=='keyLeft' and 'left' or 'right']=down end
 local action=require('UI.Skill')({visible=true,text='阶梯 E'});action.position=hud.weapon.position;action:addTo(hud.skillArea);c.action=action
 local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D);c.ui=ui
 local label=D.Label('SourceHanSansCN-Regular',24);label.anchor=D.Vec2(0,1);label.alignment='Left';label.position=D.Vec2(30,ui.height-25);label.textWidth=ui.width-400;label:addTo(ui);c.label=label
 local back=require('UI.InputButton')({text='返回控制舱',textBG=''});back.scaleX=.5;back.scaleY=.5;back.position=D.Vec2(ui.width-215,ui.height-70);back:slot('Tapped'):clear();back:addTo(ui);c.back=back
 local retry=require('UI.InputButton')({text='重试保存',textBG=''});retry.scaleX=.5;retry.scaleY=.5;retry.position=D.Vec2(ui.width-215,ui.height-130);retry:slot('Tapped'):clear();retry:addTo(ui)
 function c:saveAsync(kind,proof)
  self.phase='saving';self.pending={kind,proof};local saved,e=store:writeAsync(kind,proof)
  if self.closed then return false,'CLOSED'end
  if saved then self.state=assert(store:load());self.stage=self.state.stage;self.pending=nil;self.error=nil;self.phase='ready'else self.phase='save-error';self.error=e end
  return saved,e
 end
 local function walkTo(a,x,y)
  while not c.closed and math.abs(a.model.x-x)>1 do local delta=x-a.model.x;pose(a,a.model.x+math.max(-260*D.App.deltaTime,math.min(260*D.App.deltaTime,delta)),y,true,delta>0);D.sleep()end
  if not c.closed then pose(a,x,y,false,true)end
 end
 function c:act()
  if self.phase~='ready'then return false,'BUSY'end
  if self.stage==2 then
   if self.confrontationComplete then
    if self.duelComplete then
     if self.aftermathComplete then self.message='乌云已进入漩涡。使用返回控制舱离开平台。';return false,'AFTERMATH_RECORDED'end
     if math.abs(self.player.model.x-2520)>160 then self.message='走近乌云继续交谈。';return false,'OUT_OF_RANGE'end
     self.phase='opening-dialogue';D.thread(function()self.phase='ready';local stage,e=require('Factory.RoofAftermath').openAsync(self);if not stage then self.error=e end end);return true
    end
    self.phase='opening-battle';D.thread(function()self.phase='ready';local level,e=require('Factory.RoofBattleLevel').openAsync(self);if not level then self.error=e end end);return true
   end
   if math.abs(self.player.model.x-2520)>160 then self.message='走近发射炮旁的乌云。';return false,'OUT_OF_RANGE'end
   self.message=nil;self.phase='opening-dialogue';D.thread(function()self.phase='ready';local stage,e=require('Factory.RoofDialogue').openAsync(self);if not stage then self.error=e end end);return true
  end
  local target=self.stage==0 and G.stairX or G.climbX
  if math.abs(self.player.model.x-target)>100 then self.message=self.stage==0 and '走近阶梯再使用。' or '走近墙面再使用攀爬。';return false,'OUT_OF_RANGE'end
  self.phase=self.stage==0 and 'stairs' or 'climb';self.held={};self.message=nil
  D.thread(function()
   local success,e=xpcall(function()
    if self.stage==0 then
     local proof={actors={},samples=0};local started=D.App.runningTime
     for i,a in ipairs(self.actors)do
      walkTo(a,G.stairX,G.base);local t0=D.App.runningTime
      while not self.closed do local t=math.min(1,(D.App.runningTime-t0)/G.stairsSeconds);local x,y=G.stairPoint(t);pose(a,x,y,t<1,true);proof.samples=proof.samples+1;if t>=1 then break end;D.sleep()end
      if self.closed then return end;D.sleep(.03);proof.actors[#proof.actors+1]={endX=a.model.x,endY=a.model.y,landingCollision=self:landingCollision(a)}
      if i==1 then walkTo(a,G.stairEnd+100,G.stairY)end
     end
     proof.seconds=D.App.runningTime-started;self.lastStairs=proof;self:saveAsync('stairs',proof)
    else
     local proof={actors={}}
     for i,a in ipairs(self.actors)do
      walkTo(a,G.climbX,G.stairY);if self.closed then return end
      local report,err=require('Factory.RoofTraverse').runAsync(a.model,a.name,{top=G.top,wallX=G.wallX,landingX=G.landingX});assert(report,err and err.error or 'Climb failed');a.animation='idle'
      D.sleep(.03);report.landingCollision=self:landingCollision(a);proof.actors[#proof.actors+1]=report
      if i==1 then walkTo(a,G.landingX+160,G.top)end
     end
     self.lastClimb=proof;self:saveAsync('climb',proof)
    end
   end,debug.traceback)
   if not success and not self.closed then self.phase='action-error';self.error=e end
  end);return true
 end
 action:slot('TapBegan',function()c:act()end)
 local input=D.Node();input.keyboardEnabled=true;input:addTo(world)
 input:slot('KeyDown',function(key)
  if key=='E' and c.phase=='ready' and not world.data.storyBusy then c:act()end
 end)
 retry:slot('Tapped',function()if c.phase=='save-error'and c.pending then D.thread(function()c:saveAsync(table.unpack(c.pending))end)end end)
 back:slot('Tapped',function()if c.phase~='ready'and c.phase~='action-error'then return end;c.phase='leaving';D.thread(function()local saved,e=store:writeAsync('leave');if saved then require('Factory.ControlPod').openAsync()else c.phase='ready';c.error=e end end)end)
 world:slot('Cleanup',function()c.closed=true;c.beacon:dispose();c.vortex:dispose();hud:removeFromParent();ui:removeFromParent()end)
 world:schedule(function(dt)
  if c.phase=='battle'then return false end
  if c.phase=='ready'and not world.data.storyBusy then
   local direction=c.held.left~=c.held.right and (c.held.right and 1 or -1)or 0;local m=c.player.model
   local low=c.stage==2 and 1500 or c.stage==1 and 900 or 160;local high=c.stage==2 and 3600 or c.stage==1 and G.climbX or G.stairX
   local x=math.max(low,math.min(high,m.x+direction*260*dt));pose(c.player,x,G.floorY(c.stage),direction~=0 and x~=m.x,direction==0 and not m.fliped or direction>0)
   local a=c.nini;local target=math.max(c.stage==2 and 1450 or c.stage==1 and 920 or 120,math.min(high,x+(m.fliped and 150 or -150)));local delta=target-a.model.x;local walking=math.abs(delta)>3;local step=walking and math.max(-240*dt,math.min(240*dt,delta)) or 0;local right=not a.model.fliped;if walking then right=delta>=0 end;pose(a,a.model.x+step,G.floorY(c.stage),walking,right)
  end
  local frontOpacity=c.stage==2 and c.player.model.x>2360 and .18 or 1
  c.dome.front.opacity=c.dome.front.opacity+(frontOpacity-c.dome.front.opacity)*math.min(1,dt*5)
  local m=c.player.model;world.camera.position=D.Vec2(math.max(500,math.min(3000,m.x+300)),math.max(400,math.min(1430,m.y+250)))
  action.visible=c.phase=='ready'and not c.aftermathComplete;retry.visible=c.phase=='save-error';back.visible=c.phase=='ready'or c.phase=='action-error'
  -- Label.setText rebuilds glyph layout even for identical strings.
  local actionText=c.stage==0 and '阶梯 E' or c.stage==1 and '攀爬 E' or c.aftermathComplete and '已离开' or c.duelComplete and '交谈 E' or c.confrontationComplete and '迎战 E' or '发射炮 E'
  if action.textLabel.text~=actionText then action.textLabel.text=actionText end
  local text='工厂屋顶\n'..(c.error and '操作或保存未完成，请重试保存或返回控制舱。' or c.aftermathComplete and '乌云已进入漩涡。返回控制舱，离开工厂。' or c.duelComplete and '走近乌云，继续交谈。' or c.confrontationComplete and '阻止发射炮启动，准备迎战乌云。' or c.message or c.phase=='stairs' and '沿阶梯上行，等待妮妮跟上。' or c.phase=='climb' and '抓握墙面，翻越到上层平台。' or c.stage==2 and '沿平台前往玻璃罩内的发射炮。' or c.stage==1 and '使用摇杆走近墙面，再使用攀爬。' or '使用摇杆走近阶梯，再使用阶梯按钮。')
  if label.text~=text then label.text=text end
  return false
 end)
 return world
end
return Roof
