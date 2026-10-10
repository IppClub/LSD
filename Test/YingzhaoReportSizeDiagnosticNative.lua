-- Reproduce the captured real failed report boundary without editing the source save.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-report-size-diagnostic-result.json'
local r={status='RUNNING',osInput=false,diagnosticOnly=true};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT')))),32)
  assert(prior.status=='FAIL'and prior.operationVariant=='visible-midrange-interior-team-cover-public-route-v12'and prior.error:find('STORE_ERROR',1,true))
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-boss%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-report-size-diagnostic-'..os.time()..'.db';r.database=db;r.source=prior.database
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local S=assert(require('Mission.Service').open());local E=require('Economy.Store');assert(E.open());local ledger=assert(E.active());assert(ledger.attempt=='mission:8')
  local before=E.wallet();local beforeLedger=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0SupplyAttempts ORDER BY id'),false,true);local beforeMissions=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),false,true)
  local economy=assert(require('Economy.Ledger').settle(D.json.decode(D.json.encode(ledger,false,true),32),'failed'))
  local report=prior.battle;r.beforeReportBytes=#D.json.encode(report,false,true);local extended=D.json.decode(D.json.encode(report,false,true),32);extended.economy=economy;r.afterReportBytes=#D.json.encode(extended,false,true)
  local episode=prior.uncommittedEpisode;local encoded,why=require('Training.CombatStore').encode(episode);assert(encoded,why);r.episodeBytes=#encoded
  assert(r.beforeReportBytes<=65536 and r.afterReportBytes>65536,'Actual captured report did not reproduce the size boundary')
  local stored,reason=S:finishAsync({id=8,mission='c0-yingzhao'},'failed',report,episode);r.finishReason=reason;assert(not stored and reason=='STORE_ERROR','Original actual transaction did not reproduce STORE_ERROR')
  assert(E.wallet().available==before.available and E.wallet().revision==before.revision)
  assert(beforeLedger==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0SupplyAttempts ORDER BY id'),false,true)and beforeMissions==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),false,true))
  assert(#D.DB:query('SELECT attempt FROM lsd.Game0CombatEpisodes WHERE attempt=8')==0)
  r.actualCapturedReportBoundaryReproduced=true;r.noPartialCommit=true;r.reservedBalance=before.available;r.actualSpent=economy.cost
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
