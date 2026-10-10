local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-q-cumulative-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local path=D.Content.writablePath..'/resource-q-cumulative-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and not D.Content:exist(path));assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0)
  local function copy(v)return D.json.decode(D.json.encode(v,false,true),32)end
  local first=D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/resource-practice-ui/source.json'),32)
  local other=D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/resource-virtual-isolation-final/source.json'),32)
  local second=copy(first);second.trace=other.trace;second.episode=other.episode;second.status=other.trace.status
  assert(first.episode.episode~=second.episode.episode)
  local P=require('Training.ResourcePracticeStore');local S=require('Training.ResourceQStore');local Q=require('Training.ResourceQ');local equal=require('Training.FlowerIdentity').equal
  assert(P.saveRunAsync(first));local a,why=S.trainAsync();assert(a,why);assert(a.depth==1)
  local rounded=copy(a.models);local state,row=next(rounded.ninilite.values);local action,value=next(row);row[action]=value+1e-15
  assert(Q.equivalentModels(a.models,rounded),'Rounding compatibility missing')
  row[action]=value+1e-6;assert(not Q.equivalentModels(a.models,rounded),'Meaningful value corruption accepted')
  rounded=copy(a.models);rounded.ninilite.updates=rounded.ninilite.updates+1;assert(not Q.equivalentModels(a.models,rounded))
  local frozen=copy(a.models);assert(P.saveRunAsync(second))
  assert(D.DB:exec("CREATE TRIGGER lsd.RejectCandidate BEFORE INSERT ON Game0ResourceQCandidates BEGIN SELECT RAISE(ABORT,'candidate fault'); END")>=0)
  assert(not S.trainAsync());assert(S.loadLatestAsync().id==a.id)
  assert(D.DB:exec('DROP TRIGGER lsd.RejectCandidate')>=0)
  local b,why=S.trainAsync();assert(b,why);assert(b.depth==2 and b.id~=a.id)
  assert(equal(Q.learn(second.trace,second.episode,second.status,frozen),b.models) and equal(a.models,frozen))
  for actor,model in pairs(b.models)do assert(model.updates>a.models[actor].updates);assert(Q.restore(model,actor))end
  local again=assert(S.trainAsync());assert(again.id==b.id and equal(again.models,b.models))
  assert(D.DB:exec('DETACH DATABASE lsd')>=0);assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0);assert(equal(S.loadLatestAsync().models,b.models))
  local record=assert(P.loadVersionAsync(2));local corrupt=copy(record.source);corrupt.episode.resources.spent=999
  assert(D.DB:exec('UPDATE lsd.Game0ResourcePractices SET payload=? WHERE id=2',{D.json.encode(corrupt,false,true)})>=0)
  assert(not S.loadLatestAsync());assert(not S.trainAsync())
  assert(D.DB:exec('UPDATE lsd.Game0ResourcePractices SET payload=? WHERE id=2',{record.payload})>=0);assert(S.loadLatestAsync().id==b.id)
  local row=D.DB:query('SELECT payload FROM lsd.Game0ResourceQCandidates WHERE id=?',{b.id})[1][1]
  local wrong=D.json.decode(row,32);wrong.models.ninilite.updates=wrong.models.ninilite.updates+1
  assert(D.DB:exec('UPDATE lsd.Game0ResourceQCandidates SET payload=? WHERE id=?',{D.json.encode(wrong,false,true),b.id})>=0);assert(not S.loadLatestAsync())
  assert(D.DB:exec('UPDATE lsd.Game0ResourceQCandidates SET payload=? WHERE id=?',{row,b.id})>=0)
  assert(#D.DB:query("SELECT name FROM lsd.sqlite_master WHERE name IN ('Game0SupplyWallet','Game0FlowerQDraft')")==0)
  local recent=D.json.decode(D.Content:load(root..'/Test/resource-exploration-result.json'),32)
  assert(recent.status=='PASS' and recent.trainingGoal=='resource-clear-v1')
  local newSource=D.json.decode(D.Content:load(root..'/Test/resource-exploration-source.json'),32)
  assert(newSource.setup.trainingGoal=='resource-clear-v1');assert(P.saveRunAsync(newSource))
  local upgraded,why=S.trainAsync();assert(upgraded,why);assert(upgraded.depth==1 and upgraded.bundle.trainingGoal=='resource-clear-v1')
  assert(equal(S.loadVersionAsync(b.id).models,b.models),'Old candidate changed')
  assert(S.trainAsync().id==upgraded.id)
  assert(D.DB:exec('DETACH DATABASE lsd')>=0);assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0)
  assert(S.loadLatestAsync().id==upgraded.id and S.loadVersionAsync(b.id).depth==2)
  r.goalMigration={oldDepth=2,newDepth=upgraded.depth,oldCandidate=b.id,newCandidate=upgraded.id}
  r.depth=b.depth;r.models=b.models;r.checks={'two genuine practice sources','cumulative updates','parent models unchanged','SQL failure preserves candidate','repeat training does not double updates','file reopen rebuild','source tampering rejected','candidate tampering rejected','no wallet or legacy draft tables'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
