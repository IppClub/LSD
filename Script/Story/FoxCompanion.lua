-- Temporary original Q artwork while the rejected cutout rig is replaced by Spine.
local D=require('Dora')
local Fox={asset='Image/Companion/fox-chibi.model',referenceAsset='Image/Companion/fox-chibi.model',height=300,walkSpeed=240,walkAnimationSpeed=.85}
function Fox.loadAsync() D.Cache:loadAsync(Fox.asset)end
function Fox.create()
 local m=assert(D.Model(Fox.asset));m.recovery=.2;m.sourceArt='Image/Companion/Q-huli.png'
 m.companionForm='nine-tail-chibi';m.motionVariant='original-q-reference';m.artFacesRight=false;m.candidate=false
 m.scaleX=Fox.height/699;m.scaleY=Fox.height/699;m:play('idle',true)
 return m
end
-- The corrected Spine rig is used by movement scenes; the portrait constructor
-- remains available to existing portrait-based interrogation choreography.
Fox.animatedAsset='Spine/FoxPrototype/fox-runtime.json|Spine/FoxPrototype/fox-chibi-spine.atlas'
function Fox.loadAnimatedAsync() D.Cache:loadAsync('spine:'..Fox.animatedAsset)end
function Fox.createAnimated()
 local m=assert(D.Spine(Fox.animatedAsset));m.recovery=.2
 m.sourceArt='Image/Companion/Q-huli.png';m.companionForm='nine-tail-chibi'
 m.motionVariant='spine-corrected';m.artFacesRight=false;m.candidate=false
 m.scaleX=Fox.height/699;m.scaleY=Fox.height/699
 -- Tune gait cadence independently of world travel speed.
 m.walkAnimationSpeed=Fox.walkAnimationSpeed;m.moveAnimation='fmove';m.movementState='idle';m.strideDistance=192;m.stanceSeconds=1
 m:play('idle',true)
 return m
end
return Fox
