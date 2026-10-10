local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/q-trace-native-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,why=xpcall(function()
  local a=require('Training.Arena').createAsync({roundLimit=3,enemyMaxHP=1000,enemySpeed=0})
  local model=assert(a:trainQAsync(12345));local trace=a.qTrainingReport
  local T=require('Training.QTrace');local valid,err=T.validate(trace,model);assert(valid,err)
  local database=D.Content.writablePath..'/q-trace.db';assert(not D.Content:exist(database) and not D.DB:existDB('lsd'))
  assert(D.DB:exec("ATTACH DATABASE '"..database.."' AS lsd")>=0)
  local Store=require('Training.Store');local store=assert(Store.open());store:load()
  local old={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId='ninilite',sampleCount=7,trainingAccuracy=1,actions={'laser'},rules={{conditions={},action='laser'}}}
  assert(store:saveAsync(old));local written,reason=store:saveAsync(model,old);assert(not written and reason=='TRACE_REQUIRED')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_trace BEFORE INSERT ON Game0TrainingRuns BEGIN SELECT RAISE(ABORT,'QA trace write'); END")>=0)
  assert(not store:saveAsync(model,old,trace));assert(store.revision==1)
  assert(#D.DB:query('SELECT * FROM lsd.Game0TrainingRuns')==0 and #D.DB:query("SELECT * FROM lsd.Game0Training WHERE slot='backup'")==0)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_trace')>=0)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_policy BEFORE INSERT ON Game0Training WHEN NEW.slot='main' BEGIN SELECT RAISE(ABORT,'QA policy write'); END")>=0)
  assert(not store:saveAsync(model,old,trace));assert(#D.DB:query('SELECT * FROM lsd.Game0TrainingRuns')==0 and store.revision==1)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_policy')>=0)
  assert(store:saveAsync(model,old,trace));assert(store:saveAsync(model,old,trace));assert(#D.DB:query('SELECT * FROM lsd.Game0TrainingRuns')==1)
  assert(D.DB:exec('DETACH DATABASE lsd')>=0);assert(D.DB:exec("ATTACH DATABASE '"..database.."' AS lsd")>=0)
  store=assert(Store.open());local saved=assert(store:load());local reread=assert(store:loadTrace(saved.adopted));assert(reread.seed==12345 and reread.newUpdates==model.updates)
  assert(store:saveAsync(old,model));assert(store:loadTrace(model))
  local function copy(t)return assert(D.json.decode(D.json.encode(t),32))end
  local bad=copy(trace);bad.rounds[1].steps[1].reward=999;assert(not T.validate(bad,model))
  bad=copy(trace);bad.rounds[1].steps[1].truncated=true;assert(not T.validate(bad,model))
  local tampered=copy(model);local key=next(tampered.values);local action=next(tampered.values[key]);tampered.values[key][action]=tampered.values[key][action]+1
  assert(not T.validate(trace,tampered),'Trace accepted a different final policy')
  -- Continue from the learned table: replay must begin from the initial Q values.
  a.candidate=nil;a.adopted=model
  local nextModel=assert(a:trainQAsync(6789));local nextTrace=a.qTrainingReport
  assert(nextTrace.initialModel and nextTrace.initialModel.updates==model.updates and T.validate(nextTrace,nextModel))
  assert(store:saveAsync(nextModel,model,nextTrace));assert(#D.DB:query('SELECT * FROM lsd.Game0TrainingRuns')==2)
  require('Data.Config'):loadAsync()
  local panel=assert(require('Academy.Companion').openAsync('ninilite',a.world))
  assert(panel.view.detail.text:find('最近补练：新增 '..nextTrace.newUpdates..' 步',1,true))
  assert(panel.view.detail.text:find('第3轮',1,true))
  panel.view.closeButton:emit('Tapped');assert(panel.phase=='closed')
  r.companionReadback=true
  r.firstSteps=model.updates;r.resumedSteps=nextTrace.newUpdates;r.replayMatches=true;r.atomicBothDirections=true;r.reconnect=true;r.idempotentTrace=true
  assert(D.DB:exec('DETACH DATABASE lsd')>=0)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and why or nil;save()
end)
