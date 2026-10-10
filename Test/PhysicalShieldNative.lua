-- Controlled native fixture: authored wave, real HP callbacks and displacement.
-- Positions/idle models are fixtures, never a natural mission/adoption claim.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/physical-shield-native-result.json';local r={status='RUNNING',controlledFixture=true,osInput=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},assert(require('Economy.CombatSession').virtual('physical-shield',{{actor='wuyun',item='blade',quantity=1}})),{virtual=true})
  local partial=os.getenv('LSD_QA_PARTIAL_SHIELD')=='1'
  local support=require('Ground.LifeSupport').new(45,'defence');require('Ground.BattleSupport').attach(b,support)
  b.mentor.x=2250;b.arena.student.x=2250;b.wuyun.student.x=2250
  assert(b:start());b.arena.mode='review';b.wuyun.mode='review';local boss=b.enemies[1];boss.guard.nextAttack=math.huge;D.sleep(.5)
  local observation=b.observeYingzhao(b.mentor);local F=require('Training.YingzhaoFeatures');assert(F.validate(observation)and observation.shieldState=='covered'and observation.shieldCharge=='ready')
  assert(F.project(observation,8).shieldState==nil,'Legacy projection changed')
  local bad=D.json.decode(D.json.encode(observation),32);bad.shieldState='outside';assert(not F.validate(bad),'Forged shield observation accepted')
  local initial={mentor=b.mentor.x,ni=b.arena.student.x,wu=b.wuyun.student.x}
  if partial then b.physicalShield.charge=5;b.physicalShield.state.charge=5;b.physicalShield.initial.charge=5;b.physicalShield.state.delayUntil=D.App.runningTime+20;b.physicalShield.initial.delayUntil=b.physicalShield.state.delayUntil end
  assert(boss.guard:attack('wave',b.mentor));local stop=D.App.runningTime+8
  while boss.guard.busy or #boss.guard.waves>0 do assert(D.App.runningTime<stop,'Authored wave did not finish');D.sleep(.02)end
  b:finish('aborted','Physical shield controlled fixture')
  if not partial then
  assert(b.mentorHP==100 and b.arena.studentHP==100 and b.wuyun.studentHP==100 and support.machineHP==100,'Shield missed shared party protection')
  assert(math.abs(b.mentor.x-initial.mentor)<1 and math.abs(b.arena.student.x-initial.ni)<1 and math.abs(b.wuyun.student.x-initial.wu)<1,'Fully absorbed wave displaced a protected actor')
  else assert(b.mentorHP<100 and support.machineHP<100,'Partial shield suppressed remaining damage')end
  local shield=assert(b.bossTrace.physicalShield);assert(require('Ground.PhysicalShield').validate(shield))
  local impacts=0;local absorbed=0
  for _,e in ipairs(shield.events)do if e.kind=='impact'then impacts=impacts+1;absorbed=absorbed+e.absorbed;assert(e.incoming==16);assert(e.attackerId=='dayingzhao'and e.strikeStarted==boss.guard.strikes[1].started and e.hitIndex==1,'Wave contact lost provenance');if not partial then assert(e.remaining==0 and e.hpAfter==100)end end end
  assert(impacts==4 and absorbed==(partial and 5 or 64),'Wave did not share one finite shield across four targets')
  assert(require('Training.YingzhaoVitals').validate(b.bossTrace.vitals),'Protected HP archive invalid')
  local resource=b.supplies:evidence();b.bossTrace.resources=resource
  local episode={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-evaluation',episode=resource.attempt,versions={resources=1,bigYingzhao=1},resources=resource,boss=b.bossTrace}
  assert(require('Enemy.BigYingzhaoEvidence').validateEvaluation(episode))
  local fake=D.json.decode(D.json.encode(episode),32);fake.boss.physicalShield.events[1].absorbed=0;assert(not require('Enemy.BigYingzhaoEvidence').validateEvaluation(fake),'Forged protection accepted')
  local legacy=D.json.decode(D.json.encode(episode),32)
  for _,e in ipairs(legacy.boss.physicalShield.events)do e.attackerId=nil;e.strikeStarted=nil;e.hitIndex=nil end
  for _,e in ipairs(legacy.boss.vitals.events)do e.attackerId=nil;e.strikeStarted=nil;e.hitIndex=nil end
  assert(require('Enemy.BigYingzhaoEvidence').validateEvaluation(legacy),'Historical contact records rejected')
  local future=D.json.decode(D.json.encode(episode),32)
  for _,e in ipairs(future.boss.physicalShield.events)do if e.kind=='impact'then e.strikeStarted=e.at+1;break end end
  assert(not require('Enemy.BigYingzhaoEvidence').validateEvaluation(future),'Future attack start accepted')
  if partial then
   local wrong=D.json.decode(D.json.encode(episode),32)
   for _,e in ipairs(wrong.boss.vitals.events)do if e.physicalShieldEvent then e.attackerId='wrong-source';break end end
   assert(not require('Enemy.BigYingzhaoEvidence').validateEvaluation(wrong),'Mismatched HP contact source accepted')
  end
  r.contactProvenance=true;r.legacyContactsAccepted=true;r.futureContactRejected=true;r.mismatchedVitalRejected=partial
  r.observation=observation;r.schema9AndLegacyProjection=true;r.shield=shield;r.vitals=b.bossTrace.vitals;r.actualAuthoredWave=true;r.protectionConservation=true;r.fullyAbsorbedNoDisplacement=not partial;r.partial=partial;r.goldAfter=support.gold
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
