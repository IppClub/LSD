-- Original OuterHeaven world and Villywan assets, complete initial 2-12 encounter.
local D=require('Dora');local A=require('CombatAnimation');local Visit={}
function Visit.attach(world)
 if world.tag~='OuterHeaven' or world.valleyEncounter then return end
 local service=assert(require('Story.Service').open());local facts=assert(service:summary())
 if not facts.mission.unlocks['ruins-diversion-complete'] then return end
 local c={phase='loading',logs={},replaying=false};world.valleyEncounter=c
 local x=1800
 -- An empty tree name leaves the previous native decision leaf installed.
 -- Use an explicit Reject leaf while a scripted full animation owns the unit.
 local scriptedTree='AI:ValleyPresentation'
 D.Platformer.Data.store[scriptedTree]=D.Platformer.Decision.Reject()
 D.Entity({player=false,name='villywan',faceRight=false,position=D.Vec2(x+280,world.offset),base=true,storyCompanion=true,decisionTree='AI:PlayerControl'})
 local function actor(name) return D.Group({'name','unit'}):find(function(e) return e.name==name and e.unit.world==world end) end
 local function player() return D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==world end) end
 local bed=D.DrawNode();bed.tag='valley-vine-hammock';bed.position=D.Vec2(x,world.offset);bed:addTo(world)
 for side=-1,1,2 do bed:drawSegment(D.Vec2(side*225,0),D.Vec2(side*210,235),9,D.Color(0xff5c6843));bed:drawSegment(D.Vec2(side*210,210),D.Vec2(side*170,90),4,D.Color(0xffa6ae69)) end
 for i=-8,8 do local a=i/8;local px=a*170;local y=70+a*a*38;bed:drawSegment(D.Vec2(px,y),D.Vec2(px+25,y+35),3,D.Color(0xff89975c));bed:drawSegment(D.Vec2(px,y+35),D.Vec2(px+30,y),2,D.Color(0xffb4ba7e)) end
 local petals=D.DrawNode();petals.order=40;petals:addTo(world)
 petals:schedule(function() petals:clear();local t=D.App.runningTime;for i=1,28 do local u=(t*20+i*53)%520;local px=x-540+((i*79+t*17)%1100)+math.sin(t+i)*25;local py=world.offset+540-u;petals:drawPolygon({D.Vec2(px-5,py),D.Vec2(px,py+4),D.Vec2(px+6,py),D.Vec2(px,py-3)},D.Color(0x99efb4ca)) end;return false end)
 require('System.Music').play(world,'Music/探索.mp3');c.ambient=D.Audio:play('Sound/valley-water-birds.wav',true)
 world:slot('Cleanup',function() if c.ambient then D.Audio:stop(c.ambient) end end)
 local marker=D.Node();marker.tag='valley-awakening-ready';marker.x=x+180;marker:addTo(world)
 local anchor=D.Node();anchor.position=D.Vec2(x+280,world.offset+170);anchor:addTo(world)
 local menu=require('UI.Interaction')({text='万薇莉',buttons={{'醒来交谈',''}},fliped=false});menu.tag='valley-awakening-terminal';menu.transformTarget=anchor;menu.scaleX=.325;menu.scaleY=.325;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
 local friendly=D.Spine('xiaoshanxiao');friendly.recovery=.2;friendly:play('idle',true);friendly.scaleX=-1;friendly.scaleY=1;friendly.position=D.Vec2(x+920,world.offset);friendly.visible=false;friendly:addTo(world);c.friendly=friendly
 if facts.completed['valley-awakening'] then friendly.visible=true;friendly:play('idle1',true);c.friendlyCalmed=true end
 local commands=require('System.Command');local old={};local installed={}
 local function command(name,fn)
  old[name]=rawget(commands,name)
  local cb=function()
   if c.replaying or service:summary().completed['valley-awakening'] then return end
   D.thread(function() fn();if world.parent then D.emit('Story.Advance') end end)
   coroutine.yield('Command')
  end
  installed[name]=cb;commands[name]=cb
 end
 local function full(unit,name,key)
  local oldTree=unit.decisionTree;unit.decisionTree=scriptedTree;unit:stop();A.configure(unit,unit.entity.name)
  local log={started=D.App.runningTime};c.logs[key]=log;log.duration=A.playOnceAsync(unit,name);log.completed=D.App.runningTime;A.rest(unit);unit.decisionTree=oldTree
 end
 command('valleyWater',function()
  local v=assert(actor('villywan'));full(v.unit,'comp','water')
 end)
 command('valleyRide',function()
  local v=assert(actor('villywan'));local oldTree=v.unit.decisionTree;v.unit.decisionTree=scriptedTree;v.unit:stop();local log={started=D.App.runningTime,x=v.unit.x};c.logs.ride=log
  v.unit.faceRight=true;v.unit:start('fmove');local deadline=D.App.runningTime+8
  -- The engine swallows thread errors; stop where we are instead of a silent stall.
  while v.unit.x<x+870 and world.parent do
   if D.App.runningTime>=deadline then print('ValleyVisit: villywan walk stalled, continuing')break end
   D.sleep(.02)
  end
  v.unit:stop();v.unit.velocityX=0;friendly.visible=true
  -- Riding attaches the original Q figure to the mount presentation; collision
  -- unit remains in this world for later walking and interaction.
  c.riding=true;v.unit.playable.y=c.villyBaseY+70;friendly.x=v.unit.x;friendly:play('move',true)
  local began=D.App.runningTime;while D.App.runningTime-began<2 and world.parent do v.unit.x=v.unit.x-150*D.App.deltaTime;friendly.x=v.unit.x;D.sleep() end
  friendly:play('idle',true);log.walked=math.abs(v.unit.x-log.x)+300;log.completed=D.App.runningTime;v.unit.decisionTree=oldTree;A.rest(v.unit)
 end)
 command('valleyCalm',function()
  local v=assert(actor('villywan'));v.unit.playable.y=c.villyBaseY;c.riding=false;full(v.unit,'comp','feed');friendly:play('idle1',true);local from=friendly.x;D.cycle(.4,function(t) friendly.x=from+280*t end);c.friendlyCalmed=true
 end)
 world:slot('Cleanup',function() for name,cb in pairs(installed) do if commands[name]==cb then commands[name]=old[name] end end end)
 menu:slot('Tapped',function()
  if c.phase~='ready' or world.data.storyBusy then return end
  c.phase='dialogue';facts=assert(service:summary());c.replaying=not not facts.completed['valley-awakening']
  D.thread(function()
   local opened,err=require('Story.Flow').openAsync('valley-awakening',world,function() c.phase='ready';c.replaying=false;facts=assert(service:summary()) end,c.replaying)
   if not opened then c.phase='ready';c.error=err end
  end)
 end)
 local near=false;anchor:schedule(function()
  local p=player();local v=actor('villywan');if not p or not v then return false end
  c.actor=v;local can=(not facts.completed['valley-awakening'] or not world.valleyActivities) and c.phase=='ready' and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-v.unit.x)<180
  marker.x=v.unit.x;anchor.x=v.unit.x
  if (not not can)~=near then near=not not can;if near then menu.visible=true;menu:show() else menu:hide(false) end end
  return false
 end)
 D.thread(function()
  while not player() or not actor('villywan') do D.sleep(.02) end
  local p=player();local v=actor('villywan');c.villyBaseY=v.unit.playable.y;local playerBaseY=p.unit.playable.y;p.unit:stop();v.unit:stop();p.keyLeft=false;p.keyRight=false;world.camera.position=D.Vec2(x+180,360)
  if not facts.completed['valley-awakening'] then
   p.busy=true;D.emit('HUD.DisplayMove',false);p.unit.playable.y=playerBaseY+70
   full(p.unit,'fall','fallen');D.sleep(.5);full(p.unit,'standUp','awakening');D.cycle(.4,function(t) p.unit.playable.y=playerBaseY+70*(1-t) end);p.unit.playable.y=playerBaseY
   p.busy=false;D.emit('HUD.DisplayMove',true)
  end
  c.phase='ready'
 end)
 return c
end
return Visit
