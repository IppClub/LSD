-- Complete original 2-12 after optional exploration and actual language learning.
local D=require('Dora');local A=require('CombatAnimation');local Days={}
function Days.attach(world,activities)
 if world.valleyDays then return end
 local c={phase='ready',logs={}};world.valleyDays=c
 local function player() return D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==world end) end
 local function guide() return world.valleyEncounter and world.valleyEncounter.actor end
 local service=assert(require('Story.Service').open())
 local commands=require('System.Command');local old={};local installed={}
 local function install(name,storyId,fn)
  old[name]=rawget(commands,name)
  local cb=function()
   -- A first command runs inside UI construction, before world.storyFlow is replaced.
   if service:summary().completed[storyId] then return end
   D.thread(function() fn();if world.parent then D.emit('Story.Advance') end end);coroutine.yield('Command')
  end
  installed[name]=cb;commands[name]=cb
 end
 local function full(unit,name)
  local tree='AI:ValleyDaysPresentation';D.Platformer.Data.store[tree]=D.Platformer.Decision.Reject()
  local oldTree=unit.decisionTree;unit.decisionTree=tree;unit:stop();A.configure(unit,unit.entity.name)
  local began=D.App.runningTime;local duration=A.playOnceAsync(unit,name);c.logs[#c.logs+1]={name=name,started=began,duration=duration,completed=D.App.runningTime};A.rest(unit);unit.decisionTree=oldTree
 end
 install('valleyRest','valley-days',function()
  local p=assert(player());full(p.unit,'fall')
  local ui=D.Node();ui.size=D.App.bufferSize;ui.order=200;ui:addTo(D.Director.ui3D)
  local black=D.DrawNode();black:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff162d3d));black:addTo(ui)
  local label=D.Label('SourceHanSansCN-Regular',40);label.text='几天之后';label.position=D.Vec2(ui.width/2,ui.height/2);label:addTo(ui)
  ui.opacity=0;ui:perform(D.Opacity(.5,0,1));D.sleep(1.8);ui:perform(D.Opacity(.5,1,0));D.sleep(.5);ui:removeFromParent();full(p.unit,'standUp');c.restCompleted=true
 end)
 local function spawnFox()
  if c.fox then return c.fox end
  require('Story.FoxCompanion').loadAnimatedAsync();if not world.parent then return end
  local p=assert(player());local fox=require('Story.FoxCompanion').createAnimated();fox.recovery=.2;fox.position=D.Vec2(p.unit.x+1050,world.offset);fox:addTo(world);c.fox=fox;return fox
 end
 install('valleyFoxArrive','valley-friends',function()
  local fox=spawnFox();if not fox then return end
  local log={started=D.App.runningTime,from=fox.x};c.foxArrival=log
  local target=player().unit.x+530;local motion=require('Story.FoxMovement');motion.setVelocity(fox,(target-log.from)/2.6)
  D.sleep(fox.anticipationSeconds or 0)
  D.cycle(2.6,function(t) fox.x=log.from+(target-log.from)*t end);motion.setVelocity(fox,0);log.to=fox.x;log.completed=D.App.runningTime
 end)
 local function terminal(tag,x,text,id)
  local marker=D.Node();marker.position=D.Vec2(x,world.offset+230);marker.tag=tag..'-ready';marker:addTo(world)
  local view=require('UI.Interaction')({text=text,buttons={{id=='valley-days' and '练习几日' or '和怪物交流',''}},fliped=false});view.transformTarget=marker;view.scaleX=.325;view.scaleY=.325;view.visible=false;view.menu.enabled=false;view:addTo(world)
  local t={marker=marker,menu=view,near=false};view:slot('Tapped',function()
   if c.phase~='ready' or world.data.storyBusy or world.data.journalOpen then return end
   local p=player();if not p or math.abs(p.unit.x-marker.x)>=180 then return end
   c.phase='dialogue';local replay=not not service:summary().completed[id]
   D.thread(function() local flow,err=require('Story.Flow').openAsync(id,world,function() c.phase='ready' end,replay);if not flow then c.phase='ready';c.error=err;activities.message='先完成怪物语学习，再在吊床旁休息。' end end)
  end);return t
 end
 c.rest=terminal('valley-days',1800,'桃源日常','valley-days')
 c.friends=terminal('valley-friends',2100,'怪物朋友','valley-friends')
 local marker=D.Node();marker.tag='fox-departure-ready';marker.position=D.Vec2(0,world.offset+230);marker:addTo(world)
 local departure=require('UI.Interaction')({text='狐狸带路',buttons={{'跟随出谷',''}},fliped=false});departure.transformTarget=marker;departure.scaleX=.325;departure.scaleY=.325;departure.visible=false;departure.menu.enabled=false;departure:addTo(world)
 c.departure={marker=marker,menu=departure,near=false}
 departure:slot('Tapped',function()
  local p=player();if c.phase~='ready' or world.data.storyBusy or world.data.journalOpen or not c.fox or not p or math.abs(p.unit.x-c.fox.x)>=180 then return end
  c.phase='departing';D.thread(function()
   local trail,why=require('Story.FoxTrailStore').open();local ok=false;if trail then ok,why=trail:writeAsync('depart') end
   if not ok then c.phase='ready';c.error=why;activities.message='出谷进度尚未保存，请重试。';return end
   require('Academy.Navigation').returnToRoomAsync('Factory',{foxTrail=true,spawn=600})
  end)
 end)
 local last=-1;local facts=service:summary();local tick=D.Node();tick:addTo(world)
 tick:schedule(function()
  if D.App.runningTime-last>.5 then facts=service:summary();last=D.App.runningTime end
  local p=player();local v=guide();if v then c.friends.marker.x=v.unit.x end
  for id,t in pairs({['valley-days']=c.rest,['valley-friends']=c.friends}) do
   local unlocked=id=='valley-days' and activities.states.language.correct==3 or id=='valley-friends' and facts.completed['valley-days']
   local can=unlocked and p and not p.busy and c.phase=='ready' and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-t.marker.x)<180
   if (not not can)~=t.near then t.near=not not can;if can then t.menu.visible=true;t.menu:show() else t.menu:hide(false) end end
  end
  if c.fox then marker.x=c.fox.x end
  local can=facts.completed['valley-friends'] and c.fox and p and c.phase=='ready' and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-marker.x)<180
  if (not not can)~=c.departure.near then c.departure.near=not not can;if can then departure.visible=true;departure:show() else departure:hide(false) end end
  return false
 end)
 if facts.completed['valley-friends'] then D.thread(function() local fox=spawnFox();if fox then fox.x=player().unit.x+530;fox:play('idle',true) end end) end
 world:slot('Cleanup',function() for name,cb in pairs(installed) do if commands[name]==cb then commands[name]=old[name] end end end)
 return c
end
return Days
