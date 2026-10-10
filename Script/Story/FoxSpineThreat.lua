-- Reuse the existing transparent fang patch, following native animated head points.
local D=require('Dora');local Threat={}
function Threat.attach(model)
 local patch=assert(D.Sprite('Image/Companion/fox-snarl-mouth-v1.png'))
 local scale=116/patch.width;patch.scaleX=scale;patch.scaleY=scale;patch.visible=false;patch:addTo(model,100)
 local state={patch=patch,frames=0,active=false,alive=true}
 model:slot('Cleanup',function()state.alive=false;state.active=false end)
 local tick=D.Node();tick.scheduler=D.Director.postScheduler;tick:addTo(model)
 tick:schedule(function()
  if state.active then
   local p=model:getKey('mouthCenter/mouthCenter');local q=model:getKey('mouthAxis/mouthAxis')
   assert(p.y>100,'Fox mouth anchor missing')
   local sign=q.x>=p.x and 1 or -1
   patch.position=p;patch.scaleX=scale*sign
   patch.angle=-math.deg(math.atan((q.y-p.y)*sign,(q.x-p.x)*sign))
   state.frames=state.frames+1
  end
  return false
 end)
 function state:show(value)self.active=value;patch.visible=value end
 function state:warnAsync()
  if not self.alive then return nil,'CANCELLED' end
  if self.active then return nil,'BUSY' end
  self:show(true);local began=D.App.runningTime
  while self.alive and D.App.runningTime-began<1.2 do D.sleep(.02)end
  if not self.alive then return nil,'CANCELLED' end
  self:show(false);return true
 end
 function state:dispose()self.alive=false;self.active=false;tick:removeFromParent();patch:removeFromParent()end
 return state
end
return Threat
