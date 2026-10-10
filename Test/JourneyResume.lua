-- Reopens the tutorial/training/mission/story journey database and goes through the actual Start continue path.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local db=assert(D.Content:load(D.Path(root,"Test","journey-story-fixture.txt")))
assert(D.Path:getPath(db)==D.Content.writablePath and D.Path:getFilename(db):match("^lsd%-game0%-journey%-qa%-%d+%.db$"))
assert(not D.DB:existDB("lsd") and D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
local runId=tostring(os.time()); local out=D.Path(root,"Test","journey-resume-result.txt")
D.Content:save(out,"LSD_JOURNEY_RESUME_RUNNING runId="..runId.."\n")
require("Start")
D.thread(function()
 local ok,result=xpcall(function()
  local deadline=D.App.runningTime+20
  while not D.Platformer.Data.store.world or D.Platformer.Data.store.world.tag~="PreparationRoom" do
   assert(D.App.runningTime<deadline,"Continue did not reach academy"); D.sleep(0.1)
  end
  local player
  repeat player=D.Group({"player","unit"}):find(function(e) return e.player end); D.sleep(0.1); assert(D.App.runningTime<deadline,"Continue player unavailable") until player and not player.busy
  local config=require("Data.Config"); assert(config.char=="charF" and config.charName=="JourneyQA","Continue overwrote identity")
  local story=assert(require("Story.Service").open()); local facts=assert(story:summary())
  assert(facts.completed["academy-research"] and facts.completed["mail-one"] and facts.completed["archive-discovery"] and facts.completed["station-brief"])
  assert(facts.unlocks["station-briefed"] and facts.unlocks["archive-discovered"] and facts.mission.unlocks["library-lead"])
  local training=require("Training.Progress"); assert(training.load() and training.adopted and training.adopted.sampleCount==6,"Real learned model did not survive continue")
  local attempts=D.DB:query("SELECT status FROM lsd.Game0MissionAttempts")
  assert(#attempts==1 and attempts[1][1]=="won","Actual mission outcome not restored")
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks")==1,"Mission reward duplicated")
  local journal=assert(require("Story.Journal").openAsync(D.Platformer.Data.store.world))
  assert(journal.view.detail.text:find("三月十五日",1,true) and journal.view.detail.text:find("地面站台",1,true))
  -- Recorded room story may replay from another room without duplicate unlocks.
  local before=#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks")
  journal.view.archiveButton:emit("Tapped")
  local w=D.Platformer.Data.store.world
  while not w.storyFlow do D.sleep(0.05); assert(D.App.runningTime<deadline+10,"Replay did not open") end
  local flow=w.storyFlow
  while flow.phase=="dialogue" do if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit("Tapped") end; D.sleep(0.1); assert(D.App.runningTime<deadline+15,"Remote recorded replay failed") end
  while flow.phase=="saving" do D.sleep(0.05); assert(D.App.runningTime<deadline+20,"Replay persistence timed out") end
  assert(flow.phase=="complete" and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks")==before)
  return "PASS startContinue=true identityPreserved=true storyNodes=4 realLearnedModelSamples=6 actualMissionWon=true missionRewardOnce=true journalRestored=true recordedRemoteReplay=true duplicateReward=false"
 end,debug.traceback)
 local report="LSD_JOURNEY_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..runId
 print(report); D.Content:save(out,report.."\n")
end)
