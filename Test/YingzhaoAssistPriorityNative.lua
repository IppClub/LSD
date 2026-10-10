local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-assist-priority-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')})
  local a=b.arena;local boss=b.enemies[1];assert(b:start());a.mode='demo';b.wuyun.mode='review';boss.guard.nextAttack=math.huge
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Assist priority timeout');D.sleep(.02)end end
  a.student.x=1700;boss.enemy.x=2500;b.mentor.x=1400;b.wuyun.student.x=1500;D.sleep(.5)
  -- Isolate support-cast arbitration from rifle hit reactions cancelling wave.
  b.mentorAim.canStart=function()return false end
  assert(boss.guard:attack('wave',a.student));D.sleep(.1)
  assert(require('Training.YingzhaoActions').request(b,a,'bmove','scripted'))
  local hp=a.studentHP;local start=a.student.x;local mentor=require('Training.YingzhaoMentor');local state=mentor.new()
  mentor.step(b,state);D.sleep(.1)
  r.castDuringRetreat=b.magic:busy('fire');r.moving=a.student:isDoing(a.physical.bmove);save()
  assert(not r.castDuringRetreat and r.moving,'Auto fire overrides learner retreat')
  while boss.guard.busy do mentor.step(b,state);D.sleep(.1)end;boss.guard.nextAttack=math.huge
  assert(boss.guard.strike.completed and not boss.guard.strike.cancelled,'Wave was interrupted by assistance')
  assert(a.studentHP==hp and a.student.x<start-200,'Assisted retreat did not evade wave')
  a.student:stop();b.wuyun.student:stop();D.sleep(.2)
  mentor.step(b,state);D.sleep(.1)
  assert(b.magic:busy('fire'),'Safe assistance no longer casts')
  r.safeCast=true;r.hp=a.studentHP;r.travel=start-a.student.x
  b:finish('aborted','Assist priority fixture');wait(function()return b.phase=='aborted'end)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
