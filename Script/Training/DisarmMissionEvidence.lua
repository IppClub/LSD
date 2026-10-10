local M={}
function M.validate(e)
 if type(e)~='table'or e.schemaVersion~=1 or e.closed~=true or type(e.versions)~='table'or e.versions.disarm~=1 or e.versions.resources~=1 or e.versions.resourceSimulation~=nil or e.trainable~=false then return false,'INVALID_DISARM_MISSION'end
 local t=e.disarm
 if type(t)~='table'or t.kind~='disarm-mission'or t.demonstrator or t.candidate or t.comparisonSetup or not t.resources or t.resources.mode~='mission'or e.episode~=t.resources.attempt or not require('Training.FlowerIdentity').equal(e.resources,t.resources)then return false,'INVALID_DISARM_MISSION'end
 if not t.encounter or t.encounter.asset~='zhongyingzhao'or type(t.encounter.enemyHP)~='number'or t.encounter.enemyHP~=t.encounter.enemyHP or t.encounter.enemyHP<0 or t.encounter.enemyHP>360 then return false,'INVALID_ENCOUNTER'end
 if t.status=='won'and (t.encounter.enemyHP~=0 or not t.encounter.defeated)then return false,'UNFINISHED_ENCOUNTER'end
 local credit,why=require('Training.DisarmCredit').rebuild(t);if not credit then return false,why end
 for _,s in ipairs(t.executions)do if s.source~='model'and s.source~='adopted-disarm'then return false,'INVALID_MISSION_CONTROLLER'end end
 return true
end
return M
