-- Cold native continuation of the actual earned recovery/withdrawal checkpoint.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/low-resource-opening-hud-resume-result.json';local r={status='RUNNING',osInput=false,naturalVictory=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT')))),32)
  assert(prior.status=='PASS'and prior.returned and prior.insufficientRejected and prior.recoveryIncome==124)
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/low%-resource%-opening%-hud%-%d+%.db$'))
  local db=D.Content.writablePath..'/low-resource-opening-hud-resume-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  r.database=db;r.source=prior.database
  local function snapshot()
   local names=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' ORDER BY name");local result={}
   for _,row in ipairs(names)do result[row[1]]=D.DB:query('SELECT * FROM lsd."'..row[1]..'" ORDER BY rowid')end
   return D.json.encode(result,false,true),#names
  end
  local before,count=snapshot()
  require('Start');local stop=D.App.runningTime+30
  while not(D.Platformer.Data.store.world and D.Platformer.Data.store.world.tag=='PreparationRoom')do assert(D.App.runningTime<stop,'Cold Start stalled');D.sleep(.02)end
  local E=require('Economy.Store');assert(E.open()and not E.active());assert(E.wallet().available==prior.balanceAfter and prior.balanceAfter==232)
  local recovery=require('Economy.Recovery').load();assert(recovery.round==3 and recovery.stage==0 and recovery.balance==232 and recovery.eligible)
  local after,n=snapshot();assert(before==after and count==n,'Cold load changed saved tables')
  r.balanceAfter=E.wallet().available;r.recovery=recovery;r.tablesUnchanged=count;r.room=D.Platformer.Data.store.world.tag
  r.scope='New native process, isolated copy of actual recovery/withdrawal save, original Start and economy/recovery load; all SQL tables unchanged, no additional reward or mission; not OS or victory acceptance'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
