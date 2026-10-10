local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-execution-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local db=D.Content.writablePath..'/disarm-execution-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd'));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config')
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Training.DisarmPractice').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},{{actor='ninilite',item='emp',quantity=3},{actor='wuyun',item='emp',quantity=2}})
  local function wait(fn)local stop=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<stop,'Execution timeout');D.sleep(.02)end end
  assert(b:start());for _,a in ipairs(b.learners)do a.nextDecision=math.huge end;b.enemies[1].guard.nextAttack=math.huge;b.enemies[1].guard.update=function()end
  wait(function()return b.arena.student.onSurface and b.wuyun.student.onSurface end)
  b.arena.student.x=1200;b.enemies[1].enemy.x=3300
  local trace=b.disarmTrace
  assert(b.arena.beginCombatAction(b.mentor,'mentor')==nil and #trace.executions==0,'Mentor shot mislabelled as learner')
  assert(b.arena:request('laser','model'));local shot=trace.executions[#trace.executions];assert(shot.action=='laser'and shot.source=='model')
  wait(function()return shot.outcome~='running'end);assert(shot.outcome=='completed'and shot.duration>.1 and shot.after.at>=shot.before.at)
  local emission;for _,row in ipairs(trace.consumption)do if row.owner=='ninilite'then emission=row end end
  assert(emission and emission.step==shot.id and emission.at>=shot.startedAt and emission.at<=shot.endedAt)
  wait(function()return #trace.impacts>0 end)
  local impact=trace.impacts[1];assert(impact.step==shot.id and impact.actor=='ninilite'and impact.damage==20 and impact.at>shot.endedAt,'Late damage lost original action')
  assert(trace.projectiles[1].outcome=='contact' and trace.projectiles[1].step==shot.id)
  -- Isolate lifetime expiry with a native projectile whose collision mask is empty.
  local observe=b.arena.observeProjectile
  b.arena.observeProjectile=function(bullet,source,step)observe(bullet,source,step);bullet.targetAllow=D.Platformer.TargetAllow():toValue()end
  assert(b.arena:request('laser','model'));local missed=trace.executions[#trace.executions]
  wait(function()return #trace.projectiles==2 and trace.projectiles[2].outcome~='flying'end)
  assert(trace.projectiles[2].outcome=='removed'and trace.projectiles[2].flightSeconds>=.9 and trace.projectiles[2].step==missed.id and #trace.impacts==1,'Expired bullet gained a hit')
  wait(function()return missed.outcome~='running'end)
  b.arena.observeProjectile=function(bullet,source,step)observe(bullet,source,step);D.thread(function()D.sleep(.02);bullet:removeFromParent()end)end
  assert(b.arena:request('laser','model'))
  wait(function()return #trace.projectiles==3 and trace.projectiles[3].outcome~='flying'end)
  assert(trace.projectiles[3].outcome=='removed' and trace.projectiles[3].flightSeconds<.1 and #trace.impacts==1,'Early removal counted as expired or hit')
  b.arena.observeProjectile=observe;r.earlyRemoval=trace.projectiles[3]
  r.lateImpact=impact;r.expired=trace.projectiles[2]
  assert(b.wuyun:request('fmove','baseline'));local move=trace.executions[#trace.executions];D.sleep(.3);b.wuyun.student:stop();assert(move.outcome=='stopped'and move.duration>=.25 and move.after.x~=move.before.x)
  assert(b.wuyun:request('laser','model'));local interrupted=trace.executions[#trace.executions];b.wuyun.student:stop();D.sleep(.05);assert(interrupted.outcome=='interrupted');assert(b.supplies.ledger.stock['wuyun:emp'].used==0)
  assert(b.wuyun:request('laser','model')==false,'Interrupted shot bypassed cooldown')
  local n=#trace.executions;assert(not b.arena:request('invalid','model'));assert(#trace.executions==n,'Rejected command became execution')
  assert(b:finish('aborted','执行区间专项结束'));wait(function()return trace.sourceSaveState=='saved'or trace.sourceSaveState=='failed'or trace.sourceSaveState=='rejected'end)
  assert(trace.sourceSaveState=='saved',trace.sourceSaveError);local loaded=assert(require('Training.DisarmStore').loadLatestAsync());assert(loaded.source.trace.impactVersion==1 and #loaded.source.trace.impacts==1 and #loaded.source.trace.projectiles==3);assert(loaded.source.trace.executionVersion==1 and #loaded.source.trace.executions==#trace.executions)
  for _,row in ipairs(loaded.source.trace.executions)do assert(row.outcome~='running'and row.duration>=0)end
  r.executionCount=#trace.executions;r.shot=shot;r.movement=move;r.interrupted=interrupted;r.archived=true;r.rejectionExcluded=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
