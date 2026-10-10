local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local supplies=assert(require('Economy.CombatSession').virtual('q-native',{{actor='ninilite',item='emp',quantity=8}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},supplies,{virtual=true})
  local s=require('Training.YingzhaoQ').attach(b,'ninilite',{epsilon=1,random=function()return 0 end});assert(b:start());b.wuyun.mode='review';b.enemies[1].guard.nextAttack=math.huge;b.enemies[1].enemy.playable.speed=0
  local stop=D.App.runningTime+15;while s.q.updates<3 do assert(D.App.runningTime<stop,'Q update timeout');D.sleep(.02)end
  r.transitions=s.transitions;r.hits=b.bossTrace.hits;save()
  assert(#s.transitions==3)
  -- The aiming intent may contact a nearer limb. Use actual projectile contacts,
  -- not the requested part, as the reward oracle.
  local exposed=false
  for i,t in ipairs(s.transitions)do
   local armor,health=0,0
   for _,hit in ipairs(b.bossTrace.hits)do if hit.step==i then
    armor=armor+hit.armorDamage;health=health+hit.healthDamage
    if hit.apBefore==0 then exposed=true;assert(hit.armorDamage==0 and hit.healthDamage==0)end
   end end
   local expected=armor*.25+health-4-(i==1 and 3 or 0)
   assert(math.abs(t.reward-expected)<1e-6,'Reward differs from actual contact and paid ammunition')
  end
  assert(exposed,'Fixture did not exercise EMP against exposed armor')
  for _,t in ipairs(s.transitions)do assert(t.sealed and not t.done and #t.nextActions>0 and t.duration>0)end
  local updates=s.q.updates;b:finish('aborted','Q cancellation fixture');while not s.closed do D.sleep(.02)end
  assert(s.q.updates==updates and s.discarded>=1 and s.model.algorithm=='yingzhao-qlearning')
  assert(#b.arena.recorder.samples==0)
  local found=false;for _,step in ipairs(b.bossTrace.steps)do if step.origin=='q-learning'and step.emitted then found=true end end;assert(found)
  local action,why=s.q:choose(s.transitions[1].state,function()return true end,false,.5,function()return 0 end);assert(not action and why=='EXPLORATION_REQUIRES_TRAINING')
  r.transitions=s.transitions;r.model=s.model;r.discarded=s.discarded;r.emissions=supplies.emissions
  local Q=require('Training.YingzhaoQ')
  local restored=assert(Q.restore(s.model,'ninilite'))
  assert(restored.updates==s.q.updates and restored.states==s.q.states)
  local key=assert(require('Training.YingzhaoFeatures').key(s.transitions[1].state))
  local savedValue=s.model.values[key]['shoot@head']
  restored.values[key]['shoot@head']=999
  assert(s.model.values[key]['shoot@head']==savedValue,'Restored Q aliases saved table')
  local function bad(change)
   local m=D.json.decode(D.json.encode(s.model),32);change(m);assert(not Q.validate(m),'Invalid Q accepted')
  end
  bad(function(m)m.values[key]['shoot@unknown']=1 end)
  bad(function(m)m.values['unknown']=m.values[key]end)
  bad(function(m)m.rewardPolicy='old-policy'end)
  bad(function(m)m.values[key]['shoot@head']=math.huge end)
  bad(function(m)m.updates=0 end)
  assert(not Q.restore(s.model,'wuyun'))
  local action=Q.predict(s.model,s.transitions[1].state,function(a)return a=='shoot@head'end)
  assert(action=='shoot@head')
  local noAction,why=Q.predict(s.model,s.transitions[1].state,function()return false end)
  assert(not noAction and why=='ACTION_UNAVAILABLE')
  r.restored=true;r.invalidRejected=true
  r.terminalFixtures={}
  for _,status in ipairs({'won','failed'})do
   local budget=assert(require('Economy.CombatSession').virtual('q-terminal-'..status,{{actor='ninilite',item='emp',quantity=8}}))
   local battle=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},budget,{virtual=true})
   local training=require('Training.YingzhaoQ').attach(battle,'ninilite',{epsilon=1,random=function()return 0 end})
   assert(battle:start());battle.wuyun.mode='review';battle.enemies[1].guard.nextAttack=math.huge
   local deadline=D.App.runningTime+15
   while budget.emissions<1 do assert(D.App.runningTime<deadline);D.sleep(.02)end
   -- Inject the outcome while a paid projectile is in flight. This verifies
   -- terminal accounting only; it is not a natural victory/balance test.
   assert(battle.bossCombat:pendingActor('ninilite'))
   assert(battle:finish(status,'Q terminal accounting fixture'))
   while not training.closed do assert(D.App.runningTime<deadline);D.sleep(.02)end
   assert(training.q.updates==1 and #training.transitions==1)
   local t=training.transitions[1]
   assert(t.done and t.nextState==nil and t.nextActions==nil)
   assert(math.abs(t.reward-((status=='won'and 100 or -100)-7))<1e-6)
   assert(not battle.bossCombat:pendingActor('ninilite'))
   D.sleep(.2);assert(training.q.updates==1,'Terminal reward repeated')
   r.terminalFixtures[#r.terminalFixtures+1]={status=status,reward=t.reward,updates=training.q.updates}
  end
  local budget=assert(require('Economy.CombatSession').virtual('q-frozen',{{actor='ninilite',item='emp',quantity=8}}))
  local battle=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},budget,{virtual=true})
  require('Training.YingzhaoTrial').attach(battle,s.model)
  local frozenBefore=D.json.encode(battle.yingzhaoCandidate)
  assert(battle:start());battle.wuyun.mode='review';battle.enemies[1].guard.nextAttack=math.huge
  local deadline=D.App.runningTime+15
  while budget.emissions<1 do assert(D.App.runningTime<deadline,'Frozen Q did not fire');D.sleep(.02)end
  assert(battle.yingzhaoCandidateDecisions[1].action=='shoot@head')
  assert(battle:finish('aborted','Frozen Q fixture'))
  while not battle.settled do assert(D.App.runningTime<deadline);D.sleep(.02)end
  assert(D.json.encode(battle.yingzhaoCandidate)==frozenBefore,'Frozen Q mutated')
  assert(not battle.yingzhaoQTraining and #battle.arena.recorder.samples==0)
  r.frozenTrial={emissions=budget.emissions,updates=battle.yingzhaoCandidate.updates}

  local resumedBudget=assert(require('Economy.CombatSession').virtual('q-resume',{{actor='ninilite',item='emp',quantity=8}}))
  local resumedBattle=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},resumedBudget,{virtual=true})
  local snapshotPath=D.Path(D.Content.writablePath,'yingzhao-q-roundtrip.json')
  assert(D.Content:save(snapshotPath,D.json.encode(s.model)))
  local saved=D.json.decode(D.Content:load(snapshotPath),32)
  local resumed=Q.attach(resumedBattle,'ninilite',{model=saved,epsilon=1,random=function()return 0 end})
  assert(resumed.q.updates==s.model.updates)
  local duplicate=pcall(function()Q.attach(resumedBattle,'ninilite')end);assert(not duplicate)
  assert(resumedBattle:start());resumedBattle.wuyun.mode='review';resumedBattle.enemies[1].guard.nextAttack=math.huge
  deadline=D.App.runningTime+15
  while resumed.q.updates==s.model.updates do assert(D.App.runningTime<deadline,'Resumed Q did not update');D.sleep(.02)end
  assert(resumed.q.updates==s.model.updates+1 and saved.updates==s.model.updates)
  assert(resumedBattle:finish('aborted','Resumed Q fixture'))
  while not resumed.closed do assert(D.App.runningTime<deadline);D.sleep(.02)end
  r.resumedUpdates=resumed.q.updates

  assert(not D.DB:existDB('lsd'))
  local db=D.Content.writablePath..'/yingzhao-q-candidates-'..os.time()..'.db'
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local store=require('Training.YingzhaoQStore')
  local record={schemaVersion=2,kind='yingzhao-q-candidate',episode='q-native-first',model=s.model,transitions=s.transitions,combat=s.combat}
  local forged=D.json.decode(D.json.encode(record),32)
  forged.transitions[1].reward=999
  local rebuilt=Q.new('ninilite');for _,t in ipairs(forged.transitions)do assert(rebuilt:update(t))end;forged.model=rebuilt:snapshot()
  local valid,why=store.validate(forged);r.forgedRejection=why;r.combat=s.combat;save();assert(not valid and why=='Q_REWARD_SOURCE_MISMATCH','Unexpected fabricated reward validation: '..tostring(why))
  forged=D.json.decode(D.json.encode(record),32);forged.combat.boss.hits[1].armorDamage=999
  assert(not store.validate(forged),'Fabricated combat damage accepted')
  forged=D.json.decode(D.json.encode(record),32);forged.transitions[2].sourceStep=forged.transitions[1].sourceStep
  assert(not store.validate(forged),'Repeated source action accepted')
  local accepted,reason,id=store.saveAsync(record);assert(accepted,reason)
  local again,why,same=store.saveAsync(record);assert(again and why=='ALREADY_RECORDED'and id==same)
  local loaded=assert(store.loadLatestAsync('ninilite'));assert(loaded.id==id)
  assert(require('Training.FlowerIdentity').equal(loaded.model,s.model))
  local empty,why=store.loadLatestAsync('wuyun');assert(not empty and why=='NO_CANDIDATE')
  local payload=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoQCandidates WHERE id=?',{id})[1][1]
  local corrupt=D.json.decode(payload,32);corrupt.transitions[1].reward=999
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoQCandidates SET payload=? WHERE id=?',{D.json.encode(corrupt),id})>=0)
  loaded,why=store.loadLatestAsync('ninilite');assert(not loaded and why=='Q_REWARD_SOURCE_MISMATCH')
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoQCandidates SET payload=? WHERE id=?',{payload,id})>=0)
  local parentId=id
  local continuation={parentId=parentId,schemaVersion=2,kind='yingzhao-q-candidate',episode='q-native-resumed',model=resumed.model,base=resumed.base,transitions=resumed.transitions,combat=resumed.combat}
  assert(D.DB:exec("CREATE TRIGGER lsd.reject_q BEFORE INSERT ON Game0YingzhaoQCandidates BEGIN SELECT RAISE(ABORT,'Q write QA'); END")>=0)
  accepted,why=store.saveAsync(continuation);assert(not accepted and why=='WRITE_FAILED')
  assert(D.DB:exec('DROP TRIGGER lsd.reject_q')>=0)
  accepted,why,id=store.saveAsync(continuation);assert(accepted,why)
  loaded=assert(store.loadLatestAsync('ninilite'));assert(loaded.id==id and loaded.model.updates==4)
  local orphan=D.json.decode(D.json.encode(continuation),32);orphan.parentId=nil
  accepted,why=store.saveAsync(orphan);assert(not accepted and why=='INVALID_PARENT')
  orphan.parentId=999999;accepted,why=store.saveAsync(orphan);assert(not accepted and why=='MISSING_PARENT')
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoQCandidates SET payload=? WHERE id=?',{D.json.encode(corrupt),parentId})>=0)
  loaded,why=store.loadLatestAsync('ninilite');assert(not loaded and why=='Q_REWARD_SOURCE_MISMATCH','Corrupt ancestor hidden by leaf')
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoQCandidates SET payload=? WHERE id=?',{payload,parentId})>=0)
  assert(store.loadLatestAsync('ninilite'))
  continuation.episode=record.episode
  accepted,why=store.saveAsync(continuation);assert(not accepted and why=='PARENT_MODEL_MISMATCH')
  assert(D.DB:exec('DETACH DATABASE lsd')>=0)
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  loaded=assert(store.loadLatestAsync('ninilite'));assert(loaded.model.updates==4)
  r.candidateStore={database=db,id=id,replayed=true,retry=true,corruptRejected=true,reopened=true}

 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
