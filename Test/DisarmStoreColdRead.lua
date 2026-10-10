local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-store-cold-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-store-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-store%-%d+%.db$'))
  local dest=D.Content.writablePath..'/disarm-store-cold-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local saved=assert(require('Training.DisarmStore').loadLatestAsync())
  assert(saved.id==prior.id and saved.review.total==4 and saved.review.stolenCost==2 and saved.review.trainable==false)
  r.database=dest;r.id=saved.id;r.review=saved.review
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
