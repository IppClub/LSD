local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-cold-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local supportParent=os.getenv('LSD_QA_SUPPORT_REWARD_PARENT')
  if supportParent then
   local prior=D.json.decode(D.Content:load(supportParent),32)
   assert(prior.status=='PASS'and prior.qCandidateSaved and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-support%-reward%-v3%-%d+%.db$'))
   assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-support-v3-cold-'..os.time()..'.db'
   assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
   local Store=require('Training.YingzhaoQStore');local I=require('Training.FlowerIdentity');local candidate=assert(Store.loadLatestAsync('ninilite'))
   assert(candidate.id==prior.qCandidateId and I.equal(candidate.model,prior.qModel))
   assert(candidate.model.rewardPolicy==require('Training.YingzhaoRewards').supportPolicy and candidate.source.combat.rewardPolicy==candidate.model.rewardPolicy)
   local restored=assert(require('Training.YingzhaoQ').restore(candidate.model));assert(I.equal(restored:snapshot(),candidate.model))
   local tables=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
   assert(#tables==1 and tables[1][1]=='Game0YingzhaoQCandidates')
   r.database=db;r.source=prior.database;r.id=candidate.id;r.rewardPolicy=candidate.model.rewardPolicy;r.coldReplay=true;r.noAdoption=true;r.sourceAccount=candidate.source.combat.boss.supportAccounting
   return
  end

  local prior=D.json.decode(D.Content:load(root..'/Test/yingzhao-q-result.json'),32)
  local source=prior.candidateStore
  assert(prior.status=='PASS'and source.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-q%-candidates%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'))
  local db=D.Content.writablePath..'/yingzhao-q-cold-'..os.time()..'.db'
  assert(D.Content:copyAsync(source.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local store=require('Training.YingzhaoQStore');local candidate=assert(store.loadLatestAsync('ninilite'))
  assert(candidate.id==source.id and candidate.model.updates==4)
  assert(require('Training.YingzhaoQ').restore(candidate.model))
  local payload=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoQCandidates WHERE id=?',{candidate.id})[1][1]
  local altered=D.json.decode(payload,32);altered.base.updates=999
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoQCandidates SET payload=? WHERE id=?',{D.json.encode(altered),candidate.id})>=0)
  assert(not store.loadLatestAsync('ninilite'),'Changed base accepted')
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoQCandidates SET payload=? WHERE id=?',{payload,candidate.id})>=0)
  assert(store.loadLatestAsync('ninilite'))
  altered=D.json.decode(payload,32);altered.parentId=candidate.id
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoQCandidates SET payload=? WHERE id=?',{D.json.encode(altered),candidate.id})>=0)
  local cycle,why=store.loadLatestAsync('ninilite');assert(not cycle and why=='INVALID_PARENT')
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoQCandidates SET payload=? WHERE id=?',{payload,candidate.id})>=0)
  assert(store.loadLatestAsync('ninilite'))
  r.cycleRejected=true
  local tables=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
  assert(#tables==1 and tables[1][1]=='Game0YingzhaoQCandidates')
  r.id=candidate.id;r.updates=candidate.model.updates;r.coldReplay=true;r.noAdoption=true;r.baseCorruptionRejected=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
