local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/flower-reaction-migration-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-adoption-store-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-adoption%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-reaction-migration-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  require('Data.Config'):loadAsync()
  local S=require('Training.FlowerQAdoptionStore');local A=require('Training.FlowerQAssessment');local T=require('Training.FlowerQTrials')
  local old,why=S.inspectAsync();assert(old,why);r.historicalReadable=old.id
  local active,why=S.loadAsync(old.bundle.models);assert(not active and why=='ENCOUNTER_CHANGED');r.oldDeploymentBlocked=true
  local accepted,why=S.adoptAsync(old.bundle,{accepted=true,assessment=old.assessment},old.bundle.models,old.id)
  assert(not accepted and why=='ENCOUNTER_CHANGED'and S.currentId()==old.id);r.oldAdoptionBlocked=true
  local saved=assert(require('Training.FlowerQStore').loadAsync());local rows=assert(T.loadAsync(saved.id))
  local historical=require('Training.FlowerQReview').build(saved.id,rows);assert(historical.total==#rows)
  local bundle,why=A.captureAsync(saved.source.baseModels);assert(bundle,why)
  assert(not bundle.assessment.readyForDecision and bundle.assessment.review.total==0 and bundle.assessment.review.excluded==#rows);r.oldTrials=#rows
  local run=require('Training.FlowerQSession').runAsync({mode='evaluate',profile='near',models=saved.source.baseModels,initial=saved.models})
  assert(run.setup.hitReaction==2 and run.episode.versions.hitReaction==2)
  assert(run.episode.versions.spatial==2 and run.episode.movement and #run.episode.movement>0,'Missing forced motion ledger')
  local Spatial=require('Combat.Spatial');local beforeEvents=#run.episode.movement
  for _,event in ipairs(run.episode.movement)do assert(Spatial.eventValid(event))end
  local hullUseful=false;local firearmCount=0
  for _,step in ipairs(run.episode.steps)do
   assert(Spatial.validate(step.observation.spatial),'Missing decision positions')
   local spatial=step.observation.spatial
   if spatial.bossHull and spatial.bossHull.distance<spatial.boss.distance-100 then hullUseful=true end
   if spatial.firearm then firearmCount=firearmCount+1;assert(spatial.firearm.travel==2400 and spatial.firearm.withinTravel==(spatial.firearm.hullDistance<=2400))end
   assert(step.action.origin~='forced' ,'Forced movement mislabeled as a decision')
   if step.nextObservation then assert(Spatial.validate(step.nextObservation.spatial))end
  end
  assert(hullUseful and firearmCount>0,'Missing actual boss hull/range observations');r.hullDiffersFromCenter=true;r.firearmObservations=firearmCount
  r.spatialDecisions=#run.episode.steps;r.forcedEvents=beforeEvents
  local yes,why=T.saveAsync(run,saved.id);assert(yes,why);r.naturalStatus=run.status
  bundle,why=A.captureAsync(saved.source.baseModels);assert(bundle,why)
  assert(bundle.assessment.review.total==1 and bundle.assessment.review.excluded==#rows and not bundle.assessment.readyForDecision)
  assert(bundle.assessment.review.profiles.near.evaluate.count==1);r.currentOnly=true
  local changed=D.json.decode(D.json.encode(run,false,true),32);changed.candidate=saved.id;changed.setup.hitReaction=nil
  assert(not T.validateRecordAsync(changed),'Relabeled current journal as legacy');r.versionTamperingRejected=true
  assert(S.inspectAsync().id==old.id);assert(S.rollbackAsync(old.id));assert(S.currentId()==old.parent)
  assert(#D.DB:query('SELECT id FROM lsd.Game0FlowerQAdoptions')>=2);r.rollbackHistoryPreserved=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
