-- Explicit training/evaluation runner. No adoption, mission progress or C4.5 writes.
local D=require('Dora');local Q=require('Training.FlowerQ');local Trace=require('Training.FlowerDecisionTrace')
local S={}
local function copy(x)return D.json.decode(D.json.encode(x,false,true),32)end
function S.runAsync(options)
 local o={};for key,value in pairs(options or {})do o[key]=value end
 if o.models then o.models=copy(o.models)end;if o.initial then o.initial=copy(o.initial)end
 assert(o.mode=='basic' or o.mode=='evaluate' or o.mode=='explore','Invalid Q session mode')
 if o.virtualSupplies then
  o.virtualSupplies=copy(o.virtualSupplies)
 end
 local goal=o.virtualSupplies and 'resource-clear-v1' or nil
 if o.virtualSupplies and o.initial then for _,id in ipairs({'ninilite','wuyun'})do assert(o.initial[id] and o.initial[id].trainingGoal==goal,'TRAINING_GOAL_MISMATCH')end end
 local exploring=o.mode=='explore';local epsilon=exploring and (o.epsilon or .35) or 0
 assert(type(epsilon)=='number' and epsilon>=0 and epsilon<=1)
 assert(exploring or o.epsilon==nil or o.epsilon==0,'Evaluation cannot explore')
 local random
 if exploring then
  assert(type(o.seed)=='number' and o.seed%1==0 and o.seed>0 and o.seed<2147483647,'Explicit seed required')
  local state=o.seed;random=function()state=state*16807%2147483647;return (state-1)/2147483646 end
 end
 local Learner=o.virtualSupplies and require('Training.ResourceQ')or Q
 local models=assert(o.models);local policies={}
 local featureVersion=o.virtualSupplies and 8 or o.mode=='evaluate' and o.initial and o.initial.ninilite.featureSchemaVersion or 7
 if o.mode=='evaluate'then assert(o.initial and o.initial.ninilite and o.initial.wuyun,'Evaluation requires both candidates')end
 if o.initial then assert(o.initial.ninilite and o.initial.wuyun,'Both initial models required')end
 for _,id in ipairs({'ninilite','wuyun'})do
  policies[id]=o.initial and assert(Learner.restore(o.initial[id],id)) or Learner.new(id,o.virtualSupplies and goal or featureVersion)
  if o.virtualSupplies and exploring then policies[id].explorationPolicy='coverage-v1'end
  if not o.virtualSupplies and policies[id].featureSchemaVersion~=featureVersion then assert(exploring and featureVersion==7,'FEATURE_VERSION_MISMATCH');policies[id]=Q.new(id,featureVersion)end
 end
 local result={schemaVersion=1,mode=o.mode,seed=exploring and o.seed or nil,epsilon=epsilon,initial=o.initial and copy(o.initial) or nil,baseModels=copy(models),profile=o.profile or 'field',decisions={}}
 for _,id in ipairs({'ninilite','wuyun'})do result.decisions[id]={q=0,explored=0,fallback=0,accepted=0,rejected=0,reasons={}}end
 local service={finishAsync=function(_,attempt,status,report,episode)
  episode.context=o.virtualSupplies and 'flower-resource-practice' or 'flower-q-practice';result.status=status;result.report=report;result.episode=episode;return true
 end}
 local scenario=assert(require('Training.FlowerScenarios').get(result.profile),'Invalid scenario')
 assert(not scenario.resourceOnly or o.virtualSupplies,'Resource scenario requires virtual supplies')
 local support=require('Ground.LifeSupport').new(result.profile=='field' and 45 or 90,'defence');support.hp={100,100,100}
 S.serial=(S.serial or 0)+1
 local practiceId=o.virtualSupplies and ('resource-practice-'..os.time()..'-'..S.serial)or nil
 local battle=require('Factory.Battle').createAsync(service,{mission='c0-m05',id=practiceId,models=models},support,{training=true,virtualSupplies=o.virtualSupplies,trainingGoal=goal})
 require('Training.FlowerScenarios').apply(battle,battle.arena,result.profile)
 if result.profile~='field'then battle.wuyun.student.x=battle.arena.student.x-120 end
 result.virtualSupplies=o.virtualSupplies
 result.setup={explorationPolicy=o.virtualSupplies and exploring and 'coverage-v1' or nil,trainingGoal=goal,qFeatureVersion=featureVersion,hitReaction=require('Factory.Rules').hitReaction,bossScale=battle.roots[3].enemy.playable.scaleX,aimPolicy=require('Factory.PartCombat').aimPolicy,formation='ni-left-wu120-v1',supportGold=support.gold,mentor='auto-nearest-kinetic-v1',chant='on-confusion-v1',decisionSeconds=.25,initialDecisionSeconds=.2}
 assert(battle.mentorHP==100 and battle.arena.studentHP==100 and battle.wuyun.studentHP==100,'Incomplete party initialization')
 if o.virtualSupplies then
  result.setup.resourceFallback=3;battle.partCombat.journal.versions.resourceFallback=3;result.setup.continuousMovement=1;battle.partCombat.journal.versions.continuousMovement=1
  for _,arena in ipairs(battle.learners)do arena.continuousDecisions=true end
 end
 if o.virtualSupplies and o.mode=='basic'then
  for _,arena in ipairs(battle.learners)do
   arena.resourceTrialPredict=function(baseState,can)
    local available={};for _,name in ipairs({'idle','fmove','bmove','laser','melee'})do available[name]=can(name) and true or false end
    local observation=require('Training.FlowerFeatures').capture(battle,arena.student,battle.partCombat.known)
    return require('Training.ResourceFallback').predict(models[arena.character.id],baseState,available,observation,result.setup.resourceFallback)
   end
  end
 end
 local trace=Trace.attach(battle);if o.mode=='evaluate'then trace.decisionSourcesVersion=1 end;assert(battle:start())
 for _,arena in ipairs(battle.learners)do arena.mode=o.mode=='basic' and 'trial' or 'demo'end
 if o.onStart then o.onStart(battle,result)end
 local nextAt=D.App.totalTime+.2;local deadline=D.App.totalTime+150;local progressAt=D.App.totalTime
 while battle.phase=='playing' do
  if o.cancelled and o.cancelled()then battle:finish('aborted','自主练习已停止')break end
  assert(D.App.totalTime<deadline,'Q encounter stalled')
  if o.onProgress and D.App.totalTime>=progressAt then progressAt=D.App.totalTime+1;o.onProgress(battle,result)end
  battle:command('shoot')
  for _,state in pairs(battle.effects.states)do if D.App.runningTime<(state.confusedUntil or 0)then battle:command('song');break end end
  if o.mode~='basic' and D.App.totalTime>=nextAt then
   nextAt=D.App.totalTime+.25
   for _,arena in ipairs(battle.learners)do
    local id=arena.character.id;local counters=result.decisions[id]
    if o.mode=='evaluate'then require('Training.FlowerQExecutor').step(battle,arena,policies[id],models[id],counters,result.setup.resourceFallback)
    else
    local decision=Trace.decision(battle,arena)
    if decision then
    local mask={}
    for _,label in ipairs(decision.actions)do mask[label]=true end
    local selected,why=policies[id]:choose(decision.state,function(label)return mask[label]==true end,exploring,epsilon,random)
    if selected then
     if why=='EXPLORE'then counters.explored=counters.explored+1 else counters.q=counters.q+1 end
     local action,part=require('Training.FlowerPolicy').decodeAction(selected)
     arena.flowerTargetPart=part;arena.flowerTargetAim=part and decision.aims[part] or nil
     local ok=arena:request(action=='shoot' and 'laser' or action,'model',decision);arena.flowerTargetPart=nil;arena.flowerTargetAim=nil
     if ok and o.mode=='evaluate'then local steps=trace.actors[id].steps;steps[#steps].decisionSource={reason=why}end
     counters[ok and 'accepted' or 'rejected']=counters[ok and 'accepted' or 'rejected']+1
    elseif why=='UNSEEN_STATE' or why=='UNSEEN_ACTIONS'then
     counters.fallback=counters.fallback+1;counters.reasons[why]=(counters.reasons[why] or 0)+1
     local fallbackState=arena:snapshot();local fallbackAvailable=Trace.baseActions(decision)
     local action
     if o.virtualSupplies then action=require('Training.ResourceFallback').predict(models[id],fallbackState,fallbackAvailable,decision.state,result.setup.resourceFallback)
     else action=require('Training.Model').predict(models[id],fallbackState,function(a)return fallbackAvailable[a]end);if not action and fallbackAvailable.idle then action='idle'end end
     if action then local ok=arena:request(action,'model',decision)
      if ok and o.mode=='evaluate'then local steps=trace.actors[id].steps;steps[#steps].decisionSource={reason=why,state=fallbackState,available=fallbackAvailable}end
      counters[ok and 'accepted' or 'rejected']=counters[ok and 'accepted' or 'rejected']+1 end
    end
    else counters.skipped=(counters.skipped or 0)+1;arena.lastDecision='NO_AVAILABLE_ACTIONS'end
    end
   end
  end
  D.sleep(.02)
 end
 local saveDeadline=D.App.totalTime+10
 while battle.phase=='saving' or not result.status do assert(D.App.totalTime<saveDeadline,'Q result timeout');D.sleep(.02)end
 result.trace=trace
 if exploring and trace.trainable then result.models,result.learningError=Learner.learn(trace,result.episode,result.status,result.initial,featureVersion)end
 if not exploring then result.models=o.initial and copy(o.initial) or nil end
 if o.virtualSupplies and o.mode=='evaluate'then
  result.models={};for id,policy in pairs(policies)do result.models[id]=policy:snapshot()end
  assert(require('Training.FlowerIdentity').equal(result.models,o.initial),'Frozen resource candidate changed')
 end
 if o.onFinish then o.onFinish(battle,result)end
 if not o.keepScene then battle.arena.closed=true;battle.wuyun.closed=true;battle.arena.world:removeFromParent()end
 return result
end
return S
