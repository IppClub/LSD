local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-trials-reload-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/resource-q-frozen-trials/result.json'),32)
  assert(prior.status=='PASS' and prior.database:match('^/private/tmp/lsd%-combat%-qa%-[%w]+/save/resource%-q%-trials%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-reload-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local T=require('Training.ResourceQTrials');local records,why,detail=T.loadAsync(1);assert(records,tostring(why)..tostring(detail));assert(#records==2)
  local row=D.DB:query('SELECT id,payload FROM lsd.Game0ResourceQTrials ORDER BY id DESC LIMIT 1')[1]
  local corrupt=D.json.decode(row[2],32);local changed=false
  for _,step in ipairs(corrupt.trace.actors.ninilite.steps)do if step.decisionSource.available then step.decisionSource.available.laser=not step.decisionSource.available.laser;changed=true;break end end
  assert(changed);assert(D.DB:exec('UPDATE lsd.Game0ResourceQTrials SET payload=? WHERE id=?',{D.json.encode(corrupt,false,true),row[1]})>=0);assert(not T.loadAsync(1))
  assert(D.DB:exec('UPDATE lsd.Game0ResourceQTrials SET payload=? WHERE id=?',{row[2],row[1]})>=0);assert(#assert(T.loadAsync(1))==2)
  r.facts={records[1].facts,records[2].facts};r.checks={'cold reload','resource source reconstruction','frozen choice replay','forged fallback mask rejected'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
