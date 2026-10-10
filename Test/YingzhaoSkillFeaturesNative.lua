local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-skill-features-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local F=require('Training.YingzhaoFeatures');local S=require('Training.YingzhaoSkillFeatures');local A=require('Training.YingzhaoActions')
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Skill observation timeout');D.sleep(.02)end end
  for _,skill in ipairs({'fire','wind'})do
   local actor=skill=='fire'and'ninilite'or'wuyun'
   local supplies=assert(require('Economy.CombatSession').virtual('skill-features:'..D.App.runningTime,{{actor=actor,item='emp',quantity=2}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},supplies,{virtual=true})
   local boss=b.enemies[1];local update=boss.guard.update;boss.guard.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());b.arena.mode='review';b.wuyun.mode='review';boss.enemy.x=2500;b.mentor.x=2260;b.mentor.faceRight=true;b.arena.student.x=1800;b.wuyun.student.x=2100
   D.sleep(.4);local a=b.magic.roles[skill];local row={skill=skill};r.cases[#r.cases+1]=row
   local function observe()local s=b.observeYingzhao(a.student);assert(F.validate(s));assert(F.validate(D.json.decode(D.json.encode(s,false,true),32)));return s end
   -- Explicit snapshot-boundary fixture: wall clock is later than the captured instant.
   local boundary=D.App.runningTime-.01;local originalReady=b.magic.ready[skill];b.magic.ready[skill]=boundary
   local rawBefore,before=S.capture(b,a.student,2500,boundary-.001)
   local rawAt,at=S.capture(b,a.student,2500,boundary)
   assert(not rawBefore.available and before.skillState=='cooldown'and before.skillCooldown=='soon')
   assert(rawAt.available and at.skillState=='ready'and at.skillCooldown=='ready')
   b.magic.ready[skill]=originalReady;row.cooldownBoundary=true
   row.ready=observe();assert(row.ready.skillState=='ready'and row.ready.skillCooldown=='ready'and row.ready.skillTargetSide=='right'and row.ready.skillDefaultFacing=='toward')
   if skill=='fire'then assert(row.ready.fireAimRight=='aligned'and row.ready.fireAimLeft=='right')end
   -- Observing cannot consume cooldown, append skill logs or start an animation.
   for i=1,3 do observe()end;assert(#b.magic.logs==0 and b.magic.ready[skill]==0)
   for version=1,5 do
    local old=D.json.decode(D.json.encode(row.ready),32);old.featureSchemaVersion=version;old.skillControl=nil
    for _,name in ipairs(S.names)do old[name]=nil end
    assert(F.validate(old));local projected=assert(F.project(old,6))
    for _,name in ipairs(S.names)do assert(projected[name]=='unknown','Legacy skill readiness was invented')end
    assert(F.key(old,version)==F.key(row.ready,version),'Legacy state key changed')
   end
   b.mentor.faceRight=false;row.reversed=observe();assert(row.reversed.skillDefaultFacing=='away')
   if skill=='fire'then b.mentor.x=3000;local shifted=observe();assert(shifted.fireAimLeft=='left'and shifted.fireAimRight=='left');b.mentor.x=2260 end
   b.mentor.faceRight=true
   assert(not A.decode(skill..'@right',1)and not A.decode(skill..'@right',3))
   assert(not A.request(b,a,skill..'@right','demo',1))
   assert(not A.request(b,a,(skill=='fire'and'wind'or'fire')..'@right','demo',2))
   assert(A.available(b,a,skill..'@right',2))
   assert(A.request(b,a,skill..'@right','demo',2));row.casting=observe();assert(row.casting.skillState=='casting'and row.casting.skillCooldown=='cooling')
   local log=b.magic.logs[#b.magic.logs];local step=b.bossTrace.steps[log.step]
   assert(step.before.skillState=='ready'and step.before.skillCooldown=='ready'and step.before.at<=step.started)
   wait(function()return not b.magic:busy(skill)and not b.bossCombat:pendingActor(actor)end)
   row.cooldown=observe();assert(row.cooldown.skillState=='cooldown'and row.cooldown.skillCooldown=='cooling')
   local accepted,why=A.request(b,a,skill..'@right','demo',2);assert(not accepted and why=='COOLDOWN')
   wait(function()return log.cooldownUntil-D.App.runningTime<.8 end)
   row.soon=observe();assert(row.soon.skillState=='cooldown'and row.soon.skillCooldown=='soon')
   wait(function()return D.App.runningTime>=log.cooldownUntil end);row.recovered=observe();assert(row.recovered.skillState=='ready'and row.recovered.skillCooldown=='ready')
   -- Version 2 explicitly selects direction even if the mentor faces the other way.
   assert(A.request(b,a,skill..'@left','demo',2))
   local left=b.magic.logs[#b.magic.logs];assert(left.direction==-1 and left.source=='demo'and not b.magic.pending[skill])
   wait(function()return not b.magic:busy(skill)and not b.bossCombat:pendingActor(actor)end)
   row.left=left
   local corrupt=D.json.decode(D.json.encode(row.cooldown),32);corrupt.skillState='ready';assert(not F.validate(corrupt))
   corrupt=D.json.decode(D.json.encode(row.ready),32);corrupt.skillControl.readyAt=corrupt.at+1;assert(not F.validate(corrupt))
   corrupt=D.json.decode(D.json.encode(row.ready),32);corrupt.skillTargetSide='left';assert(not F.validate(corrupt))
   boss.enemy.opacity=0;row.hidden=observe();assert(row.hidden.target=='none'and row.hidden.skillTargetSide=='unknown'and row.hidden.skillDefaultFacing=='unknown'and row.hidden.fireAimLeft=='unknown'and row.hidden.fireAimRight=='unknown')
   local mentor=b.observeYingzhao(b.mentor);assert(F.validate(mentor)and not mentor.skillControl and mentor.skillState=='unknown')
   assert(b:finish('aborted','Skill feature fixture'));wait(function()return b.phase=='aborted'end);row.ended=observe();assert(row.ended.skillState=='inactive');save()
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
