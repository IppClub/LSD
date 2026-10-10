-- A combination has one transactional pointer. Individual histories stay intact.
local D=require('Dora');local R=require('Training.FlowerTeamReview')
local equal=require('Training.FlowerIdentity').equal
local same=require('Training.FlowerAdoptionReview').sameAssessment
local S={};local busy=false
local function open()
 if not D.DB:existDB('lsd')then return false end
 for _,sql in ipairs({
  'CREATE TABLE IF NOT EXISTS lsd.Game0FlowerTeamAdoptions(id INTEGER PRIMARY KEY AUTOINCREMENT,parent INTEGER NOT NULL CHECK(parent>=0),payload TEXT NOT NULL)',
  'CREATE TABLE IF NOT EXISTS lsd.Game0FlowerTeamState(singleton INTEGER PRIMARY KEY CHECK(singleton=1),current INTEGER NOT NULL CHECK(current>=0))',
  'INSERT OR IGNORE INTO lsd.Game0FlowerTeamState VALUES(1,0)'
 })do if D.DB:exec(sql)<0 then return false end end;return true
end
function S.currentId()
 if not open()then return nil end
 local rows=D.DB:query('SELECT current FROM lsd.Game0FlowerTeamState WHERE singleton=1');return rows and rows[1] and rows[1][1]
end
local function singlesBasic()
 local store=require('Training.FlowerAdoptionStore')
 for _,id in ipairs({'ninilite','wuyun'})do local saved,why=store.inspect(id);if saved or why~='NOT_ADOPTED'then return false end end
 return true
end
local function record(id)
 local rows=D.DB:query('SELECT parent,payload FROM lsd.Game0FlowerTeamAdoptions WHERE id=?',{id});local row=rows and rows[1]
 if not row or row[1]>=id or type(row[2])~='string' or #row[2]>R.maxBytes then return nil,'INVALID_TEAM_ADOPTION'end
 local saved=D.json.decode(row[2],32)
 if type(saved)~='table' or saved.schemaVersion~=1 or saved.accepted~=true then return nil,'INVALID_TEAM_ADOPTION'end
 local review,why=R.assess(saved.bundle,true);if not review then return nil,why end
 if not same(review,saved.review)then return nil,'INVALID_TEAM_REVIEW'end
 return {id=id,parent=row[1],bundle=saved.bundle,review=review}
end
function S.inspect()
 local id=S.currentId();if id==nil then return nil,'READ_FAILED'end;if id==0 then return nil,'NOT_ADOPTED'end;return record(id)
end
function S.load(models)
 local saved,why=S.inspect();if not saved then return nil,why end
 local current,why=R.assess(saved.bundle);if not current then return nil,why end
 if not current.readyForDecision then return nil,'ENCOUNTER_CHANGED'end
 if not singlesBasic()then return nil,'SINGLE_ADOPTION_ACTIVE'end
 if not models then models,why=require('Training.FlowerPractice').models();if not models then return nil,why end end
 if not equal(models,saved.bundle.models)then return nil,'BASIC_MODELS_CHANGED'end
 return saved
end
local function operation(fn)
 if busy then return false,'BUSY'end;busy=true;local result=table.pack(xpcall(fn,debug.traceback));busy=false
 if not result[1]then return false,'ADOPTION_ERROR',result[2]end;return table.unpack(result,2,result.n)
