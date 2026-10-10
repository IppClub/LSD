local D=require('Dora');local Arrival={}
function Arrival.attach(world)
 if world.jadeArrival then return world.jadeArrival end
 if world.tag~='RDRoom'or not require('Story.AcademyLoss').isDamaged()then return end
 local service=assert(require('Story.Service').open());local facts=assert(service:summary())
 local c={phase='loading',recorded=facts.completed['jade-arrival'],report={version=1},service=service};world.jadeArrival=c
 D.thread(function()
  local Actor=require('Rescue.Actor');Actor.loadAsync();if not world.parent then return end
  c.carrier=require('Rescue.BuddhaCarrier').new(world,3920,world.offset,'Spine/StoryActions/yu-riding.json|Spine/yu.atlas',require('Rescue.BuddhaChibiStyle'))
  c.yu={model=c.carrier.node,completed=c.carrier.completed};c.twins={Actor.new('vika',world,4150,world.offset),Actor.new('vivi',world,4350,world.offset)}
  c.ward=require('Rescue.Ward').new(world,4140,world.offset+140,460,160);c.ward:open()
  local rescued=facts.mission.unlocks['twins-rescued']
  local marker=D.Node();marker.tag=rescued and 'jade-distance-ready'or 'jade-arrival-ready';marker.position=D.Vec2(rescued and 4650 or 3760,world.offset+190);marker:addTo(world);c.marker=marker
  local menu=require('UI.Interaction')({text=rescued and '玉的支撑点'or '金色保护场',buttons=rescued and {{facts.completed['jade-distance']and '重读撤离交谈'or '与玉交谈',''},{'重读初次交谈',''}}or {{c.recorded and '重读初次交谈'or'靠近玉与双子',''}},fliped=false})
  menu.transformTarget=marker;menu.x=rescued and 0 or -160;menu.scaleX=.325;menu.scaleY=.325;menu.order=100;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
  local label=D.Label('SourceHanSansCN-Regular',24,true);label.outlineWidth=.16;label.outlineColor=D.Color(0xff101b28);label.position=D.Vec2(4140,world.offset+670);label:addTo(world);c.label=label
  label.text=c.recorded and '临时保护场 · 双子尚未撤离'or'研究区尚有回应 · 走近左侧保护场边缘'
  if facts.mission.unlocks['twins-rescued']then
   c.twins[1].model.x=5400;c.twins[2].model.x=5560;c.yu.model.x=4650;c.ward:close();label.position=D.Vec2(4650,world.offset+670);label.text=facts.completed['jade-distance']and '玉留下了有限的撤离窗口'or '双子已抵达出口 · 玉仍在支撑通道'
  end
  if not c.recorded then
   local def=D.BodyDef();def.type='Static';def:attachPolygon(100,500,0,1,0)
   c.barrier=D.Body(def,world,D.Vec2(4570,world.offset+250));c.barrier.group=D.Platformer.Data.groupTerrain;c.barrier:addTo(world)
   local wall=D.DrawNode();wall.position=D.Vec2(4570,world.offset);wall.order=1;wall:addTo(world);c.wall=wall
   wall:drawPolygon({D.Vec2(-50,0),D.Vec2(50,0),D.Vec2(50,500),D.Vec2(-50,500)},D.Color(0xff233743),2,D.Color(0xff91a4ad))
   for y=30,470,50 do wall:drawSegment(D.Vec2(-44,y),D.Vec2(44,y+24),3,D.Color(0xffa68c58))end
  end
  require('Rescue.Gate').attach(world)
  if not rescued then
   c.carrier:guard(true);local mounted=c.carrier:mountAsync();if not mounted then return end
  end
  c.phase='ready';local near=false
  local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end)end
  function c:request(index)
   local p=player();if self.phase~='ready'or world.data.storyBusy or world.data.journalOpen or not p or p.busy then return nil,'BUSY'end
   if math.abs(p.unit.x-marker.x)>=180 then return nil,'DISCOVERY_LOCATION_REQUIRED'end
   if rescued and index~=2 then return require('Rescue.Distance').openAsync(world,self,p)end
   self.phase='opening';self.report.playerX=p.unit.x
   local commands=require('System.Command');local previous=rawget(commands,'jadeOpenPassage');local command;local disposed=false
   local function dispose()if disposed then return end;disposed=true;if commands.jadeOpenPassage==command then commands.jadeOpenPassage=previous end end
   command=function()
    D.thread(function()
     local view=world.storyFlow.view;local scale,effect=D.View.scale,D.View.postEffect
     view.visible=false;D.View.scale=view._viewScale or scale;D.View.postEffect=view._viewEffect
     local start=D.App.runningTime;self.report.barrierWasSolid=self.barrier~=nil
     while D.App.runningTime-start<1.2 do
      if not world.parent then return end
      local u=math.min(1,(D.App.runningTime-start)/1.2);if self.wall then self.wall.opacity=1-u;self.wall.scaleX=1-u*.85 end;D.sleep()
     end
     if self.barrier then self.barrier:removeFromParent();self.barrier=nil end
     if self.wall then self.wall:removeFromParent();self.wall=nil end
     self.report.openSeconds=D.App.runningTime-start;self.report.barrierRemoved=true
     self.report.wardActive=self.ward.active and self.ward.age>=.6
     self.report.twinsProtected=self.ward:contains(self.twins[1].model.x,world.offset+140)and self.ward:contains(self.twins[2].model.x,world.offset+140)
     view.visible=true;D.View.scale=scale;D.View.postEffect=effect;D.emit('Story.Advance')
    end)
    coroutine.yield('Command')
   end
   commands.jadeOpenPassage=command;world:slot('Cleanup',dispose)
   local flow,why=require('Story.Flow').openAsync('jade-arrival',world,function()
    dispose();self.phase='ready';self.recorded=true;label.text=service:summary().completed['jade-distance']and '玉留下了有限的撤离窗口'or facts.mission.unlocks['twins-rescued']and '双子已抵达研究区出口'or '临时保护场 · 双子尚未撤离';require('Rescue.Gate').attach(world)
   end,self.recorded or false)
   if not flow then dispose();self.phase='ready'end;return flow,why
  end
  menu:slot('Tapped',function(index)D.thread(function()c:request(index)end)end)
  marker:schedule(function(dt)
   c.ward:update(dt);c.carrier:guard(c.ward.active and c.ward.remaining>0);for _,a in ipairs(c.twins)do a:update(0,dt)end
   local p=player();local now=c.phase=='ready'and p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-marker.x)<180
   if (not not now)~=near then near=not not now;if near then menu.visible=true;menu:show()else menu:hide(false)end end;return false
  end)
 end)
 return c
end
return Arrival
