-- Immutable per-learner adoption history. No basic-model or wallet writes.
local D=require('Dora');local S={maxBytes=64*1024*1024};local busy=false
local equal=require('Training.FlowerIdentity').equal
local function integer(n)return type(n)=='number'and n>=0 and n<2^53 and n%1==0 end
local function expectedOK(s)return type(s)=='table'and integer(s.current)and integer(s.revision)end
local function freeze(v)return D.json.decode(D.json.encode(v,false,true),32)end
local function actorOK(actor)return actor=='ninilite'or actor=='wuyun'end
local function open(actor)
 if not actorOK(actor)or not D.DB:existDB('lsd')then return false end
 for _,sql in ipairs({
  'CREATE TABLE IF NOT EXISTS lsd.Game0YingzhaoAdoptions(id INTEGER PRIMARY KEY AUTOINCREMENT,actor TEXT NOT NULL,parent INTEGER NOT NULL CHECK(parent>=0),payload TEXT NOT NULL)',
  'CREATE TABLE IF NOT EXISTS lsd.Game0YingzhaoAdoptionState(actor TEXT PRIMARY KEY,current INTEGER NOT NULL CHECK(current>=0),revision INTEGER NOT NULL CHECK(revision>=0))'
 })do if D.DB:exec(sql)<0 then return false end end
 return D.DB:exec('INSERT OR IGNORE INTO lsd.Game0YingzhaoAdoptionState VALUES(?,0,0)',{actor})>=0
end
function S.state(actor)
 if not open(actor)then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT current,revision FROM lsd.Game0YingzhaoAdoptionState WHERE actor=?',{actor})
 if not rows or not rows[1]or not integer(rows[1][1])or not integer(rows[1][2])then return nil,'READ_FAILED'end
 return {current=rows[1][1],revision=rows[1][2]}
end
local function payload(tableName,id)
 local rows=D.DB:query('SELECT payload FROM lsd.'..tableName..' WHERE id=?',{id});return rows and rows[1]and rows[1][1]
end
local function candidateTable(algorithm)
 if algorithm=='yingzhao-c45'then return 'Game0YingzhaoCandidates' end
 if algorithm=='yingzhao-qlearning'then return 'Game0YingzhaoQCandidates' end
