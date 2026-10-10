-- Frozen evaluations are separate from training sources and never update Q.
local D=require('Dora');local equal=require('Training.FlowerIdentity').equal;local T={maxBytes=16*1024*1024}
local function open()
 return D.DB:existDB('lsd') and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0ResourceQTrials(id INTEGER PRIMARY KEY AUTOINCREMENT,candidate INTEGER NOT NULL CHECK(candidate>0),episode TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0
end
local function validate(record)
 assert(type(record)=='table' and record.schemaVersion==1 and (record.mode=='basic' or record.mode=='evaluate'),'INVALID_RESOURCE_TRIAL')
 assert(record.epsilon==0 and record.seed==nil,'EXPLORING_TRIAL')
 local version,why=require('Training.ResourceQStore').loadVersionAsync(record.candidate);assert(version,why)
 assert(equal(record.baseModels,version.bundle.baseModels),'BASE_MODELS_CHANGED')
 if record.mode=='evaluate'then assert(equal(record.initial,version.models) and equal(record.models,version.models),'MODEL_CHANGED')
 else assert(record.initial==nil and record.models==nil,'BASIC_HAS_Q_MODEL')end
 assert(require('Training.FlowerScenarios').get(record.profile),'INVALID_PROFILE')
 local s=record.setup
 assert(type(s)=='table' and s.qFeatureVersion==8 and s.bossScale==1 and s.aimPolicy=='commit-at-selection-v1' and s.formation=='ni-left-wu120-v1' and s.supportGold==(record.profile=='field'and 45 or 90) and s.decisionSeconds==.25 and s.initialDecisionSeconds==.2 and s.mentor=='auto-nearest-kinetic-v1' and s.chant=='on-confusion-v1','INVALID_SETUP')
 assert(require('Training.ResourceFallback').valid(s,record.episode),'INVALID_RESOURCE_FALLBACK')
 assert(require('Factory.Outcome').validMovement(s,record.episode),'INVALID_CONTINUOUS_MOVEMENT')
 assert(require('Factory.Outcome').validGoal(s,record.episode,true),'INVALID_TRAINING_GOAL')
 assert(s.trainingGoal==version.bundle.trainingGoal,'TRAINING_GOAL_MISMATCH')
 assert(require('Factory.Rules').validReaction(s,record.episode),'INVALID_HIT_REACTION_RULE')
 assert(record.episode.context=='flower-resource-practice' and record.episode.resources.mode=='virtual','NOT_VIRTUAL')
 assert(equal(require('Economy.Ledger').quote(record.virtualSupplies),record.episode.resources.quote),'QUOTE_MISMATCH')
 for _,source in ipairs(version.records)do assert(source.source.episode.episode~=record.episode.episode,'REUSED_TRAINING_EPISODE')end
 local reviewed,why=require('Training.ResourceTraceReview').rebuild(record.trace,record.episode,record.status);assert(reviewed,why)
 if record.mode=='evaluate'then assert(record.trace.decisionSourcesVersion==1,'MISSING_DECISION_SOURCES')end
 local telemetry=require('Training.FlowerQTelemetry').build(record)
 return version,{sourceProfiles=require('Training.ResourceSourceCoverage').build(version.records),cost=record.episode.resources.spent,budget=record.episode.resources.quote.total,status=record.status,telemetry=telemetry}
end
function T.saveAsync(run,candidate)
 local ok,answer,why,id=xpcall(function()
  local record={schemaVersion=1,candidate=candidate}
  for _,key in ipairs({'mode','status','epsilon','seed','baseModels','initial','models','profile','setup','trace','episode','virtualSupplies'})do record[key]=run[key]end
  local payload=D.json.encode(record,false,true);assert(#payload<=T.maxBytes,'TRIAL_TOO_LARGE');record=D.json.decode(payload,32)
  local version=validate(record);if not open()then return false,'WRITE_FAILED'end
  local rows=D.DB:query('SELECT id,candidate,payload FROM lsd.Game0ResourceQTrials WHERE episode=?',{record.episode.episode});assert(rows,'READ_FAILED')
  if rows[1]then if rows[1][2]==candidate and equal(D.json.decode(rows[1][3],32),record)then return true,'ALREADY_SAVED',rows[1][1]end;return false,'EPISODE_CONFLICT'end
  local guard={'EXISTS(SELECT 1 FROM lsd.Game0ResourceQCandidates WHERE id=? AND payload=?)'};local args={candidate,version.payload}
  for _,source in ipairs(version.records)do guard[#guard+1]='EXISTS(SELECT 1 FROM lsd.Game0ResourcePractices WHERE id=? AND payload=?)';args[#args+1]=source.id;args[#args+1]=source.payload end
  args[#args+1]=candidate;args[#args+1]=record.episode.episode;args[#args+1]=payload
  if not D.DB:transactionAsync({{'INSERT INTO lsd.Game0ResourceQTrials(candidate,episode,payload) VALUES(CASE WHEN '..table.concat(guard,' AND ')..' THEN ? ELSE -1 END,?,?)',{args}}})then return false,'WRITE_FAILED'end
  return true,'SAVED',D.DB:query('SELECT id FROM lsd.Game0ResourceQTrials WHERE episode=?',{record.episode.episode})[1][1]
 end,debug.traceback)
 if not ok then return false,'INVALID_RESOURCE_TRIAL',answer end;return answer,why,id
end
function T.loadAsync(candidate)
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id,payload FROM lsd.Game0ResourceQTrials WHERE candidate=? ORDER BY id',{candidate});if not rows then return nil,'READ_FAILED'end
 local result={}
 for _,row in ipairs(rows)do
  local ok,record=xpcall(function()
   assert(#row[2]<=T.maxBytes);local data=D.json.decode(row[2],32);assert(data.candidate==candidate)
   local _,facts=validate(data);return {id=row[1],record=data,facts=facts}
  end,debug.traceback)
  if not ok then return nil,'INVALID_RESOURCE_TRIAL',record end;result[#result+1]=record
 end
 return result
end
return T
