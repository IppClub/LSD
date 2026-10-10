local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-q-action-audit-result.json';local r={status='RUNNING',actors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-q-supplied-trials-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-q%-supplied%-trials%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-q-action-audit-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local candidate=assert(require('Training.ResourceQStore').loadLatestAsync())
  local trials=assert(require('Training.ResourceQTrials').loadAsync(candidate.id));assert(#trials==2)
  local record;for _,entry in ipairs(trials)do if entry.record.mode=='evaluate'then record=entry.record end end;assert(record)
  local review=assert(require('Training.ResourceTraceReview').rebuild(record.trace,record.episode,record.status))
  local Q=require('Training.ResourceQ')
  for _,actor in ipairs({'ninilite','wuyun'})do
   local summary={shots=0,cost=0,zeroProgressShots=0,zeroProgressCost=0,knownExposedShots=0,negativeRewardShots=0,onlyKnownShooting=0,qShots=0,fallbackShots=0,unknownIdle=0}
   for i,t in ipairs(record.trace.actors[actor].steps)do
    local step=record.episode.steps[t.combatStep]
    if step and step.action.weapon=='emp'and(step.action.emitted or 0)>0 then
     local row=review.actors[actor].transitions[i];assert(row.combatStep==t.combatStep)
     summary.shots=summary.shots+step.action.emitted;summary.cost=summary.cost+row.cost
     local c=t.components
     if c.health==0 and c.armor==0 and c.breaks==0 and c.assistedHealth==0 then summary.zeroProgressShots=summary.zeroProgressShots+step.action.emitted;summary.zeroProgressCost=summary.zeroProgressCost+row.cost end
     if t.state.part_core=='exposed'and t.state.part_left=='exposed'and t.state.part_right=='exposed'and t.state.part_roots=='exposed'then summary.knownExposedShots=summary.knownExposedShots+step.action.emitted end
     if row.reward<0 then summary.negativeRewardShots=summary.negativeRewardShots+step.action.emitted end
     if t.decisionSource.reason=='Q_POLICY'then
      summary.qShots=summary.qShots+1
      local values=candidate.models[actor].values[assert(Q.key(t.state))];assert(values and values[t.action])
      local nonShoot=false
      for _,action in ipairs(t.actions)do if values[action]~=nil and not action:match('^shoot')then nonShoot=true end end
      if not nonShoot then summary.onlyKnownShooting=summary.onlyKnownShooting+1 end
      if values.idle==nil then summary.unknownIdle=summary.unknownIdle+1 end
     else summary.fallbackShots=summary.fallbackShots+1 end
    end
   end
   r.actors[actor]=summary
  end
  r.candidate=candidate.id;r.episode=record.episode.episode;r.note='Read-only diagnosis of emitted EMP actions; boss armor knowledge does not describe every small enemy.'
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
