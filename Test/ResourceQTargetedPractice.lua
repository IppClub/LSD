local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-q-targeted-practice-result.json';local r={status='RUNNING',trials={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local previous=D.json.decode(D.Content:load(root..'/Test/resource-q-supplied-trials-result.json'),32)
  assert(previous.status=='PASS'and previous.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-q%-supplied%-trials%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-q-targeted-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(previous.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.ResourceQStore');local Practices=require('Training.ResourcePracticeStore');local Trials=require('Training.ResourceQTrials');local equal=require('Training.FlowerIdentity').equal
  local old=assert(Store.loadLatestAsync());local oldSource=assert(Practices.loadLatestAsync());local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  local loadout={{actor='mentor',item='kinetic',quantity=60},{actor='ninilite',item='emp',quantity=30},{actor='wuyun',item='emp',quantity=6},{actor='wuyun',item='blade',quantity=60}}
  local run=require('Training.FlowerQSession').runAsync({mode='explore',seed=1702,epsilon=.65,models=old.bundle.baseModels,initial=old.models,profile='exposed',virtualSupplies=loadout})
  assert(run.models,run.learningError);assert(Practices.saveRunAsync(run));local candidate=assert(Store.trainAsync());assert(candidate.depth==old.depth+1 and candidate.id~=old.id)
  assert(require('Training.ResourceQ').equivalentModels(candidate.models,run.models));assert(equal(Store.loadVersionAsync(old.id).models,old.models))
  r.practice={status=run.status,cost=run.episode.resources.spent,seconds=run.report.seconds,seed=1702,epsilon=.65};r.candidate=candidate.id;r.depth=candidate.depth;save()
  for _,mode in ipairs({'basic','evaluate'})do
   local trial=require('Training.FlowerQSession').runAsync({mode=mode,models=old.bundle.baseModels,initial=mode=='evaluate'and candidate.models or nil,profile='exposed',virtualSupplies=loadout})
   local yes,why,diagnostic=Trials.saveAsync(trial,candidate.id);assert(yes,tostring(why)..':'..tostring(diagnostic))
   assert(equal(Store.loadLatestAsync().models,candidate.models))
   r.trials[#r.trials+1]={mode=mode,status=trial.status,cost=trial.episode.resources.spent,seconds=trial.report.seconds,outcome=trial.episode.outcome,decisions=trial.decisions};save()
  end
  local entries=assert(Trials.loadAsync(candidate.id));assert(#entries==2)
  local groups=require('Training.ResourceQReview').build(entries);assert(#groups==1);r.review=require('Training.ResourceQReview').text(groups[1]);r.facts=groups[1].evaluate
  assert(#Trials.loadAsync(old.id)==2);assert(equal(Store.loadVersionAsync(old.id).models,old.models))
  assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
  r.oldPreserved=true;r.walletUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
