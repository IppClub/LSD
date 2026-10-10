-- Authored rob3 reaches down before bringing the captured weapon back up.
local T={}
function T.stages(skill)
 if skill=='rob' then return {{name='rob'},{name='rob2'},{name='rob3',impacts={.2}},{name='rob4'}} end
 if skill=='punch' then return {{name='punch',impacts={1}}} end
 if skill=='shoot' then return {{name='shoot',impacts={1/3}}} end
 error('Unknown medium Yingzhao skill: '..tostring(skill))
end
return T
