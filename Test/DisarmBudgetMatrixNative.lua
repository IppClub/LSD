local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-budget-matrix-result.json';local r={status='RUNNING',groups={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-melee-teaching-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-melee%-teaching%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-budget-matrix-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0DisarmCandidates'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=snapshot();local models=assert(require('Training.FlowerPractice').models())
  local _,defaults=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true})
  local function lean(emp)return {{actor='mentor',item='kinetic',quantity=12},{actor='ninilite',item='emp',quantity=12},{actor='wuyun',item='emp',quantity=emp},{actor='wuyun',item='blade',quantity=16}}end
  local configs={{name='default-repeat',loadout=defaults},{name='lean-first',loadout=lean(6)},{name='lean-repeat',loadout=lean(6)},{name='low-emp',loadout=lean(3)}}
  local candidate=assert(require('Training.DisarmPolicyStore').loadLatestAsync('wuyun'));assert(candidate.id==prior.actors.wuyun.candidate);r.candidate=candidate.id
  local previousIds={}
  for _,config in ipairs(configs)do
   r.group=config.name;r.budget=assert(require('Economy.Ledger').quote(config.loadout)).total;save()
   local Compare=require('Training.DisarmCompare');local record,why=Compare.runAsync(candidate,models,config.loadout,{onBattle=function(_,index)r.currentRun=index;save()end})
   assert(record and not why,why);local review=assert(Compare.review(record));assert(not review.adoptionEligible)
   for _,run in ipairs(record.runs)do local id=run.trace.resources.attempt;assert(not previousIds[id]);previousIds[id]=true end
   local Store=require('Training.DisarmComparisonStore');local id,why=Store.saveAsync(record);assert(id,why);assert(Store.load(id))
   r.groups[#r.groups+1]={name=config.name,budget=r.budget,review=review,archive=id};assert(snapshot()==before);save()
  end
  r.originalProgressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
