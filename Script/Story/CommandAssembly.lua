-- Authored 2-14 reunion in the actual command room, with durable personnel duties.
local D=require('Dora');local Assembly={}
Assembly.roles={
 {id='liyena',name='李叶娜',offset=-1350,duty='侧翼攻防'},
 {id='moling',name='忍冬',offset=-1080,duty='医疗救护'},
 {id='moyu',name='半夏',offset=-810,duty='医疗救护'},
 {id='vika',name='烛参',offset=-540,duty='能源与研发'},
 {id='vivi',name='烛商',offset=-270,duty='能源与研发'},
 {id='sunborn',name='林睿哲',offset=270,duty='行动指挥'},
 {id='ninilite',name='妮妮莉特',offset=540,duty='主攻小队'},
 {id='wuyun',name='乌云',offset=810,duty='主攻小队'},
 {id='villywan',name='万薇莉',offset=1080,duty='计算机操作'},
}
function Assembly.attach(world)
 if world.commandAssembly then return world.commandAssembly end
 local service,why=require('Story.Service').open();if not service then return nil,why end
 local facts=service:summary();if not facts or not facts.completed['fox-trail-return'] then return end
 local c={phase='loading',actors={},labels={},service=service};world.commandAssembly=c
 local center=world.sceneWidth/2;c.center=center
 local function player() return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end) end
 local function find(id) return D.Group({'name','unit'}):find(function(e)return not e.player and e.name==id and e.unit.world==world end) end
 local marker=D.Node();marker.tag='command-assembly-ready';marker.position=D.Vec2(center,world.offset+200);marker:addTo(world);c.marker=marker
 local menu=require('UI.Interaction')({text='指挥室集合',buttons={{'汇报与分工',''},{'行动分工表',''},{'任务与编队',''},{'工厂潜入',''}},fliped=false});menu.tag='command-assembly-terminal';menu.transformTarget=marker;menu.scaleX=.32;menu.scaleY=.32;menu.x=-60;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
 local function refresh()
  facts=assert(service:summary())
  for _,role in ipairs(Assembly.roles) do
   local label=c.labels[role.id];if label then label.text=role.name..'\n'..(facts.completed['command-assembly'] and role.duty or '等待汇报') end
  end
  if c.foxLabel then c.foxLabel.text='大狐狸\n'..(facts.completed['command-assembly'] and '侦察与草药' or '新成员') end
 end
 D.thread(function()
  for _,role in ipairs(Assembly.roles) do
   D.Cache:loadAsync('spine:'..role.id);if not world.parent then return end
   local e=find(role.id)
   if not e then D.Entity({player=false,name=role.id,position=D.Vec2(center+role.offset,world.offset),faceRight=role.offset<0,order=0,base=true,storyCompanion=true,decisionTree='AI:PlayerControl'});D.sleep();e=assert(find(role.id)) end
   e.storyCompanion=true;e.keyLeft=false;e.keyRight=false;e.unit:stop();e.unit.x=center+role.offset;e.unit.velocityX=0;e.unit.faceRight=role.offset<0;e.unit.decisionTree='AI:PlayerControl';e.unit.playable.recovery=.2;c.actors[role.id]=e
   local label=D.Label('SourceHanSansCN-Regular',25);label.position=D.Vec2(center+role.offset,world.offset+390);label:addTo(world);c.labels[role.id]=label
  end
  require('Story.FoxCompanion').loadAnimatedAsync();if not world.parent then return end
  local fox=world.foxParty or require('Story.FoxCompanion').createAnimated();if not world.foxParty then fox:addTo(world);world.foxParty=fox end
  fox.recovery=.2;fox.position=D.Vec2(center+1350,world.offset);fox:play('idle',true);c.fox=fox
  local label=D.Label('SourceHanSansCN-Regular',25);label.position=D.Vec2(center+1350,world.offset+390);label:addTo(world);c.foxLabel=label
  world.zoom=1;world.camera.followTarget=assert(player()).unit
  c.phase='ready';refresh()
 end)
 function c:openAssignments()
  if world.data.storyBusy or world.data.journalOpen or self.phase~='ready' then return nil,'BUSY' end
  local assignments,err=service:assignments();if not assignments then return nil,err end
  if not service:summary().completed['command-assembly'] then return nil,'REPORT_REQUIRED' end
  for _,duty in ipairs(require('Story.Catalog')['command-assembly'].assignments) do
   local saved=assignments[duty[1]];if not saved or saved.duty~=duty[2] or saved.node~='command-assembly' then return nil,'ASSIGNMENTS_INCOMPLETE' end
  end
  local Flow=require('Story.Flow');world.data.journalOpen=true;Flow.freeze(world,true)
  local view=require('UI.Phone')({storyMode=true,panelTitle='行动分工',closeText='返回指挥室',pageText='分工 1 / 1',
   row1Title='侦察与计算机',row1Status='狐狸侦察 · 万薇莉计算机操作',row2Title='能源与研发',row2Status='烛参、烛商 · 能源护送与研发',row3Title='医疗与侧翼',row3Status='忍冬、半夏救护 · 李叶娜侧翼',row4Title='三人主攻队',row4Status='导师 · 妮妮莉特 · 乌云'})
  view.tag='command-assignment-panel';view:addTo(D.Director.ui3D);view.previousButton.visible=false;view.nextButton.visible=false;self.assignmentPanel=view
  local text={
   '狐狸加入基地侦察队伍，帮助侦察与寻找草药。\n万薇莉加入计算机操作室。\n\n保守桃源谷的位置秘密，行动中保持联络。',
   '烛参与烛商加入能源护送和研发。\n能源运输中仍需战斗保护队伍与物资。\n\n发挥所长，早日解救被断网组织抓走的父母。',
   '忍冬与半夏承担医疗救护。\n李叶娜及其队伍负责侧翼攻击与防守。\n\n保障主攻队与能源护送队的行动。',
   '导师、妮妮莉特与乌云率领主攻。\n狐狸已经收集工厂据点位置资料。\n\n准备夜光定位、火焰与旋风协同，隐蔽接近断网组织据点。'}
  for i,button in ipairs({view.mailButton,view.researchButton,view.archiveButton,view.stationButton}) do button:slot('Tapped',function() view.detail.text=text[i] end) end
  view.detail.text='行动分工已确认\n\n'..text[4]
  view.closeButton:slot('Tapped',function() if not world.data.journalOpen then return end;world.data.journalOpen=false;view:removeFromParent();Flow.freeze(world,false);self.assignmentPanel=nil end)
  return view
 end
 local hintUI=D.Node();hintUI.size=D.App.bufferSize;hintUI.order=10;hintUI:addTo(D.Director.ui3D)
 local hint=D.Label('SourceHanSansCN-Regular',25);hint.visible=false;hint:addTo(hintUI);c.hint=hint
 local function layoutHint() hintUI.size=D.App.bufferSize;hint.position=D.Vec2(D.App.bufferSize.width/2,D.App.bufferSize.height-165) end
 layoutHint();hint:gslot('AppChange',function(name) if name=='Size' then layoutHint() end end)
 world:slot('Cleanup',function() hintUI:removeFromParent() end)
 local near=false;local last=-1
 local tick=D.Node();tick:addTo(world);tick:schedule(function()
  if D.App.runningTime-last>.5 then refresh();last=D.App.runningTime end
  local p=player();local now=c.phase=='ready' and p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-center)<180
  if (not not now)~=near then near=not not now;if near then menu.visible=true;menu:show() else menu:hide(false) end end
  return false
 end)
 menu:slot('Tapped',function(index)
  if not near or c.phase~='ready' then return end
  if index==2 then local view,err=c:openAssignments();c.error=err;hint.visible=not view;hint.text=err=='REPORT_REQUIRED' and '先向林睿哲汇报，再查看行动分工。' or '分工记录暂不可用，请重试汇报。';return end
  hint.visible=false;c.phase='opening';D.thread(function()
   if index==4 then
    local opened,err=require('Story.Infiltration').enterAsync();c.error=err
    if not opened then c.phase='ready';hint.visible=true;hint.text=err=='ASSEMBLY_REQUIRED' and '先完成汇报与行动分工。' or err=='TRAINING_REQUIRED' and '先在训练室采用两名学员的训练成果。' or '行动尚未保存，请重试。'end
   elseif index==3 then
    local opened,err=require('Mission.Briefing').openAsync();world.missionBriefing=opened;c.phase='ready';c.error=err
   else
    local replay=service:summary().completed['command-assembly']
    local opened,err=require('Story.Flow').openAsync('command-assembly',world,function() c.phase='ready';refresh() end,replay)
    if not opened then c.phase='ready';c.error=err end
   end
  end)
 end)
 return c
end
return Assembly
