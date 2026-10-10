local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-emission-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local db=D.Content.writablePath..'/big-yingzhao-emission-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd'));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config');r.database=db
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local supplies=assert(require('Economy.CombatSession').virtual('big-yingzhao-emission',{{actor='mentor',item='kinetic',quantity=3},{actor='ninilite',item='emp',quantity=2},{actor='wuyun',item='blade',quantity=2}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},supplies)
  local boss=b.enemies[1];assert(b:start());boss.guard.nextAttack=math.huge
  b.bossCombat.view.node.position=D.Vec2(0,300);b.bossCombat.view.node:addTo(D.Director.ui3D)
  local function wait(fn)local deadline=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<deadline,'Emission timeout');D.sleep(.01)end end
  D.sleep(.6)
  local function settled()return not b.mentor:isDoing('groundMentorShot')and not b.arena:isAttacking()and not b.wuyun:isAttacking()and next(b.bossCombat.shots)==nil end
  local before=supplies.emissions;assert(b:command('shoot'));wait(settled)
  assert(supplies.emissions==before+1,'Mentor emission charged wrong count')
  assert(#b.bossTrace.hits>0,'Mentor actual animation shot missed fixture');local hit=b.bossTrace.hits[#b.bossTrace.hits];assert(hit.weapon=='kinetic'and hit.healthDamage==2.25 and hit.step)
  local step=b.bossTrace.steps[hit.step];assert(step.emitted==1 and step.muzzle and step.velocity and step.ended)
  local mentorPart,mentorAP=hit.part,hit.apAfter
  boss.guard.nextAttack=math.huge;local hp=boss.enemyHP
  before=supplies.emissions;assert(b.arena:request('laser','test'));wait(settled)
  assert(supplies.emissions==before+1 and boss.enemyHP==hp,'EMP used legacy HP damage')
  hit=b.bossTrace.hits[#b.bossTrace.hits];assert(hit.source=='ninilite'and hit.weapon=='emp'and hit.armorDamage>0 and hit.healthDamage==0)
  local niStep=assert(b.bossTrace.steps[hit.step]);local empPart,empAP=hit.part,hit.apAfter
  assert(niStep.before.ownHP==100 and niStep.before.knownArmor[mentorPart]and niStep.before.knownArmor[mentorPart].ap==mentorAP and niStep.after.knownArmor[empPart]and niStep.after.knownArmor[empPart].ap==empAP,'Actual contacted armor/HP not captured')
  boss.guard.nextAttack=math.huge
  b.wuyun.student.x=boss.enemy.x-240;b.wuyun.student.faceRight=true;D.sleep(.2)
  before=supplies.emissions;assert(b.wuyun:request('melee','test'));wait(settled)
  assert(supplies.emissions==before+1);hit=b.bossTrace.hits[#b.bossTrace.hits];assert(hit.source=='wuyun'and hit.weapon=='blade'and hit.step,'Melee bypassed parts')
  before=supplies.emissions;assert(b:command('shoot'));boss.enemy.opacity=0;wait(settled)
  local hidden=b.bossTrace.steps[#b.bossTrace.steps];assert(hidden.after.bossVisible==false and hidden.after.bossX==nil and hidden.after.distance==nil,'Hidden location leaked')
  assert(supplies.emissions==before and not hidden.emitted,'Invisible target shot charged/emitted')
  assert(not b:target(b.mentor));assert(not b:command('shoot'));boss.enemy.opacity=1
  assert(b:damage(boss.enemy,999)==0,'Legacy damage bypassed armor')
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-emission.tga');D.sleep(.15)
  local beforeExit=supplies.emissions;b.wuyun.nextShot=0;assert(b.wuyun:request('melee','test'))
  assert(b:finish('aborted','QA complete'));wait(function()return b.settled end)
  assert(supplies.emissions==beforeExit,'Late melee charged after outcome');r.lateMeleeBlocked=true
  assert(b.bossTrace.closed and not b.bossTrace.trainable and b.bossCombat.closed)
  r.steps=b.bossTrace.steps;r.hits=b.bossTrace.hits;r.resources=b.bossTrace.resources;r.hp=boss.enemyHP;r.legacyBlocked=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
