local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-compare-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-demonstration-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-demo%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-compare-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function saved()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0DisarmCandidates')},false,true)end
  local before=saved();local models=assert(require('Training.FlowerPractice').models());local candidate=assert(require('Training.DisarmPolicyStore').loadLatestAsync('ninilite'))
  local _,loadout=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true})
  local Compare=require('Training.DisarmCompare');local record,why=Compare.runAsync(candidate,models,loadout,{onBattle=function(_,index)r.currentRun=index;D.Content:save(out,D.json.encode(r,false,true))end})
  assert(record and not why,why);assert(#record.runs==6);local review=assert(Compare.review(record));assert(not review.adoptionEligible)
  local Store=require('Training.DisarmComparisonStore');local id,why=Store.saveAsync(record);assert(id,why);assert(Store.saveAsync(record)==id);local loaded=assert(Store.loadLatest());assert(loaded.id==id and require('Training.FlowerIdentity').equal(loaded.review,D.json.decode(D.json.encode(review),32)))
  local copy=D.json.decode(D.json.encode(record),32);copy.runs[2].trace.comparisonSetup.mentor='human';assert(not Compare.review(copy))
  copy=D.json.decode(D.json.encode(record),32);copy.runs[2].seconds=999;assert(not Compare.review(copy))
  assert(saved()==before);r.review=review;r.archive=id;r.recordsUnchanged=true;r.record=record
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
