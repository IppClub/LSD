-- Render the authored clipping boundary. The second half is behind the actor;
-- the visible rim overlays the exact edge where the Spine mesh is clipped.
local D=require('Dora');local Portal={};Portal.__index=Portal
local manifest
function Portal.new(unit)
 manifest=manifest or assert(D.json.decode(D.Content:load('Data/Combat/big-shan-portals.json')))
 local back=D.DrawNode();back:addTo(unit,-10)
 local front=D.DrawNode();front:addTo(unit,10)
 return setmetatable({unit=unit,back=back,front=front,closed=false},Portal)
end
function Portal:update(opacity)
 if self.closed then return end
 local points={};local model=self.unit.playable
 for _,key in ipairs(manifest.edge)do points[#points+1]=self.unit:convertToNodeSpace(model:convertToWorldSpace(model:getKey(key)))end
 local a,b=points[1],points[#points];local dx,dy=b.x-a.x,b.y-a.y;local len=dx*dx+dy*dy
 if len<.01 then return end
 local reflected={}
 for _,p in ipairs(points)do
  local t=((p.x-a.x)*dx+(p.y-a.y)*dy)/len
  reflected[#reflected+1]=D.Vec2(2*(a.x+t*dx)-p.x,2*(a.y+t*dy)-p.y)
 end
 local polygon={};for _,p in ipairs(points)do polygon[#polygon+1]=p end
 for i=#reflected,1,-1 do polygon[#polygon+1]=reflected[i]end
 self.back:clear();self.front:clear()
 self.back.opacity=opacity or 1;self.front.opacity=opacity or 1
 self.back:drawPolygon(polygon,D.Color(0xdd111b31))
 for i=2,#points do
  self.back:drawSegment(reflected[i-1],reflected[i],9,D.Color(0x775094bd))
  self.back:drawSegment(reflected[i-1],reflected[i],3,D.Color(0xff73d9ff))
  self.front:drawSegment(points[i-1],points[i],12,D.Color(0x4450bfff))
  self.front:drawSegment(points[i-1],points[i],4,D.Color(0xff90e9ff))
 end
 self.points=points
end
function Portal:close()
 if self.closed then return end;self.closed=true
 self.back:removeFromParent();self.front:removeFromParent()
end
return Portal
