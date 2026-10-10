-- Physical station journey in a copy of a profile earned by tutorial/training/battle/story.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","station-route-result.txt")
local function report(s) D.Content:save(out,"LSD_STATION_ROUTE_"..s.." runId="..id.."\n"); print("LSD_STATION_ROUTE_"..s) end
report("RUNNING")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","journey-story-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-game0%-journey%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-station-route-qa-"..id..".db")
  assert(not D.Content:exist(db) and not D.DB:existDB("lsd")); assert(D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local config=require("Data.Config"); config:loadAsync(); assert(config.charName=="JourneyQA")
  local story=assert(require("Story.Service").open()); local map=require("Academy.Map")
  local _,_,open=map.getRoute("PassageC","left"); assert(open[1]=="Station","Earned archive did not unlock station")
  -- Revoke only the copied QA facts to test independent room and story gates.
  local timestamp=D.DB:query("SELECT completedAt FROM lsd.Game0StoryNodes WHERE id='archive-discovery'")[1][1]
  assert(D.DB:exec("DELETE FROM lsd.Game0StoryNodes WHERE id='archive-discovery'")>=0)
  assert(D.DB:exec("DELETE FROM lsd.Game0StoryUnlocks WHERE id='archive-discovered'")>=0)
  local _,_,locked=map.getRoute("PassageC","left"); assert(#locked==0 and not story:canRead("station-brief","Station"),"Station bypassed archive gate")
  assert(D.DB:exec("INSERT INTO lsd.Game0StoryNodes VALUES ('archive-discovery',"..timestamp..")")>=0)
  assert(D.DB:exec("INSERT INTO lsd.Game0StoryUnlocks VALUES ('archive-discovered','archive-discovery')")>=0)
  assert(not story:canRead("station-brief","OperationRoom"),"Station dialogue bypassed room gate")
  D.Cache:loadAsync("spine:charF"); D.Cache:loadAsync("spine:ninilite")
  require("Academy.Navigation").returnToOperationAsync()
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(test,seconds)
   local untilTime=D.App.runningTime+(seconds or 8)
   while not test() do assert(D.App.runningTime<untilTime,"Station route timeout"); D.sleep(0.05) end
  end
  local function move(x)
   local e=assert(player()); local untilTime=D.App.runningTime+20
   while math.abs(e.unit.x-x)>40 do assert(D.App.runningTime<untilTime,"Station physical move failed"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.05) end
   e.keyLeft=false; e.keyRight=false; D.sleep(0.3)
  end
  local function door(side,target)
   local old=world(); move(side=="left" and 120 or old.sceneWidth-100)
   local e=assert(player()); local index
   assert(e.moveTargets,"Missing station/academy passage sensor")
   for i=1,e.moveTargets.count do if e.moveTargets:get(i)==target then index=i end end
   assert(index and e.interaction.menu.enabled,"Station passage target missing")
   e.interaction:emit("Tapped",index); wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3)
  end
  wait(function() return player() end)
  door("left","PassageC"); door("left","Station")
  local w=world(); local terminal=assert(w:getChildByTag("storyTerminal"))
  assert(not terminal.menu.enabled,"Station dialogue available remotely")
  wait(function() return D.Group({"name","unit"}):find(function(e) return e.name=="ninilite" and e.unit.world==w and e.storyCompanion end) end)
  move(w.sceneWidth-650); terminal:emit("Tapped",1); wait(function() return w.storyFlow and w.storyFlow.view.visible end)
  local flow=w.storyFlow; local untilTime=D.App.runningTime+20
  while flow.phase=="dialogue" or flow.phase=="saving" do
   assert(D.App.runningTime<untilTime,"Station Yarn completion failed")
   if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit("Tapped") end; D.sleep(0.1)
  end
  assert(flow.phase=="complete" and not player().busy and story:summary().unlocks["station-briefed"],"Station completion not saved/restored")
  local count=#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks")
  assert(story:completeAsync("station-brief","Station") and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks")==count,"Station reward repeated")
  door("right","PassageC"); assert(world().data.navigationAttached and player(),"Station return lost academy input")
  local journal=assert(require("Story.Journal").openAsync(world()))
  assert(journal.view.stationButton and journal.view.detail.text:find("站台记录",1,true),"Station missing from public journal")
  journal.view.stationButton:emit("Tapped")
  wait(function() return world().storyFlow and world().storyFlow.id=="station-brief" end)
  local replay=world().storyFlow; untilTime=D.App.runningTime+20
  while replay.phase=="dialogue" or replay.phase=="saving" do
   assert(D.App.runningTime<untilTime,"Recorded station replay failed")
   if replay.view.visible and not replay.view._advancing then replay.view.confirm:emit("Tapped") end; D.sleep(0.1)
  end
  assert(replay.phase=="complete" and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks")==count,"Remote replay duplicated station reward")
  wait(function() return D.Director.ui3D:getChildByTag("story-journal") end)
  D.Director.ui3D:getChildByTag("story-journal").controller.view.closeButton:emit("Tapped")
  assert(not player().busy,"Station journal failed to restore input")
  D.Content:save(D.Path(root,"Test","station-resume-fixture.txt"),db)
  return "PASS earnedArchiveSource=true copiedQaOnly=true archiveGate=true roomGate=true physicalRoute=OperationRoom>PassageC>Station>PassageC companionPresent=true authoredAdaptationYarn=true persisted=true rewardOnce=true publicJournalRecord=true recordedRemoteReplay=true restoredInput=true"
 end,debug.traceback)
 report(ok and result or "FAIL "..tostring(result))
end)
