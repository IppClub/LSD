local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-store-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-trace-review-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-trace%-review%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-store-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  local trace=assert(D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/flower-trace-review-trace.json'),32))
  local record=assert(D.json.decode(D.DB:query('SELECT payload FROM lsd.Game0FlowerTeamTrials WHERE episode=?',{trace.episode})[1][1],32))
  local run=assert(D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/flower-q-explore-session.json'),32))
  local Q=require('Training.FlowerQ');local S=require('Training.FlowerQStore');local equal=require('Training.FlowerIdentity').equal
  local seed={baseModels=record.setup.models,trace=trace,episode=record.episode,status=record.status,models=assert(Q.learn(trace,record.episode,record.status))}
  assert(equal(seed.models,run.initial),'Seed provenance does not match actual session')
  local before=D.json.encode({D.DB:query('SELECT * FROM lsd.Game0FlowerCandidates'),D.DB:query('SELECT * FROM lsd.Game0FlowerAdoptionState'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)
  local missing,why=S.loadAsync();assert(not missing and why=='NOT_RECORDED')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_q_draft BEFORE UPDATE ON Game0FlowerQDraft BEGIN SELECT RAISE(ABORT,'QA Q draft failure'); END")>=0)
  local ok,why=S.saveSeedAsync(seed,0);assert(not ok and why=='WRITE_FAILED');assert(#D.DB:query('SELECT * FROM lsd.Game0FlowerQSources')==0)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_q_draft')>=0)
  local ok,why,first=S.saveSeedAsync(seed,0);assert(ok,why);r.first=first
  local seedPayload=D.DB:query('SELECT payload FROM lsd.Game0FlowerQSources WHERE id=?',{first})[1][1]
  assert(D.DB:exec("CREATE TRIGGER lsd.change_q_parent BEFORE INSERT ON Game0FlowerQSources BEGIN UPDATE Game0FlowerQSources SET payload=payload || ' '; END")>=0)
  local ok,why=S.saveRunAsync(run,first);assert(not ok and why=='WRITE_FAILED')
  assert(#D.DB:query('SELECT * FROM lsd.Game0FlowerQSources')==1 and D.DB:query('SELECT payload FROM lsd.Game0FlowerQSources WHERE id=?',{first})[1][1]==seedPayload)
  assert(D.DB:exec('DROP TRIGGER lsd.change_q_parent')>=0);r.atomicParentGuard=true
  local ok,why,second=S.saveRunAsync(run,first);assert(ok,why);r.second=second
  local loaded,why=S.loadAsync();assert(loaded,why);assert(loaded.depth==2 and loaded.parent==first and equal(loaded.models,run.models));r.chainRebuilt=true
  local ok,why,duplicate=S.saveRunAsync(run,first);assert(ok and why=='ALREADY_SAVED' and duplicate==second and #D.DB:query('SELECT * FROM lsd.Game0FlowerQSources')==2);r.idempotent=true
  local function copy(v)return D.json.decode(D.json.encode(v,false,true),32)end
  local wrong=copy(run);wrong.models.ninilite.updates=wrong.models.ninilite.updates+1;assert(not S.saveRunAsync(wrong,first))
  wrong=copy(run);wrong.episode.episode=wrong.episode.episode..'-stale-fixture';local ok,why=S.saveRunAsync(wrong,0);assert(not ok and why=='Q_DRAFT_CHANGED')
  -- Persisted corruption must be detected by a full lineage rebuild, not by metadata alone.
  local mutated=copy(seed);mutated.models.ninilite.updates=mutated.models.ninilite.updates+1
  local payload=assert(D.json.decode(seedPayload,32));payload.models=mutated.models
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQSources SET payload=? WHERE id=?',{D.json.encode(payload,false,true),first})>=0)
  local invalid,why=S.loadAsync();assert(not invalid and why=='Q_REBUILD_MISMATCH')
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQSources SET payload=? WHERE id=?',{seedPayload,first})>=0)
  assert(S.loadAsync());r.corruptParentRejected=true
  assert(before==D.json.encode({D.DB:query('SELECT * FROM lsd.Game0FlowerCandidates'),D.DB:query('SELECT * FROM lsd.Game0FlowerAdoptionState'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true));r.noAdoptionMutation=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
