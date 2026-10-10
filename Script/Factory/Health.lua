-- Preserve the injured party between victory, material collection and treatment.
local D=require("Dora")
local Health={}
function Health.load()
 local treated=D.DB:query("SELECT id FROM lsd.Game0StoryNodes WHERE id='medical-recovery'")
 if treated and treated[1] then return {100,100,100} end
 local rows=D.DB:query("SELECT report FROM lsd.Game0MissionAttempts WHERE mission='c0-m05' AND status='won' ORDER BY id DESC LIMIT 1")
 local report=rows and rows[1] and D.json.decode(rows[1][1],32)
 if report and report.learners then return {report.mentorHP,report.learners.ninilite.hp,report.learners.wuyun.hp} end
 return {100,100,100}
end
return Health
