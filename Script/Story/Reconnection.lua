-- Chapter three opening adapted from the original synopsis; no battle victory is implied.
local D=require('Dora');local Reconnection={}
function Reconnection.attach(world)
 if world.reconnection then return world.reconnection end
 if world.tag~='OperationRoom'and world.tag~='RDRoom'then return end
 local service=assert(require('Story.Service').open());local facts=assert(service:summary())
 if not facts.completed['roof-aftermath']then return end
 local research=world.tag=='RDRoom';local id=research and 'network-warning'or'return-online'
 local c={phase='ready',service=service,id=id};world.reconnection=c
 local marker=D.Node();marker.tag=research and 'network-monitor-ready'or'return-online-ready';marker.position=D.Vec2(world.sceneWidth/2,world.offset+190);marker:addTo(world);c.marker=marker
 local buttons={{research and '读取监测记录'or'接听通讯',''}};if not research then buttons[2]={'任务与编队',''}end
 local menu=require('UI.Interaction')({text=research and '信道监测台'or'羽凌灵的通讯',buttons=buttons,fliped=false});menu.transformTarget=marker;menu.x=180;menu.order=100;menu.scaleX=.325;menu.scaleY=.325;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
 local panel=D.DrawNode();panel.position=marker.position+D.Vec2(0,220);panel:addTo(world);c.panel=panel
 local label=D.Label('SourceHanSansCN-Regular',24);label.position=panel.position+D.Vec2(0,92);label:addTo(world);c.label=label
 local elapsed=0;local near=false;local last=-1
 local function refresh()
  facts=assert(service:summary())
  label.text=facts.completed[id]and (research and '异常信道已记录'or'通讯已保存')or research and (facts.completed['return-online']and '收到信道监测记录'or'等待指挥室通讯')or'新来电 · 羽凌灵'
 end
 refresh()
 local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end)end
 function c:request()
  if self.phase~='ready'or world.data.storyBusy or world.data.journalOpen then return nil,'BUSY'end
  local p=player();if not p or math.abs(p.unit.x-marker.x)>=180 then return nil,'DISCOVERY_LOCATION_REQUIRED'end
  self.phase='opening'
  local flow,why=require('Story.Flow').openAsync(id,world,function()self.phase='ready';refresh()end,facts.completed[id]or false)
  if not flow then self.phase='ready';self.error=why;label.text=why=='STORY_LOCKED'and '先回指挥室接听羽凌灵通讯'or'通讯暂不可用，请重试。'end
  return flow,why
 end
 menu:slot('Tapped',function(index)if near then D.thread(function()if index==2 and not research then world.missionBriefing=require('Mission.Briefing').openAsync()else c:request()end end)end end)
 local tick=D.Node();tick:addTo(world);tick:schedule(function(dt)
  elapsed=elapsed+dt
  if elapsed-last>.5 then refresh();last=elapsed end
  local p=player();local now=c.phase=='ready'and p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-marker.x)<180
  if (not not now)~=near then near=not not now;if near then menu.visible=true;menu:show()else menu:hide(false)end end
  panel:clear();panel:drawPolygon({D.Vec2(-115,-55),D.Vec2(115,-55),D.Vec2(115,55),D.Vec2(-115,55)},D.Color(0xe5122734),2,D.Color(0xff79d7e8))
  local color=research and facts.completed['return-online']and D.Color(0xffffb35c)or D.Color(0xff79d7e8)
  for i=0,44 do
   local x=-108+i*4.8;local y=math.sin(i*.55-elapsed*3)*(research and (8+16*math.sin(i*.17)^2)or 14)
   local nextY=math.sin((i+1)*.55-elapsed*3)*(research and (8+16*math.sin((i+1)*.17)^2)or 14)
   panel:drawSegment(D.Vec2(x,y),D.Vec2(x+4.8,nextY),1,color)
  end
  return false
 end)
 return c
end
return Reconnection
