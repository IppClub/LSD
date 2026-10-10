local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-trial-motion-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local budget=assert(require('Economy.CombatSession').virtual('trial-motion',{{actor='wuyun',item='blade',quantity=1}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},budget,{virtual=true})
  D.sleep(.5)
  -- Synthetic frozen policy exercises execution continuity, not learning quality.
  local F=require('Training.YingzhaoFeatures');local state=b.observeYingzhao(b.arena.student);local q=require('Training.YingzhaoQ').new('ninilite',1,1)
  for _,band in ipairs({'near','mid','far'})do
   local fields={};for _,name in ipairs(F.fields(1))do fields[#fields+1]=(name=='targetDistance'or name=='bossDistance')and band or state[name]end
   q.values[table.concat(fields,'|')]={fmove=1};q.states=q.states+1;q.updates=q.updates+1
  end
  require('Training.YingzhaoTrial').attach(b,q:snapshot());assert(b:start());b.wuyun.mode='review';b.enemies[1].guard.nextAttack=math.huge
  local x=b.arena.student.x;D.sleep(.8)
  r.walkDistance=b.arena.student.x-x
  r.continued=0;for _,d in ipairs(b.yingzhaoCandidateDecisions)do if d.reason=='CONTINUED'then r.continued=r.continued+1 end end
  assert(r.continued>=1 and r.walkDistance>140,'Frozen walking was interrupted')
  r.virtualFallbacks=0;for _,d in ipairs(b.yingzhaoCandidateDecisions)do if d.fallback then r.virtualFallbacks=r.virtualFallbacks+1 end end
  assert(r.virtualFallbacks==0,'Virtual candidate silently used formal basic fallback')
  b.arena.student.x=2250;b.mentor.x=1400;b.wuyun.student.x=1550
  local boss=b.enemies[1];assert(boss.guard:attack('massive',b.arena.student))
  local K=require('Combat.Displacement');local deadline=D.App.runningTime+10
  while not K.blocked(b.arena.student)do assert(D.App.runningTime<deadline,'No real launch');D.sleep(.01)end
  local launched=b.arena.student.x;D.sleep(.3)
  r.launchTravel=math.abs(b.arena.student.x-launched);r.velocity=math.abs(b.arena.student.velocityX)
  assert(r.launchTravel>150 and r.velocity>500,'Candidate cancelled physical knockback')
  while boss.guard.busy do assert(D.App.runningTime<deadline);D.sleep(.02)end;boss.guard.nextAttack=math.huge
  r.blockedSpellChecks=0
  while K.blocked(b.arena.student)do
   assert(D.App.runningTime<deadline,'Recovery never finished')
   if b.arena.student.onSurface then
    local phase=K.snapshot(b.arena.student).phase
    local accepted,why=b.magic:request('fire')
    assert(not accepted and why=='DISPLACED','Spell command interrupted '..phase)
    assert(not b.arena.student:start(b.magic.actions.fire),'Direct spell action bypassed recovery guard')
    r.blockedSpellChecks=r.blockedSpellChecks+1
   end
   D.sleep(.02)
  end
  assert(r.blockedSpellChecks>0,'No grounded recovery spell checks')
  assert(b.magic:request('fire'),'Spell did not unlock after recovery')
  local castDeadline=D.App.runningTime+5
  while b.magic:busy('fire')do assert(D.App.runningTime<castDeadline,'Spell did not complete');D.sleep(.02)end
  assert(b.magic.logs[#b.magic.logs].releaseAt and b.magic.logs[#b.magic.logs].completedAt,'Recovered spell missed release/completion')
  assert(b.arena.studentHP<100)
  local phases=boss.guard.strike.displacements[1].reactions;r.phases=phases
  assert(#phases>=3 and phases[1].name=='hit'and phases[2].name=='fall'and phases[3].name=='standUp')
  for _,p in ipairs(phases)do assert(p.completed and p.completed>=p.started+p.duration-.1,'Reaction animation interrupted')end
  b:finish('aborted','Frozen motion fixture');r.realMassive=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
