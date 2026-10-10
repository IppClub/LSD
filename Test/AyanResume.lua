-- Earned energy copy, actual Start and academy doors, physical NPC escort and Yarn.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ayan-resume-result.txt"); D.Content:save(out,"LSD_AYAN_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","ayan-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-ayan%-visit%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ayan-resume-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Start")
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t) local deadline=D.App.runningTime+(t or 20); while not f() do assert(D.App.runningTime<deadline,"Ayan visit timed out"); D.sleep(0.02) end end
  wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end)
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); local story=assert(require("Story.Service").open()); assert(story:summary().completed["energy-recovery"])
  local function move(x)
   local e=assert(player()); local deadline=D.App.runningTime+20
   while math.abs(e.unit.x-x)>25 do assert(D.App.runningTime<deadline,"Physical escort walk stalled"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.02) end
   e.keyLeft=false; e.keyRight=false; D.sleep(0.2)
  end
  local function door(side,target)
   local old=world(); move(side=="right" and old.sceneWidth-110 or 110)
   assert(player().interaction and player().moveTargets:get(1)==target)
   player().interaction:emit("Tapped",1); wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.4)
  end
  door("right","PassageB"); door("right","TrainingRoom")
  wait(function() return world().academyVisit and world().academyVisit.actor end)
  local visit=world().academyVisit
  assert(story:summary().completed["ayan-arrival"] and story:summary().completed["ayan-detour"] and story:summary().completed["ayan-tour"])
  assert(visit.stage==4 and story:summary().unlocks["liyena-training-invited"])
  move(1900); wait(function() return visit.actor.keyLeft end)
  local journal=assert(require("Story.Journal").openAsync(world(),4)); D.sleep(0.2)
  local pausedX=visit.actor.unit.x; local playerX=player().unit.x; D.sleep(0.4); assert(math.abs(visit.actor.unit.x-pausedX)<6,"Guide walked while reading phone"); assert(math.abs(player().unit.x-playerX)<6,"Player slid while reading phone")
  journal.view.closeButton:emit("Tapped")
  move(935); wait(function() return math.abs(visit.actor.unit.x-935)<180 and not visit.actor.keyLeft and not visit.actor.keyRight end)
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='ayan-met'")==1 and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='liyena-training-invited'")==1)
  assert(models()==unchanged and story:summary().mission.rewards["energy-site-secured"]==2)
  world():getChildByTag("trainingTerminal"):emit("Tapped",1); wait(function() return world().tag=="VRTraining" end)
  assert(not D.Director.ui3D:getChildByTag("ayan-visit-guidance"))
  D.Director.ui3D:getChildByTag("training-controls"):getChildByTag("training-menu"):getChildByTag("返回训练室"):emit("Tapped")
  wait(function() return world().tag=="TrainingRoom" and player() and world().academyVisit and world().academyVisit.actor end)
  assert(world().academyVisit.stage==4)
  move(2200); move(935); wait(function() return math.abs(world().academyVisit.actor.unit.x-935)<180 and not world().academyVisit.actor.keyLeft and not world().academyVisit.actor.keyRight end)
  assert(world().academyVisit.hint.parent.visible)
  return "PASS returnFromVRVisitRestored=true liveGuidePhonePause=true playerPhonePause=true actualStartContinue=true physicalAcademyDoors=true savedCheckpoint=true physicalGuideResumed=true earnedEnergyTwoPreserved=true storyRewardsOnce=true modelRowsUnchanged=true originalTrainingReachable=true noGuideOverlayInVR=true"
 end,debug.traceback)
 local report="LSD_AYAN_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
