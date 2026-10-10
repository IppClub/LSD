-- Earned medical/preparation copy; physical train/factory route, models and real win.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","fresh-materials-current-result.json"); local evidence={status='RUNNING',osInput=false};local function save()D.Content:save(out,D.json.encode(evidence,false,true))end;save()
D.thread(function()
 local ok,result=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or root..'/Test/fresh-medical-current-result.json'),32)
  assert(prior.status=='PASS'and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-medical%-current%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'fresh-materials-current-'..id..'.db')
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(prior.database,db))
  evidence.database=db;evidence.source=prior.database;save()
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
  world():getChildByTag("groundDeploymentTerminal"):emit("Tapped",2); wait(function() return world().groundDeployment end)
  local deploy=world().groundDeployment; assert(deploy.team and deploy.formation.wuyun and deploy.view.secondCard)
  assert(deploy.auxiliaryButtons.cargo and deploy.auxiliaryButtons.defence and deploy.auxiliaryButtons.mobility)
  deploy.auxiliaryButtons.mobility:emit('Tapped');assert(deploy.auxiliaryVariant=='mobility')
  deploy.view.startButton:emit("Tapped"); wait(function() return world().tag=="Factory" and world().factoryExpedition and player() end)
  wait(function() return D.Group({"name","unit"}):find(function(e) return e.name=="wuyun" and e.unit.world==world() end) end)
  local support=world().factoryExpedition.support;assert(support.variant=='mobility' and world().auxiliaryView.actor.variant=='mobility')
  wait(function()return world().auxiliaryView.actor.completed.deploy and world().auxiliaryView.actor.completed.shield end,15)
  local remote,why=require("Story.Flow").openAsync("factory-encounter",world()); assert(not remote and why=="DISCOVERY_LOCATION_REQUIRED")
  assert(not story:canRead("factory-material","Factory") and not story:canRead("medical-notify","Factory"))
  local goldBeforePause=support.gold
  local lens=assert(require("Ground.NightLens").openAsync(world())); assert(lens.locations[2].id=="marsh" and lens.playerX)
  D.sleep(.4);assert(math.abs(support.gold-goldBeforePause)<.03,'Lens drained energy')
  lens.view.researchButton:emit("Tapped"); assert(world().nightLensTarget.x==5200); lens.view.closeButton:emit("Tapped")
  move(5200); local exp=world().factoryExpedition; exp.encounter:emit("Tapped",2); D.sleep(0.2); assert(not world().factoryBattle and not world().data.storyBusy and exp.message:find('先观察歌声',1,true),'Premature preparation froze discovery')
  exp.encounter:emit("Tapped",1); local f=dialogue("factory-encounter",5)
  assert(f.view._reviews[2].text:find("塞壬",1,true),"Original Siren voice missing")
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_factory_reward BEFORE INSERT ON Game0MissionUnlocks WHEN NEW.id='factory-site-secured' BEGIN SELECT RAISE(ABORT,'QA factory reward'); END")>=0)
  exp.encounter:emit('Tapped',2)
  local budget;wait(function()
   D.Director.ui3D.children:each(function(n)if n.quote and n.saveButton then budget=n end end)
   return budget
  end,20,'Factory formal budget absent')
  for i,target in ipairs({60,24,6,40})do
   local slot=require('Economy.Loadout').slots[i];local key=slot.actor..':'..slot.item
   while budget.values[key]~=target do budget.buttons[i][budget.values[key]<target and 1 or -1]:emit('Tapped')end
  end
  assert(budget.quote.total==289)
  assert(budget.quote.total<=prior.balance);evidence.budget=budget.quote;evidence.stage='formal-budget';save();budget.saveButton:emit('Tapped')
  wait(function()return world().factoryBattle end,20)
  local c=world().factoryBattle; local b=c.battle
  assert(b.support==support and b.support.variant=='mobility' and b.arena.world.auxiliaryView.actor.variant=='mobility','Machine reset on battle entry')
  assert(support.spent>0 and support.collectionSerial>=2,'Exploration did not consume and collect finite fuel')
  local readyGold=support.gold
  assert(b.phase=="ready" and #b.enemies==3 and b.arena.world==b.wuyun.world)
  D.sleep(2); assert(not b.started and b.mentorHP==100 and b.arena.studentHP==100 and b.wuyun.studentHP==100 and #b.roots[3].enemyAttacks==0,"Preparation ran AI or damage")
  assert(support.gold==readyGold,'Ready battle drained energy')
  local hud=D.Director.ui3D:getChildByTag("factory-battle-hud"); local song=hud.skillArea:getChildByTag("factory-song")
  c.start:emit("Tapped"); assert(b.phase=="playing")
  local deadline=D.App.runningTime+125;local overlap=false;local aimedPart;local nextAim=0;local moveSide;evidence.manualAim={begins=0,releases=0}
  while b.phase=="playing" or b.phase=="saving" do
   assert(D.App.runningTime<deadline,"Factory battle stalled")
   if b.roots[3].enemyHP<=0 then
    local target=b:target(b.mentor);local dx=target and target.enemy.x-b.mentor.x or 0
    if b.mentorAim.held then hud.weapon:emit('TapEnded');nextAim=D.App.runningTime+1 end
    local side=dx < -330 and 'Left' or dx>330 and 'Right' or nil
    if side~=moveSide then
     if moveSide then hud.move:emit(moveSide,false)end
     if side then hud.move:emit(side,true)end
     moveSide=side
    end
    if math.abs(dx)<=330 and not b.mentorAim.held and b.mentorAim.canStart() and D.App.runningTime>=nextAim then
     hud.weapon:emit('TapBegan');hud.weapon:emit('TapEnded');nextAim=D.App.runningTime+1
    end
   elseif b.mentorAim.held then
    local solution=aimedPart and b.partCombat:aim(b.mentor,aimedPart)
    if (solution and D.App.runningTime-b.mentorAim.started>.16 and math.abs(b.mentorAim.angle-solution.angle)<2)or D.App.runningTime-b.mentorAim.started>1.2 then
     hud.weapon:emit('TapEnded');evidence.manualAim.releases=evidence.manualAim.releases+1;nextAim=D.App.runningTime+1
    end
   elseif D.App.runningTime>=nextAim and b.mentorAim.canStart()then
    aimedPart=nil
    for _,part in ipairs({'petal-left','roots','flower-core','petal-right','flower-head'})do
     local seen=b.partCombat.known[part]
     if seen and seen.ap==0 and b.partCombat:aim(b.mentor,part,true)then aimedPart=part;break end
    end
    if aimedPart then hud.weapon:emit('TapBegan');evidence.manualAim.begins=evidence.manualAim.begins+1
    else hud.weapon:emit('TapBegan');hud.weapon:emit('TapEnded')end
   end
   if b.effects.confusions>0 then song:emit("TapBegan") end
   overlap=overlap or (b.arena:isAttacking() and b.wuyun:isAttacking())
   D.sleep(0.02)
  end
  evidence.remainingEnemies=b:remainingEnemies();evidence.resultState=b.phase;save()
  if b.phase~='save-error'then
   evidence.failureBattle=b.report;evidence.failureParts=b.partCombat and b.partCombat.target.damage.parts
   evidence.failureJournal=b.partCombat and b.partCombat.journal
   local path=D.Content.writablePath..'/materials-failed-muzzle.tga';D.App:saveScreenshot(path);evidence.failureScreenshot=path;save()
  end
  assert(b.phase=="save-error","Factory actual battle did not win: "..b.phase.." "..tostring(b.reason).." ni="..b.arena.studentHP.." wu="..b.wuyun.studentHP.." injury="..tostring(b.injury).." chants="..D.json.encode(b.song.logs))
  assert(b.injury and b.effects.confusions>0 and #b.song.logs>0 and b.arena.metrics.hits>0 and b.wuyun.metrics.hits>0 and overlap)
  assert(not service:summary().unlocks["factory-site-secured"] and not story:canRead("factory-material","Factory"))
  D.DB:exec("DROP TRIGGER lsd.fail_factory_reward"); c.withdraw:emit("Tapped"); wait(function() return b.phase=="won" and c.result end)
  assert(b.report.auxiliary.variant=='mobility' and b.report.auxiliary.spent>0 and b.support.maxHP[2]<=90)
  local spent=b.support.spent;local gold=b.support.gold;local collections=b.support.collectionSerial
  c.result.baseButton:emit("Tapped"); wait(function() return world().tag=="Factory" and world().factoryExpedition and player() end)
  assert(world().factoryExpedition.support==support and support.variant=='mobility' and support.spent>=spent,'Machine reset on victory return')
  assert(math.abs(support.gold-(gold+12*(support.collectionSerial-collections)-(support.spent-spent)))<.05,'Unaccounted fuel on victory return')
  local niCap=support.maxHP[2];assert(niCap<=90)
  move(6400); world().factoryExpedition.material:emit("Tapped",1); dialogue("factory-material",2)
  local j=assert(require("Story.Journal").openAsync(world(),8)); assert(j.recordIds[1]=="medical-notify")
  j.view.mailButton:emit("Tapped"); dialogue("medical-notify",1); wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  assert(support.hp[2]<=niCap,'Life field erased medical injury')
  local saved=assert(require('Ground.AuxiliarySelection').open():load());assert(saved.variant=='mobility' and saved.destination=='Factory')
  assert(models()==unchanged,"Factory changed adopted model rows")
  for _,reward in ipairs({"factory-encounter-recorded","translator-clam-material","medical-treatment-requested"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='factory-site-secured'")==1)
  local E=require('Economy.Store');assert(E.open()and not E.active()and E.wallet().available==prior.balance+b.report.economy.net);evidence.balance=E.wallet().available;evidence.battle=b.report;evidence.sameJourney=true;evidence.stage='medical-treatment-requested';save()
  return "PASS factoryAuxiliarySelection=true explorationFiniteFuel=true explorationCollection=true readyPause=true carryIntoBattle=true carryAfterVictory=true injuryPreserved=true earnedMedicalCopy=true physicalTrainExit=true publicThreeCards=true realFactoryScene=true factoryNightLens=true physicalMarshWalk=true originalSirenYarn=true initialRemoteGate=true materialWinGate=true readinessNoAI=true bothAdoptedModels=true simultaneousCombat=true actualNiVineInjury=true actualSongRelease=true realWin=true rewardRollbackRetry=true physicalMaterialCollection=true explicitMedicalNotify=true allUnlocksOnce=true modelRowsUnchanged=true report="..D.json.encode(b.report,false,true)
 end,debug.traceback)
 evidence.status=ok and 'PASS'or'FAIL';evidence.detail=ok and result or nil;evidence.error=not ok and tostring(result)or nil
 save();print('LSD_FRESH_MATERIALS_CURRENT_'..evidence.status)
end)
