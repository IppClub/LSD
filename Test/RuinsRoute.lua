-- Earned factory victory copy; original Start/doors, full treatment and next-day messages.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ruins-route-result.txt"); D.Content:save(out,"LSD_RUINS_ROUTE_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","recovery-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-recovery%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ruins-route-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t,msg) local deadline=D.App.runningTime+(t or 15); while not f() do assert(D.App.runningTime<deadline,msg or "Recovery route wait"); D.sleep(0.04) end end
  require("Start"); wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end,30)
  local story=assert(require("Story.Service").open())
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); local before=require("Factory.Health").load(); assert(before[2]==100 and story:summary().completed["ruins-station"])
  assert(not story:canRead("ayan-diary",world().tag))
  local function move(x) local e=assert(player()); local deadline=D.App.runningTime+30; while math.abs(e.unit.x-x)>30 do assert(D.App.runningTime<deadline,"Recovery physical walk stalled"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.04) end; e.keyLeft=false; e.keyRight=false; D.sleep(0.3) end
  local function door(side,target)
   local old=world(); move(side=="center" and old.center.x or side=="left" and 110 or old.sceneWidth-110)
   local e=assert(player()); local index; assert(e.moveTargets)
   for i=1,e.moveTargets.count do if e.moveTargets:get(i)==target then index=i end end
   assert(index and e.interaction.menu.enabled); e.interaction:emit("Tapped",index); wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3)
  end
  local function dialogue(node,count,expected)
   wait(function() return world().storyFlow and world().storyFlow.id==node and world().storyFlow.view.visible end,20,node)
   local f=world().storyFlow; local deadline=D.App.runningTime+60
   while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Recovery Yarn stalled "..node); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
   assert(f.phase==(expected or "complete") and #f.view._reviews==count,"Incomplete recovery Yarn "..node.." "..f.phase.." rows="..#f.view._reviews)
   return f
  end
  door("left","PassageA"); door("center","PassageC"); door("left","Station")
  move(world().sceneWidth-1800); wait(function() return world():getChildByTag("boardingTerminal").menu.enabled end)
  world():getChildByTag("boardingTerminal"):emit("Tapped",1); wait(function() return world().tag=="TrainA" end)
  move(world().sceneWidth-170); wait(function() return world():getChildByTag("groundDeploymentTerminal").menu.enabled end)
  world():getChildByTag("groundDeploymentTerminal"):emit("Tapped",3)
  wait(function() return world().groundDeployment and world().groundDeployment.phase=="briefing" end)
  local deployment=world().groundDeployment; assert(deployment.team and deployment.formation.learner and deployment.formation.wuyun)
  deployment.view.startButton:emit("Tapped"); wait(function() return world().tag=="AbandonedCity" and world().ruinsSearch and world().ruinsExpedition and world().ruinsExpedition.phase=="exploring" end,30)
  local c=world().ruinsExpedition; assert(c.stage==1 and c.body and c.bodyPose.completedAt and not world().groundExpedition)
  local remote,why=require("Story.Flow").openAsync("ruins-twins",world()); assert(not remote and why=="DISCOVERY_LOCATION_REQUIRED")
  local lens=assert(require("Ground.NightLens").openAsync(world())); assert(lens.locations[2].x==6200 and lens.locations[3].x==8500)
  lens.view.archiveButton:emit("Tapped"); assert(not world().nightLensTarget,"Unconfirmed Ayan direction leaked")
  lens.view.researchButton:emit("Tapped"); assert(world().nightLensTarget.id=="signal"); lens.view.closeButton:emit("Tapped")
  move(6200); wait(function() return c.twins.menu.enabled end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_twins BEFORE INSERT ON Game0StoryUnlocks WHEN NEW.id='ruins-twins-met' BEGIN SELECT RAISE(ABORT,'QA twins'); END")>=0)
  c.twins:emit("Tapped",1); local f=dialogue("ruins-twins",41,"save-error")
  local hit=assert(c.confrontation); assert(hit.blocked and hit.actualTarget=="mentor" and hit.hpBefore==hit.hpAfter and hit.attackAt>hit.startedAt and hit.hitAt>hit.attackAt and hit.completedAt-hit.startedAt>=1.19)
  assert(hit.guardAt and hit.guardCompletedAt and hit.guardCompletedAt-hit.startedAt>=hit.guardDuration-0.06)
  assert(not story:summary().completed["ruins-twins"] and c.stage==1 and player().busy)
  D.DB:exec("DROP TRIGGER lsd.fail_twins"); f.retryButton:emit("Tapped"); wait(function() return f.phase=="complete" and c.stage==2 end)
  local mid=D.Path(D.Content.writablePath,"lsd-ruins-twins-qa-"..id..".db"); assert(D.Content:copyAsync(db,mid)); D.Content:save(D.Path(root,"Test","ruins-mid-resume-fixture.txt"),mid)
  move(8500); wait(function() return c.found.menu.enabled end)
  for _,name in ipairs({"vika","vivi"}) do assert(c.escorted[name].walked>1000,"Twins were not physically escorted") end
  c.found:emit("Tapped",1); dialogue("ayan-found",7); wait(function() return c.stage==3 end)
  assert(story:summary().unlocks["ayan-diary-found"] and not story:summary().completed["ayan-recovery"] and c.body)
  wait(function() return c.recovery.menu.enabled end); c.recovery:emit("Tapped",1); wait(function() return world().companionPanel and world().companionPanel.phase=="information" end)
  local profile=world().companionPanel; profile.view.stationButton:emit("Tapped"); dialogue("ayan-diary",7)
  wait(function() return world().companionPanel.phase=="information" end); world().companionPanel.view.closeButton:emit("Tapped")
  wait(function() return c.recovery.menu.enabled end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_ayan_data BEFORE INSERT ON Game0StoryUnlocks WHEN NEW.id='ayan-data-recovered' BEGIN SELECT RAISE(ABORT,'QA Ayan data'); END")>=0)
  c.recovery:emit("Tapped",2); f=dialogue("ayan-recovery",8,"save-error")
  assert(c.body and not c.dataRecovery and not story:summary().completed["ayan-recovery"],"Data disappeared before save")
  D.DB:exec("DROP TRIGGER lsd.fail_ayan_data"); f.retryButton:emit("Tapped"); wait(function() return f.phase=="complete" and c.stage==4 and c.dataRecovery and c.dataRecovery.completedAt and not c.body and not player().busy end)
  assert(c.support.gold>0 and c.support.collected["ruins-gold-4"],"Actual route did not collect life-support supplies")
  assert(c.dataRecovery.completedAt-c.dataRecovery.startedAt>=1.39 and not c.diary.visible)
  for _,reward in ipairs({"ruins-twins-met","ayan-diary-found","ayan-diary-read","ayan-data-recovered"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(models()==unchanged and #D.DB:query("SELECT source FROM lsd.Game0StorySupplies WHERE amount=1")==6)
  D.Content:save(D.Path(root,"Test","ruins-resume-fixture.txt"),db)
  return "PASS actualStart=true earnedRecoveryCopy=true physicalStationTrainRoute=true originalFormationThree=true distinctRuinsDeployment=true actualSignalLensAndWalk=true firstRemoteRejected=true originalTwins41=true realProjectileShieldBlock=true fullProceduralTwinPulse=true fullOriginalFireGuard=true twinsRollbackRetry=true physicalBothTwinsEscort=true originalAyanFound7=true realFullLosePose=true characterStoryTwoDiary7=true originalRecovery8=true dataRollbackBeforeVisual=true actualDataStream=true rewardsOnce=true modelsUnchanged=true suppliesPreserved=true"
 end,debug.traceback)
 local report="LSD_RUINS_ROUTE_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
