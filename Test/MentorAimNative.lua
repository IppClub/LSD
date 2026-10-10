local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/mentor-aim-native-result.json';local r={status='RUNNING',shots={}}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f,t)local endAt=D.App.runningTime+(t or 6);while not f()do assert(D.App.runningTime<endAt,'Aim wait timeout');D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge;e.unit.x=11000 end
  wait(function()return b.mentor.onSurface end)
  for _,case in ipairs({{hold=.03,right=true},{hold=.38,right=true},{hold=.38,right=false}})do
   wait(function()return not b.mentor:isDoing('groundMentorShot') and D.App.runningTime>=b.nextMentorShot end)
   b.mentor.faceRight=case.right;local before=#b.projectiles
   assert(b.mentorAim:begin());D.sleep(case.hold);assert(#b.projectiles==before,'Fired during hold')
   assert(b.mentorAim:release());local angle=b.mentorAim.angle
   wait(function()return #b.projectiles>before end)
   local bullet=b.projectiles[#b.projectiles];assert(bullet.parent)
   assert((bullet.velocityX>0)==case.right,'Wrong facing')
   assert(math.abs(bullet.velocityY+math.sin(math.rad(angle))*2400)<3,'Velocity ignored aim')
   if case.hold<.15 then assert(angle==0)else assert(math.abs(angle)>10)end
   r.shots[#r.shots+1]={hold=case.hold,right=case.right,angle=angle,vx=bullet.velocityX,vy=bullet.velocityY}
   assert(not b.mentorAim:release(),'Duplicate release fired')
  end
  wait(function()return not b.mentor:isDoing('groundMentorShot') and D.App.runningTime>=b.nextMentorShot end)
  assert(b.mentorAim:begin());b.mentorAim:cancel();assert(not b.mentorAim:release())
  b.mentor.faceRight=true;b.enemies[2].unit.position=b.mentor.position+D.Vec2(400,0)
  assert(b:command('shoot'));wait(function()return b.mentorHits>0 end);r.legacyHit=true
  wait(function()return not b.mentor:isDoing('groundMentorShot') and D.App.runningTime>=b.nextMentorShot end)
  assert(b.mentorAim:begin());b.phase='aborted';D.sleep(.05);assert(not b.mentorAim.held and not b.mentorAim:release())
  r.cancelled=true;assert(#b.mentorCasings==4,'Casing count');D.sleep(10.6);assert(#b.mentorCasings==0,'Casing leak');r.casingsCleaned=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
