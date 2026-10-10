-- Native source/transaction check on copied, actually earned training archives.
-- This is a component encounter; it does not claim a formal main-story journey.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-adoption-result.json';local r={status='RUNNING',checks={},formalJourney=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'),'Explicit earned training archive required')
  local prior=D.json.decode(D.Content:load(parent),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-[%w%-]+%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-adoption-'..os.time()..'.db';r.database=db;r.parentEvidence=parent
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.YingzhaoAdoptionStore');local CS=require('Training.YingzhaoComparisonStore');local equal=require('Training.FlowerIdentity').equal
  local models=assert(require('Training.FlowerPractice').models());local actor='ninilite'
  local candidate
  if D.DB:exist('Game0YingzhaoQCandidates','lsd')then candidate=assert(require('Training.YingzhaoQStore').loadLatestAsync(actor))
  else candidate=assert(require('Training.YingzhaoPolicyStore').loadLatestAsync(actor))end
  r.algorithm=candidate.model.algorithm;r.candidateId=candidate.id
  local function snapshot()
   local tables=assert(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'Game0YingzhaoAdoption%' AND name NOT IN ('Game0YingzhaoComparisons','sqlite_sequence') ORDER BY name"))
   local values={};for _,row in ipairs(tables)do values[row[1]]=D.DB:query('SELECT * FROM lsd."'..row[1]..'" ORDER BY rowid')end
   return D.json.encode(values,false,true)
  end
  local before=snapshot();local states={ninilite=assert(S.state('ninilite')),wuyun=assert(S.state('wuyun'))};assert(states.ninilite.current==0 and states.wuyun.current==0)
  local _,loadout=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true})
  local report,why=require('Training.YingzhaoComparison').runAsync(models,candidate.model,loadout,function(round)r.round=round.mode;save()end,{candidateId=candidate.id,adoptionStates=states})
  assert(report,why);assert(CS.validate(report));local comparison=assert(CS.saveAsync(report));r.comparisonId=comparison
  local bundle,proof=S.captureAsync(comparison,candidate.id,candidate.model.algorithm,models);assert(bundle,proof)
  local ack={accepted=true,comparisonId=comparison,review=proof.review,scope='practice-and-mission'}
  local function reject(reason,... )local yes,why=S.adoptAsync(...);assert(not yes and why==reason,tostring(why))end
  reject('REVIEW_NOT_ACKNOWLEDGED',bundle,{accepted=false},models,states.ninilite)
  reject('BASE_MODELS_CHANGED',bundle,ack,{},states.ninilite);r.checks.explicitReview=true
  local function archive()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0YingzhaoAdoptions ORDER BY id'),D.DB:query('SELECT * FROM lsd.Game0YingzhaoAdoptionState ORDER BY actor')},false,true)end
  for _,trigger in ipairs({
   "CREATE TRIGGER lsd.break_adopt BEFORE INSERT ON Game0YingzhaoAdoptions BEGIN SELECT RAISE(ABORT,'QA failure'); END",
   "CREATE TRIGGER lsd.break_adopt AFTER UPDATE ON Game0YingzhaoAdoptionState BEGIN DELETE FROM Game0YingzhaoAdoptionState WHERE actor=NEW.actor; END",
   "CREATE TRIGGER lsd.break_adopt AFTER UPDATE ON Game0YingzhaoAdoptionState BEGIN UPDATE Game0YingzhaoAdoptionState SET revision=revision+1 WHERE actor='wuyun'; END"
  })do
   local a=archive();assert(D.DB:exec(trigger)>=0);reject('WRITE_FAILED',bundle,ack,models,states.ninilite)
   assert(D.DB:exec('DROP TRIGGER lsd.break_adopt')>=0);assert(archive()==a and snapshot()==before)
  end
  if candidate.source and candidate.source.base then
   local a=archive();local ancestor=candidate.source.parentId
   assert(D.DB:exec("CREATE TRIGGER lsd.break_ancestor AFTER INSERT ON Game0YingzhaoAdoptions BEGIN UPDATE Game0YingzhaoQCandidates SET payload='{}' WHERE id="..ancestor.."; END")>=0)
   reject('WRITE_FAILED',bundle,ack,models,states.ninilite)
   assert(D.DB:exec('DROP TRIGGER lsd.break_ancestor')>=0);assert(archive()==a and snapshot()==before);r.checks.qAncestorTransactionRace=true
  end
  r.checks.atomicAdoptionAndPartnerRace=true
  local yes,why,id=S.adoptAsync(bundle,ack,models,states.ninilite);assert(yes and why=='ADOPTED',why);r.active=id
  local saved=assert(S.loadAsync(actor,models,'mission'));assert(saved.id==id and equal(saved.proof.candidate.model,candidate.model));assert(equal(states.wuyun,S.state('wuyun')))
  reject('ADOPTION_CHANGED',bundle,ack,models,states.ninilite);r.checks.sourceRebuiltAndFrozen=true
  local checkpoint=D.Content.writablePath..'/yingzhao-adopted-checkpoint-'..os.time()..'.db'
  assert(D.DB:exec("VACUUM lsd INTO '"..checkpoint.."'")>=0);r.adoptedCheckpoint=checkpoint
  local tableName=candidate.model.algorithm=='yingzhao-qlearning'and'Game0YingzhaoQCandidates'or'Game0YingzhaoCandidates'
  local raw=D.DB:query('SELECT payload FROM lsd.'..tableName..' WHERE id=?',{candidate.id})[1][1]
  assert(D.DB:exec('UPDATE lsd.'..tableName..' SET payload=? WHERE id=?',{'{}',candidate.id})==1)
  local invalid= S.loadAsync(actor,models,'mission');assert(not invalid,'Changed source accepted')
  assert(D.DB:exec('UPDATE lsd.'..tableName..' SET payload=? WHERE id=?',{raw,candidate.id})==1);assert(S.loadAsync(actor,models,'mission'))
  r.checks.changedSourceRejected=true
  if candidate.source and candidate.source.base then
   local parentId=candidate.source.parentId;local rawParent=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoQCandidates WHERE id=?',{parentId})[1][1]
   assert(D.DB:exec('UPDATE lsd.Game0YingzhaoQCandidates SET payload=? WHERE id=?',{'{}',parentId})==1)
   assert(not S.loadAsync(actor,models,'mission'),'Corrupt Q ancestor accepted')
   assert(D.DB:exec('UPDATE lsd.Game0YingzhaoQCandidates SET payload=? WHERE id=?',{rawParent,parentId})==1);assert(S.loadAsync(actor,models,'mission'));r.checks.qAncestorRejected=true
  end
  local state=S.state(actor);local a=archive()
  assert(D.DB:exec("CREATE TRIGGER lsd.break_rollback AFTER UPDATE ON Game0YingzhaoAdoptionState BEGIN DELETE FROM Game0YingzhaoAdoptionState WHERE actor=NEW.actor; END")>=0)
  local yes,why=S.rollbackAsync(actor,state);assert(not yes and why=='WRITE_FAILED',why)
  assert(D.DB:exec('DROP TRIGGER lsd.break_rollback')>=0);assert(archive()==a)
  local yes,why=S.rollbackAsync(actor,state);assert(yes and why=='RESTORED_BASIC',why);assert(not S.loadAsync(actor,models,'mission'));assert(equal(states.wuyun,S.state('wuyun')))
  r.checks.atomicRollback=true;assert(snapshot()==before);r.checks.storyWalletModelsUnchanged=true
  -- Revision changes require a new real comparison, not rewritten metadata.
  local invalid,why=S.captureAsync(comparison,candidate.id,candidate.model.algorithm,models)
  assert(not invalid and why=='EVALUATION_DEPLOYMENT_CHANGED');r.checks.staleComparisonRejected=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
