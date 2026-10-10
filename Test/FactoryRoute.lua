-- Earned medical/preparation copy; physical train/factory route, models and real win.
local script,fixture=...
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(script))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","factory-route-result.txt"); D.Content:save(out,"LSD_FACTORY_ROUTE_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=fixture or assert(D.Content:load(D.Path(root,"Test","medical-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-medical%-visit%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-factory-route-qa-"..id..".db")
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
  deploy.view.startButton:emit("Tapped"); wait(function() return world().tag=="Factory" and world().factoryExpedition and player() end)
  wait(function() return D.Group({"name","unit"}):find(function(e) return e.name=="wuyun" and e.unit.world==world() end) end)
  local remote,why=require("Story.Flow").openAsync("factory-encounter",world()); assert(not remote and why=="DISCOVERY_LOCATION_REQUIRED")
  assert(not story:canRead("factory-material","Factory") and not story:canRead("medical-notify","Factory"))
  local lens=assert(require("Ground.NightLens").openAsync(world())); assert(lens.locations[2].id=="marsh" and lens.playerX)
  lens.view.researchButton:emit("Tapped"); assert(world().nightLensTarget.x==5200); lens.view.closeButton:emit("Tapped")
  move(5200); local exp=world().factoryExpedition; exp.encounter:emit("Tapped",2); D.sleep(0.2); assert(not world().factoryBattle,"Battle bypassed encounter")
  exp.encounter:emit("Tapped",1); local f=dialogue("factory-encounter",5)
  assert(f.view._reviews[2].text:find("塞壬",1,true),"Original Siren voice missing")
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_factory_reward BEFORE INSERT ON Game0MissionUnlocks WHEN NEW.id='factory-site-secured' BEGIN SELECT RAISE(ABORT,'QA factory reward'); END")>=0)
  exp.encounter:emit("Tapped",2); wait(function() return world().factoryBattle end,20)
  local c=world().factoryBattle; local b=c.battle
  assert(b.phase=="ready" and #b.enemies==3 and b.arena.world==b.wuyun.world)
  D.sleep(2); assert(not b.started and b.mentorHP==100 and b.arena.studentHP==100 and b.wuyun.studentHP==100 and #b.roots[3].enemyAttacks==0,"Preparation ran AI or damage")
  local hud=D.Director.ui3D:getChildByTag("factory-battle-hud"); local song=hud.skillArea:getChildByTag("factory-song")
  c.start:emit("Tapped"); assert(b.phase=="playing")
  hud.skillArea:getChildByTag("factory-gather"):emit("TapBegan")
  local frames={};local frameProbe=D.Node();frameProbe:addTo(b.arena.world);local warm=D.App.runningTime+2
  frameProbe:schedule(function(dt)if b.phase=='playing' and D.App.runningTime>warm then frames[#frames+1]=dt end;return false end)

  local deadline=D.App.runningTime+125; local overlap=false
  while b.phase=="playing" or b.phase=="saving" do
   assert(D.App.runningTime<deadline,"Factory battle stalled")
   local target=b:target(b.mentor)
   if target and not b.mentor:isDoing('groundMentorShot') and not b.mentorAim.held and (target.enemy.x>=b.mentor.x)~=b.mentor.faceRight then
    local direction=target.enemy.x>=b.mentor.x and 'Right' or 'Left'
    hud.move:emit(direction,true);D.sleep(.03);hud.move:emit(direction,false)
   end
   hud.weapon:emit("TapBegan"); hud.weapon:emit("TapEnded")
   if b.effects.confusions>0 then song:emit("TapBegan") end
   overlap=overlap or (b.arena:isAttacking() and b.wuyun:isAttacking())
   D.sleep(0.1)
  end
  local enemyState={};for _,e in ipairs(b.enemies)do enemyState[#enemyState+1]={asset=e.enemyAsset,hp=e.enemyHP,x=e.enemy.x}end
  D.Content:save(root..'/Test/factory-armor-route-diagnostic.json',D.json.encode({phase=b.phase,report=b.report,enemies=enemyState}))
  table.sort(frames);local total,slow=0,0;for _,dt in ipairs(frames)do total=total+dt;if dt>1/30 then slow=slow+1 end end
  b.report.performance={frames=#frames,mean=total/math.max(1,#frames),p99=frames[math.ceil(#frames*.99)],max=frames[#frames],over33ms=slow}
  frameProbe:removeFromParent()
  assert(b.phase=="save-error","Factory actual battle did not win: "..b.phase.." "..tostring(b.reason).." ni="..b.arena.studentHP.." wu="..b.wuyun.studentHP.." injury="..tostring(b.injury).." chants="..D.json.encode(b.song.logs))
  assert(b.injury and b.effects.confusions>0 and #b.song.logs>0 and b.arena.metrics.hits>0 and b.wuyun.metrics.hits>0 and overlap)
  assert(not service:summary().unlocks["factory-site-secured"] and not story:canRead("factory-material","Factory"))
  assert(#D.DB:query('SELECT attempt FROM lsd.Game0CombatEpisodes WHERE attempt=?',{b.attempt.id})==0,'Episode escaped failed reward transaction')
  D.DB:exec("DROP TRIGGER lsd.fail_factory_reward"); c.withdraw:emit("Tapped"); wait(function() return b.phase=="won" and c.result end)
  local episode=assert(require('Training.CombatStore').load(b.attempt.id));assert(#episode.steps==#b.combatEpisode.steps and episode.versions.observation==6)
  local evaluation=assert(require('Training.FlowerEvaluation').build(episode))
  local storedReport=D.json.decode(D.DB:query('SELECT report FROM lsd.Game0MissionAttempts WHERE id=?',{b.attempt.id})[1][1])
  assert(storedReport.evaluation and storedReport.evaluation.schemaVersion==1)
  for actor,stats in pairs(evaluation.actors)do for key,value in pairs(stats)do assert(math.abs(storedReport.evaluation.actors[actor][key]-value)<1e-5,'Stored evaluation differs')end end
  local originalSize=D.App.winSize
  D.App.winSize=D.Size(683,384);D.sleep(.3);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-evaluation-1366.tga');D.sleep(.2)
  D.App.winSize=D.Size(960,540);D.sleep(.3);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-evaluation-1920.tga');D.sleep(.2)
  D.App.winSize=originalSize;D.sleep(.2)
  assert(episode.versions.action==4)
  local movements=0;local origins={}
  for _,step in ipairs(episode.steps)do origins[step.action.origin]=true;if step.action.weapon=='none' then movements=movements+1;assert(#step.hits==0 and (step.action.emitted or 0)==0)end end
  assert(movements>0 and origins.model and origins.scripted,'Missing gathered movement or model attacks')
  b.report.movementCheck={actions=movements,origins=origins}
  local healthStates={};for _,step in ipairs(episode.steps)do assert(step.observation.featureSchemaVersion==6 and step.observation.health and step.observation.support);healthStates[step.observation.health]=true end
  b.report.observationCheck={version=6,healthStates=healthStates}
  local phases={};local actors={};local hits=0
  for _,step in ipairs(episode.steps)do phases[step.observation.phase]=true;actors[step.action.actor]=true;hits=hits+#step.hits end
  assert(phases.entrenched and phases.reproduction and actors.mentor and actors.ninilite and actors.wuyun and hits>=#b.report.partHits,'Missing flower training evidence')
  assert(episode.versions.credit==2 and episode.creditTargets)
  local netHP,netAP,budHits=0,0,0
  for _,step in ipairs(episode.steps)do for _,hit in ipairs(step.hits)do
   if hit.relation=='hostile' then
    assert(hit.credit and hit.credit.actor==hit.source)
    netHP=netHP+hit.credit.health;netAP=netAP+hit.credit.armor
    if hit.targetStage=='bud' then budHits=budHits+1;assert(hit.credit.health==0 and hit.credit.excluded=='bud-transient')end
   else assert(hit.credit==nil)end
  end end
  assert(netHP<=720 and netAP<=270,'Encounter contribution budget exceeded')
  assert(episode.versions.vitals==1 and require('Training.CombatVitals').validate(episode.vitals))
  local damage,healing,events=0,0,0
  for actor,state in pairs(episode.vitals.actors)do
   local final=actor=='mentor' and b.mentorHP or actor=='ninilite' and b.arena.studentHP or b.wuyun.studentHP
   assert(math.abs(state.finalHP-final)<1e-5,'Saved final life differs')
   damage=damage+state.damage;healing=healing+state.healing;events=events+#state.events
   for _,event in ipairs(state.events)do if event.kind=='poison' then assert(event.source~='unknown' and event.attackId,'Poison lost attack source')end end
  end
  assert(damage>0 and events>0)
  b.report.vitalsCheck={damage=damage,healing=healing,events=events,finalHPVerified=true}
  b.report.contributionCheck={netHP=netHP,netAP=netAP,budHits=budHits,replayed=true}
  b.report.episodeCheck={steps=#episode.steps,hits=hits,atomicReadback=true,phases=phases}
  c.result.baseButton:emit("Tapped"); wait(function() return world().tag=="Factory" and world().factoryExpedition and player() end)
  move(6400); world().factoryExpedition.material:emit("Tapped",1); dialogue("factory-material",2)
  local j=assert(require("Story.Journal").openAsync(world(),8)); assert(j.recordIds[1]=="medical-notify")
  j.view.mailButton:emit("Tapped"); dialogue("medical-notify",1); wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  assert(models()==unchanged,"Factory changed adopted model rows")
  for _,reward in ipairs({"factory-encounter-recorded","translator-clam-material","medical-treatment-requested"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='factory-site-secured'")==1)
  if not fixture then D.Content:save(D.Path(root,"Test","factory-resume-fixture.txt"),db)end
  return "PASS earnedMedicalCopy=true physicalTrainExit=true publicThreeCards=true realFactoryScene=true factoryNightLens=true physicalMarshWalk=true originalSirenYarn=true initialRemoteGate=true materialWinGate=true readinessNoAI=true bothAdoptedModels=true simultaneousCombat=true actualNiVineInjury=true actualSongRelease=true realWin=true rewardRollbackRetry=true physicalMaterialCollection=true explicitMedicalNotify=true allUnlocksOnce=true modelRowsUnchanged=true report="..D.json.encode(b.report,false,true)
 end,debug.traceback)
 local report="LSD_FACTORY_ROUTE_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
