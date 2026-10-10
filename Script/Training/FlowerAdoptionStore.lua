-- Independent immutable adoption history. Generic training saves are untouched.
local D=require('Dora');local R=require('Training.FlowerAdoptionReview')
local equal=require('Training.FlowerIdentity').equal
local S={};local busy=false
local function actorOK(actor)return actor=='ninilite' or actor=='wuyun'end
local function open()
 if not D.DB:existDB('lsd')then return false end
 for _,sql in ipairs({
  'CREATE TABLE IF NOT EXISTS lsd.Game0FlowerAdoptions(id INTEGER PRIMARY KEY AUTOINCREMENT, learner TEXT NOT NULL, parent INTEGER NOT NULL CHECK(parent>=0), payload TEXT NOT NULL)',
  'CREATE TABLE IF NOT EXISTS lsd.Game0FlowerAdoptionState(learner TEXT PRIMARY KEY,current INTEGER NOT NULL CHECK(current>=0))',
  "INSERT OR IGNORE INTO lsd.Game0FlowerAdoptionState VALUES('ninilite',0),('wuyun',0)"
 })do if D.DB:exec(sql)<0 then return false end end
 return true
end
local function current(actor)
 local rows=D.DB:query('SELECT current FROM lsd.Game0FlowerAdoptionState WHERE learner=?',{actor})
 return rows and rows[1] and rows[1][1]
end
local function baseline()
 local p=require('Training.Progress');local w=p.forCharacter('wuyun')
 if not p.load() or not w.load() or not p.adopted or not w.adopted then return nil,'BASIC_MODELS_UNAVAILABLE'end
 return {ninilite=p.adopted,wuyun=w.adopted}
end
local function record(id,actor)
 local rows=D.DB:query('SELECT learner,parent,payload FROM lsd.Game0FlowerAdoptions WHERE id=?',{id})
 if not rows or not rows[1]then return nil,'ADOPTION_NOT_FOUND'end
 local row=rows[1];if row[1]~=actor or row[2]>=id or type(row[3])~='string' or #row[3]>R.maxBytes then return nil,'INVALID_ADOPTION'end
 local saved=D.json.decode(row[3],32)
 if type(saved)~='table' or saved.schemaVersion~=1 or saved.accepted~=true then return nil,'INVALID_ADOPTION'end
 local review,why=R.assess(saved.bundle);if not review then return nil,why end
 if saved.bundle.learner~=actor or not review.readyForDecision or not R.sameAssessment(saved.review,review)then return nil,'INVALID_ADOPTION_REVIEW'end
 return {id=id,parent=row[2],bundle=saved.bundle,review=review}
end
local function operation(fn)
 if busy then return false,'BUSY'end;busy=true
 local result=table.pack(xpcall(fn,debug.traceback));busy=false
 if not result[1]then return false,'ADOPTION_ERROR',result[2]end
 return table.unpack(result,2,result.n)
end
-- Historical records remain readable for rollback. Deployment and new adoption
-- require the authored boss size and current shot-commitment rules.
local function currentGeometry(bundle)
 for _,list in ipairs({bundle.trials,bundle.fieldTrials or {}})do
  for _,trial in ipairs(list)do if not require('Factory.Rules').current(trial.setup) then return false end end
 end
 return true
end
-- Inspect the selected immutable archive even when deployment rules changed.
function S.inspect(actor)
 if not actorOK(actor)then return nil,'INVALID_CHARACTER'end
 if not open()then return nil,'READ_FAILED'end
 local id=current(actor);if id==nil then return nil,'READ_FAILED'end
 if id==0 then return nil,'NOT_ADOPTED'end
 return record(id,actor)
end
function S.load(actor,models)
 local group=require('Training.FlowerTeamAdoptionStore').currentId();if group==nil then return nil,'READ_FAILED' elseif group~=0 then return nil,'TEAM_ADOPTION_ACTIVE'end
 if not actorOK(actor)then return nil,'INVALID_CHARACTER'end
 if not open()then return nil,'READ_FAILED'end
 local id=current(actor);if id==nil then return nil,'READ_FAILED'end;if id==0 then return nil,'NOT_ADOPTED'end
 local saved,why=record(id,actor);if not saved then return nil,why end
 if not currentGeometry(saved.bundle)then return nil,'ENCOUNTER_CHANGED'end
 local other=actor=='ninilite' and 'wuyun' or 'ninilite'
 if current(other)~=0 then return nil,'PARTNER_DEPLOYMENT_UNTESTED'end
 if not models then models,why=baseline();if not models then return nil,why end end
 if not equal(models,saved.bundle.models)then return nil,'BASIC_MODELS_CHANGED'end
 return saved
