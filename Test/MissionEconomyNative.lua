local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/mission-economy-native-result.json'
local r={status='RUNNING'};D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local path=D.Content.writablePath..'/mission-economy-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(path));assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0);r.database=path
  local Service=require('Mission.Service');local service=assert(Service.open());local S=require('Economy.Store')
  local model={schemaVersion=1,featureSchemaVersion=1,actionSetVersion=1,characterId='ninilite',actions={'laser'},sampleCount=7,trainingAccuracy=1,rules={{conditions={},action='laser'}}}
  local formation={mentor=true,learner='ninilite'}
  -- Legacy callers complete normally and do not create a wallet or incur charges.
  local old=assert(service:beginAsync('c0-m01',model,formation));assert(service:finishAsync(old,'failed',{}))
  assert(#D.DB:query("SELECT name FROM lsd.sqlite_master WHERE name='Game0SupplyWallet'")==0)
  local supplies={loadout={{actor='mentor',item='kinetic',quantity=50}},reward=100}
  assert(S.open())
  assert(D.DB:exec("CREATE TRIGGER lsd.RejectMissionStart BEFORE INSERT ON Game0MissionAttempts BEGIN SELECT RAISE(ABORT,'start fault'); END")>=0)
  assert(not service:beginAsync('c0-m01',model,formation,supplies));assert(S.wallet().available==300);assert(not S.active())
  assert(D.DB:query('SELECT serial FROM lsd.Game0MissionMeta')[1][1]==1)
  assert(D.DB:exec('DROP TRIGGER lsd.RejectMissionStart')>=0)
  local a=assert(service:beginAsync('c0-m01',model,formation,supplies));local id='mission:'..a.id;assert(a.supplyAttempt==id)
  assert(S.wallet().available==198)
  assert(S.consumeAsync(id,{{id='shot1',owner='mentor',item='kinetic',count=3,performer='mentor'}}))
  assert(not S.settleAsync(id,'won')) -- Cannot finish wallet separately from mission facts.
  assert(D.DB:exec("CREATE TRIGGER lsd.RejectUnlock BEFORE INSERT ON Game0MissionUnlocks BEGIN SELECT RAISE(ABORT,'unlock fault'); END")>=0)
  local report={reason='QA only'};assert(not service:finishAsync(a,'won',report))
  assert(not report.economy and S.wallet().available==198 and S.load(id).status=='active' and service:summary().last.status=='active')
  assert(D.DB:exec('DROP TRIGGER lsd.RejectUnlock')>=0)
  assert(service:finishAsync(a,'won',report));assert(report.economy.net==92 and S.wallet().available==392)
  assert(service:finishAsync(a,'won',{}));assert(S.wallet().available==392 and #D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')==1)
  local saved=D.json.decode(service:summary().last.report,32);assert(saved.economy.net==92)
  local b=assert(service:beginAsync('c0-m01',model,formation,supplies));assert(S.consumeAsync('mission:'..b.id,{{id='shot2',owner='mentor',item='kinetic',count=5,performer='enemy'}}))
  assert(D.DB:exec('DETACH DATABASE lsd')>=0);assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0)
  service=assert(Service.open());assert(service:recoverAsync());assert(service:summary().last.status=='aborted' and S.wallet().available==380)
  assert(service:recoverAsync());assert(S.wallet().available==380)
  r.available=380;r.checks={'legacy free path','atomic start rollback','atomic reward rollback','persisted settlement report','idempotent reward','joint recovery'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
