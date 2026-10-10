-- Expression layer for the intact original Q fox; follows the portrait's idle motion.
local D=require('Dora');local Threat={}
function Threat.attach(model)
 local portrait=assert(model:getNodeByName('original-art'),'Original Q fox portrait required')
 local patch=assert(D.Sprite('Image/Companion/fox-snarl-mouth-v1.png'))
 patch.scaleX=110/patch.width;patch.scaleY=50/patch.height
 patch.position=D.Vec2(263,445);patch.order=10;patch.visible=false;patch:addTo(portrait)
 local state={patch=patch,active=false,alive=true}
 model:slot('Cleanup',function()state.alive=false end)
 function state:show(value)self.active=value;patch.visible=value end
 function state:warnAsync()
  if self.active then return nil,'BUSY' end
  self:show(true);local began=D.App.runningTime
  while self.alive and D.App.runningTime-began<1.2 do D.sleep(.02)end
  if not self.alive then return nil,'CANCELLED'end
  self:show(false);return true
 end
 return state
end
return Threat
