local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-comparison-store-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-wuyun-comparison-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-comparison%-ui%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-comparison-store-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local Store=require('Training.DisarmComparisonStore');local equal=require('Training.FlowerIdentity').equal
  local rows=assert(D.DB:query('SELECT id,payload FROM lsd.Game0DisarmComparisons ORDER BY id'));assert(#rows==2)
  local first=D.json.decode(rows[1][2],32);local second=D.json.decode(rows[2][2],32)
  assert(equal(first.setup,second.setup),'Repeated runs changed frozen setup')
  local seen={};for _,record in ipairs({first,second})do
   local review=assert(require('Training.DisarmCompare').review(record));assert(equal(review,record.review),'Cold review differs from original')
   for _,run in ipairs(record.runs)do local id=run.trace.resources.attempt;assert(not seen[id],'Repeated observation identity');seen[id]=true end
  end
  r.coldRead=true;r.distinctEpisodes=12
  local latest=assert(Store.loadLatest());assert(latest.id==rows[2][1]);assert(Store.saveAsync(latest.record)==latest.id)
  assert(D.DB:exec('DELETE FROM lsd.Game0DisarmComparisons WHERE id=?',{latest.id})==1)
  assert(D.DB:exec("CREATE TRIGGER lsd.reject_comparison BEFORE INSERT ON Game0DisarmComparisons BEGIN SELECT RAISE(ABORT,'test write failure'); END")>=0)
  local id,why=Store.saveAsync(latest.record);assert(not id and why=='WRITE_FAILED');assert(Store.loadLatest().id==rows[1][1]);r.failedWritePreservesPrevious=true
  assert(D.DB:exec('DROP TRIGGER lsd.reject_comparison')>=0);id=assert(Store.saveAsync(latest.record));assert(Store.saveAsync(latest.record)==id);r.retryIdempotent=true
  local payload=assert(D.DB:query('SELECT payload FROM lsd.Game0DisarmComparisons WHERE id=?',{id}))[1][1]
  local broken=D.json.decode(payload,32);broken.runs[1].seconds=999
  assert(D.DB:exec('UPDATE lsd.Game0DisarmComparisons SET payload=? WHERE id=?',{D.json.encode(broken,false,true),id})==1)
  local invalid,reason=Store.loadLatest();assert(not invalid and reason=='TIME_MISMATCH');r.corruptionRejected=true
  assert(D.DB:exec('UPDATE lsd.Game0DisarmComparisons SET payload=? WHERE id=?',{payload,id})==1)
  assert(Store.loadLatest().id==id)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
