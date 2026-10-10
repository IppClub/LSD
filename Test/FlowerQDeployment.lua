local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-deployment-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-adoption-store-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-adoption%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-deployment-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local S=require('Training.FlowerQAdoptionStore');local adopted=assert(S.inspectAsync());local models=adopted.bundle.models;r.adoption=adopted.id
  local bad,why=S.loadAsync({});r.fixture={qFeatureVersion=adopted.bundle.qFeatureVersion,hitReaction=adopted.bundle.hitReaction,current=require('Factory.Rules').qCurrent(adopted.bundle),loadReason=why};save();assert(not bad and why=='BASE_MODELS_CHANGED','Deployment fixture rejected before battle: '..tostring(why))
  local yes,why=require('Training.FlowerAdoptionStore').adoptAsync(nil,nil);assert(not yes and why=='Q_ADOPTION_ACTIVE')
  yes,why=require('Training.FlowerTeamAdoptionStore').adoptAsync(nil,nil);assert(not yes and why=='Q_ADOPTION_ACTIVE');r.otherAdoptionsBlocked=true
  local journey=D.Content.writablePath..'/lsd-ruins-route-qa-1791013294.db';assert(D.DB:exec("ATTACH DATABASE '"..journey.."' AS journey")>=0)
  assert(D.DB:exec("INSERT OR IGNORE INTO lsd.Game0StoryNodes SELECT * FROM journey.Game0StoryNodes WHERE id='factory-encounter'")>=0);assert(D.DB:exec('DETACH DATABASE journey')>=0)
  local service=assert(require('Mission.Service').open());local attempt,why=service:beginAsync('c0-m05',models,assert(service:formation()));assert(attempt,why)
  local loads=0;local load=S.loadAsync;S.loadAsync=function(...)loads=loads+1;return load(...)end
  local support=require('Ground.LifeSupport').new(45,'defence');support.hp={100,100,100}
  local level=require('Factory.Level').openAsync(service,attempt,support);local b=level.battle
  assert(loads==1);for _,arena in ipairs(b.learners)do assert(arena.flowerDeployment.qAdoptionId==adopted.id)end
  local trace=require('Training.FlowerDecisionTrace').attach(b);trace.decisionSourcesVersion=1
  level.start:emit('Tapped');assert(b.arena.mode=='demo' and b.wuyun.mode=='demo');local began=D.App.totalTime;local shot=false
  while b.phase=='playing' do
   assert(D.App.totalTime-began<150,'Deployment timeout');b:command('shoot');for _,state in pairs(b.effects.states)do if D.App.runningTime<(state.confusedUntil or 0)then b:command('song');break end end
   if not shot and D.App.totalTime-began>2 then D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-q-deployment.tga');shot=true end
   r.seconds=D.App.totalTime-began;save();D.sleep(.1)
  end
  local limit=D.App.totalTime+15;while not level.result and b.phase~='save-error'do assert(D.App.totalTime<limit);D.sleep(.05)end
  assert(b.phase=='won' or b.phase=='failed',b.saveError);r.naturalStatus=b.phase
  assert(loads==1);r.loads=loads
  local record=D.DB:query('SELECT status,report FROM lsd.Game0MissionAttempts WHERE id=?',{attempt.id})[1];local report=D.json.decode(record[2],32)
  local telemetry=require('Training.FlowerQTelemetry').build({mode='evaluate',trace=trace,episode=b.combatEpisode,initial=adopted.models,baseModels=models});r.decisions=telemetry.actors
  for _,arena in ipairs(b.learners)do local id=arena.character.id;local learner=report.learners[id]
   assert(learner.controller=='flower-qlearning' and learner.qAdoptionId==adopted.id and learner.training.qAdoptionId==adopted.id and learner.qDecisions.accepted>0 and learner.qDecisions.explored==0)
   assert(require('Training.FlowerIdentity').equal(arena.flowerDeployment.executor:snapshot(),adopted.models[id]));assert(telemetry.actors[id].total==learner.qDecisions.accepted)
  end
  assert(require('Training.CombatStore').validate(b.combatEpisode));r.savedIdentityAndNoUpdates=true
  assert(S.rollbackAsync(adopted.id));S.loadAsync=load
  local baseline=require('Factory.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m05',models=models},support)
  assert(not baseline.arena.flowerDeployment and not baseline.wuyun.flowerDeployment);baseline:finish('aborted','QA rollback');r.basicRestored=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
