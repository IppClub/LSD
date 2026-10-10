local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-policy-store-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-demonstration-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-demo%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-policy-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local Store=require('Training.DisarmPolicyStore');local Policy=require('Training.DisarmPolicy');local Archive=require('Training.DisarmStore')
  local ni=assert(Store.loadLatestAsync('ninilite'));local wu=assert(Store.loadLatestAsync('wuyun'));assert(ni.id~=wu.id);r.coldRead=true
  local records={};for _,id in ipairs(assert(Archive.listAsync()))do records[#records+1]=assert(Archive.loadAsync(id))end
  local data=assert(Policy.inspect(records,'ninilite'));assert(#data.samples==ni.model.sampleCount)
  local normal={};for _,row in ipairs(records)do if not row.source.trace.demonstrator then normal[#normal+1]=row end end;assert(#assert(Policy.inspect(normal,'ninilite')).samples==0)
  local source;for _,row in ipairs(records)do if row.source.trace.demonstrator=='ninilite'then source=row;break end end
  assert(source);local yes,why=Policy.inspect({source,source},'ninilite');assert(not yes and why=='DUPLICATE_SOURCE')
  local changed=D.json.decode(D.json.encode(source),32);changed.source.trace.demonstrator='wuyun';assert(#assert(Policy.inspect({changed},'ninilite')).samples==0)
  assert(not Policy.validate(ni.model,'wuyun'));assert(not Policy.inspect(records,'fox'))
  local decision,reason=Policy.predict(ni.model,source.source.trace.executions[1].before,function()return false end);assert(not decision and reason=='ACTION_UNAVAILABLE');r.sourceIsolation=true;r.legality=true
  assert(D.DB:exec("CREATE TRIGGER lsd.RejectDisarmCandidate BEFORE INSERT ON Game0DisarmCandidates BEGIN SELECT RAISE(ABORT,'candidate fault'); END")>=0)
  local candidate,why=Store.learnAsync('ninilite');assert(not candidate and why=='WRITE_FAILED',why);assert(D.DB:exec('DROP TRIGGER lsd.RejectDisarmCandidate')>=0);assert(Store.loadLatestAsync('ninilite').id==ni.id);r.failedWritePreserved=true
  local row=D.DB:query('SELECT payload FROM lsd.Game0DisarmCandidates WHERE id=?',{ni.id})[1][1];local tampered=D.json.decode(row,32)
  local rule=tampered.model.rules[1];rule.action=rule.action=='idle'and'fmove'or'idle'
  assert(D.DB:exec('UPDATE lsd.Game0DisarmCandidates SET payload=? WHERE id=?',{D.json.encode(tampered),ni.id})>=0)
  local altered,why=Store.loadLatestAsync('ninilite');assert(not altered and why=='SOURCE_MODEL_MISMATCH',why)
  assert(D.DB:exec('UPDATE lsd.Game0DisarmCandidates SET payload=? WHERE id=?',{row,ni.id})>=0);r.ruleTamperRejected=true
  assert(D.DB:exec('DELETE FROM lsd.Game0DisarmObservations')>=0);assert(Store.loadLatestAsync('ninilite').id==ni.id and Store.loadLatestAsync('wuyun').id==wu.id);r.sourceArchiveIndependent=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
