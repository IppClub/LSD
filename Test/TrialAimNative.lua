local script,mission=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script));local out=root..'/Test/trial-aim-native-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={mission=mission,shots={}};local ok,err=xpcall(function()
  local b=require('Trial.Battle').createAsync({finishAsync=function()return true end},{mission=mission})
  assert(not b.heroAim:begin());assert(b:begin());b.nextNpc=math.huge
  local function wait(f)local limit=D.App.totalTime+8;while not f()do assert(D.App.totalTime<limit,'Trial aim timeout');D.sleep(.02)end end
  for _,hold in ipairs({.06,.35})do
   wait(function()return b.heroAim.canStart() and not b.heroAim.shot end)
   local count=#b.projectiles;assert(b.heroAim:begin());D.sleep(hold);assert(#b.projectiles==count and b.heroAim.line.visible)
   assert(b.heroAim:release());wait(function()return #b.projectiles>count end)
   local bullet=b.projectiles[#b.projectiles];local angle=b.heroAim.angle;local vy=bullet.velocityY
   assert(hold>.15 and math.abs(angle)>10 or hold<=.15 and angle==0)
   assert(math.abs(vy+math.sin(math.rad(angle))*2400)<3)
   if hold<=.15 then wait(function()return b.heroHits>0 end)end
   r.shots[#r.shots+1]={hold=hold,angle=angle,vy=vy}
  end
  assert(#b.casings==2);r.actualHit=b.heroHits>0
  wait(function()return b.heroAim.canStart()and not b.heroAim.shot end);assert(b.heroAim:begin());b.heroAim:cancel();assert(not b.heroAim:release());r.cancelled=true
  b:finish('aborted','QA')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
