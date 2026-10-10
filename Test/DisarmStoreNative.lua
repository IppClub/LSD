local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-store-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local db=D.Content.writablePath..'/disarm-store-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  local report=D.json.decode(D.Content:load(root..'/Test/disarm-empty-resource-result.json'),32);assert(report.status=='PASS');local trace=report.trace
  local S=require('Training.DisarmStore');local accepted,why,id=S.saveAsync(trace);assert(accepted,why)
  local yes,why,again=S.saveAsync(trace);assert(yes and why=='ALREADY_RECORDED' and again==id)
  local loaded=assert(S.loadLatestAsync());assert(loaded.id==id and loaded.review.stolenCost==2 and loaded.review.total==4 and not loaded.review.trainable)
  local changed=D.json.decode(D.json.encode(trace,false,true),32);changed.finishedAt=changed.finishedAt+1
  yes,why=S.saveAsync(changed);assert(not yes and why=='SOURCE_CONFLICT')
  assert(#D.DB:query('SELECT * FROM lsd.Game0DisarmObservations')==1)
  local rows=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name IN ('Game0Training','Game0SupplyWallet')");assert(#rows==0)
  -- Corrupt only this disposable QA row and prove reads do not accept it.
  local payload=D.DB:query('SELECT payload FROM lsd.Game0DisarmObservations WHERE id=?',{id})[1][1]
  assert(D.DB:exec('UPDATE lsd.Game0DisarmObservations SET payload=? WHERE id=?',{'{invalid',id})>=0)
  loaded,why=S.loadLatestAsync();assert(not loaded and why=='INVALID_SOURCE')
  assert(D.DB:exec('UPDATE lsd.Game0DisarmObservations SET payload=? WHERE id=?',{payload,id})>=0)
  assert(S.loadLatestAsync());r.id=id;r.idempotent=true;r.conflictRejected=true;r.corruptRejected=true;r.walletAndModelsUntouched=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
