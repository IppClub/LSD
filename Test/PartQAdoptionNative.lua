local script,characterId=...;characterId=characterId or 'ninilite'
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script))
local resultName=characterId=='ninilite' and 'part-q-adoption' or 'part-q-adoption-'..characterId
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/'..resultName..'-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local p=require('Training.PartPractice').createAsync(characterId);local a=p.arena
  local report,why=p:trainPartQAsync(12345);assert(report,why)
  assert(report.updates==36 and #report.rounds==3 and #p.demonstrations==0 and not p.adopted)
  local armor,breaks,emitted=0,0,0;local Q=require('Training.PartQ');local replay=Q.new(characterId)
  for _,round in ipairs(report.rounds)do
   assert(#round.steps==12 and round.steps[12].done and round.reason=='SHOT_BUDGET')
   for _,step in ipairs(round.steps)do
    assert(step.duration>0 and step.combatStep.action.controller=='part-qlearning' and step.combatStep.sealed)
    local expected=0;for _,hit in ipairs(step.combatStep.hits)do expected=expected+hit.credit.armor end
    assert(expected==step.components.armor)
    assert(step.state['part_'..step.action]~='blocked')
    armor=armor+expected;breaks=breaks+step.components.breaks;emitted=emitted+(step.combatStep.action.emitted or 0)
    assert(replay:update(step))
   end
  end
  for key,row in pairs(report.model.values)do for action,value in pairs(row)do assert(math.abs(replay.values[key][action]-value)<1e-9)end end
  assert(armor>0 and breaks>0 and emitted==36)
  assert(not require('Training.Model').validate(report.model),'Target Q accepted as action model')
  r.training=report;r.armor=armor;r.breaks=breaks;r.emitted=emitted;r.replayed=true
  assert(require('Training.PartQ').validate(report.model,characterId))
  assert(require('Training.PartQTrace').validate(report,report.model))
  local database=D.Content.writablePath..'/'..resultName..'.db';assert(not D.DB:existDB('lsd'))
  assert(D.DB:exec("ATTACH DATABASE '"..database.."' AS lsd")>=0)
  local store=assert(require('Training.TargetStore').open(characterId));store:load();p.store=store
  local old={schemaVersion=1,purpose='part-target',partSetVersion=1,weapon='emp',enemyAsset='dataotie',characterId=characterId,roundCount=1,
   tree={schemaVersion=1,featureSchemaVersion=4,actionSetVersion=1,characterId=characterId,sampleCount=6,trainingAccuracy=1,actions={'head'},rules={{conditions={},action='head'}}}}
  assert(store:saveAsync(old));p.adopted=old
  local candidate=p.candidate;assert(candidate.q and not p:adoptAsync())
  local evaluation,evalWhy=p:evaluateAsync();assert(evaluation,evalWhy);r.comparison=evaluation.groups
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_q_target BEFORE INSERT ON "..store.tableName:match("[^.]+$").." WHEN NEW.slot='main' BEGIN SELECT RAISE(ABORT,'QA failure'); END")>=0)
  local failed,reason=p:adoptAsync();assert(not failed and reason=='WRITE_FAILED',reason)
  assert(p.adopted==old and #D.DB:query('SELECT * FROM '..store.traceTable)==0)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_q_target')>=0)
  local adopted,adoptWhy=p:adoptAsync();assert(adopted,adoptWhy)
  assert(p.adopted==candidate and p.previous==old)
  assert(p:rollbackAsync() and p.adopted==old);assert(p:rollbackAsync() and p.adopted==candidate)
  assert(D.DB:exec('DETACH DATABASE lsd')>=0);assert(D.DB:exec("ATTACH DATABASE '"..database.."' AS lsd")>=0)
  local reloaded=assert(require('Training.TargetStore').open(characterId));local saved=assert(reloaded:load());local trace=assert(reloaded:loadTrace(saved.adopted))
  assert(trace.qTraining.updates==36 and saved.adopted.q.updates==36)
  local bad=D.json.decode(D.json.encode(trace),64);bad.qTraining.rounds[1].steps[1].reward=999
  assert(not require('Training.TargetTrace').validate(bad,saved.adopted))
  local beforeUpdates=saved.adopted.q.updates
  local part=require('Training.TargetPolicy').predict(saved.adopted,report.rounds[1].steps[1].state,function()return true end,characterId,'dataotie')
  assert(part and saved.adopted.q.updates==beforeUpdates)
  assert(#D.DB:query('SELECT * FROM '..store.traceTable)==1)
  r.adoption=true;r.rollback=true;r.traceReadback=true;r.atomicFailure=true;r.rewardTamperRejected=true;r.readOnlyInference=true
  -- Interrupt an in-flight episode; partial data must never become a candidate.
  D.thread(function()D.sleep(.2);p.cancelQ=true end)
  local cancelled=p:trainPartQAsync(77);assert(not cancelled and p.qPracticeReport.status=='CANCELLED' and p.adopted==candidate)
  assert(not p.evaluating and not p.partQTraining)
  r.cancelled=true;r.noSelfLabels=#p.demonstrations==0;p:close()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
