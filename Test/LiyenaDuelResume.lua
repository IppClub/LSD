-- Actual Start after native restart, resuming a genuinely earned cooperation checkpoint.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","liyena-duel-resume-result.txt"); D.Content:save(out,"LSD_LIYENA_DUEL_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","liyena-duel-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-liyena%-duel%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-liyena-duel-resume-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db)); assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t) local deadline=D.App.runningTime+(t or 20); while not f() do assert(D.App.runningTime<deadline,"Trial resume timed out"); D.sleep(0.02) end end
  require("Start"); wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end)
  local story=assert(require("Story.Service").open()); local facts=story:summary()
  assert(facts.mission.unlocks["liyena-coop-complete"] and facts.completed["liyena-challenge"] and facts.mission.unlocks["liyena-duel-complete"] and not facts.completed["liyena-recognition"])
  local function move(x)
   local e=assert(player()); local deadline=D.App.runningTime+20
   while math.abs(e.unit.x-x)>25 do assert(D.App.runningTime<deadline,"Resume walk stalled"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.02) end
   e.keyLeft=false; e.keyRight=false; D.sleep(0.2)
  end
  local function door(target)
   local old=world(); move(old.sceneWidth-110); assert(player().interaction and player().moveTargets:get(1)==target)
   player().interaction:emit("Tapped",1); wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.4)
  end
  door("PassageB"); door("TrainingRoom"); move(935)
  world():getChildByTag("trainingTerminal"):emit("Tapped",3)
  wait(function() return world().storyFlow and world().storyFlow.id=="liyena-recognition" and world().storyFlow.view.visible end)
  local f=world().storyFlow
  while f.phase=="dialogue" or f.phase=="saving" do if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
  assert(f.phase=="complete" and #f.view._reviews==5)
  wait(function() return world().tag=="TrainingRoom" and player() end)
  assert(story:summary().completed["liyena-recognition"] and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='liyena-recognized'")==1)
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE mission='c0-m04-duel'")==1,"Recognition checkpoint forced another fight")
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0)
  return "PASS actualStart=true earnedBothWinsCheckpoint=true originalAcademyDoors=true publicRecognitionResume=true recognitionFullYarn=true noRepeatFightRequired=true recognitionRewardOnce=true safeRoomReturn=true"
 end,debug.traceback)
 local report="LSD_LIYENA_DUEL_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
