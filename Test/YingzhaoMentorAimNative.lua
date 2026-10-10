local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-mentor-aim-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local supplies=assert(require('Economy.CombatSession').virtual('mentor-aim',{{actor='mentor',item='kinetic',quantity=10},{actor='ninilite',item='emp',quantity=5}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},supplies,{virtual=true});assert(b:start())
  b.arena.mode='demo';b.wuyun.mode='review';b.mentor.x=1000 -- Head is actually reachable within the authored +/-45 degree cone.
  local boss=b.enemies[1];boss.guard.nextAttack=math.huge;boss.enemy.playable.speed=0;D.sleep(.5)
  local function wait(fn)local deadline=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<deadline,'Aim timeout');D.sleep(.02)end end
  for i=1,4 do
   if b.observeYingzhao(b.mentor).part_head=='exposed'then break end
   wait(function()return b.arena:available('laser')end)
   assert(require('Training.YingzhaoActions').request(b,b.arena,'shoot@head','test'))
   wait(function()return not b.arena:isAttacking()and not b.bossCombat:pendingActor('ninilite')end)
  end
  assert(b.observeYingzhao(b.mentor).part_head=='exposed','Real EMP did not break head')
  local hp=boss.enemyHP;local count=#b.bossTrace.hits
  assert(require('Training.YingzhaoMentor').shoot(b))
  wait(function()return not b.mentor:isDoing('groundMentorShot')and not b.bossCombat:pendingActor('mentor')end)
  r.hits=b.bossTrace.hits;r.steps=b.bossTrace.steps;save()
  local hit=b.bossTrace.hits[count+1];assert(hit and hit.source=='mentor'and hit.part=='head'and math.abs(hit.healthDamage-22.5)<1e-6,'Mentor did not hit exposed head')
  assert(math.abs(hp-boss.enemyHP-22.5)<1e-6)
  local step=b.bossTrace.steps[hit.step];assert(step.aim.intent=='head'and step.origin=='mentor-assistance')
  wait(function()return not b.mentorAim.shot and b.mentorAim.canStart()end)
  assert(not b.mentorAim:fireAt(46,true),'Out-of-range aim accepted')
  -- A visible unarmored reinforcement beside the learner competes with the
  -- exposed Boss head. Only real rifle projectiles may remove it.
  local Small=require('Enemy.SmallYingzhao')
  local child={enemy=Small.create(b.world,1200),enemyHP=70};child.guard=Small.new(b,child);child.guard.nextAttack=math.huge;b.enemies[#b.enemies+1]=child
  D.sleep(.3)
  -- The real raised muzzle places this close target outside the angle cone.
  -- Cancellation must retain ammo; only the subsequent reachable shot is paid.
  local usedBefore=supplies.emissions;local firstClose=#b.bossTrace.steps
  assert(require('Training.YingzhaoMentor').shoot(b))
  wait(function()return not b.mentor:isDoing('groundMentorShot')and not b.bossCombat:pendingActor('mentor')end)
  local cancelled=b.bossTrace.steps[firstClose+1]
  assert(cancelled.emissionCancelled=='COMMITTED_POINT_UNREACHABLE'and not cancelled.emitted and supplies.emissions==usedBefore,'Unreachable committed point consumed ammo')
  r.closeCancelledWithoutCost=true
  child.enemy.x=1450;D.sleep(.1);local shots=0
  while child.enemyHP>0 do
   wait(function()return not b.mentorAim.shot and b.mentorAim.canStart()end)
   local first=#b.bossTrace.steps;assert(require('Training.YingzhaoMentor').shoot(b))
   wait(function()return not b.mentor:isDoing('groundMentorShot')and not b.bossCombat:pendingActor('mentor')end)
   assert(b.bossTrace.steps[first+1].aim.intent=='summon','Exposed Boss displaced urgent reinforcement target')
   shots=shots+1;assert(shots<=5,'Reinforcement was not cleared by rifle hits')
  end
  r.reinforcementShots=shots;r.reinforcementHP=child.enemyHP
  assert(shots==5)
  wait(function()return not b.mentorAim.shot and b.mentorAim.canStart()end)
  local used=supplies.emissions;boss.enemy.opacity=0
  local fired,reason=require('Training.YingzhaoMentor').shoot(b);assert(not fired and reason=='NO_REACHABLE_PART'and supplies.emissions==used,'Invisible target fired at')
  b:finish('aborted','Mentor aim fixture');wait(function()return b.settled end)
  local resources=supplies:evidence();b.bossTrace.resources=resources
  local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-evaluation',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
  local valid,why=require('Enemy.BigYingzhaoEvidence').validateEvaluation(e);assert(valid,why)
  r.damage=hit.healthDamage;r.actualHead=true;r.hiddenRejected=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
