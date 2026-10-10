-- Controlled virtual training fixture; actual wave/cost/Q transitions are replayed.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-shield-q-result.json';local r={status='RUNNING',controlledFixture=true,osInput=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local supplies=assert(require('Economy.CombatSession').virtual('shield-q-native',{{actor='ninilite',item='emp',quantity=8}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},supplies,{virtual=true,physicalSupport=true})
  assert(b.physicalShield and b.support.gold==45)
  b.mentor.x=2250;b.arena.student.x=2250;b.wuyun.student.x=2250
  local session=require('Training.YingzhaoQ').attach(b,'ninilite',{epsilon=1,random=function()return 0 end})
  assert(b:start());b.wuyun.mode='review';local boss=b.enemies[1];boss.guard.nextAttack=math.huge;D.sleep(.5)
  assert(boss.guard:attack('wave',b.mentor));D.sleep(6)
  if os.getenv('LSD_QA_Q_ARRIVAL_POLICY')=='1'then
   -- Controlled pre-arrived boundary fixture isolates policy release; the
   -- formal adopted regression separately proves real travel and arrival.
   local anchor=b.maxX-25;b.mentor.x=anchor;b.arena.student.x=anchor;b.wuyun.student.x=anchor
   r.controlledArrivalSetup={x=anchor,teleportedActors={'mentor','ninilite','wuyun'},movementArrivalProof=false}
   assert(b:command('gather'));local plan=b.gatherPlan;local deadline=b.gatherUntil
   local stopAt=D.App.runningTime+13;local arrival,stepBaseline
   r.gatherDiagnostics={plan={ninilite=plan.ninilite,wuyun=plan.wuyun},duration=b.gatherDuration,minX=b.minX,maxX=b.maxX,samples={}}
   while b.phase=='playing'and D.App.runningTime<deadline do
    assert(D.App.runningTime<stopAt)
    if #r.gatherDiagnostics.samples<200 then r.gatherDiagnostics.samples[#r.gatherDiagnostics.samples+1]={at=D.App.runningTime-b.started,x=b.arena.student.x,target=plan.ninilite,onSurface=b.arena.student.onSurface,complete=b.arena.regroupComplete,phase=b.phase,attacking=b.arena:isAttacking(),steps=#b.bossTrace.steps,hp=b.arena.studentHP,owns=require('Combat.Formation').owns(b.arena,b,D.App.runningTime)}end
    if b.arena.regroupPlan==plan and b.arena.regroupComplete then
     if not arrival then arrival=D.App.runningTime;stepBaseline=#b.bossTrace.steps end
     for i=stepBaseline+1,#b.bossTrace.steps do
      local step=b.bossTrace.steps[i]
      if step.actor=='ninilite'and step.origin=='q-learning'and step.started>=arrival and step.started<deadline then
       r.arrivalPolicy={actor='ninilite',arrivalObserved=arrival-b.started,stepStarted=step.started-b.started,deadline=deadline-b.started,secondsBeforeDeadline=deadline-step.started,action=step.action};break
      end
     end
    end
    if r.arrivalPolicy then break end
    D.sleep(.02)
   end
   r.gatherDiagnostics.arrival=arrival and arrival-b.started;r.gatherDiagnostics.steps=b.bossTrace.steps
   assert(r.arrivalPolicy,'Q learner did not resume actual learning action before normal gather deadline')
  end
  b:finish('aborted','Shield Q controlled fixture');local stop=D.App.runningTime+10
  while not session.closed do assert(D.App.runningTime<stop);D.sleep(.02)end
  local record={schemaVersion=2,kind='yingzhao-q-candidate',episode=session.combat.episode,model=session.model,transitions=session.transitions,combat=session.combat}
  r.accountDebug=record.combat.boss.supportAccounting;r.accountError=record.combat.boss.supportAccountingError;save()
  local Store=require('Training.YingzhaoQStore');local valid,why=Store.validate(record);assert(valid,why)
  local Rewards=require('Training.YingzhaoRewards');local energy=Rewards.shieldCost(record.combat.boss);assert(energy>0,'No actual shield energy cost')
  local reward=assert(Rewards.rebuild(record.combat,'ninilite'));assert(math.abs(reward.shieldEnergy-energy)<1e-6 and reward.components.shieldEnergy<0)
  assert(not Rewards.rebuild(record.combat,'ninilite',Rewards.legacyPolicy),'Legacy reward silently ignored shield cost')
  local covered=false;for _,t in ipairs(record.transitions)do if t.state.shieldState=='covered'then covered=true end end;assert(covered and #record.transitions>0)
  local fake=D.json.decode(D.json.encode(record),32);fake.transitions[1].reward=fake.transitions[1].reward+energy;assert(not Store.validate(fake),'Forged free-shield Q reward accepted')
  -- Historical policy remains explicit when restored; it is not relabeled v2.
  local old=D.json.decode(D.json.encode(session.model),32);old.rewardPolicy=Rewards.legacyPolicy
  assert(require('Training.YingzhaoQ').restore(old):snapshot().rewardPolicy==Rewards.legacyPolicy)
  if os.getenv('LSD_QA_SUPPORT_FEATURES')=='1'then
   local F=require('Training.YingzhaoFeatures');local Support=require('Training.YingzhaoSupportFeatures');local I=require('Training.FlowerIdentity')
   assert(F.version==10 and #F.fields(10)==#F.fields(9)+3)
   local oldPath=assert(os.getenv('LSD_QA_OLD_FEATURES'));local oldF=assert(load(D.Content:load(oldPath),'@'..oldPath))();assert(oldF.version==9)
   local checked=0
   for _,step in ipairs(record.combat.boss.steps)do
    local observation=step.before;assert(F.validate(observation)and observation.featureSchemaVersion==10)
    assert(observation.supportState.present and Support.project(observation.supportState))
    local legacy=D.json.decode(D.json.encode(observation),32);legacy.featureSchemaVersion=9;legacy.supportState=nil
    for _,name in ipairs(Support.names)do legacy[name]=nil end
    assert(oldF.validate(legacy)and F.validate(legacy))
    for version=1,9 do
     assert(I.equal(oldF.fields(version),F.fields(version)))
     assert(I.equal(oldF.project(legacy,version),F.project(observation,version)))
     assert(oldF.key(legacy,version)==F.key(observation,version))
    end
    local unknown=assert(F.project(legacy,10));for _,name in ipairs(Support.names)do assert(unknown[name]=='unknown')end
    local forged=D.json.decode(D.json.encode(observation),32);forged.supportState.seconds=forged.supportState.seconds+1;assert(not F.validate(forged))
    forged=D.json.decode(D.json.encode(observation),32);forged.machineHealth='fallen';if observation.machineHealth~='fallen'then assert(not F.validate(forged))end
    checked=checked+1
   end
   assert(checked>0 and record.model.featureSchemaVersion==10)
   for _,transition in ipairs(record.transitions)do for _,name in ipairs(Support.names)do assert(transition.state[name]~=nil)end end
   local old=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_LEGACY_Q_RESULT'))),32).record
   assert(old.model.featureSchemaVersion==9 and Store.validate(old))
   local restored=assert(require('Training.YingzhaoQ').restore(old.model));assert(I.equal(restored:snapshot(),old.model))
   r.supportFeatureValidation={schemaVersion=10,observationsChecked=checked,legacyFieldVersionsChecked=9,legacyQArchiveValidated=true,legacyQSnapshotUnchanged=true,legacyNewFieldsUnknown=true,forgedLifetimeRejected=true,transitionsCarrySupport=true}
  end
  if os.getenv('LSD_QA_SUPPORT_BOUNDARIES')=='1'then
   local A=require('Training.YingzhaoSupportAccounting');local account=record.combat.boss.supportAccounting
   assert(A.validate(account,record.combat.boss.physicalShield))
   assert(math.abs(account.goldSpent-(b.support.spent-account.samples[1].spent))<1e-6)
   assert(account.upkeepGold>0 and account.shieldGold>0 and math.abs(account.shieldGold-energy)<1e-6)
   assert(math.abs(account.goldSpent-account.shieldGold-account.upkeepGold)<1e-6)
   for _,transition in ipairs(record.transitions)do
    assert(transition.supportBoundaryVersion==1 and A.interval(account,transition.supportStart,transition.supportEnd))
   end
   local fake=D.json.decode(D.json.encode(record),32);fake.combat.boss.supportAccounting.upkeepGold=account.upkeepGold+1;assert(not Store.validate(fake))
   fake=D.json.decode(D.json.encode(record),32);fake.transitions[1].supportStart=#account.samples;assert(not Store.validate(fake))
   r.supportBoundaryValidation={samples=#account.samples,transitions=#record.transitions,goldSpent=account.goldSpent,upkeepGold=account.upkeepGold,shieldGold=account.shieldGold,machineDamage=account.machineDamage,rewardPolicy=record.model.rewardPolicy,forgedCounterRejected=true,forgedBoundaryRejected=true}
  end
  if os.getenv('LSD_QA_SUPPORT_REWARD_V3')=='1'then
   local A=require('Training.YingzhaoSupportAccounting');local I=require('Training.FlowerIdentity');local account=record.combat.boss.supportAccounting
   assert(record.model.rewardPolicy==Rewards.supportPolicy and record.combat.rewardPolicy==Rewards.supportPolicy and reward.policy==Rewards.supportPolicy)
   local shieldOnly=assert(Rewards.rebuild(record.combat,'ninilite',Rewards.policy))
   assert(math.abs(shieldOnly.total-reward.total-account.upkeepGold-account.machineDamage*Rewards.weights.machineDamage)<1e-6)
   assert(math.abs(reward.components.shieldEnergy+reward.components.upkeepEnergy+account.goldSpent)<1e-6)
   local freeIndex
   for i,t in ipairs(record.transitions)do local c=assert(A.interval(account,t.supportStart,t.supportEnd));if c.upkeepGold+c.machineDamage>1e-6 then freeIndex=i;break end end
   assert(freeIndex)
   local fake=D.json.decode(D.json.encode(record),32);local t=fake.transitions[freeIndex];local c=assert(A.interval(account,t.supportStart,t.supportEnd));t.reward=t.reward+c.upkeepGold+c.machineDamage*Rewards.weights.machineDamage;assert(not Store.validate(fake),'Free upkeep/machine damage accepted')
   fake=D.json.decode(D.json.encode(record),32);fake.combat.rewardPolicy=Rewards.policy;assert(not Store.validate(fake),'Combat policy silently relabeled')
   fake=D.json.decode(D.json.encode(record),32);fake.combat.boss.supportAccounting=nil;fake.combat.boss.supportAccountingVersion=nil;assert(not Store.validate(fake),'New reward accepted missing account')
   local old=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PREVIOUS_SUPPORT_Q'))),32).record
   assert(old.model.rewardPolicy==Rewards.policy and Store.validate(old));local restored=assert(require('Training.YingzhaoQ').restore(old.model));assert(I.equal(restored:snapshot(),old.model))
   local archived=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_FORMAL_COST_RESULT'))),32).episode
   local previous=assert(Rewards.rebuild(archived,'ninilite'));assert(previous.policy==Rewards.policy)
   local revised=assert(Rewards.rebuild(archived,'ninilite',Rewards.supportPolicy));local costs=archived.boss.supportAccounting
   assert(costs.machineDamage>0 and costs.samples[1].spent>0)
   assert(math.abs(previous.total-revised.total-costs.upkeepGold-costs.machineDamage*Rewards.weights.machineDamage)<1e-6)
   r.supportRewardValidation={policy=record.model.rewardPolicy,actualQUpkeep=account.upkeepGold,actualQMachineDamage=account.machineDamage,storedFormalMachineDamage=costs.machineDamage,storedFormalUpkeep=costs.upkeepGold,oldV2ArchiveUnchanged=true,oldDefaultStillV2=true,freeCostsRejected=true,missingAccountRejected=true,policyRelabelRejected=true}
   assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-support-reward-v3-'..os.time()..'.db'
   assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
   local saved,why,id=Store.saveAsync(record);assert(saved,why)
   local stored=assert(Store.loadLatestAsync('ninilite'));assert(stored.id==id and I.equal(stored.source,record))
   r.database=db;r.qCandidateId=id;r.qCandidateSaved=true;r.qModel=record.model

  end
  r.record=record;r.reward=reward;r.shieldEnergy=energy;r.costReplayed=true;r.legacyPolicyPreserved=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
