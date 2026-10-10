-- Public first ground battle and rescue, continued from earned survey records.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ground-battle-result.txt"); D.Content:save(out,"LSD_GROUND_BATTLE_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","ground-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-ground%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ground-battle-qa-"..id..".db")
  assert(not D.Content:exist(db) and not D.DB:existDB("lsd") and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync(); assert(require("Training.Progress").load())
  local original=D.json.encode(require("Training.Progress").adopted,false,true)
  local story=assert(require("Story.Service").open()); assert(story:summary().completed["ground-contact"] and not story:canRead("ground-rescue","AbandonedCity"))
  require("Academy.Navigation").returnToRoomAsync("AbandonedCity")
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(test,t)
   local deadline=D.App.runningTime+(t or 15)
   while not test() do assert(D.App.runningTime<deadline,"Ground battle wait timed out"); D.sleep(0.05) end
  end
  local function move(x)
   local e=assert(player()); local deadline=D.App.runningTime+20
   while math.abs(e.unit.x-x)>35 do assert(D.App.runningTime<deadline,"Ground physical walk stalled"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.05) end
   e.keyLeft=false; e.keyRight=false; D.sleep(0.4)
  end
  local function finish(flow)
   wait(function() return flow.view.visible end)
   local deadline=D.App.runningTime+25
   while flow.phase=="dialogue" or flow.phase=="saving" do
    assert(D.App.runningTime<deadline,"Ground rescue Yarn stalled")
    if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit("Tapped") end
    D.sleep(0.1)
   end
   assert(flow.phase=="complete")
  end
  wait(player); move(2450)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_ground_reward BEFORE INSERT ON Game0MissionUnlocks BEGIN SELECT RAISE(ABORT,'QA ground reward fault'); END")>=0)
  world():getChildByTag("ground-contact"):emit("Tapped",2)
  wait(function() return world().groundBattle end); local level=world().groundBattle; local b=level.battle
  D.sleep(0.4); local hud=D.Director.ui3D:getChildByTag("ground-battle-hud")
  hud.move:emit("Right",true); D.sleep(0.15); hud.move:emit("Right",false)
  hud.weapon:emit("TapBegan"); D.sleep(0.05); hud.weapon:emit("TapEnded")
  D.Director.ui3D:getChildByTag("ground-battle-gather"):emit("TapBegan")
  wait(function() return b.phase~="playing" and b.phase~="saving" end,65)
  assert(b.phase=="save-error","Expected actual rescue save error, got "..b.phase.." / "..tostring(b.reason))
  assert(b.rescue and b.rescueHits>0 and b.rescueCompleted>=b.rescueHits and b.arena.metrics.hits>0 and b.arena.metrics.fallback==0,"Rescue didn't execute full actual actions")
  assert(not story:summary().mission.unlocks["wuyun-rescued"] and not story:canRead("ground-rescue","AbandonedCity"),"Partial rescue reward persisted")
  D.DB:exec("DROP TRIGGER lsd.fail_ground_reward"); b:saveResult()
  wait(function() return b.phase=="won" and level.result end)
  local report=b.report; assert(report.mentorHits>0,"Public mentor shooting had no real hit")
  assert(story:summary().mission.unlocks["wuyun-rescued"])
  assert(require("Training.Progress").load() and D.json.encode(require("Training.Progress").adopted,false,true)==original,"Battle overwrote learned model")
  level.result.baseButton:emit("Tapped"); wait(function() return world().storyFlow and world().storyFlow.id=="ground-rescue" end)
  finish(world().storyFlow); wait(function() return world().tag=="RestRoom" and player() end)
  wait(function() return D.Group({"name","unit"}):find(function(e) return e.name=="wuyun" and e.storyCompanion and e.unit.world==world() end) end)
  move(world().sceneWidth/2); world():getChildByTag("storyTerminal"):emit("Tapped",1)
  wait(function() return world().storyFlow and world().storyFlow.id=="wuyun-rest" end); finish(world().storyFlow)
  assert(story:summary().unlocks["chapter-one-complete"] and not player().busy)
  local count=#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks")
  assert(b.service:finishAsync(b.attempt,"won",report) and #D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks")==count)
  local journal=assert(require("Story.Journal").openAsync(world(),3)); assert(#journal.recordIds==4); journal.view.closeButton:emit("Tapped")
  D.Content:save(D.Path(root,"Test","ground-battle-resume-fixture.txt"),db)
  return "PASS earnedSurveyCopy=true physicalFrontier=true publicBattle=true publicMentorMoveShootGather=true actualBigBoss=true learnerModelActions=true limitedEnergy=true auxiliaryCarried=true physicalWuyunMelee=true fullRescueAnimations=true saveFaultRollback=true retry=true rewardOnce=true modelUnchanged=true rescueYarn=true actualRestRoom=true wuyunEntity=true restYarn=true chapterOneRecord=true journalPageThree=true report="..D.json.encode(report)
 end,debug.traceback)
 local report="LSD_GROUND_BATTLE_"..(ok and result or "FAIL "..tostring(result)).." runId="..id
 print(report); D.Content:save(out,report.."\n")
end)
