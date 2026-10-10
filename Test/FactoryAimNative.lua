-- Public factory HUD aiming, with isolated save and stationary combat fixtures.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
local out=root..'/Test/factory-aim-native-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={shots={}};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-ruins-route-qa-1791013294.db'
  local dest=D.Content.writablePath..'/factory-aim-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local function model(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  D.App.winSize=D.Size(683,384)
  local c=require('Factory.Level').openAsync({finishAsync=function()return true end},{mission='c0-m05',models={ninilite=model('ninilite','laser'),wuyun=model('wuyun','melee')}})
  local b=c.battle;local aim=b.mentorAim;local weapon=c.hud.weapon
  local function wait(f,t)local deadline=D.App.runningTime+(t or 5);while not f()do assert(D.App.runningTime<deadline,'Factory aim timeout');D.sleep(.01)end end
  D.sleep(.1);weapon:emit('TapBegan');assert(not aim.held);weapon:emit('TapEnded');assert(#b.arena.projectiles==0)
  c.start:emit('Tapped');for _,a in ipairs(b.learners)do a.nextDecision=math.huge end
  for _,e in ipairs(b.roots)do e.enemyCombat:close()end
  for _,case in ipairs({{hold=.03,right=true},{hold=.38,right=true},{hold=.38,right=false}})do
   wait(function()return aim:canStart() and not aim.shot end)
   b.mentor.faceRight=case.right;local count=#b.arena.projectiles
   weapon:emit('TapBegan');assert(aim.held and aim.line.visible);D.sleep(case.hold)
   assert(#b.arena.projectiles==count,'Fired before release')
   assert(aim.line.scaleX==(case.right and 1 or -1),'Preview facing mismatch')
   if not case.right then D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/factory-aim-preview.tga');D.sleep(.05)end
   weapon:emit('TapEnded');assert(not aim.held and not aim.line.visible)
   local angle=aim.angle;wait(function()return #b.arena.projectiles>count end)
   local bullet=b.arena.projectiles[#b.arena.projectiles]
   assert((bullet.velocityX>0)==case.right,'Factory auto-target overrode manual facing')
   assert(math.abs(bullet.velocityY+math.sin(math.rad(angle))*2400)<3,'Aim angle not used')
   if case.hold<.15 then assert(angle==0)else assert(math.abs(angle)>10)end
   r.shots[#r.shots+1]={angle=angle,right=case.right,vx=bullet.velocityX,vy=bullet.velocityY}
   if not case.right then D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/factory-aim-preview.tga');D.sleep(.05)end
   weapon:emit('TapEnded');assert(not aim.held)
  end
  wait(function()return aim:canStart() and not aim.shot end)
  weapon:emit('TapBegan');assert(aim.held)
  local target;for _,t in ipairs(b.targets())do if t.unit==b.mentor then target=t end end
  assert(b.effects:apply(target,'confuse',1,{kind='QA-aim-interruption'}));D.sleep(.05)
  assert(not aim.held and not aim.line.visible,'Confusion left preview active')
  local interruptedCount=#b.arena.projectiles;weapon:emit('TapEnded');D.sleep(.05)
  assert(#b.arena.projectiles==interruptedCount,'Status interrupted release fired')
  b.effects:clear();r.statusCancelled=true
  weapon:emit('TapBegan');assert(aim.held)
  c.withdraw:emit('Tapped');assert(not aim.held and not aim.line.visible,'Withdrawal left preview active')
  local count=#b.arena.projectiles;weapon:emit('TapEnded');D.sleep(.2)
  assert(#b.arena.projectiles==count and b.phase=='aborted','Release after withdrawal fired')
  r.readyBlocked=true;r.abortCancelled=true;r.casings=#b.mentorCasings;assert(r.casings==3)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
