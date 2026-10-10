local D=require('Dora')
local View={}
function View.create(world,variant,machineOrder,fieldOrder)
 local actor=require('Ground.AuxiliaryActor').create(variant or world.auxiliaryVariant or (world.groundSupport and world.groundSupport.variant))
 local machine=actor.node; machine.tag='ground-auxiliary'; machine.order=machineOrder or 20; machine:addTo(world)
 local field=D.DrawNode(); field.tag='ground-life-field'; field.order=fieldOrder or -2; field:addTo(world)
 local motes=D.DrawNode();motes:addTo(field)
 local shield=D.DrawNode();shield.tag='ground-physical-shield';shield:addTo(field)
 local radiusDrawn
 local view={machine=machine,field=field,actor=actor}; world.auxiliaryView=view
 function view:update(support,left,right)
  machine.position=D.Vec2(support.x or (left+right)/2,world.offset)
  actor:update(support,machine.x)
  field.visible=not not support.active
  if support.active then
   local radius=support.radius; local t=D.App.runningTime
   -- The dome and ellipse are static in local space; moving the node preserves them.
   if radiusDrawn~=radius then
   field:clear();radiusDrawn=radius
   for i=1,40 do
    local a=(i-1)*math.pi/40; local b=i*math.pi/40
    field:drawSegment(D.Vec2(math.cos(a)*radius,math.sin(a)*radius*.48),D.Vec2(math.cos(b)*radius,math.sin(b)*radius*.48),1.3,D.Color(0x3353e1d7))
    field:drawSegment(D.Vec2(math.cos(a*2)*radius,math.sin(a*2)*14),D.Vec2(math.cos(b*2)*radius,math.sin(b*2)*14),2,D.Color(0x6653e1d7))
   end
   end
   motes:clear()
   for i=1,5 do local x=-radius+((t*45+i*radius*.4)%(radius*2)); motes:drawDot(D.Vec2(x,8+math.sin(t*2+i)*4),2,D.Color(0x8853e1d7)) end
  end
  local physical=support.physicalShield
  shield.visible=physical~=nil and support.active and physical.charge>0
  if shield.visible then
   local fraction=physical.charge/physical.capacity
   if not view.shieldGeometryDrawn then
    view.shieldGeometryDrawn=true;shield:clear()
    local radius=require('Ground.PhysicalShield').rules.radius
    for i=1,30 do
     local a=(i-1)*math.pi/30;local b=i*math.pi/30
     shield:drawSegment(D.Vec2(math.cos(a)*radius,math.sin(a)*240),D.Vec2(math.cos(b)*radius,math.sin(b)*240),2,D.Color(0x886ddeff))
    end
   end
   shield.opacity=.25+.75*fraction
  end
  field.position=D.Vec2(machine.x,world.offset+8)
 end
 return view
end
return View
