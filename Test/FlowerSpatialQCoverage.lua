-- QA-only full-profile training followed by independent, frozen-policy comparisons.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-spatial-q-coverage-result.json';local r={status='RUNNING',training={},evaluation={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-spatial-q-coverage-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local Trials=require('Training.FlowerQTrials');local Session=require('Training.FlowerQSession');local equal=require('Training.FlowerIdentity').equal
  local original=assert(Store.loadAsync());local adopted=require('Training.FlowerQAdoptionStore').currentId();r.initial=original.id
  local profiles={'near','far','reproduction','field'}
  local function progress(b)r.seconds=D.App.runningTime-b.started;save()end
  for i,profile in ipairs(profiles)do
   local current=assert(Store.loadAsync());r.phase='training';r.profile=profile;save()
   local run=Session.runAsync({mode='explore',profile=profile,models=current.source.baseModels,initial=current.models,seed=91273+i*137,epsilon=.45,onProgress=progress})
   assert(run.models,run.learningError);assert(run.setup.qFeatureVersion==7)
   local yes,why,id=Store.saveRunAsync(run,current.id);assert(yes,why)
   local rebuilt=assert(Store.loadAsync());assert(rebuilt.id==id and equal(rebuilt.models,run.models))
   r.training[#r.training+1]={profile=profile,status=run.status,candidate=id,updates={ninilite=run.models.ninilite.updates,wuyun=run.models.wuyun.updates}};save()
  end
  local frozen=assert(Store.loadAsync());r.candidate=frozen.id
  for _,profile in ipairs(profiles)do
   for _,mode in ipairs({'basic','evaluate'})do
    r.phase=mode;r.profile=profile;save()
    local run=Session.runAsync({mode=mode,profile=profile,models=frozen.source.baseModels,initial=mode=='evaluate'and frozen.models or nil,onProgress=progress})
    assert(run.setup.qFeatureVersion==7 and run.epsilon==0)
    if mode=='evaluate'then assert(equal(run.models,frozen.models))end
    local yes,why=Trials.saveAsync(run,frozen.id);assert(yes,why)
    r.evaluation[#r.evaluation+1]={profile=profile,mode=mode,status=run.status,seconds=run.report.seconds,decisions=run.decisions};save()
   end
  end
  local records=assert(Trials.loadAsync(frozen.id));assert(#records==8)
  local bundle=assert(require('Training.FlowerQAssessment').captureAsync(frozen.source.baseModels));assert(bundle.assessment.review.completed==4 and bundle.assessment.review.total==8)
  assert(Store.loadAsync().id==frozen.id and require('Training.FlowerQAdoptionStore').currentId()==adopted)
  assert(equal(Store.loadVersionAsync(original.id).models,original.models))
  r.assessment=bundle.assessment;r.noImplicitAdoption=true;r.frozenEvaluations=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;r.phase='finished';save()
end)
