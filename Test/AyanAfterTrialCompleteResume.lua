-- Earned two-fight copy; original Start/doors, explicit mail forwarding and physical story-fragment unlock.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ayan-aftertrial-complete-resume-result.txt"); D.Content:save(out,"LSD_AYAN_AFTERTRIAL_COMPLETE_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","ayan-aftertrial-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-ayan%-aftertrial%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ayan-aftertrial-complete-resume-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db)); assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t,label) local deadline=D.App.runningTime+(t or 20); while not f() do assert(D.App.runningTime<deadline,"After trial timeout "..(label or "")); D.sleep(0.02) end end
  require("Start"); wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end)
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); local story=assert(require("Story.Service").open()); assert(story:summary().completed["liyena-recognition"])
  local function move(x)
   local e=assert(player()); local deadline=D.App.runningTime+20
   while math.abs(e.unit.x-x)>25 do assert(D.App.runningTime<deadline,"After trial walk stalled"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.02) end
   e.keyLeft=false; e.keyRight=false; D.sleep(0.2)
  end
  local function door(side,target)
   local old=world(); move(side=="right" and old.sceneWidth-110 or 110); assert(player().interaction and player().moveTargets:get(1)==target)
   player().interaction:emit("Tapped",1); wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.4)
  end
  for _,node in ipairs({"mail-three","mail-three-forward","ayan-refreshment","ayan-fragment","ayan-sharing"}) do assert(story:summary().completed[node]) end
  local nodeCount=#D.DB:query("SELECT id FROM lsd.Game0StoryNodes")
  local j=assert(require("Story.Journal").openAsync(world(),6)); assert(j.recordIds[2]=="ayan-fragment")
  j.view.researchButton:emit("Tapped"); wait(function() return world().storyFlow and world().storyFlow.id=="ayan-fragment" and world().storyFlow.view.visible end)
  local f=world().storyFlow; local deadline=D.App.runningTime+30
  while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Completed Yarn stalled"); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
  assert(f.phase=="complete" and #f.view._reviews==7); wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  door("right","PassageB"); door("right","TrainingRoom"); wait(function() return world().afterTrial and world().afterTrial.actor end)
  local c=world().afterTrial; assert(c.stage==8 and not c.tray.visible); move(1900); wait(function() return c.view.menu.enabled end)
  c.view:emit("Tapped",2); wait(function() return world().companionPanel and world().companionPanel.phase=="information" end)
  local info=world().companionPanel; info.view.archiveButton:emit("Tapped"); assert(info.view.detail.text:find("还需要更多证据",1,true)); info.view.closeButton:emit("Tapped")
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryNodes")==nodeCount and models()==unchanged)
  for _,reward in ipairs({"mail-three-read","ninilite-third-mail-received","academy-refreshment-received","ayan-memory-fragment","medical-pair-invited"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(story:summary().mission.rewards["energy-site-secured"]==2)
  return "PASS actualStart=true earnedCompletedCopy=true allFiveNodesSaved=true journalSixReplay=true physicalAcademyDoors=true postTrialActorRestored=true noFoodReplay=true characterStoryInformation=true clueNotClaimedAsProof=true unlocksOnce=true modelRowsUnchanged=true energyTwoPreserved=true"
 end,debug.traceback)
 local report="LSD_AYAN_AFTERTRIAL_COMPLETE_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