end
function S.adoptAsync(bundle,acknowledgement)
 return operation(function()
  local q=require('Training.FlowerQAdoptionStore').currentId();if q==nil then return false,'READ_FAILED' elseif q~=0 then return false,'Q_ADOPTION_ACTIVE'end
  local group=require('Training.FlowerTeamAdoptionStore').currentId();if group==nil then return false,'READ_FAILED' elseif group~=0 then return false,'TEAM_ADOPTION_ACTIVE'end
  local review,why=R.assess(bundle);if not review then return false,why end
  if not bundle.fieldTrials then return false,'FIELD_EVALUATION_REQUIRED'end
  if not currentGeometry(bundle)then return false,'ENCOUNTER_CHANGED'end
  if not review.readyForDecision then return false,'EVALUATION_BLOCKED'end
  if type(acknowledgement)~='table' or acknowledgement.accepted~=true or not R.sameAssessment(acknowledgement.review,review)then return false,'REVIEW_NOT_ACKNOWLEDGED'end
  local payload=D.json.encode({schemaVersion=1,bundle=bundle,review=review,accepted=true},false,true)
  if not payload or #payload>R.maxBytes then return false,'ADOPTION_EVIDENCE_TOO_LARGE'end
  local frozen=D.json.decode(payload,32);bundle=frozen.bundle
  if not open()then return false,'WRITE_FAILED'end
  local actor=bundle.learner;local parent=current(actor);if parent==nil then return false,'READ_FAILED'end
  local verified,why=R.verifyAsync(bundle);if not verified then return false,why end
  -- Recheck all live dependencies after native learning yields. An old review
  -- cannot hide a newer failure, changed candidate, partner, or basic model.
  local models,why=baseline();if not models then return false,why end
  if not equal(models,bundle.models)then return false,'BASIC_MODELS_CHANGED'end
  local source,why=require('Training.FlowerPolicyStore').evidence(actor);if not source then return false,why end
  local rows,why=require('Training.FlowerTrialStore').history(actor);if not rows then return false,why end
  local latest,why=R.make(source,models,rows);if not latest then return false,why end
  if not equal(latest,bundle)then return false,'REVIEW_STALE'end
  local other=actor=='ninilite' and 'wuyun' or 'ninilite'
  if current(other)~=0 then return false,'PARTNER_DEPLOYMENT_UNTESTED'end
  if current(actor)~=parent then return false,'ADOPTION_STATE_CHANGED'end
  if parent>0 then
   local prior,why=record(parent,actor);if not prior then return false,why end
   if equal(prior.bundle,bundle)then return true,'ALREADY_ADOPTED',parent end
  end
  local saved=D.DB:transactionAsync({
   {'INSERT INTO lsd.Game0FlowerAdoptions(learner,parent,payload) VALUES(?,?,?)',{{actor,parent,payload}}},
   {'UPDATE lsd.Game0FlowerAdoptionState SET current=CASE WHEN current=? AND (SELECT current FROM lsd.Game0FlowerAdoptionState WHERE learner=?)=0 AND (SELECT current FROM lsd.Game0FlowerTeamState WHERE singleton=1)=0 AND (SELECT current FROM lsd.Game0FlowerQAdoptionState WHERE singleton=1)=0 THEN last_insert_rowid() ELSE -1 END WHERE learner=?',{{parent,other,actor}}}
  })
  if not saved then return false,'WRITE_FAILED'end
  return true,'ADOPTED',current(actor)
 end)
end
function S.rollbackAsync(actor,expectedId)
 return operation(function()
  local group=require('Training.FlowerTeamAdoptionStore').currentId();if group==nil then return false,'READ_FAILED' elseif group~=0 then return false,'TEAM_ADOPTION_ACTIVE'end
  if not actorOK(actor)then return false,'INVALID_CHARACTER'end
  if not open()then return false,'WRITE_FAILED'end
  local id=current(actor);if id==nil then return false,'READ_FAILED'end;if id==0 then return false,'NOT_ADOPTED'end
  if expectedId~=nil and expectedId~=id then return false,'ADOPTION_STATE_CHANGED'end
  local saved,why=record(id,actor);if not saved then return false,why end
  if saved.parent>0 then local previous,why=record(saved.parent,actor);if not previous then return false,why end end
  local ok=D.DB:transactionAsync({{'UPDATE lsd.Game0FlowerAdoptionState SET current=CASE WHEN current=? AND (SELECT current FROM lsd.Game0FlowerTeamState WHERE singleton=1)=0 THEN ? ELSE -1 END WHERE learner=?',{{id,saved.parent,actor}}}})
  if not ok then return false,'WRITE_FAILED'end
  return true,saved.parent==0 and 'RESTORED_BASIC' or 'ROLLED_BACK',saved.parent
 end)
end
return S
