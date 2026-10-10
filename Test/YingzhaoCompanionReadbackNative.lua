local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-companion-readback-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-companion-observations-20261006/result.json'),32)
  assert(prior.saved and prior.error:find('Companion decisions did not round-trip',1,true))
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-mixed%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/companion-readback-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local store=require('Training.YingzhaoComparisonStore');local report=assert(store.load(prior.saved));local equal=require('Training.FlowerIdentity').equal
  assert(equal(report,prior.report),'Canonical persisted report differs')
  for _,round in ipairs(report.rounds)do assert(#round.companionDecisions>0)end
  local text=require('Training.YingzhaoComparison').text(report);assert(text:find('中的队友乌云：',1,true))
  local copy=D.json.decode(D.json.encode(report),32);copy.rounds[1].companionDecisions[1].observation.health='invalid';assert(not store.validate(copy))
  copy=D.json.decode(D.json.encode(report),32);for _,round in ipairs(copy.rounds)do round.companionDecisions=nil end;assert(store.validate(copy))
  r.report=report;r.saved=prior.saved;r.companionReadback=true;r.legacyReportCompatible=true;r.invalidObservationRejected=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
