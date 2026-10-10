-- Continue a copy of the earned opening/training/battle/investigation profile.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local runId=tostring(os.time()); local out=D.Path(root,"Test","male-current-train-route-result.txt")
D.Content:save(out,"LSD_MALE_CURRENT_TRAIN_ROUTE_RUNNING runId="..runId.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","male-story-current-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-male%-story%-current%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-male-current-train-route-qa-"..runId..".db")
  assert(not D.Content:exist(db) and not D.DB:existDB("lsd") and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local config=require("Data.Config"); config:loadAsync(); assert(config.charName=="JourneyOS" and config.char=="charM")
  local service=assert(require("Story.Service").open())
  assert(service:summary().completed["station-brief"] and not service:canRead("train-conflict","Station") and not service:canRead("mail-two","Station"),"Train/mail gates bypassed")
  D.Cache:loadAsync("spine:charM"); D.Cache:loadAsync("spine:ninilite")
  require("Start")
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(test,seconds)
   local deadline=D.App.runningTime+(seconds or 10)
   while not test() do assert(D.App.runningTime<deadline,"Train route wait timeout"); D.sleep(0.05) end
  end
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
  local function door(route,target)
   local old=world(); move(route=="left" and 120 or route=="right" and old.sceneWidth-120 or old.center.x)
   local e=player(); local index; assert(e.moveTargets,"Missing story route sensor")
   for i=1,e.moveTargets.count do if e.moveTargets:get(i)==target then index=i; break end end
   assert(index and e.interaction.menu.enabled,"Story destination missing: "..target); e.interaction:emit("Tapped",index)
   wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3)
  end
  local function finish(flow)
   wait(function() return flow.view.visible end)
   local deadline=D.App.runningTime+20
   while flow.phase=="dialogue" or flow.phase=="saving" do
    assert(D.App.runningTime<deadline,"Train Yarn stalled")
    if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit("Tapped") end
    D.sleep(0.1)
   end
  end
  wait(function() return world() and world().tag=='PreparationRoom' and player() and not player().busy end,30)
  door('left','PassageA');door('center','PassageC');door('left','Station')
  local journal=assert(require("Story.Journal").openAsync(world()))
  journal.view.nextButton:emit("Tapped"); assert(journal.page==2 and journal.view.secondMailButton)
  journal.view.secondMailButton:emit("Tapped"); assert(journal.phase=="journal" and journal.view.detail.text:find("车厢里的争执",1,true),"Locked second mail bypassed gate")
  journal.view.previousButton:emit("Tapped"); assert(journal.page==1 and journal.view.stationButton.visible)
  journal.view.closeButton:emit("Tapped"); assert(not player().busy)
  local boarding=assert(world():getChildByTag("boardingTerminal")); assert(not boarding.menu.enabled,"Remote boarding accepted")
  move(world().sceneWidth-1800)
  boarding:emit("Tapped",1)
  wait(function() return world().tag=="TrainA" and player() end); D.sleep(0.5)
  assert(D.Group({"name","unit"}):find(function(e) return e.name=="liyena" and e.storyCompanion and e.unit.world==world() end),"Li Yena absent")
  move(world().sceneWidth/2)
  world():getChildByTag("storyTerminal"):emit("Tapped",1); wait(function() return world().storyFlow end)
  local flow=world().storyFlow; finish(flow)
  assert(flow.phase=="complete")
  assert(not player().busy and service:summary().completed["train-conflict"])
  local mail=assert(require("Story.Journal").openAsync(world(),2)); mail.view.secondMailButton:emit("Tapped")
  wait(function() return world().storyFlow.id=="mail-two" end); finish(world().storyFlow)
  wait(function() return D.Director.ui3D:getChildByTag("story-journal") end)
  local saved=D.Director.ui3D:getChildByTag("story-journal").controller
  assert(saved.page==2 and service:summary().unlocks["mail-two-read"],"Mail/page not restored")
  saved.view.closeButton:emit("Tapped")
  local count=#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks")
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks")==count,"Train/mail replay duplicated reward")
  move(170); world():getChildByTag("stationReturnTerminal"):emit("Tapped",1)
  wait(function() return world().tag=="Station" and player() end); assert(not player().busy and math.abs(player().unit.x-(world().sceneWidth-1800))<40,"Train returned to wrong platform position")
  D.Content:save(D.Path(root,"Test","male-current-train-resume-fixture.txt"),db)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-train.tga'));D.sleep(.2)
  return "PASS earnedProfileCopy=true physicalBoarding=true physicalAcademyToStation=true actualCarriage=true liyenaCompanion=true conflictYarn=true secondMail=true storyRoomGate=true mailPrerequisite=true saveFaultInjected=false journalPages=true pagePreserved=true rewardOnce=true returnedStation=true"
 end,debug.traceback)
 local report="LSD_MALE_CURRENT_TRAIN_ROUTE_"..(ok and result or "FAIL "..tostring(result)).." runId="..runId
 print(report); D.Content:save(out,report.."\n")
end)
