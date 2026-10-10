-- Rebuild cumulative candidates from immutable virtual practice records.
-- No adoption pointer or legacy-Q writes. Re-training an unchanged set is idempotent.
local D=require('Dora');local Practices=require('Training.ResourcePracticeStore');local Q=require('Training.ResourceQ')
local equal=require('Training.FlowerIdentity').equal;local S={maxSources=32,maxBytes=64*1024*1024};local busy=false
local function encode(v)return D.json.encode(v,false,true)end
local function open()
 return D.DB:existDB('lsd') and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0ResourceQCandidates(id INTEGER PRIMARY KEY AUTOINCREMENT,sourceKey TEXT UNIQUE NOT NULL,payload TEXT NOT NULL,valid INTEGER NOT NULL CHECK(valid=1))')>=0
end
local function derive(ids)
 if type(ids)~='table' or #ids==0 or #ids>S.maxSources then return nil,'RESOURCE_SOURCE_LIMIT'end
 local count=0;for key in pairs(ids)do if type(key)~='number' or key%1~=0 or key<1 or key>#ids then return nil,'INVALID_SOURCE_ORDER'end;count=count+1 end
 if count~=#ids then return nil,'INVALID_SOURCE_ORDER'end
 local models,base,records,bytes,last=nil,nil,{},0,0
 local goal
 for _,id in ipairs(ids)do
  if type(id)~='number' or id%1~=0 or id<=last then return nil,'INVALID_SOURCE_ORDER'end;last=id
  local record,why=Practices.loadVersionAsync(id);if not record then return nil,why end
  bytes=bytes+#record.payload;if bytes>S.maxBytes then return nil,'RESOURCE_SOURCE_LIMIT'end
  if base and not equal(base,record.source.baseModels)then return nil,'BASE_MODELS_CHANGED'end;base=record.source.baseModels
  local sourceGoal=record.source.episode.versions.trainingGoal
  if #records>0 and sourceGoal~=goal then return nil,'TRAINING_GOAL_MISMATCH'end;goal=sourceGoal
  models,why=Q.learn(record.source.trace,record.source.episode,record.source.status,models);if not models then return nil,why end
  records[#records+1]=record;D.sleep(0)
 end
 return {trainingGoal=goal,schemaVersion=1,sourceIds=ids,models=models,baseModels=base},records
end
local function unchanged(records)
 for _,record in ipairs(records)do
  local rows=D.DB:query('SELECT payload FROM lsd.Game0ResourcePractices WHERE id=?',{record.id})
  if not rows or not rows[1]or rows[1][1]~=record.payload then return false end
 end
 return true
end
local function loadRow(row)
 if not row or type(row[3])~='string' or #row[3]>S.maxBytes then return nil,'INVALID_RESOURCE_CANDIDATE'end
 local ok,bundle=pcall(D.json.decode,row[3],32);if not ok or type(bundle)~='table' or bundle.schemaVersion~=1 or encode(bundle.sourceIds)~=row[2]then return nil,'INVALID_RESOURCE_CANDIDATE'end
 local rebuilt,records=derive(bundle.sourceIds);if not rebuilt then return nil,records end
 local expectedModels=rebuilt.models;rebuilt.models=bundle.models
 if not equal(rebuilt,bundle) or not Q.equivalentModels(expectedModels,bundle.models)then return nil,'RESOURCE_Q_REBUILD_MISMATCH'end
 if not unchanged(records)then return nil,'RESOURCE_SOURCES_CHANGED'end
 return {id=row[1],bundle=bundle,models=bundle.models,depth=#bundle.sourceIds,records=records,payload=row[3]}
end
function S.loadLatestAsync()
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id,sourceKey,payload FROM lsd.Game0ResourceQCandidates ORDER BY id DESC LIMIT 1')
 if not rows then return nil,'READ_FAILED'end;if not rows[1]then return nil,'NOT_RECORDED'end
 return loadRow(rows[1])
end
function S.loadVersionAsync(id)
 if type(id)~='number' or id%1~=0 or id<1 then return nil,'INVALID_RESOURCE_CANDIDATE'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id,sourceKey,payload FROM lsd.Game0ResourceQCandidates WHERE id=?',{id})
 if not rows or not rows[1]then return nil,'NOT_RECORDED'end
 return loadRow(rows[1])
end
function S.trainAsync()
 if busy then return nil,'BUSY'end;busy=true
 local ok,result,why=xpcall(function()
  local latest,why=Practices.loadLatestAsync();if not latest then return nil,why end
  local rows=D.DB:query('SELECT id FROM lsd.Game0ResourcePractices ORDER BY id')
  if not rows then return nil,'READ_FAILED'end
  local ids={};local targetGoal=latest.source.episode.versions.trainingGoal
  for _,row in ipairs(rows)do
   local source,why=Practices.loadVersionAsync(row[1]);if not source then return nil,why end
   if source.source.episode.versions.trainingGoal==targetGoal then ids[#ids+1]=row[1];if #ids>S.maxSources then return nil,'RESOURCE_SOURCE_LIMIT'end end
  end
  local bundle,records=derive(ids);if not bundle then return nil,records end
  if not open()then return nil,'WRITE_FAILED'end
  local key=encode(ids);local old=D.DB:query('SELECT id,sourceKey,payload FROM lsd.Game0ResourceQCandidates WHERE sourceKey=?',{key})
  if not old then return nil,'READ_FAILED'end
  if old[1]then return loadRow(old[1])end
  local guard={'(SELECT COUNT(*) FROM lsd.Game0ResourcePractices)=?'};local parameters={key,encode(bundle),#rows}
  for _,record in ipairs(records)do
   guard[#guard+1]='EXISTS(SELECT 1 FROM lsd.Game0ResourcePractices WHERE id=? AND payload=?)'
   parameters[#parameters+1]=record.id;parameters[#parameters+1]=record.payload
  end
  local committed=D.DB:transactionAsync({{'INSERT INTO lsd.Game0ResourceQCandidates(sourceKey,payload,valid) VALUES(?,?,CASE WHEN '..table.concat(guard,' AND ')..' THEN 1 ELSE 0 END)',{parameters}}})
  if not committed then return nil,'WRITE_FAILED'end
  local rows=D.DB:query('SELECT id FROM lsd.Game0ResourceQCandidates WHERE sourceKey=?',{key})
  if not rows or not rows[1]then return nil,'READ_FAILED'end
  return {id=rows[1][1],bundle=bundle,models=bundle.models,depth=#ids,records=records}
 end,debug.traceback)
 busy=false;if not ok then return nil,'RESOURCE_Q_STORE_ERROR',result end;return result,why
end
return S
