local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ground-resume-result.txt")
D.Content:save(out,"LSD_GROUND_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local db=assert(D.Content:load(D.Path(root,"Test","ground-resume-fixture.txt")))
  assert(D.Path:getPath(db)==D.Content.writablePath and D.Path:getFilename(db):match("^lsd%-ground%-route%-qa%-%d+%.db$"))
  assert(not D.DB:existDB("lsd") and D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  require("Start")
  local function wait(f)
   local untilTime=D.App.runningTime+15
   while not f() do assert(D.App.runningTime<untilTime,"Ground resume timeout"); D.sleep(0.05) end
  end
  wait(function() return D.Platformer.Data.store.world and D.Platformer.Data.store.world.tag=="PreparationRoom" end)
  local facts=assert(require("Story.Service").open():summary()); local count=0
  for _ in pairs(facts.completed) do count=count+1 end
  assert(count==8 and facts.completed["ground-arrival"] and facts.completed["ground-contact"])
  assert(require("Training.Progress").load() and require("Training.Progress").adopted)
  wait(function() local e=D.Group({"player","unit"}):find(function(e) return e.player end); return e and not e.busy end)
  local journal=assert(require("Story.Journal").openAsync(D.Platformer.Data.store.world,2)); assert(#journal.recordIds==4)
  journal.view.closeButton:emit("Tapped"); assert(not D.Platformer.Data.store.world.data.journalOpen)
  return "PASS actualStartContinue=true safeAcademyCheckpoint=true savedGroundRecords=2 totalRecords=8 adoptedModel=true journalPageTwo=true noMidPhysicsRestore=true"
 end,debug.traceback)
 local report="LSD_GROUND_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id
 print(report); D.Content:save(out,report.."\n")
end)
