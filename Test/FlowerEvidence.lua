-- Evidence survives rolling-log eviction; failed writes cannot split model/source.
local script,source=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script));local out=root..'/Test/flower-evidence-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-combat%-learning%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-evidence-'..os.time()..'.db';assert(not D.Content:exist(dest) and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.FlowerPolicyStore');local E=require('Training.FlowerEvidence');local P=require('Training.FlowerPolicy');local I=require('Training.FlowerIdentity')
  local function progress()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')},false,true)end
  local before=progress();local model=assert(S.load('ninilite'));assert(model.sampleCount==31)
  local absent,why=S.evidence('ninilite');assert(not absent and why=='EVIDENCE_NOT_RECORDED','Legacy evidence fabricated')
  local history=assert(require('Training.FlowerPracticeStore').history('ninilite'))
  local saved,why,persisted=S.saveAsync(model,history);assert(saved and persisted and I.equal(persisted,S.load('ninilite')),'Returned model differs from stored representation');local archive=assert(S.evidence('ninilite'));assert(E.verifyAsync(archive,'ninilite') and #archive.episodes==2)
  local function payloads()return D.DB:query('SELECT payload FROM lsd.Game0FlowerCandidates WHERE learner=?',{'ninilite'})[1][1],D.DB:query('SELECT payload FROM lsd.Game0FlowerCandidateEvidence WHERE learner=?',{'ninilite'})[1][1]end
  local oldPolicy,oldEvidence=payloads()
  local changed=D.json.decode(D.json.encode(model),32);changed.rules[1].action=changed.rules[1].action=='idle' and 'fmove' or 'idle'
  local ok,why=S.saveAsync(changed,history);assert(not ok and why=='REBUILD_MISMATCH','Unlearned policy archived')
  local newest={history[#history]};local newer=assert(P.buildAsync(newest,'ninilite'));assert(newer.sampleCount~=model.sampleCount)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_evidence BEFORE INSERT ON Game0FlowerCandidateEvidence BEGIN SELECT RAISE(ABORT,'QA evidence'); END")>=0)
  local ok,why=S.saveAsync(newer,newest);assert(not ok and why=='WRITE_FAILED')
  local policyAfter,evidenceAfter=payloads();assert(policyAfter==oldPolicy and evidenceAfter==oldEvidence,'Evidence failure partially changed model/source')
  assert(D.DB:exec('DROP TRIGGER lsd.fail_evidence')>=0)
  -- Simulate eviction only inside this explicitly named QA copy.
  assert(D.DB:exec("DELETE FROM lsd.Game0FlowerPractice WHERE learner='ninilite'")>=0)
  assert(#require('Training.FlowerPracticeStore').history('ninilite')==0)
  local preserved=assert(S.evidence('ninilite'));assert(E.verifyAsync(preserved,'ninilite') and I.equal(preserved.policy,model))
  local ok,why=S.saveAsync(model,{});assert(not ok and why=='MISSING_SOURCE_EPISODE')
  local mismatched=D.json.decode(oldEvidence,32);mismatched.policy.rules[1].action=changed.rules[1].action
  assert(D.DB:exec('UPDATE lsd.Game0FlowerCandidateEvidence SET payload=? WHERE learner=?',{D.json.encode(mismatched),'ninilite'})>=0)
  local rejected,why=S.evidence('ninilite');assert(not rejected and why=='EVIDENCE_POLICY_MISMATCH')
  assert(D.DB:exec('UPDATE lsd.Game0FlowerCandidateEvidence SET payload=? WHERE learner=?',{oldEvidence,'ninilite'})>=0)
  assert(S.load('wuyun').sampleCount==7 and not S.evidence('wuyun'),'Evidence crossed learners')
  assert(progress()==before)
  r.samples=model.sampleCount;r.archivedEpisodes=#archive.episodes;r.nativeRebuild=true;r.survivesEviction=true;r.atomicRollback=true;r.unlearnedRulesRejected=true;r.mismatchedArchiveRejected=true;r.legacyReadable=true;r.progressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
