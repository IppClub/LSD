-- Focused retry from an actually played failed journey, not whole-story acceptance.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local r={status='RUNNING',osInput=false,scope='earned-failed-journey-public-budget-battle',samples={},controls={}};local out=root..'/Test/pursuit-earned-retry-result.json';local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-package-fresh-ruins-current-loadout-20261006/result.json'),32)
  assert(prior.status=='FAIL'and prior.outcome=='failed'and prior.report.economy.status=='failed'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-ruins%-current%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'pursuit-earned-retry-'..os.time()..'.db');assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=prior.database
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync();local story=assert(require('Story.Service').open());local facts=story:summary();assert(facts.completed['ruins-ambush']and facts.completed['ayan-recovery']and not facts.mission.unlocks['ruins-diversion-complete'])
  local S=assert(require('Mission.Service').open());assert(S:recoverAsync());local E=require('Economy.Store');assert(E.open()and not E.active());local before=E.wallet().available;assert(before==prior.report.economy.balanceAfter);r.balanceBefore=before
  local function models()return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local unchanged=models();local c;local originalWindow=D.App.winSize;D.App.winSize=D.Size(683,384)
  D.Director.entry:slot('Cleanup',function()D.App.winSize=originalWindow end)
  local panel=assert(require('Economy.Preparation').openAsync('c0-m06',nil,nil,function(service,attempt)c=require('Ruins.PursuitLevel').openAsync(service,attempt)end))
  local slots={'mentor:kinetic','mentor:smoke','mentor:flare'};local desired={4,6,2}
  for i,key in ipairs(slots)do while panel.values[key]~=desired[i]do panel.buttons[i][panel.values[key]<desired[i]and 1 or -1]:emit('Tapped')end end
  assert(panel.quote.total==62);r.budget=panel.quote.total;save();panel.saveButton:emit('Tapped')
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 15);while not fn()do assert(D.App.runningTime<deadline,'Pursuit diagnostic wait');D.sleep(.03)end end
  wait(function()return c end,30)
  local abandoned=c;local old=abandoned.battle
  abandoned.withdraw:emit('Tapped');wait(function()return abandoned.result end)
  assert(old.phase=='aborted'and abandoned.result.resultLayout=='MissionFail'and old.report.economy.cost==2 and E.wallet().available==before-2 and not E.active())
  assert(not story:summary().mission.unlocks['ruins-diversion-complete']and models()==unchanged)
  local withdrawnBalance=E.wallet().available
  assert(S:finishAsync(old.attempt,'aborted',old.report)and E.wallet().available==withdrawnBalance,'Repeated withdrawal changed the wallet')
  abandoned.result.againButton:emit('Tapped');wait(function()return abandoned.supplyPanel end)
  assert(not E.active()and E.wallet().available==withdrawnBalance)
  abandoned.supplyPanel.closeButton:emit('Tapped');assert(not abandoned.supplyPanel and not E.active()and E.wallet().available==withdrawnBalance)
  abandoned.result.againButton:emit('Tapped');wait(function()return abandoned.supplyPanel end)
  assert(abandoned.supplyPanel.quote.total==62);abandoned.supplyPanel.saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.pursuitLevel and w.pursuitLevel~=abandoned end,30)
  c=D.Platformer.Data.store.world.pursuitLevel;r.withdrawal={cost=old.report.economy.cost,balance=withdrawnBalance,resultLayout=abandoned.result.resultLayout,cancelWithoutReserve=true,duplicateWithoutCharge=true}
  before=withdrawnBalance;r.retryBalanceBefore=before;save()
  local b=c.battle;wait(function()return b.mentor.onSurface end)
  local hud=assert(D.Director.ui3D:getChildByTag('pursuit-hud'));hud.move:emit('Right',true)
  local shot=false;local initialFlare=false;local nextSample=0;local checks={};local resized=false;r.statusChecks={};r.concealedChaseStops=0;local deadline=D.App.runningTime+100
  while b.phase=='playing'or b.phase=='saving' do
   local now=D.App.runningTime;assert(now<deadline,'Diagnostic timeout')
   if b.phase=='playing' then
    local nearest,lastEnemy
    for _,e in ipairs(b.enemies)do if e.hp>0 and not e.untargetable then local dist=math.abs(e.unit.x-b.mentor.x);if not nearest or dist<nearest.distance then nearest={distance=dist,name=e.asset,x=e.unit.x}end;lastEnemy=math.max(lastEnemy or -math.huge,e.unit.x)end end
    if now-b.started>8 and not resized then D.App.winSize=D.Size(960,540);resized=true end
    local resolution=tostring(D.App.bufferSize.width)..'x'..tostring(D.App.bufferSize.height)
    if now-b.started>1 and (not resized or now-b.started>9)and not checks[resolution]then
     assert(c.statusPanelHeight>=c.statusLabel.height+42,'Pursuit HUD text spills beyond background')
     checks[resolution]=true;D.App:saveScreenshot(root..'/Test/pursuit-earned-retry-'..math.floor(D.App.bufferSize.width)..'x'..math.floor(D.App.bufferSize.height)..'.tga');r.statusChecks[#r.statusChecks+1]={resolution=resolution,textHeight=c.statusLabel.height,panelHeight=c.statusPanelHeight}
    end
    if not b:inSmoke(b.mentor.x)then for _,enemy in ipairs(b.enemies)do
     if enemy.hp>0 and not enemy.busy and now>=enemy.stunUntil and now>=enemy.nextAttack and b:lineObscured(enemy.unit.x,b.mentor.x)then
      assert(not enemy.unit:isDoing('pursuitEnemyMove')and math.abs(enemy.unit.velocityX)<1,'Enemy tracks through concealing smoke')
      r.concealedChaseStops=r.concealedChaseStops+1
     end
    end end
    if now>=nextSample then
     local sample={at=now-b.started,x=b.mentor.x,vx=b.mentor.velocityX,hp=b.mentorHP,faceRight=b.mentor.faceRight,nearest=nearest,move=b.mentor:isDoing('groundMentorMove'),clip=b.mentor.playable.current}
     r.samples[#r.samples+1]=sample;nextSample=now+.5;save()
    end
    local busy=b.stamina.down or b.mentor:isDoing('groundMentorShot')or b.mentor:isDoing('pursuitTool')
    if not shot and b.mentor.x>=7350 and not busy then
     hud.weapon:emit('TapBegan');D.sleep(.04);hud.weapon:emit('TapEnded');shot=true;r.controls[#r.controls+1]={kind='shot',x=b.mentor.x,at=now-b.started}
    elseif shot and b.mentorHits>0 and not initialFlare and not busy then
     c.toolButtons.flare:emit('TapBegan');initialFlare=true;r.controls[#r.controls+1]={kind='first-flare',x=b.mentor.x,at=now-b.started}
    elseif not busy and nearest and nearest.distance<800 and b.mentor.x>7800 and (not lastEnemy or lastEnemy<b.mentor.x or b.mentorHP<65)and not b:inSmoke(b.mentor.x)and now>=(b.toolReady.smoke or 0)and b.supplies:canSpend('mentor','smoke')then
     c.toolButtons.smoke:emit('TapBegan');r.controls[#r.controls+1]={kind='smoke',x=b.mentor.x,hp=b.mentorHP,at=now-b.started}
    elseif not busy and nearest and nearest.distance<500 and b.mentor.x>8200 and now>=(b.toolReady.flare or 0)and b.supplies:canSpend('mentor','flare')then
     c.toolButtons.flare:emit('TapBegan');r.controls[#r.controls+1]={kind='flare',x=b.mentor.x,hp=b.mentorHP,at=now-b.started}
    end
    if b.mentorHP<=65 and not b.medicineBusy and (require('Story.Supplies').count('mentor','first-aid-water')or 0)>0 then c.toolButtons.medicine:emit('TapBegan');r.controls[#r.controls+1]={kind='medicine',x=b.mentor.x,at=now-b.started}end
   end
   D.sleep(.04)
  end
  wait(function()return c.result end);r.report=b.report;r.outcome=b.phase;r.balance=E.wallet().available;r.sameEarnedJourney=true;r.finalX=b.mentor.x
  assert(models()==unchanged and not E.active()and r.balance==before+b.report.economy.net)
  assert(c.result.resultLayout==(b.phase=='won'and 'Settlement'or 'MissionFail'));r.resultLayout=c.result.resultLayout
  r.unlocked=not not story:summary().mission.unlocks['ruins-diversion-complete'];assert(r.unlocked==(b.phase=='won'))
  D.App.winSize=originalWindow
  assert(#r.statusChecks==2 and r.concealedChaseStops>0,'Missing live layout or smoke-tracking coverage')
  assert(b.phase=='won',b.reason..' x='..b.mentor.x)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and tostring(err)or nil;save();print('LSD_PURSUIT_EARNED_RETRY_'..r.status)
end)
