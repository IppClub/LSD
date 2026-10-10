-- Reproduce the captured real failed report boundary without editing the source save.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-report-size-recovery-result.json'
local r={status='RUNNING',osInput=false,regressionOnly=true};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT')))),32)
  assert(prior.status=='FAIL'and prior.operationVariant=='visible-midrange-interior-team-cover-public-route-v12'and prior.error:find('STORE_ERROR',1,true))
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-boss%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-report-size-recovery-'..os.time()..'.db';r.database=db;r.source=prior.database
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local S=assert(require('Mission.Service').open());local E=require('Economy.Store');assert(E.open());local ledger=assert(E.active());assert(ledger.attempt=='mission:8')
  local before=E.wallet();local beforeLedger=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0SupplyAttempts ORDER BY id'),false,true);local beforeMissions=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),false,true)
  local economy=assert(require('Economy.Ledger').settle(D.json.decode(D.json.encode(ledger,false,true),32),'failed'))
  local report=prior.battle;r.beforeReportBytes=#D.json.encode(report,false,true);local extended=D.json.decode(D.json.encode(report,false,true),32);extended.economy=economy;r.afterReportBytes=#D.json.encode(extended,false,true)
  local episode=prior.uncommittedEpisode;local encoded,why=require('Training.CombatStore').encode(episode);assert(encoded,why);r.episodeBytes=#encoded
  assert(r.beforeReportBytes<=65536 and r.afterReportBytes>65536,'Actual captured report did not reproduce the size boundary')
  local protected={}
  for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' ORDER BY name"))do
   local name=row[1]
   if name~='Game0MissionAttempts'and name~='Game0SupplyAttempts'and name~='Game0SupplyWallet'and name~='Game0CombatEpisodes'then
    protected[name]=D.json.encode(D.DB:query('SELECT * FROM lsd."'..name..'"'),false,true)
   end
  end
  -- Initial report fits the bound, but the actual economy append crosses it.
  local boundary=D.json.decode(D.json.encode(report,false,true),32);boundary.padding=''
  local emptyBytes=#D.json.encode(boundary,false,true);boundary.padding=string.rep('x',1048576-emptyBytes-1)
  assert(#D.json.encode(boundary,false,true)==1048575)
  local stored,reason=S:finishAsync({id=8,mission='c0-yingzhao'},'failed',boundary,episode)
  assert(not stored and reason=='INVALID_REPORT','Oversize appended report must return a specific error')
  assert(E.wallet().available==before.available and E.wallet().revision==before.revision)
  assert(beforeLedger==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0SupplyAttempts ORDER BY id'),false,true)and beforeMissions==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),false,true))
  assert(#D.DB:query('SELECT attempt FROM lsd.Game0CombatEpisodes WHERE attempt=8')==0)
  r.oversizeRejectedWithoutPartialCommit=true
  stored,reason=S:finishAsync({id=8,mission='c0-yingzhao'},'failed',report,episode);assert(stored,reason);r.finishReason=reason
  local wallet=E.wallet();assert(wallet.available==125 and wallet.available==before.available+economy.refund and economy.cost==215 and economy.income==0 and economy.refund==58)
  local rows=D.DB:query('SELECT status,report FROM lsd.Game0MissionAttempts WHERE id=8');assert(rows[1][1]=='failed')
  assert(require('Training.FlowerIdentity').equal(D.json.decode(rows[1][2],32),report),'Stored full report differs')
  local savedEpisode=D.DB:query('SELECT payload FROM lsd.Game0CombatEpisodes WHERE attempt=8');assert(savedEpisode[1][1]==encoded,'Episode must be stored in full')
  assert(E.load('mission:8').status=='failed')
  local allBefore=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0SupplyAttempts ORDER BY id'),false,true)
  stored,reason=S:finishAsync({id=8,mission='c0-yingzhao'},'failed',report,episode);assert(stored and reason=='ALREADY_COMMITTED')
  assert(wallet.available==E.wallet().available and wallet.revision==E.wallet().revision and allBefore==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0SupplyAttempts ORDER BY id'),false,true))
  for name,expected in pairs(protected)do assert(expected==D.json.encode(D.DB:query('SELECT * FROM lsd."'..name..'"'),false,true),'Protected table changed: '..name)end
  r.fullReportAndEpisodeSaved=true;r.idempotent=true;r.protectedTablesUnchanged=true;r.balanceAfter=wallet.available;r.refund=economy.refund;r.actualSpent=economy.cost

 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
