local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local r={status='RUNNING',osInput=false,scope='Cold Start from actual current-package low-resource factory completion, unchanged full database and no duplicate recovery reward'}
 local function save()D.Content:save(root..'/Test/low-resource-factory-resume-result.json',D.json.encode(r,false,true))end;save()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-pursuit-result-low-resource-factory-20261008/result.json'),32);assert(prior.status=='PASS'and prior.stage=='factory-complete')
  local db=D.Path(D.Content.writablePath,'low-resource-factory-resume-'..os.time()..'.db');assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.source=prior.database;r.database=db
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local function state()
   local tables={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' ORDER BY name"))do tables[row[1]]=D.DB:query('SELECT * FROM lsd."'..row[1]..'" ORDER BY rowid')end
   return D.json.encode(tables,false,true)
  end
  local before=state();require('Start')
  local deadline=D.App.runningTime+35
  while not D.Platformer.Data.store.world or D.Platformer.Data.store.world.tag~='OperationRoom' do assert(D.App.runningTime<deadline,'Cold factory start did not return OperationRoom');D.sleep(.05)end
  D.sleep(.5);local E=require('Economy.Store');assert(E.open()and not E.active()and E.wallet().available==prior.balanceAfter)
  local R=require('Economy.Recovery');local recovery=assert(R.load());assert(not recovery.eligible)
  local saved,why=R.sortAsync(recovery.round,recovery.stage,R.tasks[recovery.stage+1].item);assert(not saved and why=='SUPPLIES_SUFFICIENT')
  assert(E.wallet().available==prior.balanceAfter and state()==before,'Cold start or duplicate recovery changed save')
  r.returnScene='OperationRoom';r.balance=E.wallet().available;r.recovery=recovery;r.duplicateRecoveryRejected=why;r.allTablesUnchanged=true;save()
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and tostring(err)or nil;save()
end)
