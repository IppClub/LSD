-- Real completed trial checkpoint; Start, room route and phone replay must preserve earned facts.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","liyena-complete-resume-result.txt"); D.Content:save(out,"LSD_LIYENA_COMPLETE_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","liyena-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-liyena%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-liyena-complete-resume-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db)); assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t) local deadline=D.App.runningTime+(t or 20); while not f() do assert(D.App.runningTime<deadline,"Completed trial resume timeout"); D.sleep(0.02) end end
  require("Start"); wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end)
  local story=assert(require("Story.Service").open()); local facts=story:summary(); assert(facts.completed["liyena-recognition"] and facts.mission.unlocks["liyena-coop-complete"] and facts.mission.unlocks["liyena-duel-complete"])
  local snapshot=D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true)
  local journal=assert(require("Story.Journal").openAsync(world(),5)); assert(journal.recordIds[1]=="liyena-challenge" and journal.recordIds[2]=="liyena-recognition")
  journal.view.researchButton:emit("Tapped"); wait(function() return world().storyFlow and world().storyFlow.id=="liyena-recognition" and world().storyFlow.view.visible end)
  local f=world().storyFlow; while f.phase=="dialogue" or f.phase=="saving" do if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
  assert(f.phase=="complete" and #f.view._reviews==5); wait(function() return world().storyJournal and world().storyJournal.phase=="journal" end)
  world().storyJournal.view.closeButton:emit("Tapped")
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='liyena-recognized'")==1 and #D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id LIKE 'liyena-%'")==2)
  assert(D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true)==snapshot)
  assert(facts.mission.rewards["energy-site-secured"]==2 and #D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0)
  return "PASS actualStart=true earnedBothWins=true savedRecognition=true journalPageFive=true completeRecognitionReplay=true rewardsOnce=true adoptedModelsPreserved=true energyTwoPreserved=true safeContinue=true"
 end,debug.traceback)
 local report="LSD_LIYENA_COMPLETE_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
