-- Earned two-learner profile, original formation/HUD, physical route and box.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","fresh-energy-current-result.json"); local evidence={status='RUNNING',osInput=false};local function save()D.Content:save(out,D.json.encode(evidence,false,true))end;save()
D.thread(function()
 local ok,result=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or root..'/Test/fresh-wuyun-current-result.json'),32)
  assert(prior.status=='PASS' and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-wuyun%-current%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'fresh-energy-current-'..id..'.db')
  assert(not D.Content:exist(db) and not D.DB:existDB('lsd') and D.Content:copyAsync(prior.database,db))
  evidence.database=db;evidence.source=prior.database;save()
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local original=models(); local service=assert(require("Mission.Service").open()); local story=assert(require("Story.Service").open())
  assert(story:summary().completed["energy-plan"] and not story:canRead("energy-recovery","AbandonedCity"))
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t) local deadline=D.App.runningTime+(t or 15); while not f() do assert(D.App.runningTime<deadline,"Energy route timed out"); D.sleep(0.05) end end
  local function move(x)
   local e=assert(player());local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
   local side=e.unit.x<x and 'Right' or 'Left';hud.move:emit(side,true)
   local deadline=D.App.runningTime+45
   while math.abs(e.unit.x-x)>35 do
    if D.App.runningTime>=deadline then hud.move:emit(side,false);error('Factory physical walk stalled x='..e.unit.x..' target='..x)end
    D.sleep(.02)
   end
   hud.move:emit(side,false);D.sleep(.5)
  end
  local function door(route,target)
   local old=world(); move(route=="left" and 120 or route=="right" and old.sceneWidth-120 or old.center.x)
   local e=player(); local index; assert(e.moveTargets,"Missing story route sensor")
   for i=1,e.moveTargets.count do if e.moveTargets:get(i)==target then index=i; break end end
   assert(index and e.interaction.menu.enabled,"Story destination missing: "..target); e.interaction:emit("Tapped",index)
   wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3)
  end
  require('Start');wait(function()return world() and world().tag=='PreparationRoom' and player() and not player().busy end,30)
  door('left','PassageA');door('center','PassageC');door('left','Station')
  move(world().sceneWidth-1800);world():getChildByTag('boardingTerminal'):emit('Tapped',1)
  wait(function()return world().tag=='TrainA' and player()end);move(world().sceneWidth-170)
  world():getChildByTag("groundDeploymentTerminal"):emit("Tapped",1); wait(function() return world().groundDeployment end)
  local deploy=world().groundDeployment; assert(deploy.team and deploy.view.secondCard and not deploy.formation.wuyun)
  deploy.view.startButton:emit("Tapped"); assert(deploy.phase=="briefing","Missing Wuyun bypassed public roster gate")
  deploy.view.secondCard.children.first:emit("Tapped"); wait(function() return deploy.phase=="briefing" and deploy.formation.wuyun end)
  assert(service:formation().wuyun and deploy.view.secondCard)
  deploy.view.startButton:emit("Tapped"); wait(function() return world().tag=="AbandonedCity" and world().energySquad and player() and world().energySite end)
  wait(function() return D.Group({"name","unit"}):find(function(e) return e.name=="wuyun" and e.unit.world==world() end) end)
  local lens=assert(require("Ground.NightLens").openAsync(world())); lens.view.stationButton:emit("Tapped"); assert(world().nightLensTarget.id=="energy"); lens.view.closeButton:emit("Tapped")
  move(5760); local site=world().energySite; site.view:emit("Tapped",2); D.sleep(0.2)
  assert(site.phase=="idle" and not story:summary().completed["energy-recovery"],"Unsecured box granted energy")
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_energy_reward BEFORE INSERT ON Game0MissionUnlocks BEGIN SELECT RAISE(ABORT,'QA energy reward fault'); END")>=0)
  site.view:emit('Tapped',1);wait(function()return site.supplyPanel end)
  assert(site.supplyPanel.quote.total<=prior.balance);evidence.budget=site.supplyPanel.quote;save();site.supplyPanel.saveButton:emit('Tapped')
  wait(function()return world().energyBattle end)
  local c=world().energyBattle; local b=c.battle
  assert(b.arena.world==b.wuyun.world and b.arena.student~=b.wuyun.student and b.arena.student.entity~=b.wuyun.student.entity)
  assert(b.arena.enemy.entity~=b.wuyun.enemy.entity and b.central.enemy.entity~=b.arena.enemy.entity)
  local hud=D.Director.ui3D:getChildByTag("energy-battle-hud")
  local deadline=D.App.runningTime+85; local overlap=false
  while b.phase=="playing" or b.phase=="saving" do
   assert(D.App.runningTime<deadline,"Energy battle stalled")
   hud.weapon:emit('TapBegan');hud.weapon:emit('TapEnded')
   hud.skillArea:getChildByTag('energy-fire'):emit('TapBegan')
   hud.skillArea:getChildByTag('energy-wind'):emit('TapBegan')
   hud.skillArea:getChildByTag('energy-gather'):emit('TapBegan')
   overlap=overlap or (b.arena:isAttacking() and b.wuyun:isAttacking())
   if D.App.runningTime-b.started>1 then
    local camera=b.arena.world.camera; local half=D.View.size.width/(2*camera.zoom)
    for _,enemy in ipairs(b.enemies) do assert(math.abs(enemy.enemy.x-camera.position.x)+120<half,"Squad camera clipped an opponent") end
   end
   D.sleep(0.1)
  end
  assert(b.phase=="save-error","Expected reward fault after genuine win: "..b.phase.." "..tostring(b.reason))
  assert(overlap and b.arena.metrics.modelActions>0 and b.wuyun.metrics.modelActions>0 and b.arena.metrics.hits>0 and b.wuyun.metrics.hits>0)
  assert(b.arena.metrics.fallback==0 and b.wuyun.metrics.fallback==0 and b.mentorHits>0)
  assert(not service:summary().unlocks["energy-site-secured"] and not story:canRead("energy-recovery","AbandonedCity"))
  D.DB:exec("DROP TRIGGER lsd.fail_energy_reward"); c.withdraw:emit("Tapped"); wait(function() return b.phase=="won" and c.result end)
  local report=b.report; c.result.baseButton:emit("Tapped"); wait(function() return world().tag=="AbandonedCity" and world().energySite and player() end)
  assert(world().groundExpedition.support==b.support and world().groundExpedition.support.machineHP==report.machineHP,"Result magically repaired or replaced loadout")
  move(5760); site=world().energySite; site.view:emit("Tapped",2); wait(function() return world().storyFlow and world().storyFlow.id=="energy-recovery" end)
  local flow=world().storyFlow; wait(function() return flow.view.visible end)
  deadline=D.App.runningTime+25
  while flow.phase=="dialogue" or flow.phase=="saving" do assert(D.App.runningTime<deadline,"Energy Yarn stalled"); if not flow.view._advancing then flow.view.confirm:emit("Tapped") end; D.sleep(0.1) end
  assert(flow.phase=="complete" and story:summary().unlocks["city-energy-recovered"] and not player().busy)
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='city-energy-recovered'")==1)
  assert(service:finishAsync(b.attempt,"won",report) and #D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='energy-site-secured'")==1)
  assert(models()==original,"Mission changed adopted model rows")
  local journal=assert(require("Story.Journal").openAsync(world(),4)); assert(journal.recordIds[1]=="energy-recovery" and journal.view.mailButton); journal.view.closeButton:emit("Tapped")
  local E=require('Economy.Store');assert(E.open() and not E.active() and E.wallet().available==prior.balance+report.economy.net);evidence.balance=E.wallet().available;evidence.battle=report;evidence.sameJourney=true;evidence.stage='energy-recovered'
  return "PASS earnedTwoLearnerCopy=true publicThreeCards=true rosterGate=true physicalCityWalk=true publicNightLens=true lockedBox=true simultaneousAnimations=true allOpponentsFramed=true independentEntities=true threeRealOpponents=true bothNativeModels=true fallbackZero=true mentorRealHits=true rewardRollbackRetry=true physicalEnergyBox=true loadoutCarriedBack=true realYarn=true rewardOnce=true modelRowsUnchanged=true fourthJournalPage=true report="..D.json.encode(report)
 end,debug.traceback)
 evidence.status=ok and 'PASS' or 'FAIL';evidence.detail=ok and result or nil;evidence.error=not ok and tostring(result) or nil
 save();print('LSD_FRESH_ENERGY_CURRENT_'..evidence.status)
end)
