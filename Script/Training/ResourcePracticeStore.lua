-- Immutable virtual practice sources; no candidate pointer, adoption or wallet writes.
local D=require('Dora');local S={maxBytes=8*1024*1024};local busy=false
local equal=require('Training.FlowerIdentity').equal
local function open()
 return D.DB:existDB('lsd') and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0ResourcePractices(id INTEGER PRIMARY KEY AUTOINCREMENT,episode TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0
end
local function validate(source)
 if type(source)~='table' or source.schemaVersion~=1 or (source.mode~='basic' and source.mode~='explore') or type(source.episode)~='table' or source.episode.context~='flower-resource-practice' or not source.episode.resources or source.episode.resources.mode~='virtual' then return nil,'INVALID_RESOURCE_PRACTICE'end
 if source.mode=='explore'then
  if type(source.seed)~='number' or source.seed%1~=0 or source.seed<=0 or source.seed>=2147483647 or type(source.epsilon)~='number' or source.epsilon~=source.epsilon or source.epsilon<0 or source.epsilon>1 then return nil,'INVALID_RESOURCE_EXPLORATION'end
  if source.initial~=nil then
   if type(source.initial)~='table'then return nil,'INVALID_INITIAL_MODELS'end
   for _,id in ipairs({'ninilite','wuyun'})do if not require('Training.ResourceQ').restore(source.initial[id],id)then return nil,'INVALID_INITIAL_MODELS'end end
  end
 end
 if type(source.baseModels)~='table'then return nil,'INVALID_BASE_MODELS'end
 for _,id in ipairs({'ninilite','wuyun'})do if not require('Training.Model').validate(source.baseModels[id],id)then return nil,'INVALID_BASE_MODELS'end end
 if source.initial then for _,id in ipairs({'ninilite','wuyun'})do if source.initial[id].trainingGoal~=source.episode.versions.trainingGoal then return nil,'TRAINING_GOAL_MISMATCH'end end end
 local quote=require('Economy.Ledger').quote(source.virtualSupplies)
 if not quote or not equal(quote,source.episode.resources.quote)then return nil,'RESOURCE_QUOTE_MISMATCH'end
 if not require('Training.ResourceFallback').valid(source.setup,source.episode)then return nil,'INVALID_RESOURCE_FALLBACK'end
 if not require('Factory.Outcome').validMovement(source.setup,source.episode)then return nil,'INVALID_CONTINUOUS_MOVEMENT'end
 if source.setup.explorationPolicy~=nil and (source.setup.explorationPolicy~='coverage-v1' or source.mode~='explore')then return nil,'INVALID_EXPLORATION_POLICY'end
 if not require('Factory.Outcome').validGoal(source.setup,source.episode,true)then return nil,'INVALID_TRAINING_GOAL'end
 if not require('Training.FlowerScenarios').get(source.profile)then return nil,'INVALID_RESOURCE_PROFILE'end
 return require('Training.ResourceTraceReview').rebuild(source.trace,source.episode,source.status)
end
function S.loadLatestAsync()
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id,payload FROM lsd.Game0ResourcePractices ORDER BY id DESC LIMIT 1')
 if not rows then return nil,'READ_FAILED'end;if not rows[1]then return nil,'NOT_RECORDED'end
 if #rows[1][2]>S.maxBytes then return nil,'SOURCE_TOO_LARGE'end
 local ok,source=pcall(D.json.decode,rows[1][2],32);if not ok then return nil,'INVALID_RESOURCE_PRACTICE'end
 local reviewed,why=validate(source);if not reviewed then return nil,why end
 return {id=rows[1][1],source=source,review=reviewed,payload=rows[1][2]}
end
function S.loadVersionAsync(id)
 if type(id)~='number' or id%1~=0 or id<1 then return nil,'INVALID_SOURCE_ID'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0ResourcePractices WHERE id=?',{id})
 if not rows or not rows[1]then return nil,'SOURCE_MISSING'end
 local payload=rows[1][1];if #payload>S.maxBytes then return nil,'SOURCE_TOO_LARGE'end
 local ok,source=pcall(D.json.decode,payload,32);if not ok then return nil,'INVALID_RESOURCE_PRACTICE'end
 local reviewed,why=validate(source);if not reviewed then return nil,why end
 return {id=id,source=source,review=reviewed,payload=payload}
end
function S.saveRunAsync(run)
 if busy then return false,'BUSY'end;busy=true
 local ok,accepted,why,id=xpcall(function()
  local source={schemaVersion=1,mode=run.mode,seed=run.mode=='explore' and run.seed or nil,epsilon=run.mode=='explore' and run.epsilon or nil,initial=run.mode=='explore' and run.initial or nil,baseModels=run.baseModels,profile=run.profile,setup=run.setup,virtualSupplies=run.virtualSupplies,trace=run.trace,episode=run.episode,status=run.status}
  local payload=D.json.encode(source,false,true);if #payload>S.maxBytes then return false,'SOURCE_TOO_LARGE'end
  source=D.json.decode(payload,32)
  local reviewed,why=validate(source);if not reviewed then return false,why end
  if not open()then return false,'WRITE_FAILED'end
  local rows=D.DB:query('SELECT id,payload FROM lsd.Game0ResourcePractices WHERE episode=?',{source.episode.episode});if not rows then return false,'READ_FAILED'end
  if rows[1]then
   if equal(D.json.decode(rows[1][2],32),source)then return true,'ALREADY_SAVED',rows[1][1]end
   return false,'EPISODE_CONFLICT'
  end
  if not D.DB:transactionAsync({{'INSERT INTO lsd.Game0ResourcePractices(episode,payload) VALUES(?,?)',{{source.episode.episode,payload}}}})then return false,'WRITE_FAILED'end
  local rows=D.DB:query('SELECT id FROM lsd.Game0ResourcePractices WHERE episode=?',{source.episode.episode})
  return rows and rows[1]~=nil,rows and rows[1] and 'SAVED' or 'READ_FAILED',rows and rows[1] and rows[1][1]
 end,debug.traceback)
 busy=false;if not ok then return false,'RESOURCE_STORE_ERROR',accepted end;return accepted,why,id
end
return S
