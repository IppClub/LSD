-- Scripted command-path lessons at controlled positions, never human samples
-- or evidence of a natural Boss victory. C4.5 rules must come from execution.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-wave-learning-result.json';local r={status='RUNNING',trials={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Wave learning timeout');D.sleep(.02)end end
  local function setup(b,direction,distance)
   local a=b.arena;local boss=b.enemies[1];local x=direction==1 and 2000 or 2600
   a.student:stop();a.student.velocity=D.Vec2.zero;a.student.position=D.Vec2(x+direction*(distance or 700),b.world.offset+155)
   boss.enemy:stop();boss.enemy.velocity=D.Vec2.zero;boss.enemy.position=D.Vec2(x,b.world.offset+255);boss.guard.nextAttack=math.huge
   b.mentor.x=x-direction*700;b.wuyun.student.x=x-direction*800;b.wuyun.mode='review'
   D.sleep(.4);wait(function()return a.student.onSurface and boss.enemy.onSurface end)
   return a,boss
  end
  local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor='ninilite',item='emp',quantity=1}},'ninilite')
  assert(b:start());b.enemies[1].guard.nextAttack=math.huge
  for i,direction in ipairs({1,-1,1})do
   local a,boss=setup(b,direction,({650,800,950})[i])
   assert(b:command('stop'));D.sleep(.3)
   assert(boss.guard:attack('wave',a.student));D.sleep(.1)
   assert(b:command(direction==1 and'right'or'left'))
   wait(function()return not boss.guard.busy end);boss.guard.nextAttack=math.huge
   a.student:stop();assert(a.studentHP==100,'Lesson did not evade real wave')
  end
  b:finish('aborted','Scripted defensive lesson fixture');wait(function()return b.phase=='aborted'end)
  local resources=b.supplies:evidence();b.bossTrace.resources=resources
  local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='ninilite',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
  local review=assert(require('Training.YingzhaoReview').rebuild(e));r.reviewText=require('Training.YingzhaoReview').text(review)
  assert(r.reviewText:find('后退 3 段',1,true)and r.reviewText:find('停留 3 段',1,true),'Defensive lesson omitted from review')
  local P=require('Training.YingzhaoPolicy');local data=assert(P.inspect({e},'ninilite'));r.actions=data.actions
  assert(data.actions.bmove==3 and data.actions.idle==3,'Missing executed defensive samples')
  local m=assert(P.buildAsync({e},'ninilite'));r.model=m;r.source=e;save()
  assert(m.sampleCount==6 and m.trainingAccuracy==1)
  local frozen=D.json.decode(D.json.encode(m,false,true),32)
  local virtual=assert(require('Economy.CombatSession').virtual('wave-learned-trial',{{actor='ninilite',item='emp',quantity=1}}))
  local trial=require('Enemy.BigYingzhaoBattle').createAsync(models,virtual,{virtual=true})
  require('Training.YingzhaoTrial').attach(trial,m);assert(trial:start());trial.enemies[1].guard.nextAttack=math.huge
  for _,direction in ipairs({1,-1})do
   local a,boss=setup(trial,direction,direction==1 and 750 or 850);local before=a.studentHP;local x=a.student.x;local decisions=#trial.yingzhaoCandidateDecisions
   assert(boss.guard:attack('wave',a.student))
   wait(function()return not boss.guard.busy end);boss.guard.nextAttack=math.huge
   local count=0;for i=decisions+1,#trial.yingzhaoCandidateDecisions do local d=trial.yingzhaoCandidateDecisions[i];if d.accepted and d.action=='bmove'then count=count+1 end end
   local row={direction=direction,damage=before-a.studentHP,retreatDecisions=count,travel=(a.student.x-x)*direction};r.trials[#r.trials+1]=row;save()
   assert(row.damage==0 and count>0 and row.travel>100,'Learned frozen policy did not evade')
  end
  assert(require('Training.FlowerIdentity').equal(m,frozen)and require('Training.FlowerIdentity').equal(trial.yingzhaoCandidate,frozen),'Frozen model changed')
  assert(#trial.arena.recorder.samples==0);trial:finish('aborted','Frozen evasion fixture');wait(function()return trial.phase=='aborted'end)
  r.notHumanDemonstration=true;r.notNaturalVictory=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
