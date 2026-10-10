-- Explicit overlapping edge fixtures through the public demonstration commands.
-- Boss attacks are paused here: this tests locomotion/learning, not survival.
local D=require('Dora');local entry,qaResultName=...;local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'yingzhao-edge-lesson-result.json');local r={status='RUNNING',actors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local F=require('Training.YingzhaoFeatures');local P=require('Training.YingzhaoPolicy')
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Edge lesson timeout');D.sleep(.02)end end
  for _,actor in ipairs({'ninilite','wuyun'})do
   local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor=actor,item='emp',quantity=6}},actor)
   local a=actor=='ninilite'and b.arena or b.wuyun;local other=actor=='ninilite'and b.wuyun or b.arena
   local boss=b.enemies[1];assert(b:start());boss.guard.nextAttack=math.huge;other.mode='review'
   local row={cases={}};r.actors[actor]=row
   local first
   for _,side in ipairs({'left','right','left','right','left','right'})do
    local x=side=='left'and b.minX or b.maxX;local direction=side=='left'and 1 or -1
    a.student:stop();a.student.faceRight=true;a.student.velocity=D.Vec2.zero;a.student.position=D.Vec2(x,b.world.offset+155)
    boss.enemy:stop();boss.enemy.velocity=D.Vec2.zero;boss.enemy.position=D.Vec2(x,b.world.offset+255)
    b.mentor.x=1920;other.student.x=2020;D.sleep(.3)
    local before=b.observeYingzhao(a.student);assert(F.validate(before)and before.arenaEdge==side and before.targetBossSide=='overlap')
    if side=='left'then first=before else assert(F.key(first,3)==F.key(before,3),'Legacy observations distinguish these supposedly aliased cases')end
    local forged=D.json.decode(D.json.encode(before),32);forged.arenaEdge=side=='left'and'right'or'left';assert(not F.validate(forged))
    local old=D.json.decode(D.json.encode(before),32);old.featureSchemaVersion=3;old.arenaEdge=nil;old.arenaMinX=nil;old.arenaMaxX=nil
    assert(F.validate(old)and F.project(old,4).arenaEdge=='unknown')
    local command=side=='left'and'right'or'left'
    local commands=0;local firstStep=#b.bossTrace.steps;local started=D.App.runningTime
    while math.abs(a.student.x-boss.enemy.x)<=700 do assert(b:command(command));commands=commands+1;D.sleep(.02)end
    assert(#b.bossTrace.steps-firstStep<=math.ceil((D.App.runningTime-started)/.25)+2,'Held input flooded movement records')
    a.student:stop();a.student.velocityX=0
    local travel=(a.student.x-x)*direction;assert(travel>250 and a.studentHP==100)
    row.cases[#row.cases+1]={edge=side,travel=travel,before=before,commands=commands};save()
    -- Each left/right pair shares unchanged ammunition and armor. Real shots
    -- after the pair create the next pair's ready/low state in the same ledger.
    if side=='right'then
     for shot=1,2 do
      wait(function()return a:available('laser')and not boss.guard.reacting end)
      local A=require('Training.YingzhaoActions')
      local function choose()
       local observed=b.observeYingzhao(a.student)
       for _,part in ipairs({'head','forelegs','arms','hindlegs','torso','flank'})do
        if observed['part_'..part]~='exposed'and A.plan(b,a,part)then return part end
       end
      end
      local chosen=choose()
      if not chosen then
       -- Fixture-only sightline adjustment, excluded from learned movement.
       -- Keep the same live armor/ammunition; never replenish or clear it.
       assert(A.request(b,a,'bmove','scripted'))
       local deadline=D.App.runningTime+8
       repeat D.sleep(.02);chosen=choose()until chosen or math.abs(a.student.x-boss.enemy.x)>1500 or D.App.runningTime>=deadline
       a.student:stop();a.student.velocityX=0;chosen=choose();row.sightlineAdjustments=(row.sightlineAdjustments or 0)+1
      end
      assert(chosen,'No reachable armored part after escape')
      assert(b:command('aim-part',chosen));assert(b:command('shoot'))
      wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor(actor)and not boss.guard.reacting end)
     end
    end
   end
   b:finish('aborted','Scripted edge locomotion lesson');wait(function()return b.phase=='aborted'end)
   local resources=b.supplies:evidence();b.bossTrace.resources=resources
   local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator=actor,episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   local data=assert(P.inspect({e},actor));assert(#data.samples>=18 and data.actions.fmove==3 and data.actions.bmove>=15)
   local old=assert(P.buildAsync({e},actor,3));assert(old.trainingAccuracy<1,'Old schema unexpectedly learns opposite edge actions')
   local model=assert(P.buildAsync({e},actor));row.source=e;row.model=model;save()
   assert(model.featureSchemaVersion==require('Training.YingzhaoFeatures').version) -- Fitting is reported; only actual escape predictions are required below.
   for _,c in ipairs(row.cases)do assert(P.predict(model,c.before,function()return true end)==(c.edge=='left'and'fmove'or'bmove'))end
   local coverage={move={},shot={}}
   for _,sample in ipairs(data.samples)do local group=sample.action:match('^shoot@')and'shot'or'move';coverage[group][sample.state.empAmmo]=true end
   assert(coverage.move.ready and coverage.move.low and coverage.shot.ready and coverage.shot.low,'Ammo still aliases movement and shooting')
   assert(b.supplies.emissions==6)
   row.coverage=coverage;row.shots=b.supplies.emissions;row.source=e;row.model=model;row.samples=#data.samples;row.oldSchemaAccuracy=old.trainingAccuracy;save()
  end
  r.notNaturalVictory=true;r.notHumanDemonstration=true;r.noDamageFixture=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
