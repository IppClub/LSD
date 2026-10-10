local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local r={status='RUNNING',scope='Current package public preparation, actual withdrawal and normal-HP stationary defeat, failure retry cancellation and original city return; scripted HUD, earned current-package success parent already unlocked',osInput=false,originalUnlockAlreadyEarned=true}
 local function save()D.Content:save(root..'/Test/ambush-warning-pursuit-retry-result.json',D.json.encode(r,false,true))end;save()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-ambush-warning-ruins-route-20261008/result.json'),32);assert(prior.status=='PASS' and prior.stage=='valley-arrival' and prior.outcome=='won')
  local db=D.Path(D.Content.writablePath,'pursuit-current-retry-'..os.time()..'.db');assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=prior.database;save()
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync();local S=assert(require('Mission.Service').open());assert(S:recoverAsync());local story=assert(require('Story.Service').open());local E=require('Economy.Store');assert(E.open()and not E.active())
  local before=E.wallet().available;assert(before==prior.balance);r.balanceBefore=before
  local function models()return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local originalModels=models();assert(story:summary().mission.unlocks['ruins-diversion-complete'])
  local function wait(fn,t)local untilAt=D.App.runningTime+(t or 20);while not fn()do assert(D.App.runningTime<untilAt,'Retry wait timed out');D.sleep(.03)end end
  local c;local panel=assert(require('Economy.Preparation').openAsync('c0-m06',nil,nil,function(service,attempt)c=require('Ruins.PursuitLevel').openAsync(service,attempt)end))
  local function setBudget(p,values)
   for i,key in ipairs({'mentor:kinetic','mentor:smoke','mentor:flare'})do while p.values[key]~=values[i]do p.buttons[i][p.values[key]<values[i] and 1 or -1]:emit('Tapped')end end
  end
  setBudget(panel,{4,6,2});assert(panel.quote.total==62);panel.saveButton:emit('Tapped');wait(function()return c end,30)
  local old=c;old.withdraw:emit('Tapped');wait(function()return old.result end)
  assert(old.battle.phase=='aborted' and old.result.resultLayout=='MissionFail' and old.battle.report.economy.cost==2 and E.wallet().available==before-2 and not E.active())
  local at=E.wallet().available;assert(S:finishAsync(old.battle.attempt,'aborted',old.battle.report));assert(E.wallet().available==at)
  old.result.againButton:emit('Tapped');wait(function()return old.supplyPanel end);assert(not E.active());old.supplyPanel.closeButton:emit('Tapped');assert(not old.supplyPanel and not E.active() and E.wallet().available==at)
  r.withdrawal={report=old.battle.report,layout=old.result.resultLayout,balance=at,duplicateUncharged=true,cancelUncharged=true};save()
  old.result.againButton:emit('Tapped');wait(function()return old.supplyPanel end);setBudget(old.supplyPanel,{2,0,0});assert(old.supplyPanel.quote.total==6);old.supplyPanel.saveButton:emit('Tapped')
  wait(function()local world=D.Platformer.Data.store.world;return world and world.pursuitLevel and world.pursuitLevel~=old end,30);c=D.Platformer.Data.store.world.pursuitLevel;local b=c.battle
  wait(function()return b.mentor.onSurface end);local hud=assert(D.Director.ui3D:getChildByTag('pursuit-hud'));local untilAt=D.App.runningTime+30
  while b.supplies.ledger.stock['mentor:kinetic'].remaining>0 do
   assert(b.phase=='playing' and D.App.runningTime<untilAt,'Actual shots did not consume')
   if not b.mentor:isDoing('groundMentorShot') and not b.stamina.down then hud.weapon:emit('TapBegan');D.sleep(.04);hud.weapon:emit('TapEnded')end
   D.sleep(.1)
  end
  assert(not b:command('shoot'));r.noAmmoRejected=true;save()
  -- No movement, damage/HP edits or artificial finish: retain actual enemy AI.
  wait(function()return b.phase~='playing' and b.phase~='saving'end,120);wait(function()return c.result end)
  assert(b.phase=='failed' and c.result.resultLayout=='MissionFail' and b.report.economy.cost==6 and b.report.economy.income==0 and E.wallet().available==before-8 and not E.active())
  at=E.wallet().available;assert(S:finishAsync(b.attempt,'failed',b.report));assert(E.wallet().available==at)
  c.result.againButton:emit('Tapped');wait(function()return c.supplyPanel end);assert(not E.active());c.supplyPanel.closeButton:emit('Tapped');assert(not c.supplyPanel and not E.active()and E.wallet().available==at)
  r.failure={report=b.report,layout=c.result.resultLayout,balance=at,duplicateUncharged=true,cancelUncharged=true};save()
  assert(models()==originalModels and story:summary().mission.unlocks['ruins-diversion-complete'])
  c.result.baseButton:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='AbandonedCity' and w.ruinsSearch end,30)
  r.returnScene=D.Platformer.Data.store.world.tag;r.balance=E.wallet().available;r.modelsUnchanged=true;r.oldUnlockPreserved=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and tostring(err)or nil;save()
end)
