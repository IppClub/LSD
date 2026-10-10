-- Demonstration episodes are separate from adopted models and mission rewards.
local D=require('Dora');local S={}
local function validActor(id)return id=='ninilite' or id=='wuyun'end
local function open()
 if not D.DB:existDB('lsd')then return false,'NO_GAME_DATABASE'end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0FlowerPractice (serial INTEGER PRIMARY KEY AUTOINCREMENT, episode TEXT NOT NULL UNIQUE, learner TEXT NOT NULL, status TEXT NOT NULL, payload TEXT NOT NULL)')<0 then return false,'WRITE_FAILED'end
 return true
end
function S.saveAsync(learner,status,episode)
 if not validActor(learner) or not ({won=true,failed=true,aborted=true})[status] or type(episode)~='table' or episode.context~='flower-practice' then return false,'INVALID_PRACTICE'end
 if episode.practiceProfile~=nil and episode.practiceProfile~='standard'then return false,'EVALUATION_NOT_DEMONSTRATION'end
 local payload,why=require('Training.CombatStore').encode(episode);if not payload then return false,why end
 local demo=false;for _,step in ipairs(episode.steps)do if step.action.actor==learner and step.action.origin=='demo'then demo=true;break end end
 if not demo then return false,'NO_LEARNER_DEMONSTRATION'end
 local ok,why=open();if not ok then return false,why end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0FlowerPractice WHERE episode=?',{episode.episode})
 if not rows then return false,'READ_FAILED'end
 if rows[1]then if rows[1][1]==payload then return true end;return false,'EPISODE_CONFLICT'end
 local saved=D.DB:transactionAsync({
  {'INSERT INTO lsd.Game0FlowerPractice(episode,learner,status,payload) VALUES(?,?,?,?)',{{episode.episode,learner,status,payload}}},
  {'DELETE FROM lsd.Game0FlowerPractice WHERE learner=? AND serial NOT IN (SELECT serial FROM lsd.Game0FlowerPractice WHERE learner=? ORDER BY serial DESC LIMIT 20)',{{learner,learner}}}
 })
 if not saved then return false,'WRITE_FAILED'end
 return true
end
function S.latest(learner)
 if not validActor(learner)then return nil,'INVALID_CHARACTER'end
 local ok,why=open();if not ok then return nil,why end
 local rows=D.DB:query('SELECT status,payload FROM lsd.Game0FlowerPractice WHERE learner=? ORDER BY serial DESC LIMIT 1',{learner})
 if not rows then return nil,'READ_FAILED'end
 if not rows[1]then return nil,'NOT_RECORDED'end
 if type(rows[1][2])~='string' or #rows[1][2]>require('Training.CombatStore').maxBytes then return nil,'INVALID_PAYLOAD'end
 local e=D.json.decode(rows[1][2],32);local valid,why=require('Training.CombatStore').validate(e)
 if not valid or e.context~='flower-practice' then return nil,why or 'INVALID_PRACTICE'end
 return {status=rows[1][1],episode=e}
end
function S.history(learner)
 if not validActor(learner)then return nil,'INVALID_CHARACTER'end
 local ok,why=open();if not ok then return nil,why end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0FlowerPractice WHERE learner=? ORDER BY serial DESC LIMIT 20',{learner});if not rows then return nil,'READ_FAILED'end
 local result={}
 for i=#rows,1,-1 do
  local payload=rows[i][1];if type(payload)~='string' or #payload>require('Training.CombatStore').maxBytes then return nil,'INVALID_PAYLOAD'end
  local e=D.json.decode(payload,32);local ok,why=require('Training.CombatStore').validate(e);if not ok or e.context~='flower-practice'then return nil,why or 'INVALID_PRACTICE'end
  result[#result+1]=e
 end
 return result
end
return S
