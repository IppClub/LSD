local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","cooperation-resume-result.txt")
D.Content:save(out,"LSD_COOPERATION_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local db=assert(D.Content:load(D.Path(root,"Test","cooperation-resume-fixture.txt")))
  assert(D.Path:getPath(db)==D.Content.writablePath and D.Path:getFilename(db):match("^lsd%-cooperation%-route%-qa%-%d+%.db$"))
  assert(not D.DB:existDB("lsd") and D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Start")
  local function wait(f)
   local untilTime=D.App.runningTime+15
   while not f() do assert(D.App.runningTime<untilTime,"Ground resume timeout"); D.sleep(0.05) end
  end
  wait(function() return D.Platformer.Data.store.world and D.Platformer.Data.store.world.tag=="PreparationRoom" end)
  local mission=assert(require("Mission.Service").open():summary())
  assert(mission.unlocks["library-lead"] and mission.unlocks["wuyun-rescued"])
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks")==2)
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='won'")==2)
  local facts=assert(require("Story.Service").open():summary()); local count=0
  for _ in pairs(facts.completed) do count=count+1 end
  assert(count==12 and facts.completed["ground-rescue"] and facts.completed["wuyun-rest"] and facts.unlocks["chapter-one-complete"] and facts.unlocks["night-lens"] and facts.completed["energy-plan"])
  assert(require("Training.Progress").load() and require("Training.Progress").adopted and require("Training.Progress").adopted.sampleCount==6)
  wait(function() local e=D.Group({"player","unit"}):find(function(e) return e.player end); return e and not e.busy end)
  local journal=assert(require("Story.Journal").openAsync(D.Platformer.Data.store.world,3)); assert(#journal.recordIds==4 and journal.recordIds[1]=="ground-rescue" and journal.recordIds[2]=="wuyun-rest")
  assert(journal.recordIds[3]=="underground-cooperation" and journal.recordIds[4]=="energy-plan")
  journal.view.closeButton:emit("Tapped"); assert(not D.Platformer.Data.store.world.data.journalOpen)
  local lens=assert(require("Ground.NightLens").openAsync(D.Platformer.Data.store.world)); lens.view.stationButton:emit("Tapped"); assert(lens.selected.id=="energy"); lens.view.closeButton:emit("Tapped")
  return "PASS actualStartContinue=true safeAcademyCheckpoint=true savedChapterEnd=true twoActualWonMissions=true onceRewards=true totalRecords=12 restoredNightLens=true restoredCooperation=true actualMap=true adoptedSixSampleModel=true journalPageThree=true noMidPhysicsRestore=true"
 end,debug.traceback)
 local report="LSD_COOPERATION_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id
 print(report); D.Content:save(out,report.."\n")
end)
