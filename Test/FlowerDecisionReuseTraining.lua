local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-decision-reuse-training-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-adoption-store-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-adoption%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-decision-reuse-training-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local Q=require('Training.FlowerQ');local equal=require('Training.FlowerIdentity').equal
  local old=assert(Store.loadAsync());assert(old.models.ninilite.featureSchemaVersion==6)
  local archive=assert(require('Training.FlowerQAdoptionStore').inspectAsync());r.oldArchiveReadable=archive.id
  local run=require('Training.FlowerQSession').runAsync({mode='explore',profile='near',models=old.source.baseModels,initial=old.models,seed=73219,epsilon=.55,onProgress=function(b)r.seconds=D.App.runningTime-b.started;save()end})
  assert(run.models,run.learningError);assert(run.setup.qFeatureVersion==7 and run.models.ninilite.featureSchemaVersion==7 and run.models.wuyun.featureSchemaVersion==7)
  local rebuilt,why=Q.learn(run.trace,run.episode,run.status,old.models,7);assert(rebuilt,why);assert(equal(rebuilt,run.models))
  local yes,why,id=Store.saveRunAsync(run,old.id);assert(yes,why);local current=assert(Store.loadAsync());assert(current.id==id and equal(current.models,run.models))
  assert(equal(assert(Store.loadVersionAsync(old.id)).models,old.models));r.parentPreserved=true;r.savedAndRebuilt=true;r.current=id;r.naturalStatus=run.status
  local state=run.trace.actors.ninilite.steps[1].state
  local a=D.json.decode(D.json.encode(state),32);a.spatial.ally={actor='mentor',dx=80,dy=0,distance=80}
  local b=D.json.decode(D.json.encode(state),32);b.spatial.ally={actor='mentor',dx=500,dy=0,distance=500}
  assert(Q.key(a,6)==Q.key(b,6)and Q.key(a,7)~=Q.key(b,7));r.spacingSeparatesKeys=true
  for _,actor in ipairs({'ninilite','wuyun'})do
   local q=assert(Q.restore(current.models[actor],actor));assert(equal(q:snapshot(),current.models[actor]))
  end
  local altered=D.json.decode(D.json.encode(current.models.ninilite),32);altered.featureSchemaVersion=6;assert(not Q.restore(altered));r.keyVersionTamperingRejected=true
  local missing=D.json.decode(D.json.encode(state),32);missing.spatial=nil;assert(not Q.key(missing,7));r.missingEvidenceRejected=true
  local review=assert(require('Training.FlowerQAssessment').captureAsync(old.source.baseModels));assert(review.qFeatureVersion==7 and not review.assessment.readyForDecision and review.assessment.review.total==0)
  assert(require('Training.FlowerQAdoptionStore').inspectAsync().id==archive.id);r.noImplicitAdoption=true
  r.updates={ninilite=current.models.ninilite.updates,wuyun=current.models.wuyun.updates}
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
