-- Small projecting brackets on the wall edge, aligned to the authored contacts.
local D=require('Dora');local G=require('Factory.RoofGeometry');local Climb=require('Factory.RoofClimb');local Holds={}
function Holds.build(world,names)
 local node=D.DrawNode();node:addTo(world,19);local points={}
 for _,name in ipairs(names)do
  local def=Climb.definition(name);local cycles=math.floor((G.top-G.stairY-def.HandL.highY)/Climb.rise)
  for _,key in ipairs({'HandL','HandR','FootL','FootR'})do
   local h=def[key]
   for row=0,cycles do
    local p=D.Vec2(G.climbX+h.x,G.stairY+h.highY-Climb.rise*h.phase+Climb.rise*row)
    if p.y<G.top-3 then
     local known=false;for _,old in ipairs(points)do if math.abs(old.x-p.x)<.1 and math.abs(old.y-p.y)<.1 then known=true;break end end
     if not known then
      points[#points+1]=p;local mount=D.Vec2(G.wallX+13,p.y-5)
      node:drawSegment(p-D.Vec2(4,3),mount,4,D.Color(0xff293536))
      node:drawSegment(p,mount+D.Vec2(0,5),2.4,D.Color(0xffad9870))
      node:drawSegment(p+D.Vec2(0,1.8),mount+D.Vec2(0,6.8),.7,D.Color(0xffded1ad))
      node:drawDot(mount,3,D.Color(0xff52605d));node:drawDot(mount,1,D.Color(0xffd0c096))
     end
    end
   end
  end
 end
 return {node=node,points=points}
end
return Holds
