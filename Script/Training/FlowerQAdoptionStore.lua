-- Two learners switch together; immutable adoption history and guarded rollback.
local D=require('Dora');local A=require('Training.FlowerQAssessment');local equal=require('Training.FlowerIdentity').equal
local S={maxBytes=96*1024*1024};local busy=false
local function open()
 if not D.DB:existDB('lsd')then return false end
 for _,sql in ipairs({
  'CREATE TABLE IF NOT EXISTS lsd.Game0FlowerQAdoptions(id INTEGER PRIMARY KEY AUTOINCREMENT,parent INTEGER NOT NULL CHECK(parent>=0),payload TEXT NOT NULL)',
  'CREATE TABLE IF NOT EXISTS lsd.Game0FlowerQAdoptionState(singleton INTEGER PRIMARY KEY CHECK(singleton=1),current INTEGER NOT NULL CHECK(current>=0))',
  'INSERT OR IGNORE INTO lsd.Game0FlowerQAdoptionState VALUES(1,0)'
 })do if D.DB:exec(sql)<0 then return false end end;return true
end
function S.currentId()
 if not open()then return nil end
 local rows=D.DB:query('SELECT current FROM lsd.Game0FlowerQAdoptionState WHERE singleton=1');return rows and rows[1] and rows[1][1]
end
local function raw(id)
 local rows=D.DB:query('SELECT parent,payload FROM lsd.Game0FlowerQAdoptions WHERE id=?',{id});return rows and rows[1]
end
local function read(id)
 local row=raw(id)
 if not row or row[1]<0 or row[1]>=id or type(row[2])~='string' or #row[2]>S.maxBytes then return nil,'INVALID_Q_ADOPTION'end
 local data=D.json.decode(row[2],32)
 if type(data)~='table' or data.schemaVersion~=1 or data.accepted~=true then return nil,'INVALID_Q_ADOPTION'end
 local archive,why=A.readArchiveAsync(data.bundle);if not archive then return nil,why end
 if not equal(row,raw(id))then return nil,'Q_ADOPTION_CHANGED'end
 return {id=id,parent=row[1],payload=row[2],bundle=data.bundle,models=archive.models,assessment=archive.assessment}
end
function S.inspectAsync()
 local id=S.currentId();if id==nil then return nil,'READ_FAILED'end;if id==0 then return nil,'NOT_ADOPTED'end
 local saved,why=read(id);if S.currentId()~=id then return nil,'Q_ADOPTION_CHANGED'end;return saved,why
end
local function operation(fn)
 if busy then return false,'BUSY'end;busy=true;local r=table.pack(xpcall(fn,debug.traceback));busy=false
 if not r[1]then return false,'Q_ADOPTION_ERROR',r[2]end;return table.unpack(r,2,r.n)
