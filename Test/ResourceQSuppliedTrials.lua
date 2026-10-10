local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-q-supplied-trials-result.json';local r={status='RUNNING',trials={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-q-supplied-trials-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local recent=D.json.decode(D.Content:load(root..'/Test/resource-exploration-result.json'),32);assert(recent.status=='PASS'and recent.trainingGoal=='resource-clear-v1')
  local source=D.json.decode(D.Content:load(root..'/Test/resource-exploration-source.json'),32);assert(require('Training.ResourcePracticeStore').saveRunAsync(source))
  local Store=require('Training.ResourceQStore');local candidate=assert(Store.trainAsync());local Trials=require('Training.ResourceQTrials');local equal=require('Training.FlowerIdentity').equal
  local E=require('Economy.Store');assert(E.open());local before=E.wallet()
  local loadout={{actor='mentor',item='kinetic',quantity=60},{actor='ninilite',item='emp',quantity=30},{actor='wuyun',item='emp',quantity=6},{actor='wuyun',item='blade',quantity=60}}
  for _,mode in ipairs({'basic','evaluate'})do
   local result=require('Training.FlowerQSession').runAsync({mode=mode,models=source.baseModels,initial=mode=='evaluate'and candidate.models or nil,virtualSupplies=loadout,profile='exposed'})
   local ok,why,diagnostic=Trials.saveAsync(result,candidate.id);assert(ok,tostring(why)..':'..tostring(diagnostic))
   local count=#assert(Trials.loadAsync(candidate.id));assert(Trials.saveAsync(result,candidate.id));assert(#Trials.loadAsync(candidate.id)==count)
   assert(equal(Store.loadLatestAsync().models,candidate.models),'Trial updated candidate')
   r.trials[#r.trials+1]={mode=mode,status=result.status,cost=result.episode.resources.spent,seconds=result.report.seconds,decisions=result.decisions,outcome=result.episode.outcome,trainingGoal=result.setup.trainingGoal,stock=result.episode.resources.stock,budget=result.episode.resources.quote.total,report=result.report.evaluation}
   if mode=='evaluate'then
    assert(equal(result.models,candidate.models))
    for _,c in pairs(result.decisions)do assert(c.explored==0)end
    result.models.ninilite.updates=result.models.ninilite.updates+1;assert(not Trials.saveAsync(result,candidate.id))
   end
   save();D.sleep(.2)
  end
  assert(E.wallet().available==before.available and E.wallet().revision==before.revision)
  local groups=require('Training.ResourceQReview').build(assert(Trials.loadAsync(candidate.id)));assert(#groups==1 and groups[1].basic.count==1 and groups[1].evaluate.count==1);r.review=require('Training.ResourceQReview').text(groups[1])
  r.walletUnchanged=true;r.candidateUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
