-- Human resource demonstrations are independent of Q exploration and legacy demos.
local D=require('Dora');local P=require('Training.ResourcePolicy');local S={maxBytes=8*1024*1024,maxEpisodes=20}
local function actor(id)return id=='ninilite' or id=='wuyun'end
local function open()
 return D.DB:existDB('lsd') and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0ResourceDemos(id INTEGER PRIMARY KEY AUTOINCREMENT,episode TEXT UNIQUE NOT NULL,learner TEXT NOT NULL,payload TEXT NOT NULL)')>=0
end
local function validate(record,id)
 if type(record)~='table' or record.schemaVersion~=1 or not actor(record.learner) or id and record.learner~=id or not ({won=true,failed=true,aborted=true})[record.status] then return nil,'INVALID_RESOURCE_DEMO'end
 local e=record.episode
 if type(e)~='table' or e.context~='flower-resource-demo' or (e.practiceProfile~=nil and e.practiceProfile~='standard') or not e.resources or e.resources.mode~='virtual' then return nil,'INVALID_RESOURCE_DEMO'end
 local data,why=P.inspect({e},record.learner);if not data then return nil,why end
 if data.coverage.total==0 then return nil,'NO_COMPLETE_DEMONSTRATION'end
 return data
end
function S.history(id)
 if not actor(id)then return nil,'INVALID_CHARACTER'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0ResourceDemos WHERE learner=? ORDER BY id',{id});if not rows then return nil,'READ_FAILED'end
 if #rows>S.maxEpisodes then return nil,'SOURCE_LIMIT'end
 local episodes={}
 for _,row in ipairs(rows)do
  if type(row[1])~='string' or #row[1]>S.maxBytes then return nil,'INVALID_PAYLOAD'end
  local ok,record=pcall(D.json.decode,row[1],32);if not ok then return nil,'INVALID_PAYLOAD'end
  local data,why=validate(record,id);if not data then return nil,why end
  episodes[#episodes+1]=record.episode
 end
 return episodes
end
function S.saveAsync(id,status,episode)
 local payload=D.json.encode({schemaVersion=1,learner=id,status=status,episode=episode},false,true)
 if #payload>S.maxBytes then return false,'SOURCE_TOO_LARGE'end
 local record=D.json.decode(payload,32);local data,why=validate(record,id);if not data then return false,why end
 if not open()then return false,'WRITE_FAILED'end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0ResourceDemos WHERE episode=?',{episode.episode});if not rows then return false,'READ_FAILED'end
 if rows[1]then
  local ok,old=pcall(D.json.decode,rows[1][1],32)
  if ok and require('Training.FlowerIdentity').equal(old,record)then return true,'ALREADY_SAVED'end
  return false,'EPISODE_CONFLICT'
 end
 local rows=D.DB:query('SELECT COUNT(*) FROM lsd.Game0ResourceDemos WHERE learner=?',{id});if not rows then return false,'READ_FAILED'end
 if rows[1][1]>=S.maxEpisodes then return false,'SOURCE_LIMIT'end
 local saved=D.DB:transactionAsync({{'INSERT INTO lsd.Game0ResourceDemos(episode,learner,payload) VALUES(?,?,?)',{{episode.episode,id,payload}}}})
 return saved,saved and 'SAVED' or 'WRITE_FAILED'
end
return S
