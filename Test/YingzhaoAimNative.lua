-- Authored learner attack and real EMP flight; pose changes are explicit fixtures.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-aim-result.json';local r={status='RUNNING',shots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local supplies=assert(require('Economy.CombatSession').virtual('aim-fixture',{{actor='ninilite',item='emp',quantity=12}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},supplies);require('Training.YingzhaoDemonstration').attach(b,'ninilite');assert(b:start());assert(b.controlledUnit==b.arena.student and not b.arena.recorder.active);local boss=b.enemies[1];boss.guard.nextAttack=math.huge
  local controls={battle=b};require('Training.YingzhaoTargetSelector').attach(controls)
  local a=b.arena;a.mode='demo';b.wuyun.mode='review';local A=require('Training.YingzhaoActions')
  local function wait(fn)local stop=D.App.runningTime+7;while not fn()do assert(D.App.runningTime<stop,'Aim timeout');D.sleep(.01)end end
  D.sleep(.5);boss.enemy.playable.speed=0
  local function shot(label,change)
   wait(function()return a:available('laser')and not a:isAttacking()and next(b.bossCombat.shots)==nil end)
   local count=#b.bossTrace.hits;local stepCount=#b.bossTrace.steps;local before=supplies.emissions
   controls.targetButtons[label:match('@(.+)$')]:emit('Tapped');assert(b:command('shoot')); local step=b.bossTrace.steps[stepCount+1];assert(step.aim and step.origin=='demo')
   if change then change()end
   wait(function()return not a:isAttacking()and next(b.bossCombat.shots)==nil end)
   assert(step.emitted==1 and supplies.emissions==before+1)
   local actual=-math.deg(math.atan(step.velocity.y,math.abs(step.velocity.x)));assert(math.abs(actual-step.aimEmission.angle)<.02,'Emission did not follow frozen point')
   assert(A.validateStep(step))
   local function reject(change)
    local copy=D.json.decode(D.json.encode(step),32);change(copy);assert(not A.validateStep(copy),'Forged aim accepted')
   end
   reject(function(s)s.aim.angle=90 end)
   reject(function(s)s.aim.intent='tail' end)
   reject(function(s)s.aim.committedAt=s.started+1 end)
   reject(function(s)s.velocity.x=-s.velocity.x end)
   reject(function(s)s.aim.point.y=s.aim.point.y+100 end)
   reject(function(s)s.emitted=2 end)
   reject(function(s)s.aimEmission.angle=s.aimEmission.angle+5 end)
   reject(function(s)s.muzzle.y=s.muzzle.y+50 end)
   reject(function(s)s.aimEmission.at=s.started-1 end)
   local hits={};for i=count+1,#b.bossTrace.hits do hits[#hits+1]=b.bossTrace.hits[i]end
   r.shots[#r.shots+1]={intent=label,angle=actual,hits=hits};return hits
  end
  local hits=shot('shoot@head');assert(#hits==1 and hits[1].part=='head'and hits[1].armorDamage==35,'Head intention not executed')
  hits=shot('shoot@forelegs');assert(#hits==1 and hits[1].part=='forelegs')
  hits=shot('shoot@head',function()boss.enemy.x=3100 end);assert(#hits==0,'Target motion tracked');boss.enemy.x=2500;D.sleep(.05)
  hits=shot('shoot@head',function()boss.enemy.opacity=0 end);assert(#hits==0,'Invisible target hit')
  local n=supplies.emissions;local accepted,why=A.request(b,a,'shoot@head','test');assert(not accepted and why=='BOSS_HIDDEN'and supplies.emissions==n)
  local originalX=a.student.x;local originalBossX=boss.enemy.x
  boss.enemy.x=3200
  wait(function()if a.student.x<originalX-45 then return true end;b:command('left');return false end)
  assert(not a.student.faceRight and b.observeYingzhao(a.student).bossDistance=='unknown')
  boss.enemy.x=1200
  wait(function()if a.student.x>originalX then return true end;b:command('right');return false end)
  assert(a.student.faceRight);b:command('stop');assert(a.student.velocityX==0)
  assert(supplies.emissions==n);r.hiddenMovement=true
  a.student.x=originalX;boss.enemy.x=originalBossX;boss.enemy.opacity=1
  local def=D.BodyDef();def.type='Static';def:attachPolygon(30,1700);local wall=D.Body(def,b.world,D.Vec2(2050,b.world.offset+850));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world);D.sleep(.05)
  accepted=A.request(b,a,'shoot@head','test');assert(not accepted and supplies.emissions==n,'Initial cover accepted');wall:removeFromParent();D.sleep(.05)
  local child={enemy=require('Enemy.SmallYingzhao').create(b.world,2100),enemyHP=70};child.guard=require('Enemy.SmallYingzhao').new(b,child);child.guard.nextAttack=math.huge;b.enemies[2]=child;D.sleep(.2)
  hits=shot('shoot@summon');assert(#hits==1 and hits[1].summoned and hits[1].healthDamage==0)
  assert(not b:command('aim-part','tail'));assert(b.demonstrationTarget=='summon')
  assert(#a.recorder.samples==0,'Legacy training polluted')
  r.demonstrationControl=true;r.initialCoverRejected=true;r.hiddenRejected=true
  b:finish('aborted','Aim fixture complete');assert(not b:command('shoot'));assert(not b:command('aim-part','head'))
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
