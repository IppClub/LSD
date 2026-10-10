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
  'CREATE TABLE IF NOT EXISTS lsd.Game0DisarmAdoptions(id INTEGER PRIMARY KEY AUTOINCREMENT,actor TEXT NOT NULL,parent INTEGER NOT NULL CHECK(parent>=0),payload TEXT NOT NULL)',
  'CREATE TABLE IF NOT EXISTS lsd.Game0DisarmAdoptionState(actor TEXT PRIMARY KEY,current INTEGER NOT NULL CHECK(current>=0),revision INTEGER NOT NULL CHECK(revision>=0))'
 })do if D.DB:exec(sql)<0 then return false end end
 return D.DB:exec('INSERT OR IGNORE INTO lsd.Game0DisarmAdoptionState VALUES(?,0,0)',{actor})>=0
end
function S.state(actor)
 if not open(actor)then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT current,revision FROM lsd.Game0DisarmAdoptionState WHERE actor=?',{actor})
 if not rows or not rows[1]or not integer(rows[1][1])or not integer(rows[1][2])then return nil,'READ_FAILED'end
 return {current=rows[1][1],revision=rows[1][2]}
end
local function payload(tableName,id)
 local rows=D.DB:query('SELECT payload FROM lsd.'..tableName..' WHERE id=?',{id});return rows and rows[1]and rows[1][1]
end
local function verify(bundle)
 if type(bundle)~='table'or bundle.schemaVersion~=1 or not actorOK(bundle.actor)or type(bundle.candidate)~='table'or type(bundle.comparison)~='table'then return nil,'INVALID_BUNDLE'end
 if not integer(bundle.candidate.id)or bundle.candidate.id==0 or not integer(bundle.comparison.id)or bundle.comparison.id==0 then return nil,'INVALID_BUNDLE'end
 local cp,sp=bundle.comparison.payload,bundle.candidate.payload
 if type(cp)~='string'or #cp>40*1024*1024 or type(sp)~='string'or #sp>16*1024*1024 then return nil,'INVALID_BUNDLE'end
 local record=D.json.decode(cp,32);local source=D.json.decode(sp,32)
 if type(source)~='table'or source.schemaVersion~=1 then return nil,'INVALID_SOURCE'end
 local review,why=require('Training.DisarmCompare').review(record);if not review then return nil,why end
 local P=require('Training.DisarmPolicy');local valid,why=P.validate(source.model,bundle.actor);if not valid then return nil,why end
 if not equal(record.setup.candidate,{id=bundle.candidate.id,model=source.model})then return nil,'CANDIDATE_MISMATCH'end
 local rebuilt,why=P.buildAsync(source.records,bundle.actor,source.model.featureSchemaVersion);if not rebuilt then return nil,why end
 if not equal(rebuilt,source.model)then return nil,'SOURCE_MODEL_MISMATCH'end
 return {candidate={id=bundle.candidate.id,model=source.model},record=record,review=review}
end
local function checked(bundle)
 local ok,result,why=xpcall(function()return verify(bundle)end,debug.traceback)
 if not ok then return nil,'INVALID_BUNDLE'end;return result,why
end
function S.captureAsync(comparisonId,models)
 if not integer(comparisonId)or comparisonId==0 then return nil,'INVALID_COMPARISON'end
 models=freeze(models)
 local comparison=payload('Game0DisarmComparisons',comparisonId);if not comparison then return nil,'READ_FAILED'end
 local ok,record=pcall(D.json.decode,comparison,32);if not ok or type(record)~='table'or type(record.setup)~='table'or type(record.setup.candidate)~='table'then return nil,'INVALID_COMPARISON'end
 local candidate=record.setup.candidate;local source=payload('Game0DisarmCandidates',candidate.id);if not source then return nil,'READ_FAILED'end
 local bundle={schemaVersion=1,actor=candidate.model and candidate.model.characterId,candidate={id=candidate.id,payload=source},comparison={id=comparisonId,payload=comparison}}
 local proof,why=checked(bundle);if not proof then return nil,why end
 if not require('Training.DisarmRules').current(proof.record.setup)then return nil,'ENCOUNTER_CHANGED'end
 if not equal(models,proof.record.setup.models)then return nil,'BASE_MODELS_CHANGED'end
 if source~=payload('Game0DisarmCandidates',candidate.id)or comparison~=payload('Game0DisarmComparisons',comparisonId)then return nil,'REVIEW_CHANGED'end
 return bundle,proof
