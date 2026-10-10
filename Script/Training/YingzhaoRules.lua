-- Change this version when encounter, resource or action semantics change.
local R={version='big-yingzhao-deployment-v4-living-squad'}
function R.current(setup)return type(setup)=='table'and setup.schemaVersion==1 and setup.combatRules==R.version end
return R
