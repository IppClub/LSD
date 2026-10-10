local D=require('Dora');local R={};local manifest
function R.point(unit,world)
 -- Flush the moved physics parent's transform before querying its Spine child.
 -- Child world matrices are invalidated lazily when the parent is resolved.
 unit:convertToWorldSpace(D.Vec2.zero)
 manifest=manifest or assert(D.json.decode(D.Content:load('Data/Combat/big-shan-release.json')))
 local x,y=0,0
 for _,ref in ipairs(manifest.front.refs)do local p=unit.playable:getKey(ref.key);x=x+p.x*ref.weight;y=y+p.y*ref.weight end
 return world:convertToNodeSpace(unit.playable:convertToWorldSpace(D.Vec2(x,y)))
end
return R
