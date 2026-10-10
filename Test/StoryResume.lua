-- Reopens the completed StoryUI QA database and goes through the actual Start continue path.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local db=assert(D.Content:load(D.Path(root,"Test","story-resume-fixture.txt")))
assert(D.Path:getPath(db)==D.Content.writablePath and D.Path:getFilename(db):match("^lsd%-story%-ui%-qa%-%d+%.db$"))
assert(not D.DB:existDB("lsd") and D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
local runId=tostring(os.time()); local out=D.Path(root,"Test","story-resume-result.txt")
D.Content:save(out,"LSD_STORY_RESUME_RUNNING runId="..runId.."\n")
require("Start")
D.thread(function()
 local ok,result=xpcall(function()
  local deadline=D.App.runningTime+20
  while not D.Platformer.Data.store.world or D.Platformer.Data.store.world.tag~="PreparationRoom" do
   assert(D.App.runningTime<deadline,"Continue did not reach academy"); D.sleep(0.1)
  end
  local player
  repeat player=D.Group({"player","unit"}):find(function(e) return e.player end); D.sleep(0.1); assert(D.App.runningTime<deadline,"Continue player unavailable") until player and not player.busy
  local config=require("Data.Config"); assert(config.char=="charF" and config.charName=="ArchiveQA","Continue overwrote identity")
  local story=assert(require("Story.Service").open()); local facts=assert(story:summary())
  assert(facts.completed["academy-research"] and facts.completed["mail-one"] and facts.completed["archive-discovery"])
  assert(facts.unlocks["archive-discovered"] and facts.mission.unlocks["library-lead"])
  local journal=assert(require("Story.Journal").openAsync(D.Platformer.Data.store.world))
  assert(journal.view.detail.text:find("三月十五日",1,true) and journal.view.detail.text:find("地面站台",1,true))
  -- Recorded room story may replay from another room without duplicate unlocks.
  local before=#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks")
  journal.view.archiveButton:emit("Tapped")
  local w=D.Platformer.Data.store.world
  while not w.storyFlow do D.sleep(0.05); assert(D.App.runningTime<deadline+10,"Replay did not open") end
  local flow=w.storyFlow
  while flow.phase=="dialogue" do if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit("Tapped") end; D.sleep(0.1); assert(D.App.runningTime<deadline+15,"Remote recorded replay failed") end
  while flow.phase=="saving" do D.sleep(0.05) end
  assert(flow.phase=="complete" and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks")==before)
  return "PASS startContinue=true identityPreserved=true storyNodes=3 missionReward=true journalRestored=true recordedRemoteReplay=true duplicateReward=false"
 end,debug.traceback)
 local report="LSD_STORY_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..runId
 print(report); D.Content:save(out,report.."\n")
end)
