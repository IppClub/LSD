-- Controlled ownership fixture: artificial models/positions/injury, no DB,
-- adoption, natural victory or balance claim. Authored actions remain real.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/recovery-stationary-policy-result.json'
local fixed=os.getenv('LSD_QA_EXPECT_RECOVERY_POLICY')=='1'
local r={status='RUNNING',expectStationaryPolicy=fixed,scope='controlled-arrived-recovery-basic-shot-and-frozen-skill'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 15);while not fn()do assert(D.App.runningTime<deadline,'Recovery policy fixture stalled');D.sleep(.01)end end
  local function basic(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  local models={ninilite=basic('ninilite','laser'),wuyun=basic('wuyun','idle')}
  local frozen={schemaVersion=1,algorithm='yingzhao-c45',featureSchemaVersion=6,actionSetVersion=2,builderVersion=2,enemyAsset='dayingzhao',characterId='wuyun',sampleCount=6,trainingAccuracy=1,sourceEpisodes={'controlled-recovery-policy'},rules={{conditions={},action='wind@right'}}}
  local original=D.json.encode({models,frozen},false,true)
  local supplies=assert(require('Economy.CombatSession').virtual('recovery-stationary-policy',{{actor='ninilite',item='emp',quantity=12},{actor='wuyun',item='emp',quantity=6},{actor='wuyun',item='blade',quantity=6}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true})
  require('Ground.BattleSupport').attach(b,require('Ground.LifeSupport').new(90,'defence'))
  require('Training.YingzhaoTrial').attach(b,frozen)
  wait(function()return b.mentor.onSurface and b.arena.student.onSurface and b.wuyun.student.onSurface end)
  b.mentor.x=1200;b.arena.student.x=1000;b.wuyun.student.x=1100;b.mentorHP=50
  assert(b:start());b.enemies[1].guard.nextAttack=math.huge
  assert(b:command('recover-gather'));local deadline=b.gatherUntil
  wait(function()return b.arena.regroupComplete and b.wuyun.regroupComplete end)
  local arrived=D.App.runningTime;local first=#b.bossTrace.steps
  local at={ninilite=b.arena.student.x,wuyun=b.wuyun.student.x};local finish=arrived+3.2
  r.samples={};r.decisionsBefore=#b.yingzhaoDecisionsByActor.wuyun
  while D.App.runningTime<finish do
   assert(b.phase=='playing'and b.gatherMode=='recover'and b:gatherActive(),'Recovery benefit ended before observation')
   for _,a in ipairs(b.learners)do
    assert(math.abs(a.student.x-at[a.character.id])<3,'Learned action walked out of recovery formation')
    if fixed then local legal,why=a:available('fmove');assert(not legal and why=='RECOVERY_FORMATION','Recovery allowed autonomous movement')end
   end
   r.samples[#r.samples+1]={at=D.App.runningTime,niX=b.arena.student.x,wuX=b.wuyun.student.x,niClip=b.arena.student.playable.current,wuClip=b.wuyun.student.playable.current}
   D.sleep(.02)
  end
  r.steps={};local shot,skill=0,0
  for i=first+1,#b.bossTrace.steps do local s=b.bossTrace.steps[i]
   if s.started>=arrived then r.steps[#r.steps+1]=s;if s.actor=='ninilite'and s.action=='shoot'then shot=shot+1 elseif s.actor=='wuyun'and s.action=='wind'then skill=skill+1 end end
  end
  r.shots=shot;r.skills=skill;r.decisionsAfter=#b.yingzhaoDecisionsByActor.wuyun
  assert((shot>0 and skill>0)==fixed,'Arrived basic/frozen policy execution mismatch')
  if fixed then
   assert(r.decisionsAfter>r.decisionsBefore,'Frozen policy did not run during recovery')
   -- A changed anchor must revoke the arrived policy window before regroup.
   b.mentor.x=b.mentor.x+120
   assert(not require('Combat.Formation').stationaryRecovery(b.wuyun,b,D.App.runningTime),'Stale anchor retained policy ownership')
   wait(function()return b.wuyun.regroupPlan==b.gatherPlan and not b.wuyun.regroupComplete end)
   assert(b.gatherUntil==deadline,'Replanning extended the finite recovery deadline')
   r.staleAnchorRevoked=true;r.deadlinePreserved=true
  end
  assert(original==D.json.encode({models,frozen},false,true));r.modelsUnchanged=true
  -- Observe the last scheduled release before withdrawing; a withdrawal's
  -- lawful cancellation of a pending bullet is a separate outcome.
  wait(function()return not b.arena:isAttacking()and not b.wuyun:isAttacking()end)
  r.shotEmissions=0
  for _,s in ipairs(r.steps)do if s.action=='shoot'then r.shotEmissions=r.shotEmissions+(s.emitted or 0)end end
  if fixed then assert(r.shotEmissions==shot,'Stationary shots did not reach their authored release points')end
  b:finish('aborted','Controlled recovery ownership complete');wait(function()return b.settled end)
  for _,s in ipairs(r.steps)do if s.action=='shoot'or s.action=='wind'then assert(s.ended and s.ended>=s.started+.8,'Stationary policy cut an authored attack')end end
  r.authoredActionsCompleted=true;r.phase=b.phase
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
