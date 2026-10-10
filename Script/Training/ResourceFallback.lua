-- Conservative resource-aware base fallback. Never filters learned Q actions.
local M={version=3}
function M.valid(setup,episode)
 local v=setup and setup.resourceFallback
 return type(episode)=='table' and type(episode.versions)=='table' and v==episode.versions.resourceFallback
  and (v==nil or (v==1 or v==2 or v==3) and episode.resources and episode.resources.mode=='virtual')
end
function M.predict(base,baseState,available,observation,version)
 version=version or 2;assert(version==1 or version==2 or version==3,'INVALID_RESOURCE_FALLBACK_VERSION')
 assert(require('Training.FlowerFeatures').validate(observation),'INVALID_RESOURCE_FALLBACK_OBSERVATION')
 assert(require('Training.ResourceEvidence').observation(observation.resources),'INVALID_RESOURCE_FALLBACK_RESOURCES')
 local action,why=require('Training.Model').predict(base,baseState,function(a)return available[a]end)
 if action=='laser'then
  local empty=(observation.resources.ammo.emp or 0)==0
  local exposed=observation.target=='boss'
  for name in pairs(require('Training.FlowerFeatures').parts)do
   local value=observation['part_'..name]
   if value~='exposed' and value~='unarmored'then exposed=false end
  end
  -- In this encounter small flowers/buds have only HP; EMP deals AP damage only.
  -- Use the observed target class, never later hit results or hidden boss armor.
  local small=version>=3 and (observation.target=='flower' or observation.target=='bud')
  if empty or exposed or small then action=nil;why=empty and 'EMP_EMPTY' or small and 'SMALL_TARGET_UNARMORED' or 'KNOWN_BOSS_UNARMORED'end
 end
 if not action and available.idle then action='idle'end
 return action,why
end
return M
