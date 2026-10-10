-- Durable non-exploring trials bound to an immutable Q source version.
local D=require('Dora');local equal=require('Training.FlowerIdentity').equal
local T={maxBytes=16*1024*1024}
local function open()
 return D.DB:existDB('lsd') and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0FlowerQTrials(id INTEGER PRIMARY KEY AUTOINCREMENT,candidate INTEGER NOT NULL CHECK(candidate>0),episode TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0
end
local function validate(record)
 assert(type(record)=='table' and record.schemaVersion==1,'INVALID_Q_TRIAL')
 assert(record.mode=='basic' or record.mode=='evaluate','EXPLORING_TRIAL')
 assert(record.status=='won' or record.status=='failed','NONTERMINAL_TRIAL')
 assert(record.epsilon==0 and record.seed==nil,'EXPLORING_TRIAL')
 local version,why=require('Training.FlowerQStore').loadVersionAsync(record.candidate);assert(version,why)
 assert(equal(record.baseModels,version.source.baseModels),'BASE_MODELS_CHANGED')
 if record.mode=='evaluate'then assert(equal(record.initial,version.models) and equal(record.models,version.models),'Q_MODEL_CHANGED')
 else assert(record.initial==nil and record.models==nil,'BASIC_HAS_Q_MODEL')end
 assert(require('Training.FlowerScenarios').get(record.profile),'INVALID_PROFILE')
 local s=record.setup
 assert(type(s)=='table' and s.bossScale==1 and s.aimPolicy=='commit-at-selection-v1' and s.formation=='ni-left-wu120-v1' and s.supportGold==(record.profile=='field' and 45 or 90) and s.decisionSeconds==.25 and s.initialDecisionSeconds==.2 and s.mentor=='auto-nearest-kinetic-v1' and s.chant=='on-confusion-v1','INVALID_Q_SETUP')
 assert(require('Factory.Rules').validReaction(s,record.episode),'INVALID_HIT_REACTION_RULE')
 if s.qFeatureVersion~=nil then
  assert(s.qFeatureVersion==6 or s.qFeatureVersion==7,'INVALID_Q_FEATURE_VERSION')
  if s.qFeatureVersion==7 then assert(record.episode.versions.spatial==2,'SPATIAL_EVIDENCE_REQUIRED')end
  if record.mode=='evaluate'then assert(s.qFeatureVersion==version.models.ninilite.featureSchemaVersion and s.qFeatureVersion==version.models.wuyun.featureSchemaVersion,'Q_FEATURE_VERSION_MISMATCH')end
 end
 assert(record.episode.context=='flower-q-practice','INVALID_Q_CONTEXT')
 for _,source in ipairs(version.chain)do assert(source.source.episode.episode~=record.episode.episode,'REUSED_TRAINING_EPISODE')end
 local rebuilt,why=require('Training.FlowerTraceReview').rebuild(record.trace,record.episode,record.status);assert(rebuilt,why)
 local facts,why=require('Training.FlowerEvaluation').build(record.episode);assert(facts,why)
 -- Recompute facts on read; never trust a stored display summary.
 return version,facts,require('Training.FlowerQTelemetry').build(record)
end
function T.validateRecordAsync(record)
 local ok,result=xpcall(function()
  local r=D.json.decode(D.json.encode(record,false,true),32)
  local _,facts,telemetry=validate(r);r.facts=facts;r.telemetry=telemetry;return r
 end,debug.traceback)
 if not ok then return nil,'INVALID_Q_TRIAL',result end;return result
end
function T.saveAsync(run,candidate)
 local ok,answer,why,id=xpcall(function()
  local record={schemaVersion=1,candidate=candidate}
  for _,key in ipairs({'mode','status','epsilon','seed','baseModels','initial','models','profile','setup','trace','episode'})do record[key]=run[key]end
  local payload=D.json.encode(record,false,true);assert(#payload<=T.maxBytes,'TRIAL_TOO_LARGE');record=D.json.decode(payload,32)
  local version=validate(record)
  if not open()then return false,'WRITE_FAILED'end
  local rows=D.DB:query('SELECT id,candidate,payload FROM lsd.Game0FlowerQTrials WHERE episode=?',{record.episode.episode});if not rows then return false,'READ_FAILED'end
  if rows[1]then if rows[1][2]==candidate and equal(D.json.decode(rows[1][3],32),record)then return true,'ALREADY_SAVED',rows[1][1]end;return false,'EPISODE_CONFLICT'end
  local guards,args={},{}
  for _,source in ipairs(version.chain)do
   guards[#guards+1]='EXISTS(SELECT 1 FROM lsd.Game0FlowerQSources WHERE id=? AND parent=? AND payload=?)'
   args[#args+1]=source.id;args[#args+1]=source.parent;args[#args+1]=source.payload
  end
  local recheck={};for i,v in ipairs(args)do recheck[i]=v end
  recheck[#recheck+1]=candidate;recheck[#recheck+1]=record.episode.episode
  args[#args+1]=candidate;args[#args+1]=record.episode.episode;args[#args+1]=payload
  local saved=D.DB:transactionAsync({{'INSERT INTO lsd.Game0FlowerQTrials(candidate,episode,payload) VALUES(CASE WHEN '..table.concat(guards,' AND ')..' THEN ? ELSE -1 END,?,?)',{args}},
   {'UPDATE lsd.Game0FlowerQTrials SET candidate=CASE WHEN '..table.concat(guards,' AND ')..' THEN ? ELSE -1 END WHERE episode=?',{recheck}}})
  if not saved then return false,'WRITE_FAILED'end
  local row=D.DB:query('SELECT id FROM lsd.Game0FlowerQTrials WHERE episode=?',{record.episode.episode});return true,'SAVED',row[1][1]
 end,debug.traceback)
 if not ok then return false,'INVALID_Q_TRIAL',answer end;return answer,why,id
end
function T.loadAsync(candidate)
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id,candidate,episode,payload FROM lsd.Game0FlowerQTrials WHERE candidate=? ORDER BY id DESC',{candidate});if not rows then return nil,'READ_FAILED'end
 local result={};local dependencies={}
 for _,row in ipairs(rows)do
  local ok,record=xpcall(function()
   assert(type(row[4])=='string' and #row[4]<=T.maxBytes,'TRIAL_TOO_LARGE')
   local r=D.json.decode(row[4],32);assert(r.candidate==row[2] and r.episode.episode==row[3],'TRIAL_ID_MISMATCH')
   local version,facts,telemetry=validate(r);r.telemetry=telemetry;for _,source in ipairs(version.chain)do dependencies[#dependencies+1]=source end;r.facts=facts;r.id=row[1];return r
  end,debug.traceback)
  if not ok then return nil,'INVALID_Q_TRIAL',record end
  result[#result+1]=record
 end
 -- Validation yields during provenance replay, so recheck the selected rows.
 local after=D.DB:query('SELECT id,candidate,episode,payload FROM lsd.Game0FlowerQTrials WHERE candidate=? ORDER BY id DESC',{candidate})
 if not equal(rows,after)then return nil,'Q_TRIALS_CHANGED'end
 for _,source in ipairs(dependencies)do
  local row=D.DB:query('SELECT parent,payload FROM lsd.Game0FlowerQSources WHERE id=?',{source.id})
  if not row or not row[1] or row[1][1]~=source.parent or row[1][2]~=source.payload then return nil,'Q_SOURCE_CHANGED'end
 end
 return result
end
return T
