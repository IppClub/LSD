local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-mentor-cover-result.json'
local r={status='RUNNING',cases={},notHumanDemonstration=true,notNaturalVictory=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')};local A=require('Training.YingzhaoActions');local Small=require('Enemy.SmallYingzhao')
  local function wait(fn)local untilAt=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<untilAt,'Summon escape timeout');D.sleep(.02)end end
  for _,side in ipairs({-1,1})do for _,escape in ipairs({false,true})do
   local supplies=assert(require('Economy.CombatSession').virtual('big-yingzhao-demo:'..os.time()..':'..D.App.runningTime,{{actor='ninilite',item='emp',quantity=12},{actor='mentor',item='kinetic',quantity=10}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true});local mentorCommand=b.command
   require('Training.YingzhaoDemonstration').attach(b,'ninilite');b.mentorAim.fire=function()return mentorCommand(b,'shoot')end
   local a=b.arena;assert(b:start());b.wuyun.mode='review';local boss=b.enemies[1];local update=boss.guard.update
   boss.guard.update=function(g,now)g.nextAttack=math.huge;update(g,now);g.nextAttack=math.huge end
   boss.enemy.position=D.Vec2(1920-side*900,b.world.offset+255);boss.enemy.faceRight=side>0
   a.student.position=D.Vec2(1920,b.world.offset+155);b.mentor.x=1920+side*400;b.wuyun.student.x=1920-side*1500;D.sleep(.5)
   for _,part in ipairs({'head','forelegs','arms'})do
    local attempts=0
    while b.observeYingzhao(a.student)['part_'..part]~='exposed'do
     wait(function()return a:available('laser')and not a:isAttacking()end);attempts=attempts+1;assert(attempts<=4)
     assert(A.request(b,a,'shoot@'..part,'qa-armor-setup'))
     wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor('ninilite')end)
    end
   end
   local child={enemy=Small.create(b.world,1920-side*180),enemyHP=70};child.guard=Small.new(b,child);b.enemies[#b.enemies+1]=child
   local childUpdate=child.guard.update
   child.guard.update=function(g,now)g.nextAttack=math.huge;childUpdate(g,now);g.nextAttack=math.huge end
   D.sleep(.4);wait(function()return child.enemy.onSurface end)
   local row={side=side,escape=escape,before=b.observeYingzhao(a.student),hpBefore=a.studentHP};r.cases[#r.cases+1]=row;save()
   assert(row.before.target=='summon'and row.before.targetDistance=='near'and row.before.threat=='none'and row.before.bossDistance=='far')
   assert(child.guard:attack('kick',a.student));local strike=child.guard.strike
   local canStart=b.mentorAim.canStart;b.mentorAim.canStart=function()return false end
   local mentor=require('Training.YingzhaoMentor');mentor.shoot(b)
   assert(b.yingzhaoMentorCover.reinforcements[child],'Visible close threat not retained during cooldown')
   child.enemy.visible=false;mentor.shoot(b);assert(not next(b.yingzhaoMentorCover.reinforcements),'Hidden threat retained')
   child.enemy.visible=true;mentor.shoot(b);assert(b.yingzhaoMentorCover.reinforcements[child])
   local x=child.enemy.x;child.enemy.x=1920+side*1440;mentor.shoot(b)
   assert(not next(b.yingzhaoMentorCover.reinforcements),'Distant threat retained')
   child.enemy.x=x;mentor.shoot(b);assert(b.yingzhaoMentorCover.reinforcements[child])
   row.releaseChecks=true;b.mentorAim.canStart=canStart;D.sleep(.1)
   local deadline=D.App.runningTime+10
   while child.guard.busy do
    assert(D.App.runningTime<deadline)
    if escape then assert(b:command(side>0 and 'right'or'left'))end
    D.sleep(.05)
   end
   row.strike=strike;row.damage=row.hpBefore-a.studentHP
   assert(strike.completed and #strike.impacts==1)
   assert(escape and row.damage==0 or not escape and row.damage==12,'Actual escape/control mismatch')
   if escape then
    assert(b:command('stop'))
    while child.enemyHP>0 do
     assert(D.App.runningTime<deadline,'Mentor did not remove reinforcement')
     if b.mentorAim.canStart()then
      assert(require('Training.YingzhaoMentor').shoot(b))
     end
     D.sleep(.1)
    end
    wait(function()return not b.bossCombat:pendingActor('mentor')end)
    local damage,count=0,0
    for _,hit in ipairs(b.bossTrace.hits)do if hit.source=='mentor'and hit.summoned then damage=damage+hit.healthDamage;count=count+1 end end
    row.coverDamage=damage;row.coverHits=count;assert(damage==70 and count==5)
    local canStart=b.mentorAim.canStart;b.mentorAim.canStart=function()return false end
    require('Training.YingzhaoMentor').shoot(b);b.mentorAim.canStart=canStart
    assert(not next(b.yingzhaoMentorCover.reinforcements),'Dead reinforcement retained')
   end
   row.childHP=child.enemyHP;row.empRemaining=supplies:observation('ninilite').ammo.emp
   assert(row.empRemaining==7,'Escape consumed EMP');b:finish('aborted','Near summon conservation contrast');wait(function()return b.phase=='aborted'end)
   if escape then
    local resources=supplies:evidence();b.bossTrace.resources=resources
    row.source={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='ninilite',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
    local data=assert(require('Training.YingzhaoPolicy').inspect({row.source},'ninilite'));row.samples=#data.samples;row.actions=data.actions
    local counter=0;for _,s in ipairs(data.samples)do if s.action=='bmove'and s.state.target=='summon'and s.state.targetDistance=='near'and s.state.threat=='none'and s.state.part_head=='exposed'and s.state.part_forelegs=='exposed'then counter=counter+1 end end
    row.counterexamples=counter;assert(counter>0)
   end
   save()
  end end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
