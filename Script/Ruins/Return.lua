-- Both physical return-route entry points converge on original 2-11.
local D=require('Dora');local Return={}
function Return.openAsync(world)
 local story=assert(require('Story.Service').open());local facts=assert(story:summary())
 if not facts.completed['ayan-recovery'] then return nil,'STORY_LOCKED' end
 if facts.mission.unlocks['ruins-diversion-complete'] then require('Academy.Navigation').returnToRoomAsync('OuterHeaven',{spawn=1800,valleyVisit=true});return true end
 local p=D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==world end);if not p then return nil,'NO_PLAYER' end
 local marker=world:getChildByTag('ruins-ambush-ready')
 if not marker then marker=D.Node();marker.tag='ruins-ambush-ready';marker:addTo(world) end;marker.x=p.unit.x
 local c=world.ruinsReturn or {phase='ready'};world.ruinsReturn=c
 if c.phase~='ready' then return nil,'BUSY' end
 local function begin()
  c.phase='starting';world.data.storyBusy=true;require('Story.Flow').freeze(world,true)
  D.thread(function()
   local function restore()c.supplyPanel=nil;c.phase='ready';world.data.storyBusy=false;require('Story.Flow').freeze(world,false)end
   local panel,err=require('Economy.Preparation').openAsync('c0-m06',nil,restore,function(service,attempt)
    c.supplyPanel=nil;require('Ruins.PursuitLevel').openAsync(service,attempt)
   end)
   c.supplyPanel=panel
   if not panel then c.error=err;restore()end
  end)
 end
 if facts.completed['ruins-ambush'] then begin();return c end
 c.phase='dialogue'
 local flow,err=require('Story.Flow').openAsync('ruins-ambush',world,function() c.phase='ready';begin() end)
 if not flow then c.phase='ready';return nil,err end
 c.flow=flow;return c
end
return Return
