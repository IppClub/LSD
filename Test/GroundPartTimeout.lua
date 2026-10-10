local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/ground-part-timeout-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local model={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId='ninilite',sampleCount=6,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}
  local b=require('Ground.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m02',model=model})
  b.arena.externalCombat=true -- stationary target fixture for projectile expiry, not balance
  local started=D.App.runningTime
  while b.phase=='playing' or b.phase=='saving'do
   assert(D.App.runningTime-started<80,'Battle timeout')
   if b.phase=='playing' and b.mentor.onSurface and D.App.runningTime>=b.nextMentorShot then b.mentor.faceRight=false;if b.mentorAim:begin()then D.sleep(.03);b.mentorAim:release()end end
   D.sleep(.1)
   r.seconds=D.App.runningTime-started;r.phase=b.phase;r.hp=b.arena.enemyHP;r.learnerHP=b.arena.studentHP;r.mentorHP=b.mentorHP;r.hits=#b.partCombat.events;save()
  end
  r.events=b.partCombat.events;r.result=b.report
  assert(b.phase=='failed' and r.seconds>=74,b.reason);assert(b.arena.enemyHP==b.arena.enemyMaxHP and #r.events==0,'Backward shots damaged boss')
  local sources={};for _,e in ipairs(r.events)do sources[e.source]=true;assert(e.healthDamage==e.hpBefore-e.hpAfter and e.armorDamage==e.apBefore-e.apAfter)end
  assert(b.partCombat.closed and #b.partCombat.shots==0);r.failureCleaned=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
