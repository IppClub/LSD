-- Safe finite-wave boundary with real armor breaks, summons and low ammunition.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-edge-conserve-result.json'
local r={status='RUNNING',cases={},notHumanDemonstration=true,notNaturalVictory=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')};local A=require('Training.YingzhaoActions')
  local function wait(fn)local deadline=D.App.runningTime+16;while not fn()do assert(D.App.runningTime<deadline,'Edge conservation timeout');D.sleep(.02)end end
  for _,side in ipairs({-1,1})do
   local supplies=assert(require('Economy.CombatSession').virtual('big-yingzhao-demo:'..os.time()..':'..D.App.runningTime,{{actor='wuyun',item='emp',quantity=6},{actor='wuyun',item='blade',quantity=12},{actor='mentor',item='kinetic',quantity=4}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true});local mentorCommand=b.command
   require('Training.YingzhaoDemonstration').attach(b,'wuyun');b.mentorAim.fire=function()return mentorCommand(b,'shoot')end
   local a=b.wuyun;assert(b:start());b.arena.mode='review';local boss=b.enemies[1];local g=boss.guard;local update=g.update
   g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   local bx=1920+side*400;boss.enemy.position=D.Vec2(bx,b.world.offset+255);boss.enemy.faceRight=side>0
   a.student.position=D.Vec2(bx+side*900,b.world.offset+155);b.mentor.x=bx+side*1020;b.arena.student.x=bx-side*700;D.sleep(.5)
   local row={side=side};r.cases[#r.cases+1]=row
   for _,part in ipairs({'head','forelegs','arms'})do
    local attempts=0
    while b.observeYingzhao(a.student)['part_'..part]~='exposed'do
     wait(function()return a:available('laser')and not a:isAttacking()end);attempts=attempts+1;assert(attempts<=2)
     assert(A.request(b,a,'shoot@'..part,'qa-armor-setup'))
     wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor('wuyun')end)
    end
   end
   assert(supplies:observation('wuyun').ammo.emp==1)
   assert(A.request(b,a,'bmove','qa-positioning'))
   wait(function()return math.abs(a.student.x-(side<0 and b.minX or b.maxX))<1 end)
   a.student:stop();a.student.velocityX=0
   assert(g:attack('hunt',b.arena.student));wait(function()return #g.hunt.children==2 end)
   for _,child in ipairs(g.hunt.children)do
    local childUpdate=child.guard.update
    child.guard.update=function(self,now)self.nextAttack=math.huge;childUpdate(self,now);self.nextAttack=math.huge end
   end
   wait(function()if g.busy then return false end;for _,child in ipairs(g.hunt.children)do if child.pendingPounce or child.guard.busy then return false end end;return true end)
   row.hunt=g.strike;assert(row.hunt.summons.spawned==2)
   assert(g:attack('wave',b.arena.student));local strike=g.strike;D.sleep(.1)
   assert(A.request(b,a,'bmove','qa-positioning'));D.sleep(.05);assert(b:command('stop'))
   row.before=b.observeYingzhao(a.student);local s=row.before
   assert(s.arenaEdge==(side<0 and'left'or'right')and s.bossAction=='wave'and s.waveReach=='clear'and s.threat=='none'and s.target=='boss'and s.summons=='multiple'and s.empAmmo=='low'and s.bladeAmmo=='ready')
   wait(function()return not g.busy and #g.waves==0 end)
   row.wave=strike;row.hp=a.studentHP;row.mentorHP=b.mentorHP;save()
   assert(strike.completed and strike.wave and strike.wave.reason=='RANGE')
   for _,hit in ipairs(strike.wave.hits)do assert(hit.actor~='wuyun','Wave reached boundary learner')end
   assert(row.hp==100)
   local hp=boss.enemyHP
   for i=1,3 do
    wait(function()return b.mentorAim.canStart()end);assert(require('Training.YingzhaoMentor').shoot(b))
    wait(function()return not b.mentor:isDoing('groundMentorShot')and not b.bossCombat:pendingActor('mentor')end)
   end
   row.healthDamage=hp-boss.enemyHP;assert(row.healthDamage>0)
   assert(supplies:observation('wuyun').ammo.emp==1 and supplies:observation('wuyun').ammo.blade==12)
   b:finish('aborted','Safe boundary conservation lesson');wait(function()return b.phase=='aborted'end)
   local resources=supplies:evidence();b.bossTrace.resources=resources
   row.source={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='wuyun',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   local data=assert(require('Training.YingzhaoPolicy').inspect({row.source},'wuyun'));row.samples=#data.samples;row.actions=data.actions
   assert(#data.samples==1 and data.actions.idle==1,'Setup leaked into conservation label')
   assert(data.samples[1].state.waveReach=='clear'and data.samples[1].state.bossAction=='wave');save()
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
