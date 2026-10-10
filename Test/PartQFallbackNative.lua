local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/part-q-fallback-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local p=require('Training.PartPractice').createAsync('ninilite');local a=p.arena
  local Q=require('Training.PartQ');local P=require('Training.TargetPolicy')
  local q=Q.new('ninilite');local s={distance=500,facing='no',enemyAction='idle',attackReady='yes'}
  assert(q:update({state=s,action='head',reward=1,duration=1,done=true,sealed=true}))
  local candidate={schemaVersion=1,purpose='part-target',partSetVersion=1,weapon='emp',enemyAsset='dataotie',characterId='ninilite',traceId='qa-fallback',q=q:snapshot()}
  assert(P.validate(candidate));p.candidate=candidate
  local _,why,fallback=P.resolve(candidate,s,function(id)return id~='head'end,'ninilite','dataotie')
  assert(why=='UNSEEN_ACTIONS' and fallback)
  local _,blocked,blockedFallback=P.resolve(candidate,s,function()return false end,'ninilite','dataotie')
  assert(blocked=='ACTION_UNAVAILABLE' and not blockedFallback)
  local _,wrong,wrongFallback=P.resolve(candidate,s,function()return true end,'wuyun','dataotie')
  assert(wrong=='INCOMPATIBLE_CHARACTER' and not wrongFallback)
  local _,_,invalidFallback=P.resolve(nil,s,function()return true end);assert(not invalidFallback)
  local evaluation=assert(p:evaluateAsync());local n=0
  for _,round in ipairs(evaluation.groups.candidate)do
   assert(round.emitted==6 and round.fallback==6 and round.targeted==0 and round.matched==0)
   for _,step in ipairs(round.steps)do assert(step.action.targetFallback=='UNSEEN_STATE' and step.action.intendedPart=='unknown');n=n+1 end
  end
  assert(n==18 and candidate.q.updates==1 and #p.demonstrations==0)
  -- Exercise the production model-action hook, not just the trial button.
  a:beginDemo(550);D.sleep(.2)
  while not a:available('laser')do D.sleep(.02)end
  p.partCombat.policy=candidate
  assert(a:request('laser','model'))
  while a:isAttacking() or #p.partCombat.shots>0 do D.sleep(.02)end
  local step=p.partCombat.journal.steps[#p.partCombat.journal.steps]
  assert(step.action.emitted==1 and step.action.targetFallback=='UNSEEN_STATE' and step.action.intendedPart=='unknown')
  assert(a.metrics.targetFallback==1)
  r.comparison=evaluation.groups;r.productionStep=step;r.readOnly=true;r.coverageFallback=true;r.blockedRejected=true;r.invalidRejected=true
  p:close()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
