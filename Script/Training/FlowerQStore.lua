-- Immutable Q source chain plus one draft pointer. This never adopts a policy.
local D=require('Dora');local Q=require('Training.FlowerQ');local equal=require('Training.FlowerIdentity').equal
local S={maxBytes=64*1024*1024,maxDepth=32};local busy=false
local function open()
 if not D.DB:existDB('lsd')then return false end
 for _,sql in ipairs({
  'CREATE TABLE IF NOT EXISTS lsd.Game0FlowerQSources(id INTEGER PRIMARY KEY AUTOINCREMENT,parent INTEGER NOT NULL CHECK(parent>=0),episode TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)',
  'CREATE TABLE IF NOT EXISTS lsd.Game0FlowerQDraft(singleton INTEGER PRIMARY KEY CHECK(singleton=1),current INTEGER NOT NULL CHECK(current>=0))',
  'INSERT OR IGNORE INTO lsd.Game0FlowerQDraft VALUES(1,0)'
 })do if D.DB:exec(sql)<0 then return false end end;return true
end
local function current()
 if not open()then return nil end;local rows=D.DB:query('SELECT current FROM lsd.Game0FlowerQDraft WHERE singleton=1');return rows and rows[1] and rows[1][1]
end
local function derive(source,parent)
 if type(source)~='table' or source.schemaVersion~=1 or (source.kind~='seed' and source.kind~='explore')then return nil,'INVALID_Q_SOURCE'end
 if type(source.baseModels)~='table'then return nil,'MISSING_BASE_MODELS'end
 for _,id in ipairs({'ninilite','wuyun'})do if not require('Training.Model').validate(source.baseModels[id],id)then return nil,'INVALID_BASE_MODEL'end end
 if parent and not equal(source.baseModels,parent.source.baseModels)then return nil,'BASE_MODELS_CHANGED'end
 if source.kind=='seed' then
  if parent or source.initial~=nil then return nil,'SEED_MUST_BE_ROOT'end
 else
  if source.mode~='explore' or type(source.seed)~='number' or source.seed%1~=0 or source.seed<=0 or source.seed>=2147483647 or type(source.epsilon)~='number' or source.epsilon<0 or source.epsilon>1 or source.epsilon~=source.epsilon then return nil,'INVALID_EXPLORATION'end
  if source.setup and source.setup.qFeatureVersion~=nil and source.setup.qFeatureVersion~=6 and source.setup.qFeatureVersion~=7 then return nil,'INVALID_Q_FEATURE_VERSION'end
  if not require('Factory.Rules').validReaction(source.setup,source.episode)then return nil,'INVALID_HIT_REACTION_RULE'end
  if not require('Training.FlowerScenarios').get(source.profile) or type(source.setup)~='table' or source.setup.bossScale~=1 or source.setup.aimPolicy~='commit-at-selection-v1' or source.setup.formation~='ni-left-wu120-v1' or source.setup.supportGold~=(source.profile=='field' and 45 or 90) or source.setup.decisionSeconds~=.25 or source.setup.initialDecisionSeconds~=.2 or source.setup.mentor~='auto-nearest-kinetic-v1' or source.setup.chant~='on-confusion-v1' then return nil,'INVALID_Q_SETUP'end
  if type(source.episode)~='table' or source.episode.context~='flower-q-practice'then return nil,'INVALID_Q_CONTEXT'end
  if not equal(source.initial,parent and parent.models or nil)then return nil,'INITIAL_MODEL_MISMATCH'end
 end
 local models,why=Q.learn(source.trace,source.episode,source.status,parent and parent.models or nil,source.setup and source.setup.qFeatureVersion);if not models then return nil,why end
 if not equal(models,source.models)then return nil,'Q_REBUILD_MISMATCH'end
 return models
