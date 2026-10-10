-- Shared articulated Q companion renderer; original reference artwork stays intact.
local D=require('Dora')
local Rig={}
local manifest
function Rig.create(asset,height)
 local m=assert(D.Model(asset));m.recovery=.2;m.companionForm='nine-tail-chibi';m.sourceArt='Image/Companion/Q-huli.png'
 m.scaleX=height/699;m.scaleY=height/699
 if asset:find('v5',1,true)then
  local bindings=assert(D.json.decode(assert(D.Content:load('Image/Companion/fox-chibi-motion-v5-manifest.json'))))
  for _,name in ipairs(bindings.renderParts)do
   assert(m:getNodeByName(name)).transformTarget=assert(m:getNodeByName(name..'-bone'))
  end
 end
 m.anticipationSeconds=asset:find('v5',1,true) and .2 or 0
 m.artFacesRight=false;m.strideDistance=asset:find('v5',1,true) and 140 or 180;m.stanceSeconds=.6
 if not manifest then manifest=assert(D.json.decode(assert(D.Content:load('Image/Companion/fox-chibi-rear-hair-manifest.json'))))end
 for _,part in ipairs(manifest.parts)do
  local bone=assert(m:getNodeByName(part.name));local rect=part.rect;local anchor=part.anchor
  local stencil=D.DrawNode()
  for _,r in ipairs(part.maskRuns)do
   local x=r[1]-rect[3]*anchor[1];local y=rect[4]-r[2]-rect[4]*anchor[2]
   stencil:drawPolygon({D.Vec2(x,y),D.Vec2(x+r[3],y),D.Vec2(x+r[3],y-r[4]),D.Vec2(x,y-r[4])},D.Color(0xffffffff))
  end
  local clip=D.ClipNode(stencil);clip.alphaThreshold=.1;clip.scaleX=part.scale[1];clip.scaleY=part.scale[2];clip:addTo(bone)
  local sprite=assert(D.Sprite('Image/Companion/fox-chibi-rear-hair.clip|'..part.name));sprite.anchor=D.Vec2(anchor[1],anchor[2]);sprite:addTo(clip)
  bone.rearHairSource=manifest.source;bone.rearHairSprite=sprite;bone.rearHairMask=clip
 end
 require('Story.FoxFace').attach(m)
 m:play('idle',true);return m
end
return Rig
