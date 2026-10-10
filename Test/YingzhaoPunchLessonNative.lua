-- Controlled close-range geometry; actual punch and command-path retreat.
-- Fixture repositioning is not human input or a natural encounter.
local D=require('Dora');local entry,qaResultName=...;local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'yingzhao-punch-lesson-result.json');local r={status='RUNNING',actors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Punch lesson timeout');D.sleep(.02)end end
  for _,actor in ipairs({'ninilite','wuyun'})do
   local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor=actor,item='emp',quantity=5}},actor)
   local a=actor=='ninilite'and b.arena or b.wuyun;local other=actor=='ninilite'and b.wuyun or b.arena
   local boss=b.enemies[1];assert(b:start());boss.guard.nextAttack=math.huge;other.mode='review'
   local function setup(direction)
    a.student:stop();a.student.velocity=D.Vec2.zero;a.student.position=D.Vec2(2400+direction*250,b.world.offset+155)
    boss.enemy:stop();boss.enemy.velocity=D.Vec2.zero;boss.enemy.position=D.Vec2(2400,b.world.offset+255)
    other.student.x=2400-direction*800;b.mentor.x=2400-direction*700
    D.sleep(.4);wait(function()return a.student.onSurface and boss.enemy.onSurface end)
   end
   setup(1);local hp=a.studentHP
   assert(boss.guard:attack('punch',a.student));wait(function()return not boss.guard.busy end);boss.guard.nextAttack=math.huge
   local row={controlDamage=hp-a.studentHP,trials={}};r.actors[actor]=row;save();assert(row.controlDamage>0,'Stationary control not hit')
   for _,direction in ipairs({1,-1,1})do
    setup(direction);local hp=a.studentHP;local x=a.student.x
    assert(boss.guard:attack('punch',a.student));D.sleep(.1)
    assert(b:command(direction==1 and'right'or'left'))
    wait(function()return not boss.guard.busy end);boss.guard.nextAttack=math.huge;a.student:stop()
    row.trials[#row.trials+1]={direction=direction,damage=hp-a.studentHP,travel=(a.student.x-x)*direction};save()
    assert(hp==a.studentHP and (a.student.x-x)*direction>150,'Early retreat failed to evade punch')
   end
   b:finish('aborted','Controlled punch teaching fixture');wait(function()return b.phase=='aborted'end)
   local resources=b.supplies:evidence();b.bossTrace.resources=resources
   local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator=actor,episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   local samples=assert(require('Training.YingzhaoPolicy').inspect({e},actor))
   assert(#samples.samples==3 and samples.actions.bmove==3 and not samples.actions.idle,'Control/wait leaked into lesson')
   row.source=e;row.samples=#samples.samples;save()
  end
  r.notNaturalVictory=true;r.notHumanDemonstration=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
