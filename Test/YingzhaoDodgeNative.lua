-- Controlled start positions; real Boss timelines and learner movement.
-- This tests evasion feasibility, not a learned policy or a natural victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-dodge-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')})
  local boss=b.enemies[1];local a=b.arena;local K=require('Combat.Displacement')
  assert(b:start());a.mode='demo';a.recorder.active=false;b.wuyun.mode='review';boss.guard.nextAttack=math.huge
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Dodge fixture timeout');D.sleep(.02)end end
  for _,direction in ipairs({1,-1})do
  for _,dodge in ipairs({false,true})do
   local bossX=direction==1 and 2200 or 2600
   K.clear(a.student);a.student:stop();a.student.velocity=D.Vec2.zero;a.student.position=D.Vec2(bossX+direction*700,b.world.offset+155)
   boss.enemy:stop();boss.enemy.velocity=D.Vec2.zero;boss.enemy.position=D.Vec2(bossX,b.world.offset+255)
   b.mentor.x=bossX-direction*700;b.wuyun.student.x=bossX-direction*800;boss.guard.nextAttack=math.huge
   D.sleep(.5);wait(function()return a.student.onSurface and boss.enemy.onSurface end)
   local hp=a.studentHP;local x=a.student.x
   assert(boss.guard:attack('massive',a.student));D.sleep(.1)
   local observation=b.observeYingzhao(a.student)
   assert(observation.bossAction=='massive'and observation.distance>650)
   assert(observation.threat=='melee','Advancing Boss incorrectly appears safe at 700 distance')
   local behind=b.observeYingzhao(b.mentor);assert(behind.threat=='none','Rear side marked as forward melee')
   if dodge then assert(require('Training.YingzhaoActions').request(b,a,'bmove','scripted'))end
   wait(function()return not boss.guard.busy end);boss.guard.nextAttack=math.huge
   local damage=hp-a.studentHP
   r.cases[#r.cases+1]={direction=direction,dodge=dodge,damage=damage,travel=(a.student.x-x)*direction,bossTravel=(boss.enemy.x-bossX)*direction,threat=observation.threat};save()
   if dodge then assert(damage==0 and (a.student.x-x)*direction>250,'Timely retreat did not evade')
   else assert(damage>0,'Stationary control was not hit')end
   wait(function()return not K.blocked(a.student)end)
  end
  end
  b:finish('aborted','Controlled dodge feasibility fixture')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
