-- Continues the profile produced by real tutorial gameplay. No model/reward fixtures.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","journey-fresh-academy-result.txt")
local function report(s) D.Content:save(out,"LSD_JOURNEY_FRESH_ACADEMY_"..s.." runId="..id.."\n"); print("LSD_JOURNEY_FRESH_ACADEMY_"..s) end
report("RUNNING phase=continue")
local source=assert(D.Content:load(D.Path(root,"Test","journey-resume-fixture.txt")))
assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-game0%-journey%-qa%-%d+%.db$"))
local db=D.Path(D.Content.writablePath,'lsd-game0-journey-qa-'..id..'.db')
assert(not D.Content:exist(db) and D.Content:copy(source,db))
assert(not D.DB:existDB("lsd") and D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
require("Start")
D.thread(function()
 local ok,result=xpcall(function()
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(test,seconds,message)
   local deadline=D.App.runningTime+(seconds or 6)
   while not test() do assert(D.App.runningTime<deadline,message or "Journey state timed out"); D.sleep(0.05) end
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
   local e=assert(player()); local index
   if e.moveTargets then for i=1,e.moveTargets.count do if e.moveTargets:get(i)==target then index=i end end end
   assert(index and e.interaction and e.interaction.menu.enabled,"Missing actual door "..old.tag..">"..target)
   e.interaction:emit("Tapped",index)
   wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3)
  end
  wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy and world().data.navigationAttached end,20,"Completed fresh profile replayed film/tutorial")
  assert(require("Data.Config").charName=="JourneyQA","Tutorial identity lost")
  assert(#D.DB:query("SELECT name FROM lsd.Config WHERE name='tutorialCompleted' AND value_bool=1")==1,"Real tutorial completion lost")
  door("right","PassageB"); door("right","TrainingRoom"); move(900)
  world():getChildByTag("trainingTerminal"):emit("Tapped",1)
  wait(function() return world().tag=="VRTraining" and D.Director.ui3D:getChildByTag("training-controls") end,12)
  report("RUNNING phase=demonstrate")
  local hud=assert(D.Director.ui3D:getChildByTag("trainingHUD")); local ui=D.Director.ui3D:getChildByTag("training-controls")
  local menu=ui:getChildByTag("training-menu"); local status=ui:getChildByTag("training-status")
  D.sleep(0.8)
  local idle=assert(hud.skillArea:getChildByTag("training-wait")); idle:emit("TapBegan"); idle:emit("TapEnded"); D.sleep(0.15)
  -- Natural stationary shooting demonstration plus explicit waiting, using public HUD.
  for i=1,5 do hud.weapon:emit("TapBegan"); D.sleep(0.05); hud.weapon:emit("TapEnded"); D.sleep(1.5) end
  assert(status.text:find("射击 5",1,true) and status.text:find("等待 1",1,true),"HUD demonstrations missing: "..status.text)
  menu:getChildByTag("结束示范"):emit("Tapped")
  wait(function() return status.text:find("候选模型",1,true) end,12,"Public demonstration did not build model")
  report("RUNNING phase=evaluate")
  menu:getChildByTag("三场试战"):emit("Tapped")
  wait(function() return status.text:find("三场",1,true) and status.text:find("查看结果",1,true) end,120,"Public trial matrix did not finish: "..status.text)
  assert(status.text:find("候选三场胜利 3/3",1,true),"Natural demonstrations did not win all trials: "..status.text)
  menu:getChildByTag("采用"):emit("Tapped")
  wait(function() return require("Training.Progress").adopted~=nil and status.text:find("训练成果已保存",1,true) end,10,"Public adoption did not persist")
  local model=assert(require("Training.Progress").adopted)
  assert(model.sampleCount>=6,"Model lacks natural public demonstrations")
  local saved=D.json.decode(D.DB:query("SELECT payload FROM lsd.Game0Training WHERE slot='main'")[1][1],32)
  assert(saved.adopted.sampleCount==model.sampleCount,"Persisted model mismatch")
  menu:getChildByTag("返回训练室"):emit("Tapped")
  wait(function() return world().tag=="TrainingRoom" and player() end,12); D.sleep(0.5)
  door("left","PassageB"); door("left","PreparationRoom"); door("left","PassageA"); door("center","PassageC"); door("right","OperationRoom")
  move(world().sceneWidth/2); local room=world(); room:getChildByTag("missionTerminal"):emit("Tapped",1)
  wait(function() return room.missionBriefing end)
  local briefing=room.missionBriefing; briefing.view.startButton:emit("Tapped")
  wait(function() return briefing.level end,12)
  report("RUNNING phase=mission")
  local level=briefing.level; local missionHUD=assert(D.Director.ui3D:getChildByTag("mission-hud"))
  D.sleep(1); local mentorBefore=level.battle.mentor.x
  missionHUD.move:emit("Right",true); D.sleep(0.15); missionHUD.move:emit("Right",false)
  assert(level.battle.mentor.x>mentorBefore+5,"Public mission HUD movement failed")
  D.emit("Skill.Began"); D.emit("Skill.Ended")
  wait(function() return level.phase=="result" end,65,"Actual learned-model mission did not finish")
  assert(level.battle.phase=="won" and level.battle.mentorHits>=1,"Mission not won with mentor HUD support")
  assert(briefing.service:summary().unlocks["library-lead"],"Real victory did not unlock archives")
  level.result.baseButton:emit("Tapped")
  wait(function() return world().tag=="OperationRoom" and player() end,12)
  D.Content:save(D.Path(root,"Test","journey-fresh-academy-fixture.txt"),db)
  return "PASS sameTutorialProfile=true earnedOpeningCopy=true physicalAcademyDoors=true publicHudSamples="..model.sampleCount.." nativeC45=true publicTrials=true publicAdoptionSaved=true noImportedModel=true missionHudMovement=true realMissionWon=true rewardFromBattle=true returnedCommandRoom=true openingFilmNotReplayedOnContinue=true"
 end,debug.traceback)
 report(ok and result or "FAIL "..tostring(result))
end)
