-- Original 2-13: actual factory travel, food, secret follower and lens survey.
local D=require('Dora');local A=require('CombatAnimation');local Trail={}
function Trail.attach(world)
 if world.foxTrail then return world.foxTrail end
 local store,err=require('Story.FoxTrailStore').open();if not store then return nil,err end
 local service=assert(require('Story.Service').open());local facts=service:summary();local saved=assert(store:load())
 local c={phase='loading',store=store,logs={},stamina=saved.stamina,scanDone=saved.scanned,foodRemaining=store:foodCount()};world.foxTrail=c
 local function player() return D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==world end) end
 local p=assert(player());c.player=p
 local fox=require('Story.FoxCompanion').createAnimated();fox.recovery=.2;fox.position=D.Vec2(p.unit.x+300,world.offset);fox:addTo(world);c.fox=fox
 D.Entity({player=false,name='villywan',faceRight=true,position=D.Vec2(p.unit.x-(facts.completed['fox-trail-rest'] and 250 or 550),world.offset),base=true,storyCompanion=true,decisionTree='AI:PlayerControl'})
 D.sleep()
 local v=assert(D.Group({'name','unit'}):find(function(e) return e.name=='villywan' and e.unit.world==world end));c.villy=v;v.unit.visible=not not facts.completed['fox-trail-rest']
 for _,e in ipairs({p,v}) do for _,name in ipairs({'fmove','idle','turn'}) do local a=e.unit:getAction(name);if a then a.reaction=.05 end end end
 local ui=D.Node();ui.tag='fox-trail-ui';ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
 local backdrop=D.DrawNode();backdrop:drawPolygon({D.Vec2.zero,D.Vec2(ui.width-430,0),D.Vec2(ui.width-430,110),D.Vec2(0,110)},D.Color(0xbb101b28));backdrop.position=D.Vec2(15,ui.height-260);backdrop:addTo(ui)
 local status=D.Label('SourceHanSansCN-Regular',24);status.anchor=D.Vec2(0,1);status.alignment='Left';status.textWidth=ui.width-430;status.position=D.Vec2(30,ui.height-170);status:addTo(ui);c.status=status
 local action=require('UI.Skill')({visible=true,text='行动 E'});action.position=D.Vec2(ui.width-150,110);action.scaleX=.5;action.scaleY=.5;action:addTo(ui);c.action=action;local actionLabel=action.children.last
 local marker=D.Node();marker.tag='fox-trail-marker';marker.position=D.Vec2(p.unit.x,world.offset+230);marker:addTo(world);c.marker=marker
 local menus={}
 for id,title in pairs({['valley-departure']='跟随狐狸',['fox-trail-rest']='路旁休息',['fox-trail-scout']='隐蔽侦察',['fox-trail-return']='撤到开阔处'}) do
  local node=D.Node();node.tag=id..'-ready';node.x=p.unit.x;node:addTo(world);menus[id]=node
 end
 local menu=require('UI.Interaction')({text='狐狸的路线',buttons={{'继续行动',''}},fliped=false});menu.transformTarget=marker;menu.scaleX=.325;menu.scaleY=.325;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
 local function foxState(name)
  c.foxState=name;require('Story.FoxMovement').setVelocity(fox,name=='move'and 200 or 0)
 end
 local function stage()
  facts=service:summary();c.message=nil
  if facts.completed['fox-trail-return'] then c.phase='done';c.destination=4500;c.nextId=nil
  elseif facts.completed['fox-trail-scout'] then c.phase='checkpoint';c.destination=4100;c.nextId='fox-trail-return'
  elseif facts.completed['fox-trail-rest'] then c.phase='walk2';c.destination=4100;c.nextId='fox-trail-scout'
  elseif facts.completed['valley-departure'] then c.phase='walk1';c.destination=2600;c.nextId='fox-trail-rest'
  else c.phase='intro';c.destination=600;c.nextId='valley-departure' end
  marker.x=c.destination;if c.nextId then menus[c.nextId].x=c.destination end
  if c.phase=='walk1' or c.phase=='walk2' then c.walk={phase=c.phase,from=fox.x,started=D.App.runningTime,movingSeconds=0};c.logs[#c.logs+1]=c.walk end
 end
 local function fullFood()
  local tree='AI:FoxTrailPresentation';D.Platformer.Data.store[tree]=D.Platformer.Decision.Reject();local u=p.unit;local old=u.decisionTree;u.decisionTree=tree;u:stop();A.configure(u,p.name)
  local log={phase='food',started=D.App.runningTime};c.logs[#c.logs+1]=log;log.duration=A.playOnceAsync(u,'comp');log.completed=D.App.runningTime;A.rest(u);u.decisionTree=old
 end
 local function eat()
  if c.command~='food' or c.eating then return end;c.eating=true
  D.thread(function()
   if not c.foodPerformed then fullFood();c.foodPerformed=true end
   local ok,why=store:writeAsync('food');c.eating=false
   if ok then c.foodRemaining=store:foodCount();c.stamina=100;c.foodDone=true;c.message='已补充体力。' else c.message='食物尚未使用：'..tostring(why)..'，按行动重试。';c.foodError=why end
  end)
 end
 function c:scanFromLens(lens)
  if self.command~='scan' or self.scanning or math.abs(p.unit.x-4100)>=180 then return false,'OUT_OF_RANGE' end
  if self.scanDone then lens.view.detail.text='收集完毕\n关闭夜光镜，继续撤离。';return true end
  self.scanning=true;D.thread(function()
   local began=D.App.runningTime;local origin=p.unit.x;local interrupted=false
   for i=1,30 do
    if not world.parent or lens.phase~='map' or math.abs(p.unit.x-origin)>20 then interrupted=true;break end
    lens.view.detail.text='位置资料收集中 · '..math.floor(i/30*100)..'%\n保持隐蔽，正在核实据点入口与道路。';D.sleep(.1)
   end
   if not world.parent then return end
   local ok,why=false,'SCAN_INTERRUPTED';if not interrupted then ok,why=store:writeAsync('scan',p.unit.x) end
   self.scanning=false
   if ok then self.scanDone=true;self.scanLog={started=began,completed=D.App.runningTime,x=p.unit.x};lens.view.detail.text='收集完毕\n据点入口与道路已记录。关闭夜光镜后撤离。'
   else self.scanError=why;lens.view.detail.text='位置资料尚未保存：'..tostring(why)..'\n点击收集位置资料重试。' end
  end);return true
 end
 local commands=require('System.Command');local old={};local installed={}
 local function install(name,id,fn)
  old[name]=rawget(commands,name);local cb=function()
   if service:summary().completed[id] then return end
   D.thread(function()
    local flow=world.storyFlow;local view=flow and flow.id==id and flow.view
    local scale,effect=D.View.scale,D.View.postEffect
    if view then view.visible=false;D.View.scale=view._viewScale or scale;D.View.postEffect=view._viewEffect end
    fn()
    if world.parent then if view then view.visible=true;D.View.scale=scale;D.View.postEffect=effect end;D.emit('Story.Advance') end
   end);coroutine.yield('Command')
  end;installed[name]=cb;commands[name]=cb
 end
 install('foxFood','fox-trail-rest',function()
  if assert(store:load()).foodUsed==1 then c.stamina=100;return end
  c.command='food';c.message='使用随身食物补充体力。';while not c.foodDone and world.parent do D.sleep(.03) end;c.command=nil
 end)
 install('foxVillyArrive','fox-trail-rest',function()
  c.arriving=true;v.unit.visible=true;v.busy=false;local log={phase='villy-arrival',from=v.unit.x,started=D.App.runningTime};c.logs[#c.logs+1]=log
  local deadline=D.App.runningTime+12
  -- The engine swallows thread errors; stop where we are instead of a silent stall.
  while v.unit.x<p.unit.x-240 and world.parent do
   if D.App.runningTime>=deadline then print('FoxTrail: villy arrival stalled, continuing')break end
   v.keyRight=true;D.sleep(.03)
  end
  v.keyRight=false;v.unit:stop();v.unit.velocityX=0;v.busy=true;log.to=v.unit.x;log.completed=D.App.runningTime;c.arriving=false
 end)
 install('foxSurvey','fox-trail-scout',function()
  c.command='scan';c.message='打开夜光镜，收集据点位置资料。'
  while world.parent and (not c.scanDone or world.data.journalOpen) do D.sleep(.03) end;c.command=nil
 end)
 install('foxOpenSpace','fox-trail-return',function()
  c.command='walk-open';c.phase='walk-open';c.destination=4500;c.walk={phase='walk-open',from=fox.x,started=D.App.runningTime,movingSeconds=0};c.logs[#c.logs+1]=c.walk
  D.emit('Story.Display',false)
  require('Story.Flow').freeze(world,false);c.message='跟随狐狸，撤到前方开阔处。'
  while not c.walkFinished and world.parent do D.sleep(.03) end
  require('Story.Flow').freeze(world,true);D.emit('Story.Display',true);c.command=nil;c.phase='dialogue'
 end)
 function c:request()
  if self.command=='food' then eat();return true end
  if self.command=='scan' then D.thread(function() local lens,why=require('Ground.NightLens').openAsync(world);if not lens then self.message=tostring(why) end end);return true end
  if world.data.storyBusy or world.data.journalOpen then return false,'BUSY' end
  if self.phase=='done' and math.abs(p.unit.x-4500)<180 then D.thread(function() require('Academy.Navigation').returnToRoomAsync('OperationRoom',{foxParty=true}) end);return true end
  if (self.phase~='intro' and self.phase~='checkpoint') or math.abs(p.unit.x-self.destination)>=180 then return false,'FOLLOW_FOX' end
  local id=self.nextId;self.phase='dialogue';D.thread(function() local flow,why=require('Story.Flow').openAsync(id,world,function() stage() end);if not flow then self.phase='checkpoint';self.message=tostring(why) end end);return true
 end
 action:slot('TapBegan',function() c:request() end);menu:slot('Tapped',function() c:request() end)
 ui.keyboardEnabled=true;ui:slot('KeyDown',function(key) if key=='E' then c:request() end end)
 stage();if facts.completed['fox-trail-rest'] then fox.x=(c.phase=='walk2' and 2600 or c.destination)+300 end;foxState('idle');local last=D.App.runningTime;local lastX=p.unit.x;local near=false
 local tick=D.Node();tick:addTo(world);tick:schedule(function()
  local now=D.App.runningTime;local dt=math.min(.1,now-last);last=now
  local walking=c.phase=='walk1' or c.phase=='walk2' or c.phase=='walk-open'
  if walking and not world.data.journalOpen then
   local moving=fox.x<c.destination+300-2 and fox.x<p.unit.x+480
   foxState(moving and 'move' or 'idle')
   if moving then local distance=require('Story.FoxMovement').step(fox,200,dt);fox.x=math.min(c.destination+300,fox.x);c.walk.movingSeconds=c.walk.movingSeconds+distance/200 end
   c.stamina=math.max(0,c.stamina-math.abs(p.unit.x-lastX)*.01)
   if fox.x>=c.destination+300-2 and math.abs(p.unit.x-c.destination)<130 and (not v.unit.visible or math.abs(v.unit.x-c.destination)<330) then
    c.walk.completed=now;c.walk.to=fox.x
    if c.command=='walk-open' then c.walkFinished=true else c.phase='checkpoint' end
   end
  else foxState('idle') end
  if not c.arriving and walking and not world.data.journalOpen then
   v.busy=false;v.keyLeft=v.unit.x>p.unit.x-(v.unit.visible and 250 or 550)+20;v.keyRight=v.unit.x<p.unit.x-(v.unit.visible and 250 or 550)-20
  elseif not c.arriving then v.keyLeft=false;v.keyRight=false end
  lastX=p.unit.x;marker.x=c.destination
  local can=(c.phase=='intro' or c.phase=='checkpoint' or c.phase=='done') and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-c.destination)<180
  if can~=near then near=can;if can then menu.visible=true;menu:show() else menu:hide(false) end end
  ui.visible=not world.data.journalOpen and (not world.data.storyBusy or c.command~=nil or c.arriving)
  action.visible=not world.data.storyBusy or c.command=='food' or c.command=='scan';actionLabel.text=c.command=='food' and '食物 E' or c.command=='scan' and '夜光镜 E' or c.phase=='done' and '返回基地 E' or '行动 E'
  status.text=(c.message or (walking and '沿狐狸指示的道路前行，保持隐蔽。' or c.phase=='done' and '资料已收集。到开阔处返回基地。' or '走近狐狸，继续交谈。'))..'\n体力 '..math.floor(c.stamina)..' / 100 · 随身食物 '..tostring(c.foodRemaining or '?')
  return false
 end)
 world:slot('Cleanup',function() for name,cb in pairs(installed) do if commands[name]==cb then commands[name]=old[name] end end end)
 return c
end
return Trail
