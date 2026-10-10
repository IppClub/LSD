-- Pause expedition movement and life-support drain while choosing a budget.
local D=require('Dora');local M={}
function M.openAsync(world,mission,models,support,cancelled)
 local previous=world.data.storyBusy;world.data.storyBusy=true
 local entities={}
 D.Group({'unit'}):each(function(e)
  if e.unit.world==world then entities[#entities+1]={entity=e,busy=e.busy};e.busy=true;e.keyLeft=false;e.keyRight=false;e.unit.velocityX=0 end
 end)
 local hud=D.Director.ui3D:getChildByTag('ground-hud');local visible=hud and hud.visible
 if hud then hud.visible=false end
 local function restore()
  world.data.storyBusy=previous
  for _,saved in ipairs(entities)do saved.entity.busy=saved.busy end
  if hud then hud.visible=visible end
  if cancelled then cancelled()end
 end
 local panel,why=require('Economy.Preparation').openAsync(mission,models,restore,function(service,attempt)
  require(mission=='c0-yingzhao'and 'Ground.BigYingzhaoLevel'or mission=='c0-disarm'and 'Ground.DisarmLevel'or mission=='c0-m02' and 'Ground.Level' or 'Ground.EnergyLevel').openAsync(service,attempt,support)
 end)
 if not panel then restore()end
 return panel,why
end
return M
