-- Candidate adapter: weighted point attachments expose animated hull vertices
-- through the existing Spine API. Manifest and skeleton must be exported together.
local D=require('Dora')
local Regions={}
function Regions.sample(model,manifest,toNode)
 local result={}
 for _,part in ipairs(manifest)do
  local vertices={}
  for _,refs in ipairs(part.vertices)do
   local x,y=0,0
   for _,ref in ipairs(refs)do local p=model:getKey(ref.key);x=x+p.x*ref.weight;y=y+p.y*ref.weight end
   local point=D.Vec2(x,y)
   if toNode then point=toNode:convertToNodeSpace(model:convertToWorldSpace(point))end
   vertices[#vertices+1]={x=point.x,y=point.y}
  end
  result[#result+1]={id=part.id,priority=part.priority or 0,vertices=vertices}
 end
 return result
end
return Regions
