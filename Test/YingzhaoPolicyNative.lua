-- Actual native attacks generate the training source. Frozen Boss and idle
-- teammates are fixture conditions, not a player lesson or victory evaluation.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-policy-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Training.BigYingzhaoPractice').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},{{actor='ninilite',item='emp',quantity=8}},'ninilite')
  assert(b:start());b.wuyun.mode='review';b.enemies[1].guard.nextAttack=math.huge;D.sleep(.5);b.enemies[1].enemy.playable.speed=0
  local function wait(fn)local stop=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<stop,'Policy fixture timeout');D.sleep(.02)end end
  for _,part in ipairs({'head','forelegs','head','forelegs','head','forelegs'})do
   wait(function()return not b.arena:isAttacking()and b.arena:available('laser')and next(b.bossCombat.shots)==nil end)
   assert(b:command('aim-part',part));assert(b:command('shoot'))
   wait(function()return not b.arena:isAttacking()and next(b.bossCombat.shots)==nil end)
  end
  assert(b.supplies.emissions==6);b:finish('aborted','Training fixture complete');wait(function()return b.phase=='aborted'end)
  local resources=b.supplies:evidence();b.bossTrace.resources=resources
  local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='ninilite',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
  local reward=assert(require('Training.YingzhaoRewards').rebuild(e,'ninilite'));assert(reward.consumption==24 and reward.deployment==3 and reward.health==0 and reward.armor==105 and reward.total==-.75);r.reward=reward
  local forged=D.json.decode(D.json.encode(e),32);forged.boss.hits[#forged.boss.hits+1]={attackId='forged-summon',source='ninilite',target='fake-summon',summoned=true,part='body',weapon='fire',hpBefore=70,hpAfter=0,healthDamage=999,armorDamage=0};assert(not require('Training.YingzhaoRewards').rebuild(forged,'ninilite'))
  local P=require('Training.YingzhaoPolicy');local m=assert(P.buildAsync({e},'ninilite'));assert(P.validate(m,'ninilite'))
  assert(m.sampleCount==6 and m.algorithm=='yingzhao-c45'and #m.sourceEpisodes==1)
  local state;for _,s in ipairs(e.boss.steps)do if s.aim then state=s.before;break end end
  local prediction=assert(P.predict(m,state));assert(require('Training.YingzhaoActions').decode(prediction)=='laser')
  local action,why=P.predict(m,state,function()return false end);assert(not action and why=='ACTION_UNAVAILABLE')
  local copy=D.json.decode(D.json.encode(m),32);assert(P.validate(copy));copy.rules[1].action='shoot@tail';assert(not P.validate(copy))
  copy=D.json.decode(D.json.encode(m),32);copy.rules[1].conditions={{name='hpAfter',op='==',value='0'}};assert(not P.validate(copy))
  assert(not require('Training.Model').validate(m,'ninilite',{laser=true,idle=true,fmove=true,bmove=true}))
  local virtual=assert(require('Economy.CombatSession').virtual('candidate-execution',{{actor='ninilite',item='emp',quantity=4}}))
  local trial=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},virtual,{virtual=true})
  require('Training.YingzhaoTrial').attach(trial,m);assert(trial:start());trial.enemies[1].guard.nextAttack=math.huge;trial.wuyun.mode='review'
  wait(function()return virtual.emissions>=1 end)
  wait(function()return #trial.bossTrace.hits>=1 end)
  assert(trial.bossTrace.steps[trial.bossTrace.hits[1].step].origin=='candidate')
  assert(#trial.arena.recorder.samples==0 and #trial.yingzhaoCandidateDecisions>0)
  trial:finish('aborted','Candidate execution complete');wait(function()return trial.phase=='aborted'end)
  r.candidateExecuted=true
  r.samples=m.sampleCount;r.accuracy=m.trainingAccuracy;r.rules=#m.rules;r.prediction=prediction;r.source=e;r.model=m
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
