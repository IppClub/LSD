-- True restart after an earned public energy recovery; no fabricated rewards.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","wind-fire-resume-result.txt"); D.Content:save(out,"LSD_WIND_FIRE_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local db=assert(D.Content:load(D.Path(root,"Test","wind-fire-resume-fixture.txt")))
  assert(D.Path:getPath(db)==D.Content.writablePath and D.Path:getFilename(db):match("^lsd%-wind%-fire%-route%-qa%-%d+%.db$"))
  assert(not D.DB:existDB("lsd") and D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Start")
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f) local deadline=D.App.runningTime+20; while not f() do assert(D.App.runningTime<deadline,"Energy resume timed out"); D.sleep(0.05) end end
  wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end)
  local p=require("Training.Progress"); local w=p.forCharacter("wuyun"); assert(p.load() and w.load() and p.adopted.sampleCount==6 and w.adopted.sampleCount==18)
  local service=assert(require("Mission.Service").open()); assert(service:formation().learner and service:formation().wuyun)
  assert(service:summary().rewards["energy-site-secured"]==2,"Earned doubled reward lost on restart")
  local story=assert(require("Story.Service").open()); local facts=assert(story:summary())
  assert(facts.completed["energy-recovery"] and facts.unlocks["city-energy-recovered"] and facts.mission.unlocks["energy-site-secured"])
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='city-energy-recovered'")==1 and #D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='energy-site-secured'")==1)
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0)
  local lens=assert(require("Ground.NightLens").openAsync(world())); assert(lens.view.detail.text:find("中央能源已回收",1,true)); lens.view.closeButton:emit("Tapped")
  local journal=assert(require("Story.Journal").openAsync(world(),4)); assert(journal.recordIds[1]=="energy-recovery"); journal.view.closeButton:emit("Tapped")
  local old=assert(require("Mission.Briefing").openAsync())
  old.view.rosterButton:emit("Tapped"); wait(function() return old.phase=="briefing" and not old.formation.learner end); assert(service:formation().wuyun,"Legacy roster removed Wuyun")
  old.view.rosterButton:emit("Tapped"); wait(function() return old.phase=="briefing" and old.formation.learner end); assert(service:formation().wuyun)
  old.view.backButton:emit("Tapped"); wait(function() return world().tag=="OperationRoom" and player() end)
  require("Academy.Navigation").returnToRoomAsync("TrainA"); wait(player)
  local e=player(); local x=world().sceneWidth-170; local deadline=D.App.runningTime+25
  while math.abs(e.unit.x-x)>35 do assert(D.App.runningTime<deadline,"Train public exit walk stalled"); e.keyRight=true; D.sleep(0.05) end; e.keyRight=false; D.sleep(0.4)
  world():getChildByTag("groundDeploymentTerminal"):emit("Tapped",1); wait(function() return world().groundDeployment end)
  local c=world().groundDeployment; assert(c.team and c.formation.wuyun and c.view.mentorCard and c.view.learnerCard and c.view.secondCard)
  assert(c.view.status.text:find("18",1,true) and c.view.status.text:find("6",1,true))
  return "PASS actualStartContinue=true earnedEnergyReward=true doubledRewardPersisted=true collectedMapStatus=true bothModelsSixEighteen=true twoMemberFormationPersisted=true legacyRosterPreservesWuyun=true noActiveAttempt=true rewardOnce=true fourthJournalPage=true physicalTrainExit=true originalThreeCards=true"
 end,debug.traceback)
 local report="LSD_WIND_FIRE_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
