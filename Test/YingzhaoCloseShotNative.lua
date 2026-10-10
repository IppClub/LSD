-- Validate planned close shots against real projectile barrel sweeps and payment.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-close-shot-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Close shot timeout');D.sleep(.02)end end
  for _,side in ipairs({-1,1})do for _,distance in ipairs({41,60,100,140})do
   local supplies=assert(require('Economy.CombatSession').virtual('close-shot:'..D.App.runningTime,{{actor='mentor',item='kinetic',quantity=3}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},supplies,{virtual=true})
   local boss=b.enemies[1];local g=boss.guard;local update=g.update;g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());b.arena.mode='review';b.wuyun.mode='review';D.sleep(.4);assert(g:attack('hunt',b.mentor));wait(function()return #g.hunt.children==2 end)
   for _,e in ipairs(g.hunt.children)do e.pendingPounce=nil;e.guard.update=function()end;e.enemy:stop();e.enemy.velocity=D.Vec2.zero end
   local first=g.hunt.children[1];local x=1920
   b.mentor.position=D.Vec2(x,b.world.offset+155);boss.enemy.x=x+side*1100
   first.enemy.position=D.Vec2(x+side*distance,b.world.offset+105);g.hunt.children[2].enemy.x=x+side*(distance+300)
   D.sleep(.2);local A=require('Training.YingzhaoActions');local aim=assert(A.plan(b,{student=b.mentor},'summon'));local hp=first.enemyHP
   if distance==41 then
    local contact=b.bossCombat.contact
    b.bossCombat.contact=function()return {enemy=first},true end
    assert(not A.plan(b,{student=b.mentor},'summon'),'Terrain precedence bypassed')
    b.bossCombat.contact=function()return {enemy=g.hunt.children[2]},false end
    assert(not A.plan(b,{student=b.mentor},'summon'),'Different first body bypassed')
    b.bossCombat.contact=contact
   end
   b.mentorPartAim=aim;b.mentorActionOrigin='qa';assert(b.mentorAim:fireAt(aim.angle,aim.faceRight));b.mentorPartAim=nil;b.mentorActionOrigin=nil
   wait(function()return not b.mentor:isDoing('groundMentorShot')and not b.bossCombat:pendingActor('mentor')end)
   assert(hp-first.enemyHP==15 and supplies.emissions==1 and supplies:observation('mentor').ammo.kinetic==2,'Close paid shot mismatch')
   local step=b.bossTrace.steps[1];assert(A.validateStep(step));assert(b.bossTrace.hits[1].summoned)
   r.cases[#r.cases+1]={side=side,distance=distance,aim=aim,damage=hp-first.enemyHP,step=step,hit=b.bossTrace.hits[1]};save()
   b:finish('aborted','Close shot proof');while b.phase=='settling'do D.sleep(.02)end
  end end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
