local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-trace-review-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-team-native-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-team%-native%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-trace-review-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local P=require('Training.FlowerPractice');local sources=assert(P.teamSources());local equal=require('Training.FlowerIdentity').equal
  local c=P.openAsync(nil,'ninilite',nil,nil,nil,'far',sources);D.sleep(.3)
  c.arena.studentEnergy=60;c.arena.initialEnergy=60
  local trace=require('Training.FlowerDecisionTrace').attach(c.battle);c.trialButton:emit('Tapped')
  local start=D.App.totalTime
  while c.battle.phase=='playing' and D.App.totalTime-start<150 do D.sleep(.1)end
  assert(c.battle.phase~='playing','Timed out');local deadline=D.App.totalTime+20
  while not c.result do assert(D.App.totalTime<deadline and c.battle.phase~='save-error');D.sleep(.02)end
  assert(trace.closed and trace.trainable);r.battleStatus=trace.status
  local episode=c.battle.combatEpisode;local evaluation=assert(require('Training.FlowerEvaluation').build(episode));r.actors={};r.delayedCredits=0;r.delayedAssists=0
  local byAttack={}
  for id,actor in pairs(trace.actors)do
   assert(#actor.steps>1);local totals={health=0,armor=0,breaks=0,assistedHealth=0,friendlyDamage=0,damageTaken=0,healing=0,shots=0}
   for i,row in ipairs(actor.steps)do
    assert(row.sealed and row.duration>0 and row.finished-row.started==row.duration)
    assert(require('Training.FlowerFeatures').validate(row.state) and require('Training.FlowerFeatures').validate(row.nextState))
    if i>1 then local previous=actor.steps[i-1];assert(equal(previous.nextState,row.state) and equal(previous.nextActions,row.actions) and previous.finished==row.started)end
    local legal=false;for _,action in ipairs(row.actions)do if action==row.action then legal=true end end;assert(legal)
    if i==#actor.steps then assert(row.done and #row.nextActions==0)else assert(not row.done and #row.nextActions>0)end
    local step=episode.steps[row.combatStep];assert(step.action.actor==id)
    for _,hit in ipairs(step.hits)do byAttack[hit.attackId]=row;if hit.credit and hit.credit.at>row.finished then r.delayedCredits=r.delayedCredits+1 end end
    for k in pairs(totals)do totals[k]=totals[k]+row.components[k]end
   end
   for _,key in ipairs({'health','armor','breaks','assistedHealth','friendlyDamage','shots'})do assert(math.abs(totals[key]-evaluation.actors[id][key])<1e-6,id..':'..key)end
   assert(math.abs(totals.damageTaken-(evaluation.actors[id].damageTaken-actor.steps[1].before.damage))<1e-6)
   assert(math.abs(totals.healing-(evaluation.actors[id].healing-actor.steps[1].before.healing))<1e-6)
   r.actors[id]={steps=#actor.steps,totals=totals}
  end
  for _,step in ipairs(episode.steps)do for _,hit in ipairs(step.hits)do local assist=hit.credit and hit.credit.assist
   if assist and byAttack[assist.attackId] and hit.credit.at>byAttack[assist.attackId].finished then r.delayedAssists=r.delayedAssists+1 end
  end end
  assert(trace.unassignedAssists==0);assert(r.delayedAssists>0,'No delayed collaboration observed')
  D.Content:save(root..'/Docs/evidence/2026-10-05/flower-trace-review-trace.json',D.json.encode(trace,false,true))
  r.continuousActorBoundaries=true;r.rewardLedgerMatches=true
  local Review=require('Training.FlowerTraceReview');local rebuilt,why=Review.rebuild(trace,episode,trace.status);assert(rebuilt,why)
  local energy=0;local spent=0;for _,row in ipairs(trace.actors.ninilite.steps)do energy=energy+row.components.energy;spent=spent+row.components.supportSpent end
  assert(energy>0 and energy<=60 and math.abs(energy-(60-c.arena.studentEnergy))<1e-6 and spent>0)
  r.energySpent=energy;r.supportSpent=spent;r.rebuilt=true
  local function copy(x)return D.json.decode(D.json.encode(x,false,true),32)end
  assert(Review.rebuild(copy(trace),copy(episode),trace.status));r.jsonRoundtrip=true
  local bad=copy(trace);bad.actors.ninilite.steps[1].reward=bad.actors.ninilite.steps[1].reward+1;assert(not Review.rebuild(bad,episode,trace.status))
  bad=copy(trace);bad.actors.ninilite.steps[1].components.health=999;assert(not Review.rebuild(bad,episode,trace.status))
  bad=copy(trace);bad.actors.ninilite.steps[2].state.health='fallen';assert(not Review.rebuild(bad,episode,trace.status))
  bad=copy(trace);bad.resources[1].used=bad.resources[1].used+.1;assert(not Review.rebuild(bad,episode,trace.status))
  bad=copy(trace);bad.actors.ninilite.steps[1].after.events=999999;assert(not Review.rebuild(bad,episode,trace.status))
  assert(not Review.rebuild(trace,episode,'aborted'));r.tamperingRejected=true
  local Q=require('Training.FlowerQ');local models,why=Q.learn(trace,episode,trace.status);assert(models,why);r.updates={}
  for _,id in ipairs({'ninilite','wuyun'})do assert(Q.restore(models[id],id));assert(models[id].updates==#trace.actors[id].steps);r.updates[id]=models[id].updates end
  assert(equal(models,assert(Q.learn(copy(trace),copy(episode),trace.status))));r.deterministicLearning=true

  -- Explicitly aborted practice must not produce training-ready transitions.
  c=P.openAsync(nil,'ninilite',nil,nil,nil,'field',sources);D.sleep(.2);local aborted=require('Training.FlowerDecisionTrace').attach(c.battle)
  c.trialButton:emit('Tapped');D.sleep(1);c.finishButton:emit('Tapped');assert(aborted.closed and not aborted.trainable and aborted.status=='aborted');r.abortExcluded=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
