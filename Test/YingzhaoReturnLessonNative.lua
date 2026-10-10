-- Controlled continuous post-armor lesson, real paid shots and full skill/wave timelines.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-return-lesson-result.json';local r={status='RUNNING',cases={},notHumanDemonstration=true,notNaturalVictory=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local A=require('Training.YingzhaoActions');local P=require('Training.YingzhaoPolicy')
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local deadline=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<deadline,'Exposed lesson timeout');D.sleep(.02)end end
  for _,direction in ipairs({1,-1})do
   local b=require('Training.BigYingzhaoPractice').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},{{actor='wuyun',item='emp',quantity=12},{actor='wuyun',item='blade',quantity=12}},'wuyun')
   local a=b.wuyun;local boss=b.enemies[1];local g=boss.guard;local update=g.update
   g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());b.arena.mode='review';a.student.x=1020;b.mentor.x=1920+direction*1200;b.mentor.faceRight=direction==1;b.arena.student.x=1920+direction*1300
   D.sleep(.5);local row={direction=direction,shots={},cycles={}};r.cases[#r.cases+1]=row
   -- Establish exposed armor through actual paid projectiles, never modify knowledge/AP.
   for shot=1,8 do
    if b.observeYingzhao(a.student).part_head=='exposed'then break end
    wait(function()return a:available('laser')and not g.reacting end)
    assert(A.request(b,a,'shoot@head','scripted',2))
    wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor('wuyun')and not g.reacting end)
    row.shots[#row.shots+1]=b.bossTrace.hits[#b.bossTrace.hits];save()
   end
   assert(b.observeYingzhao(a.student).part_head=='exposed','Paid shots did not expose head')
   -- Mirror the controlled starting side only after the real frontal head shot.
   if direction==-1 then a.student.position=D.Vec2(2820,b.world.offset+155);a.student.velocity=D.Vec2.zero;D.sleep(.4)end
   for cycle=1,2 do
    wait(function()return b.magic:available('wind')and not g.reacting and not g.busy and D.App.runningTime>=(g.nextReaction or 0)end)
    -- Real return movement remains outside teaching; response movement below is demonstration.
    local target=boss.enemy.x-direction*650
    a.student.faceRight=direction==1
    if math.abs(a.student.x-target)>30 then
     assert(A.request(b,a,(target-a.student.x)*direction>0 and'fmove'or'bmove','scripted',2))
     wait(function()return math.abs(a.student.x-target)<30 end);a.student:stop()
    end
    assert(g:attack('wave',a.student));local strike=g.strike;D.sleep(.1)
    assert(b:command('wind'));local log=b.magic.logs[#b.magic.logs]
    wait(function()return not b.magic:busy('wind')and not g.busy end)
    assert(log.hits==1 and strike.cancelled=='HIT'and a.studentHP==100)
    wait(function()return not g.reacting end)
    assert(g:attack('wave',a.student));local dodge=g.strike;D.sleep(.1)
    local before=b.observeYingzhao(a.student);assert(before.part_head=='exposed'and before.skillState=='cooldown')
    assert(b:command(direction==1 and'left'or'right'))
    wait(function()return not g.busy and #g.waves==0 end);assert(b:command('stop'));assert(a.studentHP==100,'Cooldown retreat took damage')
    -- Continue the same demonstration: re-enter range and pay for a follow-up shot.
    local returnBefore=b.observeYingzhao(a.student)
    assert(b:command(direction==1 and'right'or'left'))
    wait(function()return math.abs(a.student.x-boss.enemy.x)<=900 end);assert(b:command('stop'))
    wait(function()return a:available('laser')and not g.reacting end)
    local observation=b.observeYingzhao(a.student);local part
    for _,id in ipairs({'forelegs','arms','torso','flank','hindlegs'})do if observation['part_'..id]~='exposed'and A.plan(b,a,id)then part=id;break end end
    assert(part,'No follow-up armor target');local n=#b.bossTrace.hits
    assert(b:command('aim-part',part));assert(b:command('shoot'))
    wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor('wuyun')end)
    local damage=0;for i=n+1,#b.bossTrace.hits do damage=damage+b.bossTrace.hits[i].armorDamage end
    assert(damage>0,'Follow-up shot did not damage armor')
    row.cycles[#row.cycles+1]={cast=log,castStrike=strike,dodgeStrike=dodge,before=before,hp=a.studentHP,returnBefore=returnBefore,shotBefore=observation,shotPart=part,armorDamage=damage};save()
   end
   assert(b:finish('aborted','Post-armor counter and cooldown retreat lesson'));wait(function()return b.phase=='aborted'end)
   local resources=b.supplies:evidence();b.bossTrace.resources=resources
   row.source=D.json.decode(D.json.encode({schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='wuyun',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace},false,true),32)
   local data=assert(P.inspect({row.source},'wuyun'));row.actions=data.actions;row.samples=#data.samples
   assert(data.actions['wind@'..(direction==1 and'right'or'left')]==2 and data.actions.bmove==2)
   for _,s in ipairs(data.samples)do assert(s.state.part_head=='exposed');if s.action:match('^shoot@')then assert(s.firstStep>1,'Setup shot leaked into samples')end end
   assert(data.actions.fmove==2 and b.supplies.emissions==3,'Continuous follow-up missing')
   save()
  end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
