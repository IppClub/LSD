local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-skill-evidence-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Skill evidence timeout');D.sleep(.02)end end
  local E=require('Enemy.BigYingzhaoEvidence')
  for _,skill in ipairs({'fire','wind'})do for _,mode in ipairs(skill=='fire'and{'released','hidden','interrupted','after-release','ended','synergy'}or{'released','hidden','interrupted','after-release','ended'})do
   local actor=skill=='fire'and'ninilite'or'wuyun'
   local supplies=assert(require('Economy.CombatSession').virtual('skill-evidence:'..D.App.runningTime,{{actor=actor,item='emp',quantity=2}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},supplies,{virtual=true});local boss=b.enemies[1];local update=boss.guard.update
   boss.guard.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());b.arena.mode='review';b.wuyun.mode='review';b.mentor.x=2250;b.mentor.faceRight=true;b.wuyun.student.x=2100;b.arena.student.x=1800;boss.enemy.x=2500
   if mode=='hidden'then boss.enemy.opacity=0 end
   if mode=='synergy'then
    -- Fire aimed at the tall Boss hits its upper body before entering the floor-level gust.
    -- A real summoned enemy lets falling feathers cross the real cone before impact.
    b.mentor.x=1950;b.wuyun.student.x=1800;boss.enemy.x=3000
    local Small=require('Enemy.SmallYingzhao');local child={enemy=Small.create(b.world,2250),enemyHP=70};child.guard=Small.new(b,child);b.enemies[#b.enemies+1]=child
    local update=child.guard.update;child.guard.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   end
   D.sleep(.4);local a=b.magic.roles[skill]
   if mode=='interrupted'or mode=='after-release'then
    if mode=='interrupted'then b.mentor.x=3300 end
    local Small=require('Enemy.SmallYingzhao');local child={enemy=Small.create(b.world,a.student.x+(mode=='after-release'and -150 or 150)),enemyHP=70};child.guard=Small.new(b,child);b.enemies[#b.enemies+1]=child
    local u=child.guard.update;child.guard.update=function(self,now)self.nextAttack=math.huge;u(self,now);self.nextAttack=math.huge end
    D.sleep(.3);wait(function()return child.enemy.onSurface end);assert(child.guard:attack('kick',a.student));if mode=='interrupted'then D.sleep(.5)end
   end
   if mode=='synergy'then assert(b.magic:request('wind',{source='qa-synergy',noQueue=true,faceRight=true}))end
   assert(b.magic:request(skill,{source='demo',noQueue=true,faceRight=true}))
   if mode=='ended'then D.sleep(.1);assert(b:finish('aborted','End before release'))end
   wait(function()return not b.magic:busy(skill)and not b.bossCombat:pendingActor(actor)end)
   if mode~='ended'then assert(b:finish('aborted','Skill evidence fixture'))end;wait(function()return b.phase=='aborted'end)
   local resources=supplies:evidence();b.bossTrace.resources=resources
   local source={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator=actor,episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   assert(E.validateVirtual(source));local decoded=D.json.decode(D.json.encode(source,false,true),32);assert(E.validateVirtual(decoded))
   local index,step;for i,s in ipairs(source.boss.steps)do if s.action==skill then assert(not step);index=i;step=s end end;assert(step)
   assert(step.before.featureSchemaVersion==6 and step.before.skillState=='ready'and step.before.skillCooldown=='ready','Skill decision snapshot was captured after action start')
   local review=assert(require('Training.YingzhaoReview').rebuild(source));local row=review.rows[index]
   if mode=='released'or mode=='synergy'then assert(row.hits>0 and row.health>0 and row.outcome=='effective'and row.cost==0 and step.skill.status=='completed')
   elseif mode=='after-release'then assert(row.hits>0 and row.health>0 and row.outcome=='effective'and step.emitted==1 and step.skill.status=='cancelled')
   elseif mode=='hidden'then assert(row.hits==0 and row.outcome=='miss'and step.emitted==1)
   else assert(row.hits==0 and row.outcome=='not-released'and step.skill.status=='cancelled'and not step.emitted)end
   if mode=='synergy'then
    local enhanced=0;for _,hit in ipairs(source.boss.hits)do if hit.step==index and hit.weapon=='wind-fire'then enhanced=enhanced+1 end end;assert(enhanced>0,'Actual wind did not enhance fire')
   end
   assert(#assert(require('Training.YingzhaoPolicy').inspect({source},actor,6,1)).samples==0,'Version 1 learned unversioned skill')
   local samples=assert(require('Training.YingzhaoPolicy').inspect({source},actor,6,2)).samples
   local expected=step.emitted==1 and 1 or 0
   assert(#samples==expected,'Release/miss/interruption filtering changed')
   if expected==1 then assert(samples[1].action==skill..'@right')end
   local historical=D.json.decode(D.json.encode(source),32);historical.boss.steps[index].before.featureSchemaVersion=5
   assert(#assert(require('Training.YingzhaoPolicy').inspect({historical},actor,6,2)).samples==0,'Historical post-start skill observation became a training sample')
   local corrupt=D.json.decode(D.json.encode(source),32);corrupt.boss.steps[index].skill.actor='mentor';assert(not E.validateVirtual(corrupt))
   corrupt=D.json.decode(D.json.encode(source),32)
   local before=corrupt.boss.steps[index].before
   before.skillControl.available=false;before.skillControl.reason='ALREADY_CASTING';before.skillControl.readyAt=step.skill.cooldownUntil;before.skillState='casting';before.skillCooldown='cooling'
   assert(require('Training.YingzhaoFeatures').validate(before),'Corruption must remain a valid post-start observation')
   assert(not E.validateVirtual(corrupt),'Accepted post-start state as decision evidence')
   for _,bad in ipairs({false,'six',6})do
    corrupt=D.json.decode(D.json.encode(source),32)
    if bad==6 then corrupt.boss.steps[index].before.skillControl=1 else corrupt.boss.steps[index].before.featureSchemaVersion=bad end
    local checked,valid=pcall(E.validateVirtual,corrupt);assert(checked and not valid,'Malformed skill observation crashed validator')
   end
   if mode=='released'or mode=='after-release'then
    corrupt=D.json.decode(D.json.encode(source),32);corrupt.boss.hits[1].step=nil;assert(not E.validateVirtual(corrupt))
    corrupt=D.json.decode(D.json.encode(source),32);corrupt.boss.steps[index].skill.releaseAt=step.started-1;assert(not E.validateVirtual(corrupt))
   end
   r.cases[#r.cases+1]={skill=skill,mode=mode,source=source,hits=row.hits,health=row.health,outcome=row.outcome,review=require('Training.YingzhaoReview').text(review)};save()
  end end
  local old=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-spacing-natural-20261006/result.json'),32);assert(old.status=='PASS');assert(require('Training.YingzhaoComparisonStore').validate(old.report));r.legacyCompatible=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
