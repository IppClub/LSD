local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/part-aim-native-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local model={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId='ninilite',sampleCount=6,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}
  local b=require('Ground.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m02',model=model})
  local a=b.arena;a.externalCombat=true;a.mode='demo'
  local function wait(f)local limit=D.App.runningTime+5;while not f()do assert(D.App.runningTime<limit,'Aim wait');D.sleep(.01)end end
  wait(function()return a.student.onSurface and a.enemy.onSurface end)
  D.sleep(.3);a.student.faceRight=true
  local reachable={};local strongest,angle
  for _,name in ipairs({'head','head-gem','back-front','back-rear','front-leg','rear-leg','tail'})do
   local solution=b.partCombat:aim(a.student,name);if solution then reachable[#reachable+1]=name;if not angle or math.abs(solution.angle)>angle then strongest=name;angle=math.abs(solution.angle)end end
  end
  assert(#reachable>0,'No reachable part')
  assert(a.student.playable:setBoneRotation('aim',0),'Student aim bone missing')
  local part=assert(strongest,'No angled reachable part');r.selected=part;r.previewAngle=angle;assert(a.selectPart(part));assert(not a.selectPart('missing'))
  assert(a:request('laser','demo'));wait(function()return #a.projectiles>0 end)
  local bullet=a.projectiles[#a.projectiles];local step=b.partCombat.journal.steps[1];r.firstStep=step;save()
  assert(step.action.intendedPart==part and step.action.muzzle and math.abs(step.action.aimAngle)<=45 and math.abs(step.action.aimAngle)>.1,'Angled fire not exercised')
  assert(math.abs(math.deg(math.atan(bullet.velocityY,math.abs(bullet.velocityX)))+step.action.aimAngle)<.01)
  wait(function()return #b.partCombat.events>0 end)
  r.first={intended=part,actual=b.partCombat.events[1].part,angle=step.action.aimAngle};assert(r.first.actual==part,'Stationary first-ray hit disagreed')
  wait(function()return not a:isAttacking() and a:available('laser')end)
  assert(a.selectPart(part));assert(a:request('laser','demo'))
  local previous=#b.partCombat.events;local energy=a.studentEnergy
  wait(function()return #b.partCombat.shots>0 end)
  -- Move the target only after the projectile is emitted: it must not home.
  a.enemy.position=a.enemy.position+D.Vec2(0,1000)
  D.sleep(1.3);assert(#b.partCombat.events==previous,'Projectile became a guaranteed hit')
  assert(a.studentEnergy<energy,'Actual emitted shot did not spend energy')
  r.movingTargetMiss=true;r.reachable=reachable
  b:finish('aborted','Native part aim fixture')
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
