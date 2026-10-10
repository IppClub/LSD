-- Actual scripted QA demonstrations, not player input or a natural victory.
local D=require('Dora');local entry,qaResultName=...;local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'yingzhao-wave-reach-result.json');local r={status='RUNNING',actors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local F=require('Training.YingzhaoFeatures');local P=require('Training.YingzhaoPolicy')
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Wave reach lesson timeout');D.sleep(.02)end end
  -- Archived observations cannot reveal the historical travelling front.
  local old=D.json.decode(D.Content:load(root..'/Test/yingzhao-alternating-result.json'),32)
  assert(old.status=='PASS');local archived=old.source.boss.steps[1].before
  assert(archived.featureSchemaVersion==2 and F.validate(archived))
  assert(F.project(archived,3).waveReach=='unknown')
  assert(F.key(archived,2)==table.concat((function()local values={};for _,n in ipairs(F.fields(2))do values[#values+1]=archived[n]end;return values end)(),'|'))
  for _,actor in ipairs({'ninilite','wuyun'})do
   local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor=actor,item='emp',quantity=6}},actor)
   local a=actor=='ninilite'and b.arena or b.wuyun;local other=actor=='ninilite'and b.wuyun or b.arena
   local boss=b.enemies[1];assert(b:start());boss.guard.nextAttack=math.huge;other.mode='review'
   local row={cycles={}};r.actors[actor]=row
   for i=1,3 do
    wait(function()return not boss.guard.busy and not boss.guard.reacting and not a:isAttacking()and not b.bossCombat:pendingActor(actor)end)
    boss.guard.nextAttack=math.huge
    a.student:stop();a.student.velocity=D.Vec2.zero;a.student.position=D.Vec2(1020,b.world.offset+155)
    boss.enemy:stop();boss.enemy.velocity=D.Vec2.zero;boss.enemy.position=D.Vec2(1920,b.world.offset+255)
    b.mentor.x=3100;other.student.x=3200;D.sleep(.3)
    assert(boss.guard:attack('wave',a.student));D.sleep(.1)
    local near=b.observeYingzhao(a.student);assert(F.validate(near)and near.threat=='wave'and near.waveReach=='approaching')
    assert(b:command('left'))
    wait(function()return b.observeYingzhao(a.student).waveReach=='clear'end)
    a.student:stop();a.student.velocityX=0
    -- Require a real released projectile, not a shot cancelling its wind-up.
    wait(function()return boss.guard.strike.wave~=nil end)
    local far=b.observeYingzhao(a.student);assert(F.validate(far)and far.threat=='wave'and far.bossAction=='wave')
    local chosen
    for _,part in ipairs({'head','forelegs','arms','hindlegs','torso','flank'})do
     if far['part_'..part]~='exposed'and require('Training.YingzhaoActions').plan(b,a,part)then chosen=part;break end
    end
    assert(chosen,'No reachable armored region after wave release')
    assert(b:command('aim-part',chosen));assert(b:command('shoot'))
    wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor(actor)and not boss.guard.busy and not boss.guard.reacting end)
    boss.guard.nextAttack=math.huge
    assert(a.studentHP==100,'Wave reached safe firing position')
    assert(boss.guard.strike.wave,'Missing actual wave emission')
    row.cycles[#row.cycles+1]={near=near.distance,far=far.distance,hp=a.studentHP,part=chosen,wave=boss.guard.strike.wave};save()
   end
   b:finish('aborted','Finite-wave QA lesson');wait(function()return b.phase=='aborted'end)
   local resources=b.supplies:evidence();b.bossTrace.resources=resources
   local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator=actor,episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   assert(require('Training.YingzhaoReview').rebuild(e))
   local samples=assert(P.inspect({e},actor));assert(#samples.samples==6 and samples.actions.bmove==3)
   local model=assert(P.buildAsync({e},actor));assert(model.featureSchemaVersion==require('Training.YingzhaoFeatures').version and model.trainingAccuracy==1)
   for _,step in ipairs(e.boss.steps)do if step.origin=='demo'and(step.action=='bmove'or step.action=='shoot')then
    assert(P.predict(model,step.before,function()return true end)==(step.action=='shoot'and('shoot@'..step.aim.intent)or'bmove'))
   end end
   row.source=e;row.model=model;row.samples=#samples.samples;row.shots=b.supplies.emissions;save()
  end
  r.oldProjectionUnchanged=true;r.notNaturalVictory=true;r.notHumanDemonstration=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