end
local function conflictGuard()
 local guards={}
 for _,name in ipairs({'Game0FlowerTeamState','Game0FlowerAdoptionState'})do
  local rows=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name=?",{name});if not rows then return nil end
  if rows[1]then
   local active=D.DB:query('SELECT COUNT(*) FROM lsd.'..name..' WHERE current<>0');if not active or active[1][1]>0 then return nil,'OTHER_POLICY_ACTIVE'end
   guards[#guards+1]='NOT EXISTS(SELECT 1 FROM lsd.'..name..' WHERE current<>0)'
  else guards[#guards+1]="NOT EXISTS(SELECT 1 FROM lsd.sqlite_master WHERE type='table' AND name='"..name.."')"end
 end
 return table.concat(guards,' AND ')
end
function S.loadAsync(models)
 local frozen=D.json.decode(D.json.encode(models,false,true),32)
 local saved,why=S.inspectAsync();if not saved then return nil,why end
 if not require('Factory.Rules').qCurrent(saved.bundle)then return nil,'ENCOUNTER_CHANGED'end
 if not equal(frozen,saved.bundle.models)then return nil,'BASE_MODELS_CHANGED'end
 local guard,why=conflictGuard();if not guard then return nil,why or 'READ_FAILED'end
 return saved
end
function S.adoptAsync(bundle,ack,models,expected)
 return operation(function()
  if type(expected)~='number' or expected<0 or expected%1~=0 then return false,'EXPECTED_ADOPTION_REQUIRED'end
  bundle=D.json.decode(D.json.encode(bundle,false,true),32);ack=D.json.decode(D.json.encode(ack,false,true),32)
  if not require('Factory.Rules').qCurrent(bundle)then return false,'ENCOUNTER_CHANGED'end
  if not bundle.assessment or not bundle.assessment.readyForDecision then return false,'EVALUATION_BLOCKED'end
  if type(ack)~='table' or ack.accepted~=true or not equal(ack.assessment,bundle.assessment)then return false,'REVIEW_NOT_ACKNOWLEDGED'end
  if S.currentId()~=expected then return false,'Q_ADOPTION_CHANGED'end
  local verified,why=A.verifyAsync(bundle,models);if not verified then return false,why end
  local other,why=conflictGuard();if not other then return false,why or 'READ_FAILED'end
  local prior
  if expected>0 then prior,why=read(expected);if not prior then return false,why end end
  if S.currentId()~=expected then return false,'Q_ADOPTION_CHANGED'end
  if prior and equal(prior.bundle,bundle)then return true,'ALREADY_ADOPTED',expected end
  local payload=D.json.encode({schemaVersion=1,accepted=true,bundle=bundle},false,true);if #payload>S.maxBytes then return false,'ADOPTION_TOO_LARGE'end
  local guard={'current=?','(SELECT current FROM lsd.Game0FlowerQDraft WHERE singleton=1)=?',other};local args={expected,bundle.candidate}
  if prior then guard[#guard+1]='EXISTS(SELECT 1 FROM lsd.Game0FlowerQAdoptions WHERE id=? AND parent=? AND payload=?)';args[#args+1]=prior.id;args[#args+1]=prior.parent;args[#args+1]=prior.payload end
  for _,source in ipairs(bundle.sources)do guard[#guard+1]='EXISTS(SELECT 1 FROM lsd.Game0FlowerQSources WHERE id=? AND parent=? AND payload=?)';args[#args+1]=source.id;args[#args+1]=source.parent;args[#args+1]=source.payload end
  guard[#guard+1]='(SELECT COUNT(*) FROM lsd.Game0FlowerQTrials WHERE candidate=?)=?';args[#args+1]=bundle.candidate;args[#args+1]=#bundle.trials
  for _,row in ipairs(bundle.trials)do guard[#guard+1]='EXISTS(SELECT 1 FROM lsd.Game0FlowerQTrials WHERE id=? AND candidate=? AND episode=? AND payload=?)';for _,v in ipairs(row)do args[#args+1]=v end end
  local afterGuard={};for i,clause in ipairs(guard)do afterGuard[i]=i==1 and '(SELECT current FROM lsd.Game0FlowerQAdoptionState WHERE singleton=1)=last_insert_rowid()' or clause end
  local afterArgs={};for i=2,#args do afterArgs[#afterArgs+1]=args[i]end
  local yes=D.DB:transactionAsync({
   {'INSERT INTO lsd.Game0FlowerQAdoptions(parent,payload) VALUES(?,?)',{{expected,payload}}},
   {'UPDATE lsd.Game0FlowerQAdoptionState SET current=CASE WHEN '..table.concat(guard,' AND ')..' THEN last_insert_rowid() ELSE -1 END WHERE singleton=1',{args}},
   {'INSERT INTO lsd.Game0FlowerQAdoptionState(singleton,current) SELECT 2,0 WHERE COALESCE(('..table.concat(afterGuard,' AND ')..'),0)=0',{afterArgs}}
  })
  if not yes then return false,'WRITE_FAILED'end
  return true,'ADOPTED',S.currentId()
 end)
end
function S.rollbackAsync(expected)
 return operation(function()
  if S.currentId()~=expected or expected==0 then return false,'Q_ADOPTION_CHANGED'end
  local row=raw(expected);if not row or row[1]<0 or row[1]>=expected then return false,'INVALID_Q_ADOPTION'end
  local prior,why;if row[1]>0 then prior,why=read(row[1]);if not prior then return false,why end end
  local guard='current=? AND EXISTS(SELECT 1 FROM lsd.Game0FlowerQAdoptions WHERE id=? AND parent=? AND payload=?)';local args={expected,expected,row[1],row[2]}
  if prior then
   local other,why=conflictGuard();if not other then return false,why or 'READ_FAILED'end;guard=guard..' AND '..other
   guard=guard..' AND EXISTS(SELECT 1 FROM lsd.Game0FlowerQAdoptions WHERE id=? AND parent=? AND payload=?)';args[#args+1]=prior.id;args[#args+1]=prior.parent;args[#args+1]=prior.payload
   for _,source in ipairs(prior.bundle.sources)do guard=guard..' AND EXISTS(SELECT 1 FROM lsd.Game0FlowerQSources WHERE id=? AND parent=? AND payload=?)';args[#args+1]=source.id;args[#args+1]=source.parent;args[#args+1]=source.payload end
   for _,record in ipairs(prior.bundle.trials)do guard=guard..' AND EXISTS(SELECT 1 FROM lsd.Game0FlowerQTrials WHERE id=? AND candidate=? AND episode=? AND payload=?)';for _,value in ipairs(record)do args[#args+1]=value end end
  end
  local afterArgs={};for i,v in ipairs(args)do afterArgs[i]=v end;afterArgs[1]=row[1]
  local afterGuard=guard:gsub('^current=%?', '(SELECT current FROM lsd.Game0FlowerQAdoptionState WHERE singleton=1)=?')
  args[#args+1]=row[1]
  -- Check dependencies after the pointer mutation too. A failing CHECK rolls
  -- back both the pointer and any trigger-side dependency mutation.
  local yes=D.DB:transactionAsync({
   {'UPDATE lsd.Game0FlowerQAdoptionState SET current=CASE WHEN '..guard..' THEN ? ELSE -1 END WHERE singleton=1',{args}},
   {'INSERT INTO lsd.Game0FlowerQAdoptionState(singleton,current) SELECT 2,0 WHERE COALESCE(('..afterGuard..'),0)=0',{afterArgs}}
  })
  if not yes then return false,'WRITE_FAILED'end
  return true,row[1]==0 and 'RESTORED_BASIC' or 'ROLLED_BACK',row[1]
 end)
end
return S
