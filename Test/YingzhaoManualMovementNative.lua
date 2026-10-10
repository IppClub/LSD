-- Native command-path QA, not OS input or a human training demonstration.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-manual-movement-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Training.BigYingzhaoPractice').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},{{actor='ninilite',item='emp',quantity=1}},'ninilite')
  local a=b.arena;local boss=b.enemies[1];assert(b:start());b.wuyun.mode='review';boss.guard.nextAttack=math.huge;D.sleep(.5)
  assert(b:command('right'));D.sleep(.2);assert(a.student.velocityX>0)
  -- A different side can become the nearest target before the next input.
  boss.enemy.x=a.student.x-500
  local accepted,why=b:command('left');D.sleep(.15)
  r.turn={accepted=accepted,reason=why,velocity=a.student.velocityX,faceRight=a.student.faceRight}
  assert(accepted and a.student.velocityX<0 and not a.student.faceRight,'Repeated forward label ignored changed direction')
  assert(b:command('stop'))
  local movements={}
  for _,step in ipairs(b.bossTrace.steps)do if step.actor=='ninilite'and step.origin=='demo'and step.action=='fmove'then movements[#movements+1]=step end end
  assert(#movements==2 and movements[1].ended and movements[2].ended,'Direction change did not close separate intervals')
  assert(movements[1].after.ownX>movements[1].before.ownX and movements[2].after.ownX<movements[2].before.ownX,'Movement evidence disagrees with input')
  r.separateIntervals=true
  a.student.x=2250;boss.enemy.x=2000;b.mentor.x=1400;b.wuyun.student.x=1500;D.sleep(.3)
  assert(boss.guard:attack('massive',a.student))
  local K=require('Combat.Displacement');local deadline=D.App.runningTime+10
  while not K.blocked(a.student)do assert(D.App.runningTime<deadline);D.sleep(.01)end
  local velocity=a.student.velocityX;local accepted,why=b:command('stop')
  assert(not accepted and why=='DISPLACED','Stop command bypassed forced movement')
  assert(a.student.velocityX==velocity,'Stop erased knockback velocity')
  while K.blocked(a.student)or boss.guard.busy do assert(D.App.runningTime<deadline);D.sleep(.02)end;boss.guard.nextAttack=math.huge
  assert(b:command('stop'));r.recoveryProtected=true
  b:finish('aborted','Manual movement fixture');r.notHumanDemonstration=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
