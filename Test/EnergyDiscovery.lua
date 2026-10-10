-- A won encounter permits discovery only at the physical box, not the journal.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","energy-discovery-result.txt"); D.Content:save(out,"LSD_ENERGY_DISCOVERY_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","energy-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-energy%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-energy-discovery-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync(); local s=assert(require("Story.Service").open())
  assert(s:summary().mission.unlocks["energy-site-secured"])
  -- Rewind only this QA copy's box discovery; the encounter remains genuinely won.
  assert(D.DB:transactionAsync({"DELETE FROM lsd.Game0StoryNodes WHERE id='energy-recovery'","DELETE FROM lsd.Game0StoryUnlocks WHERE id='city-energy-recovered'"}))
  require("Academy.Navigation").returnToRoomAsync("AbandonedCity",{energySquad=true})
  local w=D.Platformer.Data.store.world
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==w end) end
  local function wait(f,t) local deadline=D.App.runningTime+(t or 15); while not f() do assert(D.App.runningTime<deadline,"Energy discovery timed out"); D.sleep(0.05) end end
  wait(player); local journal=assert(require("Story.Journal").openAsync(w,4)); journal.view.mailButton:emit("Tapped")
  assert(journal.phase=="journal" and not s:summary().completed["energy-recovery"])
  assert(journal.view.detail.text:find("首次收取请走近",1,true)); journal.view.closeButton:emit("Tapped")
  local remote,err=require("Story.Flow").openAsync("energy-recovery",w); assert(not remote and err=="DISCOVERY_LOCATION_REQUIRED" and not player().busy)
  local e=player(); local deadline=D.App.runningTime+40
  while math.abs(e.unit.x-5760)>35 do assert(D.App.runningTime<deadline,"Box approach stalled"); e.keyRight=true; D.sleep(0.05) end; e.keyRight=false; D.sleep(0.4)
  w.energySite.view:emit("Tapped",2); wait(function() return w.storyFlow and w.storyFlow.view.visible end)
  local flow=w.storyFlow; deadline=D.App.runningTime+25
  while flow.phase=="dialogue" or flow.phase=="saving" do assert(D.App.runningTime<deadline,"Physical discovery Yarn stalled"); if not flow.view._advancing then flow.view.confirm:emit("Tapped") end; D.sleep(0.1) end
  assert(flow.phase=="complete" and s:summary().unlocks["city-energy-recovered"] and not player().busy)
  local lens=assert(require("Ground.NightLens").openAsync(w)); assert(lens.view.detail.text:find("中央能源已回收",1,true)); lens.view.closeButton:emit("Tapped")
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='city-energy-recovered'")==1)
  return "PASS earnedEncounterPreserved=true qaDiscoveryRewindOnly=true remoteJournalRejected=true remoteFlowRejected=true physicalWalkRequired=true publicBox=true actualYarn=true onceReward=true collectedMapStatus=true"
 end,debug.traceback)
 local report="LSD_ENERGY_DISCOVERY_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
