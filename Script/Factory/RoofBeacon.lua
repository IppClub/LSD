-- Bone-following arm mark and cannon light; no character mesh is modified.
local D=require('Dora');local Beacon={}
function Beacon.attach(world,model)
 local state={active=false,frames=0,elapsed=0};local mark=D.DrawNode();mark:addTo(model,100);mark.visible=false;state.mark=mark
 for _,r in ipairs({13,8})do
  local points={};for i=0,24 do local t=i/24*math.pi*2;points[#points+1]=D.Vec2(math.cos(t)*r,math.sin(t)*r*.65)end
  for i=1,#points-1 do mark:drawSegment(points[i],points[i+1],r==13 and 1.4 or .8,D.Color(0xffa2f6ff))end
 end
 for _,x in ipairs({-5,0,5})do mark:drawSegment(D.Vec2(x,-6),D.Vec2(x,6),.8,D.Color(0xffe1ffff))end
 local beam=D.DrawNode();beam.position=D.Vec2(2820,1725);beam:addTo(world,31);beam.visible=false;state.beam=beam
 for _,s in ipairs({{68,0x1256dfff},{42,0x247cefff},{23,0x509efaff},{9,0xb8e2ffff}})do
  beam:drawPolygon({D.Vec2(-s[1],0),D.Vec2(s[1],0),D.Vec2(s[1]*1.4,1100),D.Vec2(-s[1]*1.4,1100)},D.Color(s[2]))
 end
 local motes=D.DrawNode();motes:addTo(beam);local tick=D.Node();tick.scheduler=D.Director.postScheduler;tick:addTo(world)
 tick:schedule(function(dt)
  if state.active then
   state.elapsed=state.elapsed+dt;local p=model:getKey('roofMark/roofMark');local q=model:getKey('roofMarkAxis/roofMarkAxis')
   assert((q-p).length>1,'Wuyun forearm anchors missing')
   mark.position=p;mark.angle=-math.deg(math.atan(q.y-p.y,q.x-p.x));mark.opacity=.8+.2*math.sin(state.elapsed*4)
   beam.opacity=math.min(1,state.elapsed/1.4)*(.88+.12*math.sin(state.elapsed*3));motes:clear()
   for i=1,12 do local y=(i*83+state.elapsed*170)%1000;local x=math.sin(i*2.4+state.elapsed)*27;motes:drawDot(D.Vec2(x,y),1.8,D.Color(0xffd9ffff))end
   state.frames=state.frames+1;state.lastAnchor={x=p.x,y=p.y};state.lastAxis={x=q.x,y=q.y}
  end
  return false
 end)
 function state:activate()self.active=true;mark.visible=true;beam.visible=true end
 function state:dispose()self.active=false;tick:removeFromParent();mark:removeFromParent();beam:removeFromParent()end
 return state
end
return Beacon
