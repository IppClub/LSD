local D=require('Dora');local R={};local manifest
function R.point(unit,world,skill,index)
 manifest=manifest or assert(D.json.decode(D.Content:load('Data/Combat/shan-release.json')))
 local hand=skill=='litter' and index==1 and 'rear' or 'front'
 local x,y=0,0
 for _,ref in ipairs(manifest[hand].refs)do local p=unit.playable:getKey(ref.key);x=x+p.x*ref.weight;y=y+p.y*ref.weight end
 return world:convertToNodeSpace(unit.playable:convertToWorldSpace(D.Vec2(x,y))),hand
end
return R
