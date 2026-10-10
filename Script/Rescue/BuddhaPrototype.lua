-- Shield presentation rig. Damage and capacity remain owned by Rescue.Ward.
local D=require('Dora');local Robot={}
function Robot.create(style)
 style=style or {}
 local node=D.Node();local body=D.Node();body:addTo(node)
 local function part(index,parent,scale,anchor)
  local s=assert(D.Sprite(style.texture or 'Image/Rescue/buddha-guard-parts.png'))
  local row=style.rowHeight or 512;local h=index<3 and row or 1024-row
  s.textureRect=D.Rect((index%3)*512,index<3 and 0 or row,512,h);s.size=D.Size(512,h)
  s.anchor=anchor or D.Vec2(.5,.5);s.scaleX=scale;s.scaleY=scale;s:addTo(parent);return s
 end
 local haloScale=style.haloScale or 1.05
 local halo=part(5,body,haloScale);halo.y=style.haloY or 100;halo.order=-10
 local function independentPart(spec)
  local sprite=assert(D.Sprite(spec.texture))
  sprite.textureRect=spec.rect;sprite.size=D.Size(spec.rect.width,spec.rect.height)
  sprite.anchor=spec.anchor;sprite.scaleX=spec.scale;sprite.scaleY=spec.scale
  sprite.position=spec.position;sprite.order=spec.order or 0;sprite:addTo(body)
  return sprite
 end
 local torso
 if style.torsoPart then torso=independentPart(style.torsoPart)
 else torso=part(0,body,style.torsoScale or .85);torso.order=0;torso.y=style.torsoY or 0 end
 if style.headPart then independentPart(style.headPart) end
 local arms={}
 for side=-1,1,2 do
  for i=1,3 do
  local sideRoot=D.Node();sideRoot.scaleX=side;sideRoot.order=i==3 and 2 or -1;sideRoot:addTo(body)
  local roots=style.shoulders and style.shoulders[side]
  local shoulder=D.Node();shoulder.position=roots and roots[i] or D.Vec2(({40,75,55})[i],({15,-20,-70})[i]);shoulder.order=i==3 and 2 or -1;shoulder:addTo(sideRoot)
  part(1,shoulder,.25,style.upperAnchor or D.Vec2(.51,.81))
  local elbow=D.Node();elbow.position=style.elbowOffset or D.Vec2(0,-82);elbow:addTo(shoulder);part(2,elbow,.25,style.forearmAnchor or D.Vec2(.5,.76))
  local wrist=D.Node();wrist.position=style.wristOffset or D.Vec2(0,-85);wrist:addTo(elbow)
  local hand=part(i==3 and 4 or 3,wrist,.22,i==3 and (style.cupAnchor or D.Vec2(.15,.53))or (style.handAnchor or D.Vec2(.51,.17)));hand.angle=i==3 and -45 or 180;if i==3 then hand.scaleX=-.22 end
  arms[#arms+1]={shoulder=shoulder,elbow=elbow,wrist=wrist,hand=hand,index=i,side=side}
 end end
 local pulse=0
 node:slot('Pulse',function()pulse=.3 end)
 local time=0;local blend=0;local guarding=false;local from=0;local transition=.2
 node.recovery=.2;node.state='idle';node.completedTransitions=0
 node:slot('Guard',function(value)
  value=not not value;if value==guarding then return end
  guarding=value;from=blend;transition=0;node.state='recovering'
 end)
 node:schedule(function(dt)
  time=time+dt;local target=guarding and 1 or 0
  if transition<node.recovery then
   transition=math.min(node.recovery,transition+dt);local t=transition/node.recovery;blend=from+(target-from)*t*t*(3-2*t)
   if transition==node.recovery then node.state=guarding and 'guard'or'idle';node.completedTransitions=node.completedTransitions+1 end
  end
  pulse=math.max(0,pulse-dt)
  body.y=math.sin(time*1.4)*5;halo.angle=math.sin(time*.3)*4;halo.opacity=math.min(1,.7+blend*.2+pulse)
  halo.scaleX=haloScale+pulse*.2;halo.scaleY=halo.scaleX
  for _,a in ipairs(arms)do
   local base=style.shoulderAngles and style.shoulderAngles[a.side]
   a.shoulder.angle=(base and base[a.index] or ({-140,-75,-20})[a.index])+math.sin(time*1.2+a.index)*3-blend*12
   a.elbow.angle=({65,55,65})[a.index]+blend*20
   if a.index==3 then a.hand.angle=-a.shoulder.angle-a.elbow.angle end
  end
  return false
 end)
 node.arms=arms;return node
end
return Robot
