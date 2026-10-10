-- Candidate adapter: weighted point attachments expose animated hull vertices
-- through the existing Spine API. Manifest and skeleton must be exported together.
local D=require('Dora')
local Regions={}
function Regions.sample(model,manifest,toNode)
 local result={};local keys={};local bases={}
 local function key(name)
  local point=keys[name];if not point then point=model:getKey(name);keys[name]=point end;return point
 end
 for _,part in ipairs(manifest)do
  local vertices={};local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
  for _,refs in ipairs(part.vertices)do
   local x,y=0,0
   for _,ref in ipairs(refs)do
    local px,py
    if ref.basis then
     local basis=bases[ref.basis]
     if not basis then
      local prefix=ref.basis
      local o=key(prefix..'-o/'..prefix..'-o');local u=key(prefix..'-x/'..prefix..'-x');local v=key(prefix..'-y/'..prefix..'-y')
      basis={o.x,o.y,(u.x-o.x)/1024,(u.y-o.y)/1024,(v.x-o.x)/1024,(v.y-o.y)/1024};bases[prefix]=basis
     end
     px=basis[1]+basis[3]*ref.x+basis[5]*ref.y;py=basis[2]+basis[4]*ref.x+basis[6]*ref.y
    else local p=key(ref.lookupPath or ref.key);px,py=p.x,p.y end
    x=x+px*ref.weight;y=y+py*ref.weight
   end
   local point=D.Vec2(x,y)
   if toNode then point=toNode:convertToNodeSpace(model:convertToWorldSpace(point))end
   local px,py=point.x,point.y
   minX=math.min(minX,px);minY=math.min(minY,py);maxX=math.max(maxX,px);maxY=math.max(maxY,py)
   vertices[#vertices+1]={x=px,y=py}
  end
  result[#result+1]={id=part.id,priority=part.priority or 0,vertices=vertices,bounds={minX=minX,minY=minY,maxX=maxX,maxY=maxY}}
 end
 return result
end
return Regions
