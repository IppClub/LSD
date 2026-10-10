-- Calibrated from native xiaoyingzhao poses, 2026-10-05.
-- jump2 .20: foreclaws extended during the forward pounce.
-- kick .65: inverted body, hind hooves striking forward (not wind-up .45).
-- Damage, target sweep and locomotion belong to the encounter controller.
local T={}
function T.stages(skill)
 if skill=='jump' then return {{name='jump'},{name='jump2',impacts={.2}},{name='jump3'},{name='jump4'}} end
 if skill=='kick' then return {{name='kick',impacts={.65}}} end
 error('Unknown small Yingzhao skill: '..tostring(skill))
end
return T
