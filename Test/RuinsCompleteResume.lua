-- Earned factory victory copy; original Start/doors, full treatment and next-day messages.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ruins-complete-resume-result.txt"); D.Content:save(out,"LSD_RUINS_COMPLETE_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","ruins-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-ruins%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ruins-complete-resume-qa-"..id..".db")
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
  assert(story:canRead("ayan-diary",world().tag))
  assert(story:summary().completed["ruins-twins"] and story:summary().completed["ayan-found"])
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
  local c=world().ruinsExpedition
  assert(c.stage==4 and not c.body and not c.bodyPose and not c.confrontation and not c.dataRecovery)
  for _,node in ipairs({"ruins-twins","ayan-found","ayan-diary","ayan-recovery"}) do assert(story:summary().completed[node]) end
  local function replay(page,button,node,count)
   local j=assert(require("Story.Journal").openAsync(world(),page)); j.view[button]:emit("Tapped"); dialogue(node,count)
   wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  end
  replay(9,"archiveButton","ruins-twins",41)
  replay(9,"stationButton","ayan-found",7)
  local profile=assert(require("Academy.Companion").openAsync("ayan",world(),"information")); profile.view.stationButton:emit("Tapped"); dialogue("ayan-diary",7)
  wait(function() return world().companionPanel.phase=="information" end); world().companionPanel.view.closeButton:emit("Tapped")
  replay(10,"researchButton","ayan-recovery",8)
  assert(c.stage==4 and not c.body and not c.bodyPose and not c.confrontation and not c.dataRecovery,"Replay repeated physical events")
  for _,reward in ipairs({"ruins-twins-met","ayan-diary-found","ayan-diary-read","ayan-data-recovered"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(models()==unchanged and #D.DB:query("SELECT source FROM lsd.Game0StorySupplies WHERE amount=1")==6)
  require("Academy.Navigation").returnToTrainingAsync()
  wait(function() return world().tag=="TrainingRoom" and player() end)
  D.sleep(0.5)
  local ayan=D.Group({"name","unit"}):find(function(e) return e.name=="ayan" and e.unit.world==world() end)
  assert(not ayan and not world().afterTrial,"Missing Ayan must not reappear in the training room")
  return "PASS actualStart=true earnedCompletedCopy=true physicalStationTrainDeployment=true fourNodesRestored=true noForcedConfrontation=true noRespawnedAyanBody=true noRepeatedDataStream=true fullFourReplays=true characterDiaryProfile=true rewardsOnce=true modelsUnchanged=true suppliesPreserved=true noMissingAyanTrainingRespawn=true"
 end,debug.traceback)
 local report="LSD_RUINS_COMPLETE_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
