-- Earned energy copy, actual Start and academy doors, physical NPC escort and Yarn.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ayan-mid-resume-result.txt"); D.Content:save(out,"LSD_AYAN_MID_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","ayan-mid-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-ayan%-mid%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ayan-mid-resume-qa-"..id..".db")
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
  assert(story:summary().completed["ayan-arrival"] and not story:summary().completed["ayan-detour"])
  assert(visit.stage==2,"Mid checkpoint did not resume next leg")
  local opened,why=require("Story.Flow").openAsync("ayan-detour",world()); assert(not opened and why=="DISCOVERY_LOCATION_REQUIRED")
  local function dialogue(id,count)
   visit.view:emit("Tapped"); wait(function() return world().storyFlow and world().storyFlow.id==id and world().storyFlow.view.visible end)
   local f=world().storyFlow; local deadline=D.App.runningTime+25
   while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Resumed Yarn stalled"); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
   assert(f.phase=="complete" and #f.view._reviews==count)
  end
  move(3100); wait(function() return visit.view.menu.enabled end); dialogue("ayan-detour",9)
  move(2200); wait(function() return visit.stage==3 and visit.view.menu.enabled end); dialogue("ayan-tour",14)
  wait(function() return visit.stage==4 end)
  move(935); wait(function() return math.abs(visit.actor.unit.x-935)<180 and not visit.actor.keyLeft and not visit.actor.keyRight end)
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='ayan-met'")==1 and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='liyena-training-invited'")==1)
  assert(models()==unchanged and story:summary().mission.rewards["energy-site-secured"]==2)
  world():getChildByTag("trainingTerminal"):emit("Tapped",1); wait(function() return world().tag=="VRTraining" end)
  assert(not D.Director.ui3D:getChildByTag("ayan-visit-guidance"))
  return "PASS actualStartContinue=true physicalAcademyDoors=true savedCheckpoint=true physicalGuideResumed=true earnedEnergyTwoPreserved=true storyRewardsOnce=true modelRowsUnchanged=true originalTrainingReachable=true noGuideOverlayInVR=true"
 end,debug.traceback)
 local report="LSD_AYAN_MID_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
