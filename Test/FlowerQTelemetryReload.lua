local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-telemetry-reload-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-telemetry-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-telemetry%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-telemetry-reload-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  local Trials=require('Training.FlowerQTrials');local records,why,detail=Trials.loadAsync(2);assert(records,tostring(why)..':'..tostring(detail));assert(#records==11);local record=records[1];local t=record.telemetry;assert(t.actors.ninilite.total==20 and t.actors.wuyun.total==23);r.coldVerified=true
  local raw=D.DB:query('SELECT payload FROM lsd.Game0FlowerQTrials WHERE id=?',{record.id})[1][1]
  local function tamper(fn)
   local altered=D.json.decode(raw,32);fn(altered);assert(D.DB:exec('UPDATE lsd.Game0FlowerQTrials SET payload=? WHERE id=?',{D.json.encode(altered,false,true),record.id})>=0)
   local rows,why=Trials.loadAsync(2);assert(not rows and why=='INVALID_Q_TRIAL')
   assert(D.DB:exec('UPDATE lsd.Game0FlowerQTrials SET payload=? WHERE id=?',{raw,record.id})>=0)
  end
  tamper(function(a)a.trace.timing.finished=a.trace.timing.finished+1 end)
  tamper(function(a)a.trace.actors.ninilite.steps[1].decisionSource=nil end)
  tamper(function(a)for _,step in ipairs(a.trace.actors.ninilite.steps)do if step.decisionSource.state then step.decisionSource.state={};return end end;error('No fallback witness')end)
  r.tamperRejected=true
  assert(#assert(Trials.loadAsync(2))==11);local yes,why=Trials.saveAsync(record,2);assert(yes and why=='ALREADY_SAVED');r.idempotent=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
