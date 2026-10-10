-- Earned medical/preparation copy; physical train/factory route, models and real win.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","factory-auxiliary-route-result.txt"); D.Content:save(out,"LSD_FACTORY_AUXILIARY_ROUTE_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","medical-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-medical%-visit%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-factory-auxiliary-route-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local story=assert(require("Story.Service").open()); local service=assert(require("Mission.Service").open())
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); assert(story:summary().completed["translator-preparation"])
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t,msg) local deadline=D.App.runningTime+(t or 15); while not f() do assert(D.App.runningTime<deadline,msg or "Factory route timed out"); D.sleep(0.05) end end
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
  local function dialogue(node,count)
   wait(function() return world().storyFlow and world().storyFlow.id==node and world().storyFlow.view.visible end,20,node)
   local f=world().storyFlow; local deadline=D.App.runningTime+45
   while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Factory Yarn stalled"); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
   assert(f.phase=="complete" and #f.view._reviews==count,"Factory incomplete Yarn "..node.." "..f.phase.." rows="..#f.view._reviews)
   return f
  end
  -- Directly choose the earned train safe point; the factory trip itself is public.
  require("Academy.Navigation").returnToRoomAsync("TrainA"); wait(player); move(world().sceneWidth-170)
  world():getChildByTag("groundDeploymentTerminal"):emit("Tapped",2); wait(function() return world().groundDeployment end)
  local deploy=world().groundDeployment; assert(deploy.team and deploy.formation.wuyun and deploy.view.secondCard)
  assert(deploy.auxiliaryButtons.cargo and deploy.auxiliaryButtons.defence and deploy.auxiliaryButtons.mobility)
  deploy.auxiliaryButtons.cargo:emit('Tapped');assert(deploy.auxiliaryVariant=='cargo')
  deploy.view.startButton:emit("Tapped"); wait(function() return world().tag=="Factory" and world().factoryExpedition and player() end)
  wait(function() return D.Group({"name","unit"}):find(function(e) return e.name=="wuyun" and e.unit.world==world() end) end)
  local support=world().factoryExpedition.support;assert(support.variant=='cargo' and world().auxiliaryView.actor.variant=='cargo')
  wait(function()return world().auxiliaryView.actor.completed.deploy and world().auxiliaryView.actor.completed.shield end,15)
  local remote,why=require("Story.Flow").openAsync("factory-encounter",world()); assert(not remote and why=="DISCOVERY_LOCATION_REQUIRED")
  assert(not story:canRead("factory-material","Factory") and not story:canRead("medical-notify","Factory"))
  local goldBeforePause=support.gold
  local lens=assert(require("Ground.NightLens").openAsync(world())); assert(lens.locations[2].id=="marsh" and lens.playerX)
  D.sleep(.4);assert(math.abs(support.gold-goldBeforePause)<.03,'Lens drained energy')
  lens.view.researchButton:emit("Tapped"); assert(world().nightLensTarget.x==5200); lens.view.closeButton:emit("Tapped")
  move(5200); local exp=world().factoryExpedition; exp.encounter:emit("Tapped",2); D.sleep(0.2); assert(not world().factoryBattle,"Battle bypassed encounter")
  exp.encounter:emit("Tapped",1); local f=dialogue("factory-encounter",5)
  assert(f.view._reviews[2].text:find("塞壬",1,true),"Original Siren voice missing")
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_factory_reward BEFORE INSERT ON Game0MissionUnlocks WHEN NEW.id='factory-site-secured' BEGIN SELECT RAISE(ABORT,'QA factory reward'); END")>=0)
  exp.encounter:emit("Tapped",2); wait(function() return world().factoryBattle end,20)
  local c=world().factoryBattle; local b=c.battle
  assert(b.support==support and b.support.variant=='cargo' and b.arena.world.auxiliaryView.actor.variant=='cargo','Machine reset on battle entry')
  assert(support.spent>0 and support.collectionSerial>=2,'Exploration did not consume and collect finite fuel')
  local readyGold=support.gold
  assert(b.phase=="ready" and #b.enemies==3 and b.arena.world==b.wuyun.world)
  D.sleep(2); assert(not b.started and b.mentorHP==100 and b.arena.studentHP==100 and b.wuyun.studentHP==100 and #b.roots[3].enemyAttacks==0,"Preparation ran AI or damage")
  assert(support.gold==readyGold,'Ready battle drained energy')
  local hud=D.Director.ui3D:getChildByTag("factory-battle-hud"); local song=hud.skillArea:getChildByTag("factory-song")
  c.start:emit("Tapped"); assert(b.phase=="playing")
  local deadline=D.App.runningTime+125; local overlap=false
  while b.phase=="playing" or b.phase=="saving" do
   assert(D.App.runningTime<deadline,"Factory battle stalled")
   hud.weapon:emit("TapBegan"); hud.weapon:emit("TapEnded")
   if b.effects.confusions>0 then song:emit("TapBegan") end
   overlap=overlap or (b.arena:isAttacking() and b.wuyun:isAttacking())
   D.sleep(0.1)
  end
  assert(b.phase=="save-error","Factory actual battle did not win: "..b.phase.." "..tostring(b.reason).." ni="..b.arena.studentHP.." wu="..b.wuyun.studentHP.." injury="..tostring(b.injury).." chants="..D.json.encode(b.song.logs))
  assert(b.injury and b.effects.confusions>0 and #b.song.logs>0 and b.arena.metrics.hits>0 and b.wuyun.metrics.hits>0 and overlap)
  assert(not service:summary().unlocks["factory-site-secured"] and not story:canRead("factory-material","Factory"))
  D.DB:exec("DROP TRIGGER lsd.fail_factory_reward"); c.withdraw:emit("Tapped"); wait(function() return b.phase=="won" and c.result end)
  assert(b.report.auxiliary.variant=='cargo' and b.report.auxiliary.spent>0 and b.support.maxHP[2]<=90)
  local spent=b.support.spent;local gold=b.support.gold;local collections=b.support.collectionSerial
  c.result.baseButton:emit("Tapped"); wait(function() return world().tag=="Factory" and world().factoryExpedition and player() end)
  assert(world().factoryExpedition.support==support and support.variant=='cargo' and support.spent>=spent,'Machine reset on victory return')
  assert(math.abs(support.gold-(gold+12*(support.collectionSerial-collections)-(support.spent-spent)))<.05,'Unaccounted fuel on victory return')
  local niCap=support.maxHP[2];assert(niCap<=90)
  move(6400); world().factoryExpedition.material:emit("Tapped",1); dialogue("factory-material",2)
  local j=assert(require("Story.Journal").openAsync(world(),8)); assert(j.recordIds[1]=="medical-notify")
  j.view.mailButton:emit("Tapped"); dialogue("medical-notify",1); wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  assert(support.hp[2]<=niCap,'Life field erased medical injury')
  local saved=assert(require('Ground.AuxiliarySelection').open():load());assert(saved.variant=='cargo' and saved.destination=='Factory')
  assert(models()==unchanged,"Factory changed adopted model rows")
  for _,reward in ipairs({"factory-encounter-recorded","translator-clam-material","medical-treatment-requested"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='factory-site-secured'")==1)
  D.Content:save(D.Path(root,"Test","factory-auxiliary-resume-fixture.txt"),db)
  return "PASS factoryAuxiliarySelection=true explorationFiniteFuel=true explorationCollection=true readyPause=true carryIntoBattle=true carryAfterVictory=true injuryPreserved=true earnedMedicalCopy=true physicalTrainExit=true publicThreeCards=true realFactoryScene=true factoryNightLens=true physicalMarshWalk=true originalSirenYarn=true initialRemoteGate=true materialWinGate=true readinessNoAI=true bothAdoptedModels=true simultaneousCombat=true actualNiVineInjury=true actualSongRelease=true realWin=true rewardRollbackRetry=true physicalMaterialCollection=true explicitMedicalNotify=true allUnlocksOnce=true modelRowsUnchanged=true report="..D.json.encode(b.report,false,true)
 end,debug.traceback)
 local report="LSD_FACTORY_AUXILIARY_ROUTE_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