end
local function raw(id)
 local rows=D.DB:query('SELECT actor,parent,payload FROM lsd.Game0DisarmAdoptions WHERE id=?',{id});return rows and rows[1]
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
 if not require('Training.DisarmRules').current(saved.proof.record.setup)then return nil,'ENCOUNTER_CHANGED'end
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
  if not require('Training.DisarmRules').current(proof.record.setup)then return false,'ENCOUNTER_CHANGED'end
  if not equal(models,proof.record.setup.models)then return false,'BASE_MODELS_CHANGED'end
  local scope=ack.scope or 'practice';if scope~='practice'and scope~='practice-and-mission'then return false,'INVALID_SCOPE'end
  local current;if expected.current>0 then current,why=read(actor,expected.current);if not current then return false,why end end
  if not equal(expected,S.state(actor))then return false,'ADOPTION_CHANGED'end
  if current and current.scope==scope and equal(current.bundle,bundle)then return true,'ALREADY_ADOPTED',current.id end
  if bundle.candidate.payload~=payload('Game0DisarmCandidates',bundle.candidate.id)or bundle.comparison.payload~=payload('Game0DisarmComparisons',bundle.comparison.id)then return false,'REVIEW_CHANGED'end
  local data=D.json.encode({accepted=true,scope=scope,bundle=bundle},false,true);if #data>S.maxBytes then return false,'ADOPTION_TOO_LARGE'end
  local dependencies='EXISTS(SELECT 1 FROM lsd.Game0DisarmCandidates WHERE id=? AND payload=?) AND EXISTS(SELECT 1 FROM lsd.Game0DisarmComparisons WHERE id=? AND payload=?)'
  local depArgs={bundle.candidate.id,bundle.candidate.payload,bundle.comparison.id,bundle.comparison.payload}
  if current then dependencies=dependencies..' AND EXISTS(SELECT 1 FROM lsd.Game0DisarmAdoptions WHERE id=? AND actor=? AND parent=? AND payload=?)';for _,v in ipairs({current.id,actor,current.parent,current.payload})do depArgs[#depArgs+1]=v end end
  local args={expected.current,expected.revision};for _,v in ipairs(depArgs)do args[#args+1]=v end;args[#args+1]=actor
  local after='EXISTS(SELECT 1 FROM lsd.Game0DisarmAdoptionState WHERE actor=? AND current=last_insert_rowid() AND revision=?) AND EXISTS(SELECT 1 FROM lsd.Game0DisarmAdoptions WHERE id=last_insert_rowid() AND actor=? AND parent=? AND payload=?) AND '..dependencies
  local afterArgs={actor,expected.revision+1,actor,expected.current,data};for _,v in ipairs(depArgs)do afterArgs[#afterArgs+1]=v end
  local ok=D.DB:transactionAsync({
   {'INSERT INTO lsd.Game0DisarmAdoptions(actor,parent,payload) VALUES(?,?,?)',{{actor,expected.current,data}}},
   {'UPDATE lsd.Game0DisarmAdoptionState SET current=CASE WHEN current=? AND revision=? AND '..dependencies..' THEN last_insert_rowid() ELSE -1 END,revision=revision+1 WHERE actor=?',{args}},
   {"INSERT INTO lsd.Game0DisarmAdoptionState(actor,current,revision) SELECT 'invalid',-1,0 WHERE COALESCE(("..after.."),0)=0",{afterArgs}}
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
  local dependencies='EXISTS(SELECT 1 FROM lsd.Game0DisarmAdoptions WHERE id=? AND actor=? AND parent=? AND payload=?)'
  local depArgs={expected.current,actor,row[2],row[3]}
  if prior then dependencies=dependencies..' AND EXISTS(SELECT 1 FROM lsd.Game0DisarmAdoptions WHERE id=? AND actor=? AND parent=? AND payload=?)';for _,v in ipairs({prior.id,actor,prior.parent,prior.payload})do depArgs[#depArgs+1]=v end end
  local args={expected.current,expected.revision};for _,v in ipairs(depArgs)do args[#args+1]=v end;args[#args+1]=row[2];args[#args+1]=actor
  local after='EXISTS(SELECT 1 FROM lsd.Game0DisarmAdoptionState WHERE actor=? AND current=? AND revision=?) AND '..dependencies
  local afterArgs={actor,row[2],expected.revision+1};for _,v in ipairs(depArgs)do afterArgs[#afterArgs+1]=v end
  local ok=D.DB:transactionAsync({
   {'UPDATE lsd.Game0DisarmAdoptionState SET current=CASE WHEN current=? AND revision=? AND '..dependencies..' THEN ? ELSE -1 END,revision=revision+1 WHERE actor=?',{args}},
   {"INSERT INTO lsd.Game0DisarmAdoptionState(actor,current,revision) SELECT 'invalid',-1,0 WHERE COALESCE(("..after.."),0)=0",{afterArgs}}
  })
  if not ok then return false,'WRITE_FAILED'end;return true,row[2]==0 and 'RESTORED_BASIC'or'ROLLED_BACK',row[2]
 end)
end
return S
