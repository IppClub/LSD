-- Transactional supply wallet. Gameplay activation is gated by mission integration.
local D=require('Dora')
local Ledger=require('Economy.Ledger')
local equal=require('Training.FlowerIdentity').equal
local S={};local busy=false
local function encode(v)return D.json.encode(v,false,true)end
function S.open()
 if not D.DB:existDB('lsd')then return nil,'NO_GAME_DATABASE'end
 local ok=D.DB:transaction({
  'CREATE TABLE IF NOT EXISTS lsd.Game0SupplyWallet(id INTEGER PRIMARY KEY CHECK(id=1),version INTEGER NOT NULL CHECK(version=1),available INTEGER NOT NULL CHECK(available>=0),revision INTEGER NOT NULL CHECK(revision>=0))',
  'CREATE TABLE IF NOT EXISTS lsd.Game0SupplyAttempts(id TEXT PRIMARY KEY, status TEXT NOT NULL, payload TEXT NOT NULL)',
  "CREATE UNIQUE INDEX IF NOT EXISTS lsd.Game0SupplyOneActive ON Game0SupplyAttempts(status) WHERE status='active'",
  'INSERT OR IGNORE INTO lsd.Game0SupplyWallet VALUES(1,1,300,0)'})
 if not ok then return nil,'SCHEMA_FAILED'end
 local row=D.DB:query('SELECT version FROM lsd.Game0SupplyWallet WHERE id=1')
 if not row or not row[1] or row[1][1]~=1 then return nil,'INCOMPATIBLE_SAVE'end
 return true
end
function S.wallet()
 local rows=D.DB:query('SELECT available,revision FROM lsd.Game0SupplyWallet WHERE id=1')
 if not rows or not rows[1]then return nil,'READ_FAILED'end
 return {available=rows[1][1],revision=rows[1][2]}
end
function S.load(id)
 local rows=D.DB:query('SELECT payload FROM lsd.Game0SupplyAttempts WHERE id=?',{id})
 if not rows then return nil,'READ_FAILED'end
 if not rows[1]then return nil,'NOT_RECORDED'end
 local ok,ledger=pcall(D.json.decode,rows[1][1],32)
 if not ok or type(ledger)~='table' or ledger.schemaVersion~=1 or ledger.attempt~=id then return nil,'INVALID_SAVE'end
 return ledger
end
function S.find(id)
 local rows=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name='Game0SupplyAttempts'")
 if not rows then return nil,'READ_FAILED'end
 if not rows[1]then return nil,'NOT_RECORDED'end
 return S.load(id)
end
function S.active()
 local rows=D.DB:query("SELECT id FROM lsd.Game0SupplyAttempts WHERE status='active'")
 if not rows then return nil,'READ_FAILED'end
 if not rows[1]then return nil,'NOT_RECORDED'end
 return S.load(rows[1][1])
end
local function operation(fn)
 if busy then return nil,'BUSY'end
 busy=true;local values=table.pack(xpcall(fn,debug.traceback));busy=false
 if not values[1]then return nil,'STORE_ERROR',values[2]end
 return table.unpack(values,2,values.n)
end
-- Revision CHECK forces rollback even if another writer changed the wallet.
local function commit(wallet,available,ledger,insert,extra,synchronous)
 local statements={
  {'UPDATE lsd.Game0SupplyWallet SET available=?,revision=CASE WHEN revision=? THEN revision+1 ELSE -1 END WHERE id=1',{{available,wallet.revision}}},
  insert and {'INSERT INTO lsd.Game0SupplyAttempts VALUES(?,?,?)',{{ledger.attempt,ledger.status,encode(ledger)}}}
   or {'UPDATE lsd.Game0SupplyAttempts SET status=?,payload=? WHERE id=?',{{ledger.status,encode(ledger),ledger.attempt}}}}
 for _,statement in ipairs(extra or {})do statements[#statements+1]=statement end
 local saved
 if synchronous then saved=D.DB:transaction(statements)else saved=D.DB:transactionAsync(statements)end
 if not saved then return nil,'WRITE_FAILED'end
 return ledger
end
function S.beginAsync(id,loadout,reward,extra)
 return operation(function()
  if type(id)~='string' or id==''then return nil,'INVALID_ATTEMPT'end
  local prior,why=S.load(id)
  if prior then
   if equal(prior.loadout,loadout) and prior.reward==reward then return prior,'ALREADY_RECORDED'end
   return nil,'ATTEMPT_CONFLICT'
  elseif why~='NOT_RECORDED'then return nil,why end
  local active,why=S.active();if active then return nil,'MISSION_ALREADY_ACTIVE'elseif why~='NOT_RECORDED'then return nil,why end
  local wallet,why=S.wallet();if not wallet then return nil,why end
  local ledger,why=Ledger.new(id,loadout,wallet.available,reward);if not ledger then return nil,why end
  ledger.loadout=D.json.decode(encode(loadout),32)
  return commit(wallet,wallet.available-ledger.quote.total,ledger,true,extra)
 end)
end
-- Batch completed consumption events off the frame loop. No input/hit-based charges.
-- Battle wiring must also handle unflushed events at interruption before activation.
local function consume(id,events,synchronous)
 return operation(function()
  if type(events)~='table' or #events==0 then return nil,'EMPTY_EVENTS'end
  local ledger,why=S.load(id);if not ledger then return nil,why end
  local wallet,why=S.wallet();if not wallet then return nil,why end
  local changed=false
  for _,event in ipairs(events)do
   if type(event)~='table'then return nil,'INVALID_EVENT'end
   local ok,why=Ledger.consume(ledger,event.id,event.owner,event.item,event.count,event.performer,event.step)
   if not ok then return nil,why end
   changed=changed or why~='ALREADY_RECORDED'
  end
  if not changed then return ledger,'ALREADY_RECORDED'end
  return commit(wallet,wallet.available,ledger,false,nil,synchronous)
 end)
end
function S.consumeAsync(id,events)return consume(id,events,false)end
-- Only at committed attack frames; never from per-frame update or input polling.
function S.consumeNow(id,events)return consume(id,events,true)end
function S.settleAsync(id,status,buildOperations)
 if type(id)=='string' and id:match('^mission:') and not buildOperations then return nil,'MISSION_SERVICE_REQUIRED'end
 return operation(function()
  local ledger,why=S.load(id);if not ledger then return nil,why end
  local wallet,why=S.wallet();if not wallet then return nil,why end
  local result,why=Ledger.settle(ledger,status);if not result then return nil,why end
  if why=='ALREADY_SETTLED'then return result,why end
  local extra
  if buildOperations then
   local why;extra,why=buildOperations(result)
   if not extra then return nil,why or 'INVALID_OPERATIONS'end
  end
  local saved,why=commit(wallet,wallet.available+result.refund+result.income,ledger,false,extra)
  if not saved then return nil,why end
  return result
 end)
end
-- Safe restart ends interrupted attempts; durable spent supplies remain spent.
function S.recoverAsync()
 local ledger,why=S.active()
 if not ledger then return why=='NOT_RECORDED' and true or nil,why end
 return S.settleAsync(ledger.attempt,'aborted')
end
return S
