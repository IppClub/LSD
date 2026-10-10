-- Earned factory victory copy; original Start/doors, full treatment and next-day messages.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ruins-outcomes-result.txt"); D.Content:save(out,"LSD_RUINS_OUTCOMES_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","ruins-mid-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-ruins%-twins%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ruins-outcomes-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local w=require("Academy.Navigation").returnToRoomAsync("AbandonedCity",{energySquad=true,ruinsSearch=true,spawn=8500})
  local c=w.ruinsExpedition; local deadline=D.App.runningTime+20
  while c.phase~="exploring" do assert(D.App.runningTime<deadline,"Ruins actors unavailable"); D.sleep(0.04) end
  local before=D.json.encode(D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks ORDER BY id"),false,true)
  c.support.gold=0; c.support.hp[1]=0.01
  while D.Platformer.Data.store.world==w do assert(D.App.runningTime<deadline,"Life-support exhaustion did not evacuate"); D.sleep(0.02) end
  assert(D.Platformer.Data.store.world.tag=="TrainA" and c.phase=="evacuating" and c.support.hp[1]==0)
  assert(before==D.json.encode(D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks ORDER BY id"),false,true))
  return "PASS explicitLowLifeFixture=true actualLifeSupportHazard=true actualTrainEvacuation=true noStoryRewardAdded=true"
 end,debug.traceback)
 local report="LSD_RUINS_OUTCOMES_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