end
local function verify(bundle)
 if type(bundle)~='table'or bundle.schemaVersion~=1 or not actorOK(bundle.actor)or type(bundle.candidate)~='table'or type(bundle.comparison)~='table'then return nil,'INVALID_BUNDLE'end
 if not integer(bundle.candidate.id)or bundle.candidate.id==0 or not integer(bundle.comparison.id)or bundle.comparison.id==0 then return nil,'INVALID_BUNDLE'end
 local tableName=candidateTable(bundle.candidate.algorithm);if not tableName then return nil,'INVALID_ALGORITHM'end
 local cp,sp=bundle.comparison.payload,bundle.candidate.payload
 if type(cp)~='string'or #cp>16*1024*1024 or type(sp)~='string'or #sp>16*1024*1024 then return nil,'INVALID_BUNDLE'end
 local record=D.json.decode(cp,32);local source=D.json.decode(sp,32)
 if type(source)~='table'or type(source.model)~='table'then return nil,'INVALID_SOURCE'end
 local valid,why=require('Training.YingzhaoComparisonStore').validate(record);if not valid then return nil,why end
 local setup=record.setup
 if type(setup)~='table'or setup.schemaVersion~=1 or not equal(setup.candidate,{id=bundle.candidate.id,algorithm=bundle.candidate.algorithm})or type(setup.models)~='table'then return nil,'EVALUATION_CONTEXT_REQUIRED'end
 if not equal(record.candidate,source.model)or source.model.characterId~=bundle.actor or source.model.algorithm~=bundle.candidate.algorithm then return nil,'CANDIDATE_MISMATCH'end
 local ancestors={}
 if bundle.candidate.algorithm=='yingzhao-c45'then
  local P=require('Training.YingzhaoPolicy');local valid,why=P.validate(source.model,bundle.actor);if not valid then return nil,why end
  if source.schemaVersion~=1 then return nil,'INVALID_SOURCE'end
  local rebuilt,why=P.buildAsync(source.records,bundle.actor,source.model.featureSchemaVersion,source.model.builderVersion or 1,source.model.actionSetVersion);if not rebuilt then return nil,why end
  if not equal(rebuilt,source.model)then return nil,'SOURCE_MODEL_MISMATCH'end
 else
  local candidate,why=require('Training.YingzhaoQStore').loadAsync(bundle.candidate.id);if not candidate then return nil,why end
  if not equal(candidate.source,source)then return nil,'SOURCE_MODEL_MISMATCH'end
  -- Guard every verified Q ancestor inside the adoption transaction as well.
  -- A change after rebuilding must roll back the new immutable adoption row.
  local child=source;local childId=bundle.candidate.id
  while child.base do
   local id=child.parentId
   if not integer(id)or id==0 or id>=childId or #ancestors>=1024 then return nil,'INVALID_PARENT'end
   local rawParent=payload(tableName,id);if not rawParent then return nil,'SOURCE_CHANGED'end
   local parent=D.json.decode(rawParent,32)
   if type(parent)~='table'or not equal(parent.model,child.base)then return nil,'SOURCE_CHANGED'end
   ancestors[#ancestors+1]={id=id,payload=rawParent};child=parent;childId=id
  end
  -- Replay the chain once more, then ensure every captured raw row still
  -- matches. Avoid rebuilding each ancestor's full chain (quadratic work).
  local stable,why=require('Training.YingzhaoQStore').loadAsync(bundle.candidate.id)
  if not stable then return nil,why end
  if not equal(stable.source,source)then return nil,'SOURCE_CHANGED'end
  for _,ancestor in ipairs(ancestors)do if ancestor.payload~=payload(tableName,ancestor.id)then return nil,'SOURCE_CHANGED'end end
 end
 if sp~=payload(tableName,bundle.candidate.id)or cp~=payload('Game0YingzhaoComparisons',bundle.comparison.id)then return nil,'SOURCE_CHANGED'end
 local rounds={}
 for i,r in ipairs(record.rounds)do rounds[i]={status=r.status,cost=r.cost,armorDamage=r.armorDamage,healthDamage=r.healthDamage,seconds=r.seconds,hp=freeze(r.hp)}end
 local review={schemaVersion=1,actor=bundle.actor,algorithm=bundle.candidate.algorithm,comparisonId=bundle.comparison.id,rounds=rounds,stableBenefitProven=false}
 return {candidate={id=bundle.candidate.id,model=source.model},record=record,review=review,ancestors=ancestors}
end
local function checked(bundle)
 local ok,result,why=xpcall(function()return verify(bundle)end,debug.traceback)
 if not ok then return nil,'INVALID_BUNDLE'end;return result,why
end
function S.captureAsync(comparisonId,candidateId,algorithm,models)
 if not integer(comparisonId)or comparisonId==0 or not integer(candidateId)or candidateId==0 then return nil,'INVALID_COMPARISON'end
 local tableName=candidateTable(algorithm);if not tableName then return nil,'INVALID_ALGORITHM'end
 models=freeze(models)
 local comparison=payload('Game0YingzhaoComparisons',comparisonId);local source=payload(tableName,candidateId)
 if not comparison or not source then return nil,'READ_FAILED'end
 local ok,record=pcall(D.json.decode,comparison,32);if not ok or type(record)~='table'or type(record.candidate)~='table'then return nil,'INVALID_COMPARISON'end
 local bundle={schemaVersion=1,actor=record.candidate.characterId,candidate={id=candidateId,algorithm=algorithm,payload=source},comparison={id=comparisonId,payload=comparison}}
 local proof,why=checked(bundle);if not proof then return nil,why end
 if not require('Training.YingzhaoRules').current(proof.record.setup)then return nil,'ENCOUNTER_CHANGED'end
 if not equal(models,proof.record.setup.models)then return nil,'BASE_MODELS_CHANGED'end
 for _,actor in ipairs({'ninilite','wuyun'})do if not equal(proof.record.setup.states[actor],S.state(actor))then return nil,'EVALUATION_DEPLOYMENT_CHANGED'end end
 return bundle,proof
end
local function raw(id)
 local rows=D.DB:query('SELECT actor,parent,payload FROM lsd.Game0YingzhaoAdoptions WHERE id=?',{id});return rows and rows[1]
end
local function read(actor,id)
 local row=raw(id);if not row or row[1]~=actor or not integer(row[2])or row[2]>=id or type(row[3])~='string'or #row[3]>S.maxBytes then return nil,'INVALID_ADOPTION'end
 local ok,data=pcall(D.json.decode,row[3],32);if not ok or type(data)~='table'or data.accepted~=true then return nil,'INVALID_ADOPTION'end
 if data.scope~=nil and data.scope~='practice'and data.scope~='practice-and-mission'then return nil,'INVALID_ADOPTION'end
 local proof,why=checked(data.bundle);if not proof or data.bundle.actor~=actor then return nil,why or 'ACTOR_MISMATCH'end
 if not equal(row,raw(id))then return nil,'ADOPTION_CHANGED'end
 return {id=id,parent=row[2],payload=row[3],scope=data.scope or 'practice',bundle=data.bundle,proof=proof}
end
function S.inspectAsync(actor)
 local state,why=S.state(actor);if not state then return nil,why end;if state.current==0 then return nil,'NOT_ADOPTED'end
 local saved,why=read(actor,state.current);if not equal(state,S.state(actor))then return nil,'ADOPTION_CHANGED'end
 return saved,why
end
function S.loadAsync(actor,models,scope)
 models=freeze(models)
 local saved,why=S.inspectAsync(actor);if not saved then return nil,why end
 if scope=='mission'and saved.scope~='practice-and-mission'then return nil,'MISSION_NOT_CONFIRMED'end
 if not require('Training.YingzhaoRules').current(saved.proof.record.setup)then return nil,'ENCOUNTER_CHANGED'end
 if not equal(models,saved.proof.record.setup.models)then return nil,'BASE_MODELS_CHANGED'end
 return saved
end
local function operation(fn)
 if busy then return false,'BUSY'end;busy=true
 local r=table.pack(xpcall(fn,debug.traceback));busy=false
 if not r[1]then return false,'ADOPTION_ERROR'end;return table.unpack(r,2,r.n)
end
function S.adoptAsync(bundle,ack,models,expected)
 return operation(function()
  if not expectedOK(expected)then return false,'EXPECTED_ADOPTION_REQUIRED'end
  bundle=freeze(bundle);ack=freeze(ack);models=freeze(models);expected=freeze(expected)
  local proof,why=checked(bundle);if not proof then return false,why end
  local actor=bundle.actor
  if not equal(expected,S.state(actor))then return false,'ADOPTION_CHANGED'end
  if type(ack)~='table'or ack.accepted~=true or ack.comparisonId~=bundle.comparison.id or not equal(ack.review,proof.review)then return false,'REVIEW_NOT_ACKNOWLEDGED'end
  if not require('Training.YingzhaoRules').current(proof.record.setup)then return false,'ENCOUNTER_CHANGED'end
  if not equal(models,proof.record.setup.models)then return false,'BASE_MODELS_CHANGED'end
  for _,id in ipairs({'ninilite','wuyun'})do if not equal(proof.record.setup.states[id],S.state(id))then return false,'EVALUATION_DEPLOYMENT_CHANGED'end end
  local scope=ack.scope or 'practice';if scope~='practice'and scope~='practice-and-mission'then return false,'INVALID_SCOPE'end
  local current;if expected.current>0 then current,why=read(actor,expected.current);if not current then return false,why end end
  if not equal(expected,S.state(actor))then return false,'ADOPTION_CHANGED'end
  if current and current.scope==scope and equal(current.bundle,bundle)then return true,'ALREADY_ADOPTED',current.id end
  if bundle.candidate.payload~=payload(candidateTable(bundle.candidate.algorithm),bundle.candidate.id)or bundle.comparison.payload~=payload('Game0YingzhaoComparisons',bundle.comparison.id)then return false,'REVIEW_CHANGED'end
  local data=D.json.encode({accepted=true,scope=scope,bundle=bundle},false,true);if #data>S.maxBytes then return false,'ADOPTION_TOO_LARGE'end
  local dependencies='EXISTS(SELECT 1 FROM lsd.'..candidateTable(bundle.candidate.algorithm)..' WHERE id=? AND payload=?) AND EXISTS(SELECT 1 FROM lsd.Game0YingzhaoComparisons WHERE id=? AND payload=?)'
  local depArgs={bundle.candidate.id,bundle.candidate.payload,bundle.comparison.id,bundle.comparison.payload}
  for _,ancestor in ipairs(proof.ancestors)do
   dependencies=dependencies..' AND EXISTS(SELECT 1 FROM lsd.Game0YingzhaoQCandidates WHERE id=? AND payload=?)'
   depArgs[#depArgs+1]=ancestor.id;depArgs[#depArgs+1]=ancestor.payload
  end
  local other=actor=='ninilite'and'wuyun'or'ninilite';local partner=proof.record.setup.states[other]
  dependencies=dependencies..' AND EXISTS(SELECT 1 FROM lsd.Game0YingzhaoAdoptionState WHERE actor=? AND current=? AND revision=?)'
  for _,v in ipairs({other,partner.current,partner.revision})do depArgs[#depArgs+1]=v end
  if current then dependencies=dependencies..' AND EXISTS(SELECT 1 FROM lsd.Game0YingzhaoAdoptions WHERE id=? AND actor=? AND parent=? AND payload=?)';for _,v in ipairs({current.id,actor,current.parent,current.payload})do depArgs[#depArgs+1]=v end end
  local args={expected.current,expected.revision};for _,v in ipairs(depArgs)do args[#args+1]=v end;args[#args+1]=actor
  local after='EXISTS(SELECT 1 FROM lsd.Game0YingzhaoAdoptionState WHERE actor=? AND current=last_insert_rowid() AND revision=?) AND EXISTS(SELECT 1 FROM lsd.Game0YingzhaoAdoptions WHERE id=last_insert_rowid() AND actor=? AND parent=? AND payload=?) AND '..dependencies
  local afterArgs={actor,expected.revision+1,actor,expected.current,data};for _,v in ipairs(depArgs)do afterArgs[#afterArgs+1]=v end
  local ok=D.DB:transactionAsync({
   {'INSERT INTO lsd.Game0YingzhaoAdoptions(actor,parent,payload) VALUES(?,?,?)',{{actor,expected.current,data}}},
   {'UPDATE lsd.Game0YingzhaoAdoptionState SET current=CASE WHEN current=? AND revision=? AND '..dependencies..' THEN last_insert_rowid() ELSE -1 END,revision=revision+1 WHERE actor=?',{args}},
   {"INSERT INTO lsd.Game0YingzhaoAdoptionState(actor,current,revision) SELECT 'invalid',-1,0 WHERE COALESCE(("..after.."),0)=0",{afterArgs}}
  })
  if not ok then return false,'WRITE_FAILED'end
  return true,'ADOPTED',S.state(actor).current
 end)
end
function S.rollbackAsync(actor,expected)
 return operation(function()
  if not expectedOK(expected)then return false,'EXPECTED_ADOPTION_REQUIRED'end
  expected=freeze(expected)
  if not equal(expected,S.state(actor))or expected.current==0 then return false,'ADOPTION_CHANGED'end
  local row=raw(expected.current);if not row or row[1]~=actor or not integer(row[2])or row[2]>=expected.current then return false,'INVALID_ADOPTION'end
  local prior,why;if row[2]>0 then prior,why=read(actor,row[2]);if not prior then return false,why end end
  local dependencies='EXISTS(SELECT 1 FROM lsd.Game0YingzhaoAdoptions WHERE id=? AND actor=? AND parent=? AND payload=?)'
  local depArgs={expected.current,actor,row[2],row[3]}
  if prior then dependencies=dependencies..' AND EXISTS(SELECT 1 FROM lsd.Game0YingzhaoAdoptions WHERE id=? AND actor=? AND parent=? AND payload=?)';for _,v in ipairs({prior.id,actor,prior.parent,prior.payload})do depArgs[#depArgs+1]=v end end
  local args={expected.current,expected.revision};for _,v in ipairs(depArgs)do args[#args+1]=v end;args[#args+1]=row[2];args[#args+1]=actor
  local after='EXISTS(SELECT 1 FROM lsd.Game0YingzhaoAdoptionState WHERE actor=? AND current=? AND revision=?) AND '..dependencies
  local afterArgs={actor,row[2],expected.revision+1};for _,v in ipairs(depArgs)do afterArgs[#afterArgs+1]=v end
  local ok=D.DB:transactionAsync({
   {'UPDATE lsd.Game0YingzhaoAdoptionState SET current=CASE WHEN current=? AND revision=? AND '..dependencies..' THEN ? ELSE -1 END,revision=revision+1 WHERE actor=?',{args}},
   {"INSERT INTO lsd.Game0YingzhaoAdoptionState(actor,current,revision) SELECT 'invalid',-1,0 WHERE COALESCE(("..after.."),0)=0",{afterArgs}}
  })
  if not ok then return false,'WRITE_FAILED'end;return true,row[2]==0 and 'RESTORED_BASIC'or'ROLLED_BACK',row[2]
 end)
end
return S