end
local function loadAt(id)
 local chain,seen,bytes={}, {},0;local selected=id
 while id>0 do
  if seen[id] or #chain>=S.maxDepth then return nil,'Q_CHAIN_LIMIT'end;seen[id]=true
  local rows=D.DB:query('SELECT parent,episode,payload FROM lsd.Game0FlowerQSources WHERE id=?',{id});local row=rows and rows[1]
  if not row or row[1]>=id or row[1]<0 or type(row[3])~='string'then return nil,'Q_SOURCE_MISSING'end
  bytes=bytes+#row[3];if bytes>S.maxBytes then return nil,'Q_CHAIN_TOO_LARGE'end
  local source=D.json.decode(row[3],32);if type(source)~='table' or type(source.episode)~='table' or source.episode.episode~=row[2]then return nil,'Q_SOURCE_ID_MISMATCH'end
  chain[#chain+1]={id=id,parent=row[1],source=source,payload=row[3]};id=row[1]
 end
 local parent
 for i=#chain,1,-1 do
  local item=chain[i];local models,why=derive(item.source,parent);if not models then return nil,why end
  item.models=models;parent=item;D.sleep(0)
 end
 if not parent then return nil,'NOT_RECORDED'end
 return {id=selected,parent=parent.parent,source=parent.source,models=parent.models,chain=chain,depth=#chain,bytes=bytes}
end
local function unchanged(chain)
 for _,item in ipairs(chain)do
  local rows=D.DB:query('SELECT parent,payload FROM lsd.Game0FlowerQSources WHERE id=?',{item.id})
  if not rows or not rows[1] or rows[1][1]~=item.parent or rows[1][2]~=item.payload then return false end
 end
 return true
end
function S.loadAsync()
 local id=current();if id==nil then return nil,'READ_FAILED'end;if id==0 then return nil,'NOT_RECORDED'end
 local result,why=loadAt(id);if not result then return nil,why end
 if current()~=id or not unchanged(result.chain) then return nil,'Q_DRAFT_CHANGED'end;return result
end
-- Historical trials bind to a specific immutable source, independently of today's draft.
function S.loadVersionAsync(id)
 if type(id)~='number' or id<=0 or id%1~=0 then return nil,'INVALID_Q_VERSION'end
 if not open()then return nil,'READ_FAILED'end
 local result,why=loadAt(id);if not result then return nil,why end
 if not unchanged(result.chain)then return nil,'Q_DRAFT_CHANGED'end;return result
end
local function operation(fn)
 if busy then return false,'BUSY'end;busy=true;local r=table.pack(xpcall(fn,debug.traceback));busy=false
 if not r[1]then return false,'Q_STORE_ERROR',r[2]end;return table.unpack(r,2,r.n)
end
local function save(source,expected)
 return operation(function()
  if type(expected)~='number' or expected<0 or expected%1~=0 then return false,'EXPECTED_PARENT_REQUIRED'end
  if not open()then return false,'WRITE_FAILED'end
  local payload=D.json.encode(source,false,true);if #payload>S.maxBytes then return false,'Q_CHAIN_TOO_LARGE'end;source=D.json.decode(payload,32)
  if type(source.episode)~='table' or type(source.episode.episode)~='string'then return false,'INVALID_EPISODE'end
  local existing=D.DB:query('SELECT id,parent,payload FROM lsd.Game0FlowerQSources WHERE episode=?',{source.episode.episode})
  if not existing then return false,'READ_FAILED'end
  if existing[1]then
   local row=existing[1];if row[2]==expected and equal(D.json.decode(row[3],32),source)then local verified,why=loadAt(row[1]);if not verified then return false,why end;if not unchanged(verified.chain)then return false,'Q_DRAFT_CHANGED'end;return true,'ALREADY_SAVED',row[1]end
   return false,'EPISODE_CONFLICT'
  end
  if current()~=expected then return false,'Q_DRAFT_CHANGED'end
  local parent,why;if expected>0 then parent,why=loadAt(expected);if not parent then return false,why end end
  if (parent and parent.depth or 0)>=S.maxDepth or (parent and parent.bytes or 0)+#payload>S.maxBytes then return false,'Q_CHAIN_LIMIT'end
  local models,why=derive(source,parent);if not models then return false,why end
  local guard,parameters={'current=?'},{expected}
  -- Parent rows are also guarded: never append to a chain changed while replay yielded.
  for _,item in ipairs(parent and parent.chain or {})do
   guard[#guard+1]='EXISTS(SELECT 1 FROM lsd.Game0FlowerQSources WHERE id=? AND parent=? AND payload=?)'
   parameters[#parameters+1]=item.id;parameters[#parameters+1]=item.parent;parameters[#parameters+1]=item.payload
  end
  local ok=D.DB:transactionAsync({
   {'INSERT INTO lsd.Game0FlowerQSources(parent,episode,payload) VALUES(?,?,?)',{{expected,source.episode.episode,payload}}},
   {'UPDATE lsd.Game0FlowerQDraft SET current=CASE WHEN '..table.concat(guard,' AND ')..' THEN last_insert_rowid() ELSE -1 END WHERE singleton=1',{parameters}}
  })
  if not ok then return false,'WRITE_FAILED'end
  return true,'SAVED',current()
 end)
end
function S.saveRunAsync(run,expected)
 if type(run)~='table'then return false,'INVALID_RUN'end
 return save({schemaVersion=1,kind='explore',mode=run.mode,seed=run.seed,epsilon=run.epsilon,profile=run.profile,setup=run.setup,baseModels=run.baseModels,initial=run.initial,models=run.models,trace=run.trace,episode=run.episode,status=run.status},expected)
end
function S.saveSeedAsync(seed,expected)
 if type(seed)~='table'then return false,'INVALID_SEED'end
 return save({schemaVersion=1,kind='seed',baseModels=seed.baseModels,models=seed.models,trace=seed.trace,episode=seed.episode,status=seed.status},expected)
end
return S
