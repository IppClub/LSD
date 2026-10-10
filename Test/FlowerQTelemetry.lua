local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-telemetry-result.json';local r={status='RUNNING',matches={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-profiles-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-profiles%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-telemetry-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local Trials=require('Training.FlowerQTrials');local saved=assert(Store.loadAsync());local Session=require('Training.FlowerQSession');local Telemetry=require('Training.FlowerQTelemetry')
  local legacy=assert(Trials.loadAsync(saved.id));assert(#legacy==9);for _,row in ipairs(legacy)do assert(not row.telemetry.seconds and not row.telemetry.actors)end;r.legacyMissing=true
  for _,mode in ipairs({'basic','evaluate'})do
   r.current=mode;save()
   local run=Session.runAsync({mode=mode,profile='near',models=saved.source.baseModels,initial=mode=='evaluate' and saved.models or nil,onProgress=function(b)r.seconds=D.App.runningTime-b.started;save()end})
   local roundtrip=D.json.decode(D.json.encode(run,false,true),32);local telemetry=Telemetry.build(roundtrip);assert(math.abs(telemetry.seconds-run.report.seconds)<.1)
   if mode=='evaluate'then
    for _,id in ipairs({'ninilite','wuyun'})do local c=telemetry.actors[id];assert(c.q+c.fallback==#run.trace.actors[id].steps and c.total==run.decisions[id].accepted);assert(c.q==run.decisions[id].q and c.fallback==run.decisions[id].fallback)end
    local row=roundtrip.trace.actors.ninilite.steps[1];local original=row.decisionSource.reason;row.decisionSource.reason='EXPLORE';assert(not pcall(Telemetry.build,roundtrip));row.decisionSource.reason=original;r.reasonTamperRejected=true
    local timing=roundtrip.trace.timing.finished;roundtrip.trace.timing.finished=timing+1;assert(not pcall(Telemetry.build,roundtrip));roundtrip.trace.timing.finished=timing;r.timeTamperRejected=true
   end
   local yes,why,detail=Trials.saveAsync(roundtrip,saved.id);assert(yes,tostring(why)..':'..tostring(detail));r.matches[#r.matches+1]={mode=mode,status=run.status,telemetry=telemetry};save()
  end
  local rows=assert(Trials.loadAsync(saved.id));assert(#rows==11 and rows[1].telemetry.actors and rows[2].telemetry.seconds)
  local review=require('Training.FlowerQReview').build(saved.id,rows);assert(review.profiles.near.basic.timed==1 and review.profiles.near.evaluate.timed==1 and review.profiles.near.evaluate.sourceGames==1)
  assert(require('Training.FlowerIdentity').equal(Store.loadAsync().models,saved.models));r.candidateUnchanged=true
  local panel=require('Training.FlowerQPanel').openAsync(function()end,saved.source.baseModels);panel.reviewButton:emit('Tapped');D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-q-telemetry.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
