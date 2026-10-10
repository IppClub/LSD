-- Actual EMP breaks followed by deliberate hold-fire while mentor exploits armor.
-- Boss automatic attacks are paused; this is a controlled QA lesson, not a win.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-conserve-lesson-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')};local A=require('Training.YingzhaoActions')
  local function wait(fn)local untilAt=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<untilAt,'Conservation lesson timeout');D.sleep(.02)end end
  for _,side in ipairs({-1,1})do
   local supplies=assert(require('Economy.CombatSession').virtual('big-yingzhao-demo:'..os.time()..':'..D.App.runningTime,{{actor='ninilite',item='emp',quantity=12},{actor='mentor',item='kinetic',quantity=4}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true});local mentorCommand=b.command
   require('Training.YingzhaoDemonstration').attach(b,'ninilite');b.mentorAim.fire=function()return mentorCommand(b,'shoot')end
   local a=b.arena;assert(b:start());b.wuyun.mode='review';local boss=b.enemies[1];local update=boss.guard.update
   boss.guard.update=function(g,now)g.nextAttack=math.huge;update(g,now);g.nextAttack=math.huge end
   boss.enemy.faceRight=side>0;a.student.position=D.Vec2(1920+side*900,b.world.offset+155)
   b.mentor.x=1920+side*1100;b.wuyun.student.x=1920-side*1300;D.sleep(.5)
   local row={side=side,shots={}};r.cases[#r.cases+1]=row
   for _,part in ipairs({'head','forelegs','arms'})do
    local attempts=0
    while b.observeYingzhao(a.student)['part_'..part]~='exposed'do
     wait(function()return a:available('laser')and not a:isAttacking()end)
     attempts=attempts+1;assert(attempts<=4,'Repeated EMP failed to break intended armor')
     assert(A.plan(b,a,part),'Requested front armor not reachable')
     assert(A.request(b,a,'shoot@'..part,'qa-armor-setup'))
     wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor('ninilite')end)
     row.shots[#row.shots+1]=part
    end
   end
   local before=b.observeYingzhao(a.student);row.before=before;save()
   assert(before.aim_flank=='blocked'and before.part_head=='exposed'and before.part_forelegs=='exposed'and before.part_arms=='exposed')
   local ammo=supplies:observation('ninilite').ammo.emp;local hp=boss.enemyHP
   -- Setup is retained in the trace but is not a demonstrated strategy.
   -- A real release after this positioning starts the deliberate idle interval.
   assert(A.request(b,a,'bmove','qa-positioning'));D.sleep(.2);assert(b:command('stop'));D.sleep(.3)
   for i=1,3 do
    wait(function()return b.mentorAim.canStart()end);assert(require('Training.YingzhaoMentor').shoot(b))
    wait(function()return not b.mentor:isDoing('groundMentorShot')and not b.bossCombat:pendingActor('mentor')end)
   end
   assert(supplies:observation('ninilite').ammo.emp==ammo,'Hold-fire consumed EMP')
   row.healthDamage=hp-boss.enemyHP;assert(row.healthDamage>0);row.empRemaining=ammo
   assert(supplies:observation('mentor').ammo.kinetic==1)
   b:finish('aborted','Controlled conservation lesson');while b.phase=='settling'do D.sleep(.02)end
   local resources=supplies:evidence();b.bossTrace.resources=resources
   local source={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='ninilite',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   local data=assert(require('Training.YingzhaoPolicy').inspect({source},'ninilite'));row.source=source;row.samples=#data.samples;row.actions=data.actions
   local held=0;for _,s in ipairs(data.samples)do if s.action=='idle'and s.state.aim_flank=='blocked'and s.state.part_head=='exposed'and s.state.part_forelegs=='exposed'and s.state.part_arms=='exposed'then held=held+1 end end
   assert(#data.samples==1 and held==1,'Hold-fire was not recorded as an actual completed interval');row.heldSamples=held;save()
  end
  r.notHumanDemonstration=true;r.notNaturalVictory=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
