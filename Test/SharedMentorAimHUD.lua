local script,variant=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script));local out=root..'/Test/shared-mentor-aim-hud-result.json';local r={status='RUNNING',variant=variant,shots={}};D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS' and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/shared-aim-'..variant..'-'..os.time()..'.db';assert(not D.DB:existDB('lsd') and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local models={};for _,id in ipairs({'ninilite','wuyun'})do models[id]={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local c,hud
  if variant=='mission'then
   c=require('Mission.Level').openAsync({finishAsync=function()return true end},{mission='c0-m01',model=models.ninilite},'charM');hud=D.Director.ui3D:getChildByTag('mission-hud')
  elseif variant=='energy'then
   c=require('Ground.EnergyLevel').openAsync({finishAsync=function()return true end},{mission='c0-m03',models=models});hud=D.Director.ui3D:getChildByTag('energy-battle-hud')
  else
   local modules={patrol='Factory.PatrolBattle',second='Factory.SecondPatrolBattle',researcher='Factory.ResearcherBattle',rescue='Rescue.Battle',defense='Academy.DefenseBattle',final='Final.Battle'}
   local factory=require(assert(modules[variant])).createAsync
   c=require('Factory.PatrolLevel').openAsync(models,function()end,{battleFactory=function(m)return factory(m,'defence')end});hud=c.hud
   hud.weapon:emit('TapBegan');D.sleep(.04);assert(not c.battle.mentorAim.held,'Aim started while ready');hud.weapon:emit('TapEnded');c.start:emit('Tapped')
  end
  local b=c.battle;local function wait(f)local untilAt=D.App.totalTime+10;while not f()do assert(D.App.totalTime<untilAt,'Aim HUD timeout '..variant);D.sleep(.01)end end
  wait(function()return b.phase=='playing' and b.mentor.onSurface end)
  for _,hold in ipairs({.06,.35})do
   wait(function()return b.mentorAim.canStart() and not b.mentorAim.shot end)
   local count=#b.arena.projectiles;hud.weapon:emit('TapBegan');D.sleep(hold)
   assert(b.mentorAim.held and b.mentorAim.line.visible and #b.arena.projectiles==count,'Early fire '..variant)
   hud.weapon:emit('TapEnded');wait(function()return #b.arena.projectiles>count end)
   local bullet=b.arena.projectiles[#b.arena.projectiles];local angle=b.mentorAim.angle
   assert(hold>.15 and math.abs(angle)>10 or hold<=.15 and angle==0,'Wrong aim convention')
   assert(math.abs(bullet.velocityY+math.sin(math.rad(angle))*2400)<3,'Wrong bullet direction')
   r.shots[#r.shots+1]={hold=hold,angle=angle,vy=bullet.velocityY}
   if variant=='mission' and hold<=.15 then wait(function()return b.mentorHits>0 end);r.actualHit=true end
  end
  wait(function()return b.mentorAim.canStart() and not b.mentorAim.shot end);hud.weapon:emit('TapBegan');D.sleep(.04);assert(b.mentorAim.held)
  local count=#b.arena.projectiles;D.emit('AppEvent','WillEnterBackground');D.sleep(.05);assert(not b.mentorAim.held and not b.mentor:isDoing(variant=='mission' and 'missionMentorShot' or 'groundMentorShot') and #b.arena.projectiles==count,'Background fired');r.backgroundCancelled=true
  D.emit('AppEvent','DidEnterForeground');D.sleep(.05);hud.weapon:emit('TapBegan');D.sleep(.04);assert(b.mentorAim.held)
  hud:removeFromParent();D.sleep(.05);assert(not b.mentorAim.held and not b.mentorAim:release() and #b.arena.projectiles==count,'Cleanup fired');r.cleanupCancelled=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
