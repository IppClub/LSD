-- Controlled native full-size animation poses; not natural battle or a policy.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/yingzhao-head-coverage-result.json'
local r={status='RUNNING',scope='native-head-visibility-vs-legal-ray',cases={},falseUnreachable={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local supplies=assert(require('Economy.CombatSession').virtual('native-head-coverage',{{actor='ninilite',item='emp',quantity=36}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},supplies,{virtual=true})
  local boss=b.enemies[1];boss.guard.update=function()end
  assert(b:start());for _,a in ipairs(b.learners)do a.nextDecision=math.huge end
  D.sleep(.3);assert(b.arena.student.onSurface)
  local Muzzle=require('Combat.Muzzle');local Actions=require('Training.YingzhaoActions')
  local emissions={};local prepare=b.arena.prepareStudentShot
  b.arena.prepareStudentShot=function(owner,step)
   local shot=prepare(owner,step)
   if shot then
    local angle=math.rad(shot.angle);local sign=owner.faceRight and 1 or -1
    local to={x=shot.origin.x+sign*math.cos(angle)*require('Combat.FirearmRules').travel,y=shot.origin.y-math.sin(angle)*require('Combat.FirearmRules').travel}
    local hit,terrain=b.bossCombat:contact(shot.origin,to)
    emissions[#emissions+1]={step=step,origin=shot.origin,angle=shot.angle,contact=hit,terrain=terrain,bossX=boss.enemy.x,bossY=boss.enemy.y}
   end
   return shot
  end
  for _,pose in ipairs({{'idle',.2},{'punch',.2},{'punch',.5},{'punch',.8},{'massive',.2},{'massive',.5},{'massive',.8}})do
   boss.enemy.playable.speed=1
   local duration=boss.enemy.playable:play(pose[1],false);assert(duration>0)
   D.sleep(duration*pose[2]);boss.enemy.playable.speed=0
   for _,side in ipairs({-1,1})do
    boss.enemy.faceRight=side<0;D.sleep(.1);b.bossCombat:sample()
    for _,distance in ipairs({300,600,900,1200,1500})do
     local owner=b.arena.student;owner.x=boss.enemy.x+side*distance;owner.velocityX=0;owner.faceRight=side<0;D.sleep(.1)
     local plan,why=Actions.plan(b,b.arena,'head');local actualRay
     if not plan then
      for angle=-45,45,.5 do
       local origin=Muzzle.learnerPreview(b.world,owner,angle,owner.faceRight)or Muzzle.preview(b.world,owner)
       local radians=math.rad(angle);local direction=owner.faceRight and 1 or -1
       local point={x=origin.x+direction*math.cos(radians)*require('Combat.FirearmRules').travel,y=origin.y-math.sin(radians)*require('Combat.FirearmRules').travel}
       local hit,terrain=b.bossCombat:contact(origin,point)
       if hit and not terrain and not hit.enemy and hit.part=='head'then actualRay={angle=angle,origin=origin,contact=hit.position};break end
      end
     end
     local row={clip=pose[1],fraction=pose[2],side=side,distance=distance,planned=plan~=nil,reason=why,actualHeadRay=actualRay}
     if plan and (distance==600 or pose[1]=='massive'and side==1 and distance>=900)then
      local first=#b.bossTrace.steps;local hits=#b.bossTrace.hits;local used=supplies.emissions
      assert(Actions.request(b,b.arena,'shoot@head','demo'))
      local deadline=D.App.runningTime+5
      while b.arena:isAttacking()or next(b.bossCombat.shots)do assert(D.App.runningTime<deadline,'Head emission stalled');D.sleep(.01)end
      local step=b.bossTrace.steps[first+1];assert(Actions.validateStep(step))
      row.emittedStep=step;row.actualHits={};row.flights=b.bossTrace.flights;row.emissionDiagnostics=emissions;row.bossAtFinish={x=boss.enemy.x,y=boss.enemy.y}
      for i=hits+1,#b.bossTrace.hits do row.actualHits[#row.actualHits+1]=b.bossTrace.hits[i]end
      r.lastEmission=row;save()
      assert(step.emitted==1 and supplies.emissions==used+1,'Legal head plan did not emit once')
      assert(#b.bossTrace.hits==hits+1 and b.bossTrace.hits[hits+1].part=='head','Stationary head plan hit another part')
      row.emittedStep=step;row.hit=b.bossTrace.hits[hits+1]
     end
     r.cases[#r.cases+1]=row;if actualRay then r.falseUnreachable[#r.falseUnreachable+1]=row end
    end
   end
   save()
  end
  r.bossScale=boss.enemy.unitDef.scale;assert(r.bossScale==1)
  assert(#r.falseUnreachable==0,'Legal native head ray missed by part candidate selector')
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
