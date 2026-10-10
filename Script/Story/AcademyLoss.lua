-- Damage persists through the completed story fact; transient presentation never grants it.
local D=require('Dora');local Loss={}
local rooms={PassageA=true,PassageB=true,PassageC=true,PassageD=true,RestRoom=true,PreparationRoom=true,TrainingRoom=true,OperationRoom=true,RDRoom=true,LibraryRoom=true}
function Loss.isDamaged()
 if not D.DB:exist('Game0StoryNodes','lsd')then return false end
 local rows=D.DB:query("SELECT id FROM lsd.Game0StoryNodes WHERE id='academy-loss'")
 return rows and rows[1]~=nil or false
end
function Loss.attach(world)
 if world.academyLoss then return world.academyLoss end
 if not rooms[world.tag]then return end
 local service=assert(require('Story.Service').open());local facts=assert(service:summary());local recorded=facts.completed['academy-loss']
 if not recorded and (world.tag~='PassageA'or not facts.mission.unlocks['academy-defense-complete'])then return end
 local c={phase='ready',recorded=recorded,report={version=1,scene=world.tag},service=service};world.academyLoss=c
 local marker=D.Node();marker.tag='academy-loss-ready';marker.position=D.Vec2(world.tag=='PassageA'and 1900 or world.sceneWidth/2,world.offset+190);marker:addTo(world);c.marker=marker
 local menu=require('UI.Interaction')({text=recorded and '失联终端'or'各区通讯',buttons=recorded and {{'查看人员状态',''},{'重读通讯',''}}or{{'确认其他小组',''}},fliped=false})
 menu.transformTarget=marker;menu.order=100;menu.scaleX=.325;menu.scaleY=.325;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
 local hint=D.Label('SourceHanSansCN-Regular',24,true);hint.outlineWidth=.16;hint.outlineColor=D.Color(0xff101b28);hint.position=marker.position+D.Vec2(0,260);hint:addTo(world)
 require('UI.KeepOnScreen')(hint,{hint})
 hint.text=recorded and '区域损坏 · 人员记录已保存'or'主通道已守住 · 其他小组尚未回应';c.hint=hint
 function c:damage()
  if self.damageNode then return end
  local art=Loss.damageWorld(world);self.damageNode=art.damageNode;self.smoke=art.smoke
 end
 if recorded then c:damage()end
 local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end)end
 function c:showRecord()
  local roster,why=require('Story.AcademyLossRecords').current();if not roster then hint.text='人员记录暂不可读取，存档已保留。';return nil,why end
  self.phase='record';world.data.journalOpen=true;require('Story.Flow').freeze(world,true)
  local page=1;local view;local selected=1
  local function render()
   if view then view:removeFromParent()end
   local r=roster[selected]
   local args={panelTitle='各区人员',closeText='关闭记录',pageText='记录 '..page..' / '..math.ceil(#roster/4),journalText=r.name..' · '..r.place..'\n\n'..r.detail..'\n\n'..(r.duty and '此前分工：'..({flank='侧翼防守',medical='医疗救助',computing='计算机操作',recon='侦察', ['energy-research']='能源与研发'})[r.duty]..'\n\n'or '')..'主通道的防卫结果已保存。\n'..require('Story.AcademyLossRecords').rescueHint(roster)}
   for i=1,4 do local item=roster[(page-1)*4+i];args['row'..i..'Visible']=item~=nil;args['row'..i..'Title']=item and item.name or '';args['row'..i..'Status']=item and item.detail or ''end
   view=require('UI.StoryJournal')(args);view:addTo(D.Director.ui3D);self.record=view
   view.closeButton:slot('Tapped',function()view:removeFromParent();self.phase='ready';world.data.journalOpen=false;require('Story.Flow').freeze(world,false)end)
   for i,button in ipairs({view.mailButton,view.researchButton,view.archiveButton,view.stationButton})do local index=(page-1)*4+i;button:slot('Tapped',function()if roster[index]then selected=index;render()end end)end
   view.previousButton.visible=page>1;view.nextButton.visible=page<math.ceil(#roster/4)
   view.previousButton:slot('Tapped',function()page=math.max(1,page-1);selected=(page-1)*4+1;render()end)
   view.nextButton:slot('Tapped',function()page=math.min(math.ceil(#roster/4),page+1);selected=(page-1)*4+1;render()end)
  end
  render();world:slot('Cleanup',function()if view and view.parent then view:removeFromParent()end end);return view
 end
 function c:request()
  local p=player();if self.phase~='ready'or world.data.storyBusy or world.data.journalOpen or not p or p.busy then return nil,'BUSY'end
  if math.abs(p.unit.x-marker.x)>=180 then return nil,'DISCOVERY_LOCATION_REQUIRED'end
  if self.recorded then return self:showRecord()end
  self.phase='opening';self.report.roster=assert(require('Story.AcademyLossRecords').build())
  local commands=require('System.Command');local previous=rawget(commands,'academyImpact');local disposed=false;local action
  local function dispose()if disposed then return end;disposed=true;if commands.academyImpact==action then commands.academyImpact=previous end end
  action=function()
   D.thread(function()
    local story=world.storyFlow.view;local scale,effect=D.View.scale,D.View.postEffect
    story.visible=false;D.View.scale=story._viewScale or scale;D.View.postEffect=story._viewEffect
    local started=D.App.runningTime;local camera=world.camera.position;self:damage()
    while D.App.runningTime-started<1.4 do
     if not world.parent then return end
     local age=D.App.runningTime-started;world.camera.position=camera+D.Vec2(math.sin(age*37)*7*(1-age/1.4),math.cos(age*29)*3*(1-age/1.4));D.sleep()
    end
    world.camera.position=camera;self.report.impactSeconds=D.App.runningTime-started;self.report.damageVisible=true
    story.visible=true;D.View.scale=scale;D.View.postEffect=effect;D.emit('Story.Advance')
   end)
   coroutine.yield('Command')
  end
  commands.academyImpact=action;world:slot('Cleanup',dispose)
  local flow,why=require('Story.Flow').openAsync('academy-loss',world,function()
   dispose();self.phase='ready';self.recorded=true
   -- Recreate from the committed state, suppressing historical NPCs and services.
   D.thread(function()require('Academy.Navigation').returnToRoomAsync('PassageA')end)
  end,false)
  if not flow then dispose();self.phase='ready'end
  return flow,why
 end
 menu:slot('Tapped',function(index)D.thread(function()if index==2 and c.recorded and c.phase=='ready'and not world.data.storyBusy and not world.data.journalOpen then require('Story.Flow').openAsync('academy-loss',world,nil,true)else c:request()end end)end)
 local near=false;marker:schedule(function()
  local p=player();local now=c.phase=='ready'and p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-marker.x)<180
  if (not not now)~=near then near=not not now;if near then menu.visible=true;menu:show()else menu:hide(false)end end
  return false
 end)
 return c
end
function Loss.damageWorld(world)
 if world._layers then
  for key,node in pairs(world._layers)do
   if key:match('^spotlight')then node.visible=false end
  end
 end
 local Art=require('Story.AcademyDamageArt')
 return {damageNode=Art.create(world),smoke=Art.createDust(world)}
end
return Loss
