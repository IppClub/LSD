local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/pursuit-aim-hud-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={shots={}};local ok,err=xpcall(function()
  local c=require('Ruins.PursuitLevel').openAsync({finishAsync=function()return true end},{mission='c0-m06'});local b=c.battle
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end;b.mentorHP=10000
  local function wait(f)local untilAt=D.App.totalTime+6;while not f()do assert(D.App.totalTime<untilAt,'HUD aim timed out');D.sleep(.01)end end
  local hud=assert(D.Director.ui3D:getChildByTag('pursuit-hud'))
  for _,hold in ipairs({.06,.35})do
   wait(function()return b.mentor.onSurface and b.mentorAim.canStart()end)
   local count=#b.projectiles;hud.weapon:emit('TapBegan');D.sleep(hold)
   assert(b.mentorAim.held and b.mentorAim.line.visible and #b.projectiles==count,'HUD press fired early')
   hud.weapon:emit('TapEnded');wait(function()return #b.projectiles>count end)
   local bullet=b.projectiles[#b.projectiles];local angle=b.mentorAim.angle
   assert(hold>.15 and math.abs(angle)>10 or hold<=.15 and angle==0,'Hold/tap aim convention')
   assert(math.abs(bullet.velocityY+math.sin(math.rad(angle))*2400)<3)
   r.shots[#r.shots+1]={hold=hold,angle=angle,vy=bullet.velocityY}
   wait(function()return not b.mentorAim.shot end)
  end
  wait(function()return b.mentorAim.canStart()end);hud.weapon:emit('TapBegan');D.sleep(.04);assert(b.mentorAim.held)
  b:finish('aborted','QA');D.sleep(.05);assert(not b.mentorAim.held and not b.mentorAim:release());r.cancelledOnExit=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
