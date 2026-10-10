-- Decision-time projection shared by upcoming resource C4.5 and Q versions.
local E=require('Training.ResourceEvidence');local F={version=1}
F.names={'kineticAmmo','empAmmo','bladeAmmo','missionBudget'}
F.categories={kineticAmmo='unequipped empty low ready',empAmmo='unequipped empty low ready',bladeAmmo='unequipped empty low ready',missionBudget='empty low ready'}
local function ammo(n)if n==nil then return 'unequipped' elseif n==0 then return 'empty' elseif n<=3 then return 'low' else return 'ready'end end
function F.project(observation)
 local resource=type(observation)=='table' and observation.resources
 if not E.observation(resource)then return nil,'RESOURCE_OBSERVATION_REQUIRED'end
 return {schemaVersion=1,kineticAmmo=ammo(resource.ammo.kinetic),empAmmo=ammo(resource.ammo.emp),bladeAmmo=ammo(resource.ammo.blade),missionBudget=resource.budgetLeft==0 and 'empty' or resource.budgetLeft<=resource.reserved*.2 and 'low' or 'ready'}
end
function F.key(observation)
 local state,why=F.project(observation);if not state then return nil,why end
 local values={};for _,name in ipairs(F.names)do values[#values+1]=state[name]end;return table.concat(values,'|')
end
return F
