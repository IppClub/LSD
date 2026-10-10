-- Same ledger and continuous HP/armor, alternating actual shots and dodges.
-- Boss attacks are cued by this QA fixture. Return-to-position movement is
-- scripted (excluded from demonstrations), never fabricated human input.
local D=require('Dora');local entry,qaResultName=...;local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'yingzhao-wuyun-alternating-result.json');local r={status='RUNNING',cycles={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor='wuyun',item='emp',quantity=5}},'wuyun')
  local a=b.wuyun;local boss=b.enemies[1];local A=require('Training.YingzhaoActions');local F=require('Training.YingzhaoFeatures')
  local update=boss.guard.update;boss.guard.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
  assert(b:start());boss.guard.nextAttack=math.huge;b.arena.mode='review';b.mentor.x=3300;b.arena.student.x=3200
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Alternating lesson timeout');D.sleep(.02)end end
  D.sleep(.5)
  for i=1,5 do
   -- Walk back with an explicitly non-demonstration source; no teleports,
   -- replenishment, HP/AP resets or changes to the real attack timeline.
   if a.student.x<boss.enemy.x-700 then
    assert(A.request(b,a,'fmove','scripted'))
    wait(function()return a.student.x>=boss.enemy.x-700 end);a.student:stop()
   end
   wait(function()return a:available('laser')and not boss.guard.reacting end)
   local observed=b.observeYingzhao(a.student);local chosen
   for _,part in ipairs({'head','forelegs','arms','hindlegs','torso','flank'})do
    if observed['part_'..part]~='exposed'and A.plan(b,a,part)then chosen=part;break end
   end
   r.preShot={x=a.student.x,bossX=boss.enemy.x,observation=observed};save();assert(chosen,'No reachable armored part for actual shot')
   assert(b:command('aim-part',chosen));assert(b:command('shoot'))
   wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor('wuyun')and not boss.guard.reacting end)
   assert(boss.guard:attack('wave',a.student));D.sleep(.1)
   assert(b:command('left'))
   wait(function()return not boss.guard.busy end);boss.guard.nextAttack=math.huge;a.student:stop()
   assert(a.studentHP==100,'Alternating lesson did not evade wave')
   r.cycles[#r.cycles+1]={part=chosen,ammo=observed.empAmmo,remaining=b.supplies:observation('wuyun').ammo.emp,hp=a.studentHP};save()
  end
  b:finish('aborted','Alternating QA lesson');wait(function()return b.phase=='aborted'end)
  local resources=b.supplies:evidence();b.bossTrace.resources=resources
  local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='wuyun',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
  r.hitParts={};r.armorDamage=0
  for _,hit in ipairs(e.boss.hits)do r.hitParts[hit.part]=(r.hitParts[hit.part]or 0)+1;r.armorDamage=r.armorDamage+hit.armorDamage end
  local P=require('Training.YingzhaoPolicy');local data=assert(P.inspect({e},'wuyun'));assert(#data.samples==10 and not data.actions.fmove,'Scripted return leaked into teaching')
  local coverage={};for _,s in ipairs(data.samples)do local group=s.action=='bmove'and'dodge'or'shot';coverage[group]=coverage[group]or{};coverage[group][s.state.empAmmo]=true end
  assert(coverage.dodge.ready and coverage.dodge.low and coverage.shot.ready and coverage.shot.low,'Ammo still separates attack and dodge')
  local m=assert(P.buildAsync({e},'wuyun'));r.model=m;r.source=e;r.coverage=coverage;r.samples=#data.samples;save()
  -- Predictions use real sampled observations, not hand-written rules.
  local matched=0
  for _,step in ipairs(e.boss.steps)do if step.origin=='demo'and step.action=='bmove'then
   assert(P.predict(m,step.before,function()return true end)=='bmove','Actual wave sample was not learned');matched=matched+1
  end end
  assert(matched==5);r.actualShots=b.supplies.emissions;r.notNaturalVictory=true;r.notHumanDemonstration=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
