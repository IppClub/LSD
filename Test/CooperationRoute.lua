-- Chapter 2 entry from a truly earned chapter-1 QA copy, original doors and UI.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","cooperation-route-result.txt"); D.Content:save(out,"LSD_COOPERATION_ROUTE_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","ground-battle-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-ground%-battle%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-cooperation-route-qa-"..id..".db")
  assert(not D.Content:exist(db) and not D.DB:existDB("lsd") and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync(); assert(require("Training.Progress").load())
  local model=D.json.encode(require("Training.Progress").adopted,false,true)
  local story=assert(require("Story.Service").open()); assert(story:summary().unlocks["chapter-one-complete"])
  local Nav=require("Academy.Navigation"); Nav.returnToRoomAsync("PreparationRoom")
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t)
   local deadline=D.App.runningTime+(t or 15)
   while not f() do assert(D.App.runningTime<deadline,"Cooperation wait timed out"); D.sleep(0.05) end
  end
  local function move(x)
   local e=assert(player()); local deadline=D.App.runningTime+25
   while math.abs(e.unit.x-x)>30 do assert(D.App.runningTime<deadline,"Cooperation physical walk stalled"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.05) end
   e.keyLeft=false; e.keyRight=false; D.sleep(0.4)
  end
  local function door(side,target)
   move(world()[side].x); wait(function() return player().interaction and player().interaction.visible end)
   player().interaction:emit("Tapped",1); wait(function() return world().tag==target and player() and not player().busy end)
  end
  local function finish(flow)
   wait(function() return flow.view.visible end)
   local deadline=D.App.runningTime+40
   while flow.phase=="dialogue" or flow.phase=="saving" do assert(D.App.runningTime<deadline,"Cooperation Yarn stalled"); if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit("Tapped") end; D.sleep(0.1) end
  end
  assert(not require("Ground.NightLens").openAsync(world()),"Night lens unlocked before cooperation")
  wait(function() return player() and not player().busy end)
  door("left","PassageA"); door("left","RestRoom"); move(world().sceneWidth/2)
  wait(function() return D.Group({"name","unit"}):find(function(e) return e.name=="sunborn" and e.unit.world==world() end) end)
  assert(not story:canRead("energy-plan","RestRoom"),"Plan skipped cooperation")
  local terminal=world():getChildByTag("storyTerminal")
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_cooperation BEFORE INSERT ON Game0StoryUnlocks BEGIN SELECT RAISE(ABORT,'QA cooperation fault'); END")>=0)
  terminal:emit("Tapped",2); wait(function() return world().storyFlow and world().storyFlow.id=="underground-cooperation" end)
  local flow=world().storyFlow; finish(flow); assert(flow.phase=="save-error" and player().busy)
  assert(not story:summary().unlocks["night-lens"] and not story:summary().completed["underground-cooperation"])
  D.DB:exec("DROP TRIGGER lsd.fail_cooperation"); flow.retryButton:emit("Tapped"); wait(function() return flow.phase=="complete" and not player().busy end)
  assert(story:summary().unlocks["night-lens"])
  wait(function() return not D.Group({"name","unit"}):find(function(e) return e.name=="sunborn" and e.unit.world==world() end) end)
  terminal:emit("Tapped",3); wait(function() return world().storyFlow~=flow and world().storyFlow.id=="energy-plan" end); finish(world().storyFlow)
  assert(story:summary().unlocks["energy-survey-briefed"] and not player().busy)
  local journal=assert(require("Story.Journal").openAsync(world(),3)); assert(#journal.recordIds==4 and journal.recordIds[3]=="underground-cooperation" and journal.recordIds[4]=="energy-plan")
  journal.view.archiveButton:emit("Tapped"); wait(function() return world().storyFlow.id=="underground-cooperation" and world().storyFlow~=flow end); finish(world().storyFlow)
  wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryNodes")==12 and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='night-lens'")==1)
  wait(function() return D.Director.ui3D:getChildByTag("night-lens-button").visible end)
  D.Director.ui3D:getChildByTag("night-lens-button"):emit("Tapped"); wait(function() return world().nightLens and world().nightLens.phase=="map" end)
  local lens=world().nightLens; assert(not require("Ground.NightLens").openAsync(world()),"Duplicate map allowed")
  for i,button in ipairs({lens.view.mailButton,lens.view.researchButton,lens.view.archiveButton,lens.view.stationButton}) do button:emit("Tapped"); assert(lens.selected.id==require("Ground.NightLens").locations[i].id) end
  lens.view.stationButton:emit("Tapped"); assert(lens.selected.id=="energy" and not lens.playerX and player().busy)
  lens.view.closeButton:emit("Tapped"); assert(not player().busy and not world().data.journalOpen)
  Nav.returnToRoomAsync("AbandonedCity"); wait(player); move(1700)
  local gold=world().groundExpedition.support.gold; local x=player().unit.x
  D.Director.ui3D:getChildByTag("night-lens-button"):emit("Tapped"); wait(function() return world().nightLens and world().nightLens.phase=="map" end)
  gold=world().groundExpedition.support.gold
  lens=world().nightLens; lens.view.stationButton:emit("Tapped"); assert(math.abs(lens.playerX-x)<5 and lens.selected.x==5760)
  D.sleep(0.5); assert(world().groundExpedition.support.gold==gold,"Map consumed life resources")
  lens.view.closeButton:emit("Tapped"); move(1900)
  assert(player().unit.x>x+150 and world().nightLensTarget.id=="energy","Map target moved player or disappeared")
  assert(require("Training.Progress").load() and D.json.encode(require("Training.Progress").adopted,false,true)==model,"Cooperation overwrote model")
  assert(not story:summary().completed["energy-recovered"],"Unimplemented mission awarded success")
  D.Content:save(D.Path(root,"Test","cooperation-resume-fixture.txt"),db)
  return "PASS earnedChapterCopy=true physicalAcademyRestRoute=true actualSunborn=true originalPortraitYarn=true planGate=true saveRollback=true retry=true onceEquipment=true wuyunPlan=true journalReplay=true originalPhoneMap=true realCityPosition=true waypointOnly=true lifePaused=true adoptedModelUnchanged=true records=12"
 end,debug.traceback)
 local report="LSD_COOPERATION_ROUTE_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
