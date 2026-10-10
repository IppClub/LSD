local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-restraint-review-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-restraint-trials-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-restraint%-trials%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-restraint-review-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local history=assert(require('Training.ResourceC45Trials').history('ninilite'));assert(#history==2)
  local basic,candidate;for _,record in ipairs(history)do if record.controller=='basic'then basic=record else candidate=record end end
  r.comparison=assert(require('Training.ResourceC45Comparison').build(basic,candidate))
  assert(not r.comparison.adoptionEligible)
  local altered=D.json.decode(D.json.encode(candidate,false,true),32);altered.setup.supportGold=1
  assert(not require('Training.ResourceC45Comparison').build(basic,altered),'Different setup compared')
  r.text=require('Training.ResourceC45Comparison').text(r.comparison)
  r.checks={'reopen and source rebuild','same candidate and setup and budget required','different setup refused','no automatic adoption'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
