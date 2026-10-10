-- Real saved budget/consumption/transaction UI. Outcome is a failure fixture;
-- this is not a natural Boss victory or a real OS input acceptance run.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-settlement-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  local db=D.Content.writablePath..'/big-yingzhao-settlement-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local service=assert(require('Mission.Service').open());local models=assert(require('Training.FlowerPractice').models());local formation=assert(service:formation())
  local E=require('Economy.Store');assert(E.open());local initial=E.wallet().available
  local L=require('Economy.Loadout');local values=L.defaults();values['mentor:kinetic']=3;values['ninilite:emp']=2;values['wuyun:emp']=0;values['wuyun:blade']=2;assert(L.saveAsync(values))
  local function wait(fn)local stop=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<stop,'Settlement timeout');D.sleep(.02)end end
  local supplies=assert(L.forMission('c0-yingzhao',formation));local attempt=assert(service:beginAsync('c0-yingzhao',models,formation,supplies))
  local c=require('Ground.BigYingzhaoLevel').openAsync(service,attempt);c.withdraw:emit('Tapped');wait(function()return c.phase=='result'end)
  assert(c.result.resultLayout=='MissionFail'and c.battle.report.economy.cost==6 and E.wallet().available==initial-6);r.withdrawCost=6
  local episode=assert(require('Training.CombatStore').load(attempt.id));assert(episode.boss.status=='aborted'and not episode.trainable)
  local balance=E.wallet().available;assert(service:finishAsync(attempt,'aborted',c.battle.report,episode));assert(E.wallet().available==balance);r.idempotent=true
  c.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=c.battle.world end)
  supplies=assert(L.forMission('c0-yingzhao',formation));attempt=assert(service:beginAsync('c0-yingzhao',models,formation,supplies))
  c=require('Ground.BigYingzhaoLevel').openAsync(service,attempt);local b=c.battle;c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  b.enemies[1].guard.nextAttack=math.huge
  for _,a in ipairs(b.learners)do a.mode='review';a.nextDecision=math.huge end
  D.sleep(.5);assert(b:command('shoot'));wait(function()return not b.mentor:isDoing('groundMentorShot')and next(b.bossCombat.shots)==nil end)
  assert(b.supplies.emissions==1 and #b.bossTrace.hits==1)
  b.enemies[1].enemy.playable.speed=0;b.arena.mode='demo'
  assert(require('Training.YingzhaoActions').request(b,b.arena,'shoot@head','test'))
  wait(function()return not b.arena:isAttacking()and next(b.bossCombat.shots)==nil end)
  assert(b.supplies.emissions==2 and #b.bossTrace.hits==2 and b.bossTrace.hits[2].part=='head')
  assert(D.DB:exec("CREATE TRIGGER lsd.reject_big_boss_result BEFORE UPDATE OF status ON Game0MissionAttempts BEGIN SELECT RAISE(ABORT,'settlement QA'); END")>=0)
  b:finish('failed','失败结算保存测试');wait(function()return c.phase=='save-error'end)
  assert(not c.result.baseButton.visible);local reserved=E.wallet().available
  assert(D.DB:exec('DROP TRIGGER lsd.reject_big_boss_result')>=0);c.result.againButton:emit('Tapped');wait(function()return c.phase=='result'end)
  assert(c.result.resultLayout=='MissionFail'and b.report.economy.cost==12 and b.report.economy.income==0 and E.wallet().available==initial-18)
  episode=assert(require('Training.CombatStore').load(attempt.id));assert(episode.boss.hits[1].healthDamage==2.25)
  local fake=D.json.decode(D.json.encode(episode),32);fake.boss.status='won';assert(not require('Enemy.BigYingzhaoEvidence').validate(fake),'Empty victory accepted')
  fake=D.json.decode(D.json.encode(episode),32);fake.boss.hits[1].healthDamage=999;assert(not require('Enemy.BigYingzhaoEvidence').validate(fake),'Forged damage accepted')
  fake=D.json.decode(D.json.encode(episode),32);fake.boss.hits[1].step=999;assert(not require('Enemy.BigYingzhaoEvidence').validate(fake),'Unpaid damage accepted')
  local aimStep
  for i,step in ipairs(episode.boss.steps)do if step.aim then aimStep=i end end
  assert(aimStep,'Saved aim missing')
  fake=D.json.decode(D.json.encode(episode),32);fake.boss.steps[aimStep].velocity.x=-fake.boss.steps[aimStep].velocity.x
  assert(not require('Enemy.BigYingzhaoEvidence').validate(fake),'Forged saved aim accepted')
  r.aimPersisted=true
  balance=E.wallet().available;assert(service:finishAsync(attempt,'failed',b.report,episode));assert(E.wallet().available==balance)
  r.atomicRetry=true;r.failed={cost=b.report.economy.cost,refund=b.report.economy.refund,balance=balance,reservedDuringFailure=reserved};r.invalidRejected=true
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-failed-settlement.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
