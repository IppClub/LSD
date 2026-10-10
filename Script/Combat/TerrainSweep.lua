-- Terrain and animated parts compete along the same point-projectile segment.
local D=require('Dora')
local T={}
function T.first(world,from,to,part)
 local dx,dy=to.x-from.x,to.y-from.y;local length2=dx*dx+dy*dy
 if length2<=1e-16 then return part,false end
 local nearest
 -- Physics enumeration is not distance ordered. Inspect every terrain hit.
 world:raycast(D.Vec2(from.x,from.y),D.Vec2(to.x,to.y),false,function(body,point)
  if body.group==D.Platformer.Data.groupTerrain then
   local t=((point.x-from.x)*dx+(point.y-from.y)*dy)/length2
   if t>=-1e-8 and t<=1+1e-8 and (not nearest or t<nearest)then nearest=t end
  end
  return false
 end)
 -- Terrain wins coincident contacts, preventing damage through a wall edge.
 if nearest and (not part or nearest<=part.t+1e-8)then return nil,true end
 return part,false
end
return T
