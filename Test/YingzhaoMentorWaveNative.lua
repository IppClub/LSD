local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-mentor-wave-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')})
  local boss=b.enemies[1];assert(b:start());b.arena.mode='review';b.wuyun.mode='review';boss.guard.nextAttack=math.huge
  -- Isolate visible-cue movement from damage interrupting the attack.
  b.mentorAim.canStart=function()return false end;b.magic.ready.fire=D.App.runningTime+3600;b.magic.ready.wind=D.App.runningTime+3600
  local M=require('Training.YingzhaoMentor')
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Mentor wave timeout');D.sleep(.02)end end
  for _,direction in ipairs({-1,1})do
  for _,distance in ipairs({900,1400})do
   local x=direction==-1 and 2500 or 2000
   boss.enemy:stop();boss.enemy.velocity=D.Vec2.zero;boss.enemy.position=D.Vec2(x,b.world.offset+255)
   b.mentor:stop();b.mentor.velocity=D.Vec2.zero;b.mentor.position=D.Vec2(x+direction*distance,b.world.offset+155)
   b.arena.student.x=x-direction*400;b.wuyun.student.x=x-direction*500;D.sleep(.5)
   local hp=b.mentorHP;local start=b.mentor.x;local state=M.new()
   assert(boss.guard:attack('wave',b.mentor));D.sleep(.1)
   while boss.guard.busy do M.step(b,state);D.sleep(.1)end;boss.guard.nextAttack=math.huge
   assert(boss.guard.strike.completed and not boss.guard.strike.cancelled)
   local row={distance=distance,direction=direction,damage=hp-b.mentorHP,travel=(b.mentor.x-start)*direction};r.cases[#r.cases+1]=row;save()
   assert(row.damage==0,'Wave damaged mentor')
   if distance==900 then assert(row.travel>250 and row.travel<500,'Retreat should end outside wave reach')else assert(math.abs(row.travel)<1,'Mentor retreated from unreachable wave')end
  end
  end
  b:finish('aborted','Controlled mentor wave fixture');wait(function()return b.phase=='aborted'end)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
