local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/ground-part-q-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  assert(not D.DB:existDB('lsd'))
  assert(D.DB:exec("ATTACH DATABASE '"..D.Content.writablePath.."/deployed-q.db' AS lsd")>=0)
  local store=assert(require('Training.TargetStore').open('ninilite'));local saved=assert(store:load());assert(saved.adopted.q)
  local updates=saved.adopted.q.updates
  local model={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId='ninilite',sampleCount=6,trainingAccuracy=1,actions={'laser'},rules={{conditions={},action='laser'}}}
  local b=require('Ground.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m02',model=model})
  assert(b.partCombat.policy and b.partCombat.policy.traceId==saved.adopted.traceId)
  local started=D.App.runningTime
  while b.phase=='playing' or b.phase=='saving'do
   assert(D.App.runningTime-started<80,'Battle timeout')
   if b.phase=='playing' and b.mentor.onSurface and D.App.runningTime>=b.nextMentorShot then b:command('shoot')end
   D.sleep(.1)
   r.seconds=D.App.runningTime-started;r.phase=b.phase;r.hp=b.arena.enemyHP;r.learnerHP=b.arena.studentHP;r.mentorHP=b.mentorHP;r.hits=#b.partCombat.events;save()
  end
  r.events=b.partCombat.events;r.result=b.report
  assert(b.phase=='won',b.reason)
  local sources={};for _,e in ipairs(r.events)do sources[e.source]=true;assert(e.healthDamage==e.hpBefore-e.hpAfter and e.armorDamage==e.apBefore-e.apAfter)end
  assert(sources.learner and sources.mentor and sources.rescue,'Missing combat participant')
  r.allThreeSources=true
  assert(b.partCombat.policy.q.updates==updates and store:load().adopted.q.updates==updates)
  r.targetUnavailable=b.arena.metrics.targetUnavailable;r.targetFallback=b.arena.metrics.targetFallback;r.policyReadOnly=true
  local hp,ap,breaks,assists=0,0,0,0
  for _,e in ipairs(r.events)do
   assert(e.credit and not e.creditError,'Missing authoritative credit')
   local c=e.credit;hp=hp+c.health;ap=ap+c.armor;breaks=breaks+c.breaks
   if e.source=='learner'then assert(c.actor=='ninilite' and c.health==0)end
   if e.source=='mentor'then assert(c.actor=='mentor')end
   if e.source=='rescue'then assert(c.actor=='wuyun')end
   if c.assist then assert(c.assist.actor~=c.actor and c.assist.health<=c.health and e.apBefore==0);assists=assists+1 end
  end
  assert(math.abs(hp-b.arena.enemyMaxHP)<1e-6 and ap<=460 and breaks<=6)
  r.credit={hp=hp,ap=ap,breaks=breaks,assists=assists,actors=b.partCombat.credits:snapshot().actors}
  local snapshot=b.partCombat.journal:snapshot()
  assert(require('Training.CombatStore').validate(snapshot),'Credit persistence contract rejected')
  local sampled=0;local steps=b.partCombat.journal.steps
  for _,step in ipairs(steps)do sampled=sampled+#step.hits;assert(step.observation and not step.observation.hits)end
  assert(sampled==#r.events,'Lost hit attribution');assert(steps[1].observation.observedPart=='unknown')
  r.journal={steps=#steps,hits=sampled,closed=b.partCombat.journal.closed};assert(r.journal.closed)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
