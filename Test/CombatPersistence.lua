local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/combat-persistence-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local model={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId='ninilite',sampleCount=6,trainingAccuracy=1,actions={'laser'},rules={{conditions={},action='laser'}}}
  local db=D.Content.writablePath..'/combat-persistence.db'
  assert(not D.Content:exist(db) and not D.DB:existDB('lsd'))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local service=assert(require('Mission.Service').open())
  assert(D.DB:exec("INSERT INTO lsd.Game0MissionAttempts VALUES (1,'c0-m02','active','{}',NULL)")>=0)
  assert(D.DB:exec("CREATE TABLE lsd.Game0Training(slot TEXT PRIMARY KEY,payload TEXT)")>=0)
  assert(D.DB:exec("INSERT INTO lsd.Game0Training VALUES ('main','existing-model-sentinel')")>=0)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_episode BEFORE INSERT ON Game0CombatEpisodes BEGIN SELECT RAISE(ABORT,'QA episode write failure'); END")>=0)
  local b=require('Ground.Battle').createAsync(service,{id=1,mission='c0-m02',model=model})
  local started=D.App.runningTime
  while b.phase=='playing' or b.phase=='saving'do
   assert(D.App.runningTime-started<80,'Battle timeout')
   if b.phase=='playing' and b.mentor.onSurface and D.App.runningTime>=b.nextMentorShot then b:command('shoot')end
   D.sleep(.1)
   r.seconds=D.App.runningTime-started;r.phase=b.phase;r.hp=b.arena.enemyHP;r.learnerHP=b.arena.studentHP;r.mentorHP=b.mentorHP;r.hits=#b.partCombat.events;save()
  end
  r.events=b.partCombat.events;r.result=b.report
  assert(b.phase=='save-error' and b.pendingStatus=='won','Fault was not propagated')
  assert(D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=1')[1][1]=='active')
  assert(#D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')==0 and #D.DB:query('SELECT * FROM lsd.Game0CombatEpisodes')==0)
  D.DB:exec('DROP TRIGGER lsd.fail_episode');b:saveResult()
  while b.saving do D.sleep(.01)end
  assert(b.phase=='won',b.saveError)
  local loaded=assert(require('Training.CombatStore').load(1))
  local function equal(a,c,path)
   assert(type(a)==type(c),'Type mismatch '..path)
   if type(a)=='table'then for k,v in pairs(a)do equal(v,c[k],path..'.'..tostring(k))end;for k in pairs(c)do assert(a[k]~=nil,'Extra field '..path..'.'..tostring(k))end
   elseif type(a)=='number'then assert(math.abs(a-c)<.00000001,'Number mismatch '..path)
   else assert(a==c,'Value mismatch '..path)end
  end
  equal(loaded,b.combatEpisode,'episode')
  assert(loaded.versions.credit==1)
  local credited=0
  for _,step in ipairs(loaded.steps)do for _,hit in ipairs(step.hits)do assert(hit.credit and not hit.creditError);credited=credited+1 end end
  assert(credited==#r.events);r.creditsRoundTripped=credited
  assert(service:finishAsync(b.attempt,'won',b.report,b.combatEpisode))
  assert(#D.DB:query('SELECT * FROM lsd.Game0CombatEpisodes')==1)
  assert(#D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')==1)
  assert(D.DB:query('SELECT payload FROM lsd.Game0Training')[1][1]=='existing-model-sentinel')
  assert(not require('Training.CombatStore').load(999));r.phase=b.phase;r.atomicRollback=true;r.retryOnce=true;r.modelsUntouched=true
  D.DB:exec('DETACH DATABASE lsd')
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  assert(require('Training.CombatStore').load(1));r.reopened=true
  D.DB:exec('DETACH DATABASE lsd')
  local sources={};for _,e in ipairs(r.events)do sources[e.source]=true;assert(e.healthDamage==e.hpBefore-e.hpAfter and e.armorDamage==e.apBefore-e.apAfter)end
  assert(sources.learner and sources.mentor and sources.rescue,'Missing combat participant')
  r.allThreeSources=true
  local sampled=0;local steps=b.partCombat.journal.steps
  for _,step in ipairs(steps)do sampled=sampled+#step.hits;assert(step.observation and not step.observation.hits)end
  assert(sampled==#r.events,'Lost hit attribution');assert(steps[1].observation.observedPart=='unknown')
  r.journal={steps=#steps,hits=sampled,closed=b.partCombat.journal.closed};assert(r.journal.closed)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
