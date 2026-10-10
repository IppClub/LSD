local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-spatial-q-evaluation-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-spatial-q-evaluation-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync());assert(saved.models.ninilite.featureSchemaVersion==7)
  local run=require('Training.FlowerQSession').runAsync({mode='evaluate',profile='near',models=saved.source.baseModels,initial=saved.models,onProgress=function(b)r.seconds=D.App.runningTime-b.started;save()end})
  assert(run.setup.qFeatureVersion==7 and run.epsilon==0 and require('Training.FlowerIdentity').equal(run.models,saved.models))
  local Trials=require('Training.FlowerQTrials');local yes,why=Trials.saveAsync(run,saved.id);assert(yes,why)
  local rows=assert(Trials.loadAsync(saved.id));assert(#rows==1 and rows[1].setup.qFeatureVersion==7)
  local assessment=assert(require('Training.FlowerQAssessment').captureAsync(saved.source.baseModels))
  assert(assessment.qFeatureVersion==7 and assessment.assessment.review.total==1 and not assessment.assessment.readyForDecision)
  assert(Store.loadAsync().id==saved.id);r.noModelUpdate=true;r.naturalStatus=run.status;r.decisions=run.decisions;r.savedAndReviewed=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
