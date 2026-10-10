local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-adoption-store-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-repeated-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-repeated%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-adoption-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync());local A=require('Training.FlowerQAssessment');local S=require('Training.FlowerQAdoptionStore')
  local bundle,why=A.captureAsync(saved.source.baseModels);assert(bundle,why);assert(bundle.assessment.readyForDecision and S.currentId()==0)
  local ack={accepted=true,assessment=bundle.assessment};local yes,why=S.adoptAsync(bundle,{accepted=false},saved.source.baseModels,0);assert(not yes and why=='REVIEW_NOT_ACKNOWLEDGED')
  assert(D.DB:exec("UPDATE lsd.Game0FlowerAdoptionState SET current=999 WHERE learner='ninilite'")>=0)
  yes,why=S.adoptAsync(bundle,ack,saved.source.baseModels,0);assert(not yes and why=='OTHER_POLICY_ACTIVE')
  assert(D.DB:exec("UPDATE lsd.Game0FlowerAdoptionState SET current=0 WHERE learner='ninilite'")>=0);r.otherPolicyGuard=true
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_q_adoption BEFORE UPDATE ON Game0FlowerQAdoptionState BEGIN SELECT RAISE(ABORT,'QA adoption'); END")>=0)
  yes,why=S.adoptAsync(bundle,ack,saved.source.baseModels,0);assert(not yes and why=='WRITE_FAILED');assert(S.currentId()==0 and #D.DB:query('SELECT id FROM lsd.Game0FlowerQAdoptions')==0);r.failureAtomic=true
  assert(D.DB:exec('DROP TRIGGER lsd.fail_q_adoption')>=0)
  local source=D.DB:query('SELECT payload FROM lsd.Game0FlowerQSources WHERE id=2')[1][1]
  assert(D.DB:exec("CREATE TRIGGER lsd.change_q_adoption BEFORE INSERT ON Game0FlowerQAdoptions BEGIN UPDATE Game0FlowerQSources SET payload='{}' WHERE id=2; END")>=0)
  yes,why=S.adoptAsync(bundle,ack,saved.source.baseModels,0);assert(not yes and why=='WRITE_FAILED');assert(S.currentId()==0 and #D.DB:query('SELECT id FROM lsd.Game0FlowerQAdoptions')==0)
  assert(D.DB:query('SELECT payload FROM lsd.Game0FlowerQSources WHERE id=2')[1][1]==source);r.dependencyAtomic=true
  assert(D.DB:exec('DROP TRIGGER lsd.change_q_adoption')>=0)
  local id;yes,why,id=S.adoptAsync(bundle,ack,saved.source.baseModels,0);assert(yes,tostring(why));r.adopted=id
  local adopted,why=S.inspectAsync();assert(adopted,why);assert(adopted.id==id and require('Training.FlowerIdentity').equal(adopted.models,saved.models))
  yes,why=S.adoptAsync(bundle,ack,saved.source.baseModels,id);assert(yes and why=='ALREADY_ADOPTED');assert(#D.DB:query('SELECT id FROM lsd.Game0FlowerQAdoptions')==1);r.idempotent=true
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQDraft SET current=1 WHERE singleton=1')>=0);assert(S.inspectAsync().id==id);r.draftIndependent=true
  yes,why=S.rollbackAsync(id+1);assert(not yes and why=='Q_ADOPTION_CHANGED')
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQDraft SET current=2 WHERE singleton=1')>=0)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_q_rollback BEFORE UPDATE ON Game0FlowerQAdoptionState BEGIN SELECT RAISE(ABORT,'QA rollback'); END")>=0)
  yes,why=S.rollbackAsync(id);assert(not yes and why=='WRITE_FAILED' and S.currentId()==id)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_q_rollback')>=0);yes,why=S.rollbackAsync(id);assert(yes and why=='RESTORED_BASIC' and S.currentId()==0)
  assert(#D.DB:query('SELECT id FROM lsd.Game0FlowerQAdoptions')==1);r.rollbackRetainsHistory=true
  yes,why,id=S.adoptAsync(bundle,ack,saved.source.baseModels,0);assert(yes);r.current=id;assert(S.inspectAsync().id==id)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
