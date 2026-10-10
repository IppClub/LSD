-- Earned energy copy, actual Start and academy doors, physical NPC escort and Yarn.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","fresh-ayan-visit-result.txt"); D.Content:save(out,"LSD_FRESH_AYAN_VISIT_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","fresh-energy-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-fresh%-energy%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-fresh-ayan-visit-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Start")
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t) local deadline=D.App.runningTime+(t or 20); while not f() do assert(D.App.runningTime<deadline,"Ayan visit timed out"); D.sleep(0.02) end end
  wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end)
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); local story=assert(require("Story.Service").open()); assert(story:summary().completed["energy-recovery"])
  local function move(x)
   local e=assert(player());local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
   local side=e.unit.x<x and 'Right' or 'Left';hud.move:emit(side,true)
   local deadline=D.App.runningTime+45
   while math.abs(e.unit.x-x)>35 do
    if D.App.runningTime>=deadline then hud.move:emit(side,false);error('Factory physical walk stalled x='..e.unit.x..' target='..x)end
    D.sleep(.02)
   end
   hud.move:emit(side,false);D.sleep(.5)
  end
  local function door(side,target)
   local old=world(); move(side=="right" and old.sceneWidth-110 or 110)
   assert(player().interaction and player().moveTargets:get(1)==target)
   player().interaction:emit("Tapped",1); wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.4)
  end
  door("right","PassageB"); door("right","TrainingRoom")
  wait(function() return world().academyVisit and world().academyVisit.actor end)
  local visit=world().academyVisit
  local opened,why=require("Story.Flow").openAsync("ayan-arrival",world()); assert(not opened and why=="DISCOVERY_LOCATION_REQUIRED","Remote greeting allowed")
  local journal=assert(require("Story.Journal").openAsync(world(),4)); assert(journal.recordIds[2]=="ayan-arrival")
  journal.view.researchButton:emit("Tapped"); assert(journal.phase=="journal" and not world().data.storyBusy,"Journal granted first meeting remotely"); journal.view.closeButton:emit("Tapped")
  move(2600); wait(function() return visit.view.menu.enabled end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_ayan_unlock BEFORE INSERT ON Game0StoryUnlocks BEGIN SELECT RAISE(ABORT,'QA Ayan save fault'); END")>=0)
  local function dialogue(id,expect)
   visit.view:emit("Tapped"); wait(function() return world().storyFlow and world().storyFlow.id==id and world().storyFlow.view.visible end)
   local f=world().storyFlow; local deadline=D.App.runningTime+30
   while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Ayan Yarn stalled"); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
   local lines={ ["ayan-arrival"]=11,["ayan-detour"]=9,["ayan-tour"]=14 }
   assert(#f.view._reviews==lines[id],"Yarn did not play all authored lines: "..id.." "..#f.view._reviews)
   if id=="ayan-arrival" then assert(f.view._reviews[5].text:find(require("Data.Config").charName,1,true),"Player name was not interpolated") end
   assert(f.phase==(expect or "complete"),id.." "..f.phase); return f
  end
  local f=dialogue("ayan-arrival","save-error")
  assert(not story:summary().completed["ayan-arrival"] and not story:summary().unlocks["ayan-met"] and player().busy)
  D.DB:exec("DROP TRIGGER lsd.fail_ayan_unlock"); f.retryButton:emit("Tapped"); wait(function() return f.phase=="complete" and not player().busy end)
  local mid=D.Path(D.Content.writablePath,"lsd-fresh-ayan-mid-qa-"..id..".db"); assert(not D.Content:exist(mid) and D.Content:copyAsync(db,mid)); D.Content:save(D.Path(root,"Test","fresh-ayan-mid-resume-fixture.txt"),mid)
  move(3100); wait(function() return visit.stage==2 and visit.view.menu.enabled end)
  dialogue("ayan-detour"); move(2200); wait(function() return visit.stage==3 and visit.view.menu.enabled end)
  dialogue("ayan-tour"); wait(function() return visit.stage==4 end)
  move(935); wait(function() return math.abs(visit.actor.unit.x-935)<180 and not visit.actor.keyLeft and not visit.actor.keyRight end)
  assert(visit.hint.parent.visible,"Escort guidance stayed hidden after dialogue")
  assert(visit.walked>1500,"Guide teleported instead of walking")
  assert(story:summary().unlocks["liyena-training-invited"] and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='liyena-training-invited'")==1)
  assert(story:completeAsync("ayan-tour","TrainingRoom") and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='liyena-training-invited'")==1)
  assert(models()==unchanged,"Visit changed adopted learner models")
  D.Content:save(D.Path(root,"Test","fresh-ayan-resume-fixture.txt"),db)
  world():getChildByTag("trainingTerminal"):emit("Tapped",1); wait(function() return world().tag=="VRTraining" end)
  assert(not D.Director.ui3D:getChildByTag("ayan-visit-guidance"),"Escort UI leaked into VR")
  return "PASS actualStart=true physicalAcademyDoors=true remoteMeetingRejected=true remoteJournalRejected=true realYarnThreeNodes=true physicalGuide=true wrongTurnAndCorrection=true rewardRollbackRetry=true rewardOnce=true modelRowsUnchanged=true originalTrainingStillReachable=true noGuideOverlayInVR=true"
 end,debug.traceback)
 local report="LSD_FRESH_AYAN_VISIT_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
