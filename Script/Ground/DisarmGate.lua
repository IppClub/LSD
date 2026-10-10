-- Optional chapter-two encounter; does not gate energy recovery or story nodes.
local D=require('Dora');local M={}
function M.attach(world,support)
 local c={};world.disarmGate=c
 local anchor=D.Node();anchor.position=D.Vec2(4650,world.offset+150);anchor:addTo(world)
 local menu=require('UI.Interaction')({text='英招调查 · 可选任务',buttons={{'准备清障',''},{'大英招讨伐',''}},fliped=false})
 menu.tag='disarm-terminal';menu.transformTarget=anchor;menu.scaleX=.325;menu.scaleY=.325;menu.visible=false;menu.menu.enabled=false;menu:addTo(world);c.menu=menu
 local label=D.Label('SourceHanSansCN-Regular',23);label.textWidth=700;label.position=D.Vec2(0,240);label:addTo(anchor);c.label=label
 local near=false;local busy=false
 anchor:schedule(function()
  local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end)
  local value=not not(p and not p.busy and not world.data.storyBusy and not world.data.journalOpen and math.abs(p.unit.x-anchor.x)<180)
  if value~=near then near=value;if near then menu.visible=true;menu:show()else menu:hide(false)end end
  return false
 end)
 menu:slot('Tapped',function(index)
  if not near or busy then return end;busy=true
  D.thread(function()
   local mission=index==2 and 'c0-yingzhao'or'c0-disarm'
   if mission=='c0-yingzhao'then
    local service,why=require('Mission.Service').open();local facts=service and service:summary()
    if not facts then label.text='任务记录暂时无法读取，请重试。';busy=false;return end
    if not facts.unlocks['yingzhao-route-cleared']then label.text='先完成中英招清障，再准备大英招讨伐。';busy=false;return end
   end
   local models,why=require('Training.FlowerPractice').models()
   if not models then label.text='先完成两名学员的基础训练并采用成果。';busy=false;return end
   c.supplyPanel,why=require('Ground.Preparation').openAsync(world,mission,models,support,function()c.supplyPanel=nil;busy=false end)
   if not c.supplyPanel then label.text='补给准备未完成：'..tostring(why);busy=false end
  end)
 end)
 return c
end
return M
