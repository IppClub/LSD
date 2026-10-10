-- Weighted attachments expose the animated hull. Manifests are immutable for
-- an export; cache only their lookup plan, never a pose or returned vertices.
local D=require('Dora')
local Regions={}
local plans=setmetatable({},{__mode='k'})
local function compile(manifest)
 local plan={parts={},keys={},bases={}};local keyIds,basisIds={},{}
 local function key(name)
  local id=keyIds[name]
  if not id then id=#plan.keys+1;keyIds[name]=id;plan.keys[id]=name end
  return id
 end
 for _,part in ipairs(manifest)do
  local p={id=part.id,geometryId=part.geometryId,priority=part.priority or 0,vertices={}}
  for _,refs in ipairs(part.vertices)do
   local vertex={}
   for _,ref in ipairs(refs)do
    if ref.basis then
     local id=basisIds[ref.basis]
     if not id then
      id=#plan.bases+1;basisIds[ref.basis]=id
      local prefix=ref.basis
      local function probe(suffix)local name=prefix..'-'..suffix;return key((ref.basisSlot or name)..'/'..name)end
      plan.bases[id]={probe('o'),probe('x'),probe('y')}
     end
     vertex[#vertex+1]={id,ref.weight,ref.x*ref.weight,ref.y*ref.weight}
    else vertex[#vertex+1]={false,ref.weight,key(ref.lookupPath or ref.key)}end
   end
   p.vertices[#p.vertices+1]=vertex
  end
  plan.parts[#plan.parts+1]=p
 end
 plans[manifest]=plan;return plan
end
function Regions.sample(model,manifest,toNode)
 local plan=plans[manifest] or compile(manifest)
 local points,bases={},{}
 for i,name in ipairs(plan.keys)do
  local p=model:getKey(name);points[i]={p.x,p.y}
 end
 for i,ids in ipairs(plan.bases)do
  local o,u,v=points[ids[1]],points[ids[2]],points[ids[3]]
  bases[i]={o[1],o[2],(u[1]-o[1])/1024,(u[2]-o[2])/1024,(v[1]-o[1])/1024,(v[2]-o[2])/1024}
 end
 -- Node transforms are affine, including reflected/non-uniform parent scales.
 local transform
 if toNode then
  local function convert(x,y)return toNode:convertToNodeSpace(model:convertToWorldSpace(D.Vec2(x,y)))end
  local o,u,v=convert(0,0),convert(1024,0),convert(0,1024)
  transform={o.x,o.y,(u.x-o.x)/1024,(u.y-o.y)/1024,(v.x-o.x)/1024,(v.y-o.y)/1024}
 end
 local result={}
 for _,part in ipairs(plan.parts)do
  local vertices={};local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
  for _,refs in ipairs(part.vertices)do
   local x,y=0,0
   for _,ref in ipairs(refs)do
    if ref[1] then
     local b=bases[ref[1]];local w,xw,yw=ref[2],ref[3],ref[4]
     x=x+b[1]*w+b[3]*xw+b[5]*yw;y=y+b[2]*w+b[4]*xw+b[6]*yw
    else local p=points[ref[3]];x=x+p[1]*ref[2];y=y+p[2]*ref[2]end
   end
   local px,py=x,y
   if transform then px=transform[1]+transform[3]*x+transform[5]*y;py=transform[2]+transform[4]*x+transform[6]*y end
   if px<minX then minX=px end;if py<minY then minY=py end
   if px>maxX then maxX=px end;if py>maxY then maxY=py end
   vertices[#vertices+1]={x=px,y=py}
  end
  result[#result+1]={id=part.id,geometryId=part.geometryId,priority=part.priority,vertices=vertices,bounds={minX=minX,minY=minY,maxX=maxX,maxY=maxY}}
 end
 return result
end
return Regions
