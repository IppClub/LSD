-- Controlled initial injury/positions, followed by the actual authored Boss wave.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/living-support-native-result.json'
local r={status='RUNNING',osInput=false,controlledFixture=true,fixtureContinuesAfterLearnerDefeat=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},assert(require('Economy.CombatSession').virtual('living-support',{{actor='wuyun',item='blade',quantity=1}})),{virtual=true})
  -- A deliberately injured learner stands in the wave; both living companions
  -- are outside its range. No claim of natural mission completion is made.
  b.arena.studentHP=8
  b.mentor.x=3500;b.wuyun.student.x=3500;b.arena.student.x=2250
  local support=require('Ground.LifeSupport').new(45,'defence');require('Ground.BattleSupport').attach(b,support)
  assert(support.x==2875 and support.span==1250)
  -- The production patrol fails when any teammate falls. This fixture keeps
  -- only the controller open to exercise life-field following after a defeat;
  -- it does not change that production failure rule or claim a playable victory.
  b.partyDefeated=function(self)return self.mentorHP<=0 end
  assert(b:start());b.arena.mode='review';b.wuyun.mode='review';local boss=b.enemies[1];boss.guard.nextAttack=math.huge
  D.sleep(.5);assert(boss.guard:attack('wave',b.mentor))
  local deadline=D.App.runningTime+8
  while boss.guard.busy or #boss.guard.waves>0 do assert(D.App.runningTime<deadline,'Wave deadline');D.sleep(.02)end
  D.sleep(.2)
  r.afterWave={phase=b.phase,niniliteHP=b.arena.studentHP,mentorHP=b.mentorHP,wuyunHP=b.wuyun.studentHP,machineX=support.x,span=support.span};save()
  assert(b.phase=='playing' and b.arena.studentHP==0 and b.mentorHP>0 and b.wuyun.studentHP>0,'Authored wave did not defeat the isolated learner')
  assert(math.abs(support.x-3500)<1 and support.span<1 and support.radius==180,'Defeated learner dragged the live machine')
  assert(math.abs(b.machine.x-support.x)<1 and math.abs(b.supportView.machine.x-support.x)<1,'Actual machine/view did not follow living squad')
  assert(support.hp[2]==0 and support.hp[1]==b.mentorHP and support.hp[3]==b.wuyun.studentHP,'Role indices or defeated HP changed')
  local gold=support.gold;D.sleep(.5);assert(gold-support.gold>0 and gold-support.gold<.25,'Defeated separation still charged as live squad span')
  b:finish('aborted','Living squad controlled native fixture')
  assert(b.report.auxiliary.lifeRuleVersion==2)
  assert(require('Training.YingzhaoVitals').validate(b.bossTrace.vitals))
  assert(require('Ground.PhysicalShield').validate(b.bossTrace.physicalShield))
  r.actualWaveDefeat=true;r.livingFollow=true;r.viewAndBodyAgree=true;r.roleIndices=true;r.fallenNotRevived=true;r.goldHalfSecond=gold-support.gold;r.support=b.report.auxiliary;r.vitals=b.bossTrace.vitals;r.wave=boss.guard.strike
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
