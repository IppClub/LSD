local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/q-policy-native-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local Q=require('Training.QModel');local Model=require('Training.Model');local Store=require('Training.Store')
  local a=require('Training.Arena').createAsync({enemySpeed=0,enemyMaxHP=1000,roundLimit=5})
  local calls=0
  local session=assert(a:beginQRound({epsilon=1,random=function()calls=calls+1;return calls%2==1 and 0 or ((math.floor(calls/2)-1)%4+.1)/4 end}))
  while not session.closed do D.sleep(.05)end
  local q=session.model:snapshot();assert(Q.validate(q))
  local old={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId='ninilite',sampleCount=7,trainingAccuracy=1,actions={'laser'},rules={{conditions={},action='laser'}}}
  assert(not D.DB:existDB('lsd'))
  local database=D.Content.writablePath..'/q-policy.db';assert(not D.Content:exist(database))
  assert(D.DB:exec("ATTACH DATABASE '"..database.."' AS lsd")>=0)
  local store=assert(Store.open());assert(not store:load());assert(store:saveAsync(old));assert(store:saveAsync(q,old))
  assert(D.DB:exec('DETACH DATABASE lsd')>=0);assert(D.DB:exec("ATTACH DATABASE '"..database.."' AS lsd")>=0)
  store=assert(Store.open());local saved=assert(store:load())
  assert(saved.adopted.algorithm=='qlearning' and saved.previous.sampleCount==7 and not store.writeBlocked)
  local observed=session.steps[1].state
  assert(Model.predict(saved.adopted,observed)==Model.predict(q,observed))
  local before=D.DB:query("SELECT payload FROM lsd.Game0Training WHERE slot='backup'")[1][1]
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_q BEFORE INSERT ON Game0Training WHEN NEW.slot='main' BEGIN SELECT RAISE(ABORT,'QA Q failure'); END")>=0)
  assert(not store:saveAsync(old,q));assert(store.revision==2)
  assert(D.DB:query("SELECT payload FROM lsd.Game0Training WHERE slot='backup'")[1][1]==before)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_q')>=0)
  assert(store:saveAsync(old,q));store=assert(Store.open());saved=assert(store:load());assert(saved.previous.algorithm=='qlearning' and saved.adopted.sampleCount==7)
  assert(store:saveAsync(q,old))
  local future=Q.restore(q):snapshot();future.rewardPolicy='future-v99'
  local payload=D.json.encode({schemaVersion=1,revision=99,characterId='ninilite',adopted=future})
  assert(D.DB:exec("UPDATE lsd.Game0Training SET payload=? WHERE slot='main'",{{payload}})>=0)
  store=assert(Store.open());local recovery,status=store:load();assert(recovery and status=='RECOVERED_BACKUP' and store.writeBlocked)
  local written,reason=store:saveAsync(q,old);assert(not written and reason=='INCOMPATIBLE_SAVE_READ_ONLY')
  assert(D.DB:query("SELECT payload FROM lsd.Game0Training WHERE slot='main'")[1][1]==payload)
  assert(D.DB:exec('DETACH DATABASE lsd')>=0)
  -- A held-out, far-distance inference round exercises explicit baseline fallback.
  local original=D.json.encode(q);a.roundLimit=3;assert(a:beginTrial(680,q))
  while a.mode=='trial' do D.sleep(.05)end
  assert(q.updates==session.model.updates and D.json.encode(q)==original,'Inference modified Q table')
  assert(a.metrics.fallback>0 and a.metrics.baselineActions>0,'Missing explicit unseen-state baseline')
  r.updates=q.updates;r.fallback=a.metrics.fallback;r.baselineActions=a.metrics.baselineActions
  r.mixedModels=true;r.rollback=true;r.atomicFailure=true;r.futureReadOnly=true;r.nativeInference=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
