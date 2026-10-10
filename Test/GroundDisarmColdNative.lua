local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/ground-disarm-cold-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  local db=D.Content.writablePath..'/ground-disarm-cold-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local rows=assert(D.DB:query("SELECT id,status,report FROM lsd.Game0MissionAttempts WHERE mission='c0-disarm' ORDER BY id"));assert(#rows==2)
  local Store=require('Training.CombatStore');local equal=require('Training.FlowerIdentity').equal
  for _,row in ipairs(rows)do
   local e,why=Store.load(row[1]);assert(e,why);local report=D.json.decode(row[3],32);assert(e.disarm.status==row[2]and e.resources.spent==report.economy.cost)
   local saved=assert(require('Economy.Store').find(e.episode));assert(equal(saved.events,e.resources.events)and saved.status==row[2])
  end
  r.coldReceipts=true;local e=assert(Store.load(rows[2][1]));local before=require('Economy.Store').wallet().available
  assert(before==prior.won.balance)
  assert(require('Mission.Service').open():finishAsync({id=rows[2][1],mission='c0-disarm'},'won',{},e));assert(require('Economy.Store').wallet().available==before);r.noDuplicateReward=true
  local function clone()return D.json.decode(D.json.encode(e,false,true),32)end
  local broken=clone();broken.disarm.encounter.enemyHP=1;assert(not Store.validate(broken))
  broken=clone();broken.resources.spent=broken.resources.spent+1;assert(not Store.validate(broken))
  broken=clone();broken.disarm.demonstrator='wuyun';assert(not Store.validate(broken))
  local samples,why=require('Training.DisarmPolicy').inspect({{source={trace=broken.disarm}}},'wuyun');assert(not samples and why=='INVALID_DEMONSTRATION_SOURCE');r.formalNeverDemonstration=true
  assert(#assert(require('Training.DisarmPolicy').inspect({{source={trace=e.disarm}}},'wuyun')).samples==0);r.tamperingRejected=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
