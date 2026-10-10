local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/part-q-wuyun-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local p=require('Training.PartPractice').createAsync('wuyun');local a=p.arena
  local report,why=p:trainPartQAsync(12345);assert(report,why)
  assert(report.updates==36 and #report.rounds==3 and #p.demonstrations==0 and not p.adopted)
  local armor,breaks,emitted=0,0,0;local Q=require('Training.PartQ');local replay=Q.new('wuyun')
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
  -- Interrupt an in-flight episode; partial data must never become a candidate.
  D.thread(function()D.sleep(.2);p.cancelQ=true end)
  local cancelled=p:trainPartQAsync(77);assert(not cancelled and p.qPracticeReport.status=='CANCELLED' and not p.adopted)
  assert(not p.evaluating and not p.partQTraining)
  r.cancelled=true;r.noSelfLabels=#p.demonstrations==0;p:close()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
