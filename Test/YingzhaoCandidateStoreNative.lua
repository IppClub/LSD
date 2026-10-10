local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-candidate-store-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/yingzhao-policy-result.json'),32);assert(prior.status=='PASS'and prior.candidateExecuted)
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-candidates-'..os.time()..'.db';r.database=db;assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local archive=require('Training.YingzhaoStore');assert(archive.saveAsync(prior.source))
  local store=require('Training.YingzhaoPolicyStore');local candidate=assert(store.learnAsync('ninilite'))
  local loaded=assert(store.loadLatestAsync('ninilite'));assert(loaded.id==candidate.id and require('Training.FlowerIdentity').equal(loaded.model,candidate.model))
  local empty,why=store.loadLatestAsync('wuyun');assert(not empty and why=='NO_CANDIDATE')
  local row=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoCandidates WHERE id=?',{candidate.id})[1][1]
  local altered=D.json.decode(row,32);altered.model.trainingAccuracy=altered.model.trainingAccuracy==1 and .5 or 1
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoCandidates SET payload=? WHERE id=?',{D.json.encode(altered),candidate.id})>=0)
  loaded,why=store.loadLatestAsync('ninilite');assert(not loaded and why=='SOURCE_MODEL_MISMATCH')
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoCandidates SET payload=? WHERE id=?',{row,candidate.id})>=0)
  assert(D.DB:exec("CREATE TRIGGER lsd.reject_candidate BEFORE INSERT ON Game0YingzhaoCandidates BEGIN SELECT RAISE(ABORT,'candidate write QA'); END")>=0)
  loaded,why=store.learnAsync('ninilite');assert(not loaded and why=='WRITE_FAILED')
  assert(D.DB:exec('DROP TRIGGER lsd.reject_candidate')>=0);loaded=assert(store.learnAsync('ninilite'));assert(loaded.id>candidate.id)
  assert(require('Training.FlowerIdentity').equal(assert(store.loadLatestAsync('ninilite')).model,candidate.model))
  r.id=loaded.id;r.samples=candidate.model.sampleCount;r.rebuild=true;r.forgedRejected=true;r.writeRetry=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
