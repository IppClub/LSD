-- Departure affects present-day actors and deployment, never historical training data.
local D=require('Dora')
local Availability={}
function Availability.canDeploy(id)
 if D.DB:existDB('lsd')and require('Story.AcademyLoss').isDamaged()then
  local roster,why=require('Story.AcademyLossRecords').saved();if not roster then return false,why end
  for _,r in ipairs(roster)do if r.role==id and (r.status=='deceased'or r.status=='previously-deceased')then return false,'CHARACTER_DECEASED'end end
 end
 if id~='wuyun' then return true end
 if not D.DB:existDB('lsd')then return false,'NO_GAME_DATABASE'end
 if not D.DB:exist('Game0StoryNodes','lsd')then return true end
 local rows=D.DB:query("SELECT id FROM lsd.Game0StoryNodes WHERE id='roof-aftermath'")
 if not rows then return false,'READ_FAILED'end
 if rows[1]then return false,'CHARACTER_DEPARTED'end
 return true
end
return Availability
