local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local report=assert(D.json.decode(D.Content:load('Docs/evidence/2026-10-05/part-q-adoption-result.json'),64))
  local policy={schemaVersion=1,purpose='part-target',partSetVersion=1,weapon='emp',enemyAsset='dataotie',characterId='ninilite',traceId='qa-trace-fallback',q=report.training.model}
  local T=require('Training.TargetTrace')
  local trace=assert(T.create(policy,{}, {model=policy,groups=report.comparison},report.training))
  assert(T.validate(trace,policy));r.legacy=true
  local round=trace.groups.candidate[1];local step=round.steps[1];local action=step.action
  local matched=0;for _,hit in ipairs(step.hits)do if hit.part==action.intendedPart then matched=matched+1 end end
  round.targeted=round.targeted-action.emitted;round.matched=round.matched-matched
  action.intendedPart='unknown';action.targetFallback='UNSEEN_STATE';round.fallback=action.emitted
  assert(T.validate(trace,policy));r.accounting=true
  round.fallback=0;assert(not T.validate(trace,policy));round.fallback=action.emitted
  action.targetFallback='ACTION_UNAVAILABLE';assert(not T.validate(trace,policy));action.targetFallback='UNSEEN_STATE'
  action.intendedPart='head';assert(not T.validate(trace,policy));r.tamperRejected=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil
 D.Content:save(root..'/Test/part-q-fallback-trace-result.json',D.json.encode(r))
end)
