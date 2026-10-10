-- Bump when the encounter, weapon economy, or action semantics change.
-- Historical comparisons remain readable; activation requires this version.
local R={version='medium-yingzhao-resources-v1'}
function R.current(setup)return type(setup)=='table'and setup.combatRules==R.version end
return R
