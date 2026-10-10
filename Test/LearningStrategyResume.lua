-- Reopen a real public-demonstration model after an actual native restart.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","learning-strategy-resume-result.txt")
D.Content:save(out,"LSD_LEARNING_RESUME_RUNNING runId="..id.."\n")
assert(not D.DB:existDB("lsd"))
D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
D.thread(function()
 local ok,result=xpcall(function()
  local old=assert(D.Content:load(D.Path(root,"Test","training-resume-fixture.txt")))
  local rich=assert(D.Content:load(D.Path(root,"Test","learning-strategy-resume-fixture.txt")))
  assert(D.Path:getPath(old)==D.Content.writablePath and D.Path:getFilename(old):match("^lsd%-game0%-training%-qa%-%d+%.db$"))
  assert(D.Path:getPath(rich)==D.Content.writablePath and D.Path:getFilename(rich):match("^lsd%-learning%-strategy%-qa%-%d+%.db$"))
  assert(D.DB:exec("ATTACH DATABASE '"..old:gsub("'","''").."' AS lsd")>=0)
  local store=assert(require("Training.Store").open()); local legacy=assert(store:load())
  assert(legacy.adopted.featureSchemaVersion==1 and not store.writeBlocked,"Legacy feature model rejected")
  D.DB:exec("DETACH DATABASE lsd")
  assert(D.DB:exec("ATTACH DATABASE '"..rich:gsub("'","''").."' AS lsd")>=0)
  local progress=require("Training.Progress"); assert(progress.load() and progress.adopted.featureSchemaVersion==2 and progress.adopted.sampleCount==18 and not progress.store.writeBlocked,"Rich feature model rejected after restart")
  local model=progress.adopted
  require("Training.Level")()
  local deadline=D.App.runningTime+12
  while not D.Director.ui3D:getChildByTag("training-controls") do assert(D.App.runningTime<deadline,"Restored public UI absent"); D.sleep(0.05) end
  local ui=D.Director.ui3D:getChildByTag("training-controls"); local a=ui.arena
  local rows={}
  for _,distance in ipairs({220,420,680}) do
   assert(a:beginTrial(distance,model)); local untilTime=D.App.runningTime+38
   while a.mode=="trial" do assert(D.App.runningTime<untilTime,"Restored learned battle stuck"); D.sleep(0.1) end
   assert(a.result.won and a.result.studentHP==100 and a.result.metrics.fallback==0 and a.result.metrics.baselineActions==0,"Restored strategy lost behavior")
   rows[#rows+1]=a.result
  end
  return "PASS legacyFeatureOne=true rangeFeatureTwo=true samples=18 publicUI=true restoredTrials=3 health=100 fallback=0 baselineActions=0 savedTreeReused=true summary="..D.json.encode(require("Training.Arena").summarize(rows))
 end,debug.traceback)
 local report="LSD_LEARNING_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id
 print(report); D.Content:save(out,report.."\n")
end)
