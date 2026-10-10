-- Independent process verifies an actual adopted checkpoint and Q ancestry.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-adoption-cold-result.json';local r={status='RUNNING',checks={},formalJourney=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32)
  assert(prior.status=='PASS'and prior.adoptedCheckpoint:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-checkpoint%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-adoption-cold-'..os.time()..'.db';r.database=db;r.parentEvidence=parent
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.adoptedCheckpoint,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.YingzhaoAdoptionStore');local models=assert(require('Training.FlowerPractice').models());local actor='ninilite'
  local saved,why=S.loadAsync(actor,models,'mission');assert(saved,why);assert(saved.id==prior.active and saved.bundle.candidate.id==prior.candidateId and saved.proof.candidate.model.algorithm==prior.algorithm)
  r.algorithm=prior.algorithm;r.active=saved.id;r.checks.independentNativeRead=true
  local invalid,why=S.loadAsync(actor,{},'mission');assert(not invalid and why=='BASE_MODELS_CHANGED')
  local Rules=require('Training.YingzhaoRules');local version=Rules.version;Rules.version='qa-rules-changed'
  local invalid,why=S.loadAsync(actor,models,'mission');assert(not invalid and why=='ENCOUNTER_CHANGED');Rules.version=version
  assert(S.inspectAsync(actor).id==saved.id);r.checks.runtimeContextChecked=true
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0YingzhaoAdoptionState ORDER BY actor'),false,true)
  local row=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoAdoptions WHERE id=?',{saved.id})[1][1]
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoAdoptions SET payload=? WHERE id=?',{'{}',saved.id})==1)
  assert(not S.loadAsync(actor,models,'mission'),'Corrupt adoption accepted')
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoAdoptions SET payload=? WHERE id=?',{row,saved.id})==1);assert(S.loadAsync(actor,models,'mission'))
  assert(D.json.encode(D.DB:query('SELECT * FROM lsd.Game0YingzhaoAdoptionState ORDER BY actor'),false,true)==before);r.checks.corruptionCannotChangeSelection=true
  local partner=S.state('wuyun');local yes,why=S.rollbackAsync(actor,S.state(actor));assert(yes and why=='RESTORED_BASIC',why)
  assert(require('Training.FlowerIdentity').equal(partner,S.state('wuyun')));local invalid,why=S.loadAsync(actor,models,'mission');assert(not invalid and why=='NOT_ADOPTED');r.checks.coldRollback=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
