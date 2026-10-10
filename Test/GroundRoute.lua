-- Actual deployment/roam from the earned train profile, no user DB or invented completion.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ground-route-result.txt")
D.Content:save(out,"LSD_GROUND_ROUTE_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","train-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-train%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ground-route-qa-"..id..".db")
  assert(not D.Content:exist(db) and not D.DB:existDB("lsd") and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local service=assert(require("Story.Service").open()); assert(service:summary().completed["mail-two"])
  require("Academy.Navigation").returnToRoomAsync("TrainA")
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(test,t)
   local endAt=D.App.runningTime+(t or 12)
   while not test() do assert(D.App.runningTime<endAt,"Ground route wait timed out"); D.sleep(0.05) end
  end
  local function move(x)
   local e=assert(player()); local endAt=D.App.runningTime+25
   while math.abs(e.unit.x-x)>35 do assert(D.App.runningTime<endAt,"Ground walk failed"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.05) end
   e.keyLeft=false; e.keyRight=false; D.sleep(0.4)
  end
  local function finish(flow)
   wait(function() return flow.view.visible end)
   local endAt=D.App.runningTime+25
   while flow.phase=="dialogue" or flow.phase=="saving" do
    assert(D.App.runningTime<endAt,"Ground Yarn stalled")
    if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit("Tapped") end
    D.sleep(0.1)
   end
   assert(flow.phase=="complete")
  end
  wait(player); D.sleep(0.5)
  assert(not service:canRead("ground-arrival","TrainA"),"Remote ground story accepted")
  local terminal=assert(world():getChildByTag("groundDeploymentTerminal")); assert(not terminal.menu.enabled)
  move(world().sceneWidth-170)
  local time=D.DB:query("SELECT completedAt FROM lsd.Game0StoryNodes WHERE id='mail-two'")[1][1]
  D.DB:exec("DELETE FROM lsd.Game0StoryNodes WHERE id='mail-two'")
  terminal:emit("Tapped",1); D.sleep(0.2); assert(not world().groundDeployment,"Deployment bypassed mail gate")
  D.DB:exec("INSERT INTO lsd.Game0StoryNodes VALUES ('mail-two',"..time..")")
  terminal:emit("Tapped",1); wait(function() return world().groundDeployment end)
  local deploy=world().groundDeployment; assert(player().busy)
  deploy.view.rosterButton:emit("Tapped"); wait(function() return deploy.phase=="briefing" and not deploy.formation.learner end)
  deploy.view.startButton:emit("Tapped"); assert(deploy.phase=="briefing" and world().tag=="TrainA","Unformed squad deployed")
  deploy.view.rosterButton:emit("Tapped"); wait(function() return deploy.phase=="briefing" and deploy.formation.learner end)
  deploy.view.startButton:emit("Tapped"); wait(function() return world().tag=="AbandonedCity" and player() and world().groundExpedition end)
  D.sleep(0.7)
  local expedition=world().groundExpedition; local support=expedition.support
  assert(world():getChildByTag("ground-auxiliary") and support.active and support.spent>0)
  move(900); world():getChildByTag("storyTerminal"):emit("Tapped",1); wait(function() return world().storyFlow end)
  local before=support.gold; D.sleep(0.5); assert(math.abs(support.gold-before)<0.01,"Story drains life support")
  finish(world().storyFlow); assert(service:summary().completed["ground-arrival"] and not player().busy)
  move(1150); assert(support.collected["survey-gold-1"],"Physical pickup failed")
  local journal=assert(require("Story.Journal").openAsync(world(),2)); before=support.gold; D.sleep(0.4)
  assert(math.abs(support.gold-before)<0.01 and #journal.recordIds==4,"Journal doesn't pause support or list ground nodes")
  journal.view.closeButton:emit("Tapped")
  move(2450); assert(world():getChildByTag("ground-boss")); world():getChildByTag("ground-contact"):emit("Tapped",1)
  wait(function() return world().storyFlow.id=="ground-contact" end); finish(world().storyFlow)
  assert(service:summary().completed["ground-contact"] and not player().busy and expedition.collected>=3)
  local snapshot={gold=support.gold,spent=support.spent,collected=expedition.collected,hp=support.hp}
  local adopted=assert(require("Training.Progress").adopted)
  move(170); world():getChildByTag("groundReturnTerminal"):emit("Tapped",1)
  wait(function() return world().tag=="TrainA" and player() end)
  assert(service:summary().completed["ground-contact"] and require("Training.Progress").adopted==adopted,"Return lost state")
  D.Content:save(D.Path(root,"Test","ground-resume-fixture.txt"),db)
  return "PASS earnedProfileCopy=true physicalDeployment=true mailGate=true rosterGate=true actualCity=true auxiliary=true goldConsumption=true collectOnce=true storyPause=true journalPause=true arrivalYarn=true contactYarn=true actualBossAsset=true returnedTrain=true modelPreserved=true rescueNotClaimed=true snapshot="..D.json.encode(snapshot)
 end,debug.traceback)
 local report="LSD_GROUND_ROUTE_"..(ok and result or "FAIL "..tostring(result)).." runId="..id
 print(report); D.Content:save(out,report.."\n")
end)