end
-- Compare the exact dependency rows inside the write transaction as well as
-- checking semantic identity before it. Async DB scheduling must not create a
-- gap in which a new model/trial can be adopted using an older review.
local function dependencies()
 local clauses,values={},{}
 for _,spec in ipairs({
  {'Game0FlowerCandidates','learner','payload'},
  {'Game0FlowerCandidateEvidence','learner','payload'},
  {'Game0Training','slot','payload'},{'Game0Training_wuyun','slot','payload'},
  {'Game0FlowerTeamTrials','serial','episode','payload'}
 })do
  local columns={};for i=2,#spec do columns[#columns+1]=spec[i]end
  local tableName='lsd.'..spec[1]
  local rows=D.DB:query('SELECT '..table.concat(columns,',')..' FROM '..tableName)
  if not rows then return nil end
  clauses[#clauses+1]='(SELECT COUNT(*) FROM '..tableName..')=?';values[#values+1]=#rows
  for _,row in ipairs(rows)do
   local terms={};for i,column in ipairs(columns)do terms[#terms+1]=column..'=?';values[#values+1]=row[i]end
   clauses[#clauses+1]='EXISTS(SELECT 1 FROM '..tableName..' WHERE '..table.concat(terms,' AND ')..')'
  end
 end
 return table.concat(clauses,' AND '),values
end
function S.adoptAsync(bundle,ack)
 return operation(function()
  local q=require('Training.FlowerQAdoptionStore').currentId();if q==nil then return false,'READ_FAILED' elseif q~=0 then return false,'Q_ADOPTION_ACTIVE'end
  local review,why=R.assess(bundle);if not review then return false,why end
  if not review.readyForDecision then return false,'EVALUATION_BLOCKED'end
  if type(ack)~='table' or ack.accepted~=true or not same(ack.review,review)then return false,'REVIEW_NOT_ACKNOWLEDGED'end
  local payload=D.json.encode({schemaVersion=1,accepted=true,bundle=bundle,review=review},false,true)
  if #payload>R.maxBytes then return false,'ADOPTION_EVIDENCE_TOO_LARGE'end
  bundle=D.json.decode(payload,32).bundle
  local parent=S.currentId();if parent==nil then return false,'WRITE_FAILED'end
  if not singlesBasic()then return false,'SINGLE_ADOPTION_ACTIVE'end
  local verified,why=R.verifyAsync(bundle);if not verified then return false,why end
  local dependencyGuard,dependencyValues=dependencies();if not dependencyGuard then return false,'READ_FAILED'end
  local P=require('Training.FlowerPractice');local sources,why=P.teamSources();if not sources then return false,why end
  local models,why=P.models();if not models then return false,why end
  local rows,why=require('Training.FlowerTeamTrials').history();if not rows then return false,why end
  local latest,why=R.make(sources,models,rows);if not latest then return false,why end
  if not equal(latest,bundle)then return false,'REVIEW_STALE'end
  if S.currentId()~=parent then return false,'ADOPTION_STATE_CHANGED'end
  if not singlesBasic()then return false,'SINGLE_ADOPTION_ACTIVE'end
  if parent>0 then local prior,why=record(parent);if not prior then return false,why end;if equal(prior.bundle,bundle)then return true,'ALREADY_ADOPTED',parent end end
  local parameters={parent};for _,value in ipairs(dependencyValues)do parameters[#parameters+1]=value end
  local ok=D.DB:transactionAsync({
   {'INSERT INTO lsd.Game0FlowerTeamAdoptions(parent,payload) VALUES(?,?)',{{parent,payload}}},
   {'UPDATE lsd.Game0FlowerTeamState SET current=CASE WHEN current=? AND (SELECT COUNT(*) FROM lsd.Game0FlowerAdoptionState WHERE current<>0)=0 AND (SELECT current FROM lsd.Game0FlowerQAdoptionState WHERE singleton=1)=0 AND '..dependencyGuard..' THEN last_insert_rowid() ELSE -1 END WHERE singleton=1',{parameters}}
  })
  if not ok then return false,'WRITE_FAILED'end;return true,'ADOPTED',S.currentId()
 end)
end
function S.rollbackAsync(expectedId)
 return operation(function()
  local saved,why=S.inspect();if not saved then return false,why end
  if expectedId~=nil and saved.id~=expectedId then return false,'ADOPTION_STATE_CHANGED'end
  if saved.parent>0 then local prior,why=record(saved.parent);if not prior then return false,why end end
  local ok=D.DB:transactionAsync({{'UPDATE lsd.Game0FlowerTeamState SET current=CASE WHEN current=? THEN ? ELSE -1 END WHERE singleton=1',{{saved.id,saved.parent}}}})
  if not ok then return false,'WRITE_FAILED'end
  return true,saved.parent==0 and 'RESTORED_BASIC' or 'ROLLED_BACK',saved.parent
 end)
end
return S
