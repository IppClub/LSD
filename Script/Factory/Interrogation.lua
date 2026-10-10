-- Original 2-15 dialogue owns a temporary actor stage; saves only after the final row.
local D=require('Dora');local Stage={}
function Stage.openAsync(world,onClosed)
 local service,why=require('Story.Service').open();if not service then return nil,why end
 local allowed,err=service:canRead('researcher-interrogation',world.tag,false);if not allowed then return nil,err end
 if service:summary().completed['researcher-interrogation'] then return nil,'ALREADY_INTERROGATED'end
 local c={report={version=1},hidden={},commands={}};world.interrogation=c
 local pair=require('Factory.InterrogationActors').new(world);pair.node.position=D.Vec2(4290,world.offset);pair:addCompanions(require('Data.Config').char=='charF' and 'charF' or 'charM');c.actors=pair
 local function hide(node)if node then c.hidden[#c.hidden+1]={node=node,visible=node.visible};node.visible=false end end
 D.Group({'name','unit'}):each(function(e)if e.unit.world==world then hide(e.unit)end end)
 if world.infiltration then hide(world.infiltration.researcher);hide(world.infiltration.fox)end
 local commands=require('System.Command');local disposed=false
 local function dispose()
  if disposed then return end;disposed=true
  for name,entry in pairs(c.commands)do if commands[name]==entry.callback then commands[name]=entry.previous end end
  for _,entry in ipairs(c.hidden)do entry.node.visible=entry.visible end
  if pair.alive then pair.node:removeFromParent()end
 end
 world:slot('Cleanup',function()
  if not disposed then
   disposed=true
   for name,entry in pairs(c.commands)do if commands[name]==entry.callback then commands[name]=entry.previous end end
  end
 end)
 local function install(name,fn)
  local entry={previous=rawget(commands,name)};c.commands[name]=entry
  entry.callback=function()
   D.thread(function()
    local flow=world.storyFlow;local view=flow and flow.view
    local scale,effect=D.View.scale,D.View.postEffect
    if view then view.visible=false;D.View.scale=view._viewScale or scale;D.View.postEffect=view._viewEffect end
    local ok,actionError=fn()
    if not ok then
     -- The engine swallows thread errors; restore the view so the scene stays operable.
     print('Interrogation: stage failed '..tostring(actionError))
     if world.parent and view then view.visible=true;D.View.scale=scale;D.View.postEffect=effect end
     return
    end
    c.report.events=pair.events
    if world.parent then
     if view then view.visible=true;D.View.scale=scale;D.View.postEffect=effect end
     D.emit('Story.Advance')
    end
   end)
   coroutine.yield('Command')
  end
  commands[name]=entry.callback
 end
 install('researcherCover',function()return pair:coverAsync()end)
 install('researcherRelease',function()return pair:releaseAsync()end)
 install('researcherFoxWarning',function()return pair:warnAsync()end)
 install('researcherSlap',function()return pair:slapAsync()end)
 local flow,flowError=require('Story.Flow').openAsync('researcher-interrogation',world,function()
  c.phase='complete';dispose();if onClosed then onClosed(c)end
 end,false)
 if not flow then dispose();return nil,flowError end
 c.flow=flow;c.phase='dialogue';return c
end
return Stage
