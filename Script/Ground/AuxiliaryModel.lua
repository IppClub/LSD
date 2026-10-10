-- Original transparent artwork, with native stencil masks for atlas neighbours.
-- No raster rewrite: the original source PNG hashes remain unchanged.
local D=require('Dora')
local Model={}
local base='Image/Auxiliary/'
local manifest
function Model.create(variant)
 variant=variant or 'defence'
 if not manifest then manifest=assert(D.json.decode(assert(D.Content:load(base..'manifest.json')))) end
 local definition=assert(manifest.variants[variant],'Unknown auxiliary variant')
 local model=assert(D.Model(base..variant..'.model')); model.recovery=.2
 model.auxiliaryParts=definition.parts
 for index,part in ipairs(definition.parts) do
  local joint=assert(model:getNodeByName(part.name)); joint.order=index
  if type(part.maskRuns)=="table" then
   local node=assert(model:getNodeByName(part.name)); local parent=node.parent
   local rect=part.rect; local anchor=part.anchor
   local stencil=D.DrawNode()
   for _,r in ipairs(part.maskRuns) do
    local x=r[1]-rect[3]*anchor[1]; local y=rect[4]-r[2]-rect[4]*anchor[2]
    stencil:drawPolygon({D.Vec2(x,y),D.Vec2(x+r[3],y),D.Vec2(x+r[3],y-r[4]),D.Vec2(x,y-r[4])},D.Color(0xffffffff))
   end
   local clip=D.ClipNode(stencil); clip.order=index; clip.alphaThreshold=.1; clip:addTo(parent)
   node:removeFromParent(false); node.order=0; node:addTo(clip)
   local function sync() stencil.position=node.position; stencil.angle=node.angle; stencil.scaleX=node.scaleX; stencil.scaleY=node.scaleY end
   sync(); clip:schedule(function() sync(); return false end)
  end
 end
 return model
end
return Model
