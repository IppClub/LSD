local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-adoption-reload-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-adoption-store-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-adoption%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-adoption-reload-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync());local A=require('Training.FlowerQAssessment');local S=require('Training.FlowerQAdoptionStore')
  local adopted,why=S.inspectAsync();assert(adopted,why);assert(adopted.id==prior.current and adopted.parent==0);r.coldRead=true
  local run=require('Training.FlowerQSession').runAsync({mode='evaluate',profile='near',models=saved.source.baseModels,initial=saved.models,onProgress=function(b)r.seconds=D.App.runningTime-b.started;save()end})
  local yes,why=require('Training.FlowerQTrials').saveAsync(run,saved.id);assert(yes,why);r.naturalStatus=run.status
  assert(S.inspectAsync().id==adopted.id);r.additionalTrialKeepsAdoption=true
  yes,why=A.verifyAsync(adopted.bundle,saved.source.baseModels);assert(not yes and why=='REVIEW_STALE');r.oldReviewStale=true
  local bundle=assert(A.captureAsync(saved.source.baseModels));local id
  yes,why,id=S.adoptAsync(bundle,{accepted=true,assessment=bundle.assessment},saved.source.baseModels,adopted.id);assert(yes,why)
  assert(S.inspectAsync().parent==adopted.id);r.child=id
  local source=D.DB:query('SELECT payload FROM lsd.Game0FlowerQSources WHERE id=2')[1][1]
  assert(D.DB:exec("CREATE TRIGGER lsd.change_q_rollback BEFORE UPDATE ON Game0FlowerQAdoptionState BEGIN UPDATE Game0FlowerQSources SET payload='{}' WHERE id=2; END")>=0)
  yes,why=S.rollbackAsync(id);assert(not yes and why=='WRITE_FAILED');assert(S.currentId()==id and D.DB:query('SELECT payload FROM lsd.Game0FlowerQSources WHERE id=2')[1][1]==source);r.rollbackDependencyAtomic=true
  assert(D.DB:exec('DROP TRIGGER lsd.change_q_rollback')>=0)
  yes,why=S.rollbackAsync(id);assert(yes and why=='ROLLED_BACK');assert(S.inspectAsync().id==adopted.id)
  yes,why=S.rollbackAsync(adopted.id);assert(yes and why=='RESTORED_BASIC' and S.currentId()==0);r.parentRollback=true
  assert(#D.DB:query('SELECT id FROM lsd.Game0FlowerQAdoptions')==3);r.histories=3
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
