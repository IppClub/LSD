-- Per-part knowledge comes from observed hit feedback, never hidden armor.
local F={version=4,names={},parts={head='head',gem='head-gem',front_back='back-front',rear_back='back-rear',front_leg='front-leg',rear_leg='rear-leg',tail='tail'},categories={}}
local labels={'head','gem','front_back','rear_back','front_leg','rear_leg','tail'}
for _,label in ipairs(labels)do
 local name='part_'..label;F.names[#F.names+1]=name
 F.categories[name]={unknown=true,blocked=true,armored=true,exposed=true,unarmored=true}
end
function F.value(state,name)if state[name]==nil then return 'unknown'end;return state[name]end
function F.validate(state)
 for _,name in ipairs(F.names)do if not F.categories[name][F.value(state,name)]then return false,'INVALID_'..name end end
 return true
end
function F.capture(state,known,reachable)
 local result={};for k,v in pairs(state)do result[k]=v end
 for _,label in ipairs(labels)do
  local part=F.parts[label];local observation=known[part]
  local value='unknown'
  if not reachable(part)then value='blocked'
  elseif observation then value=observation.maxAP==0 and 'unarmored' or observation.ap<=0 and 'exposed' or 'armored'end
  result['part_'..label]=value
 end
 return result
end
function F.reachable(state,part)
 for label,id in pairs(F.parts)do if id==part then local value=state['part_'..label];return value~=nil and value~='blocked'end end
 return false
end
return F
