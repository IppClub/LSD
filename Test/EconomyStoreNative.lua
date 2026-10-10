local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/economy-store-native-result.json'
local r={status='RUNNING'};D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local path=D.Content.writablePath..'/economy-store-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(path))
  assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0);r.database=path
  -- A sentinel represents unrelated legacy progression and must survive migration.
  assert(D.DB:exec('CREATE TABLE lsd.LegacyProgress(value INTEGER)')>=0)
  assert(D.DB:exec('INSERT INTO lsd.LegacyProgress VALUES(73)')>=0)
  local S=require('Economy.Store');assert(S.open());assert(S.wallet().available==300)
  local loadout={{actor='mentor',item='kinetic',quantity=60},{actor='ninilite',item='emp',quantity=30}}
  local ledger=assert(S.beginAsync('first',loadout,100));assert(S.wallet().available==55)
  assert(S.beginAsync('first',loadout,100));assert(S.wallet().available==55)
  assert(not S.beginAsync('second',loadout,100));assert(not S.beginAsync('first',loadout,101))
  local shot={id='shot1',owner='mentor',item='kinetic',count=3,performer='enemy'}
  assert(S.consumeAsync('first',{shot}));assert(S.consumeAsync('first',{shot}));assert(S.load('first').spent==11)
  -- A later invalid event rolls back the whole batch, including an earlier valid one.
  assert(not S.consumeAsync('first',{{id='valid',owner='mentor',item='kinetic',count=1,performer='mentor'},{id='empty',owner='mentor',item='kinetic',count=100,performer='mentor'}}))
  assert(S.load('first').spent==11 and not S.load('first').events.valid)
  -- Database failure after wallet update must leave both wallet and ledger intact.
  assert(D.DB:exec("CREATE TRIGGER lsd.RejectSupplyWrite BEFORE UPDATE ON Game0SupplyAttempts BEGIN SELECT RAISE(ABORT,'injected write failure'); END")>=0)
  local before=S.wallet();assert(not S.settleAsync('first','won'))
  assert(S.wallet().available==before.available and S.wallet().revision==before.revision and S.load('first').status=='active')
  assert(D.DB:exec('DROP TRIGGER lsd.RejectSupplyWrite')>=0)
  local result=assert(S.settleAsync('first','won'));assert(result.net==89 and S.wallet().available==389)
  assert(S.settleAsync('first','won'));assert(S.wallet().available==389);assert(not S.settleAsync('first','failed'))
  assert(S.open());assert(S.wallet().available==389)
  assert(S.beginAsync('interrupted',loadout,100));assert(S.consumeAsync('interrupted',{shot}))
  -- Reopen the actual file and reload modules, with no live in-memory ledger.
  assert(D.DB:exec('DETACH DATABASE lsd')>=0);assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0)
  package.loaded['Economy.Store']=nil;S=require('Economy.Store');assert(S.open());assert(S.active().spent==11)
  assert(S.load('first').result.lines[1].usedByOthers==3 and S.load('first').result.lines[1].cost==8)
  local recovery=assert(S.recoverAsync());assert(recovery.status=='aborted' and recovery.cost==11 and S.wallet().available==378)
  assert(S.recoverAsync());assert(S.wallet().available==378)
  assert(S.beginAsync('loss',loadout,100));assert(S.consumeAsync('loss',{{id='all1',owner='mentor',item='kinetic',count=60,performer='mentor'},{id='all2',owner='ninilite',item='emp',count=30,performer='ninilite'}}))
  result=assert(S.settleAsync('loss','won'));assert(result.net==-145 and S.wallet().available==233)
  local denied,why=S.beginAsync('poor',loadout,100);assert(not denied and why=='INSUFFICIENT_SUPPLIES')
  assert(D.DB:query('SELECT value FROM lsd.LegacyProgress')[1][1]==73)
  r.available=S.wallet().available;r.checks={'one-time migration','reservation','single active attempt','event replay','batch rollback','SQL failure rollback','settlement replay','database reopen recovery','negative victory','insufficient budget','legacy preservation'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
