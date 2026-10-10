-- Reach the command room through real academy doors, then exercise public UI.
-- Model fixture is copied from real TrainingArena demonstrations, not trained here.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local runId=tostring(os.time()); local out=D.Path(root,"Test","mission-music-ui-result.txt")
D.Content:save(out,"LSD_MISSION_MUSIC_UI_RUNNING runId="..runId.."\n")
local db=D.Path(D.Content.writablePath,"lsd-mission-music-ui-qa-"..runId..".db")
assert(not D.Content:exist(db) and not D.DB:existDB("lsd"))
assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
D.thread(function()
 local ok,result=xpcall(function()
  local config=require("Data.Config"); config:loadAsync(); config.char="charM"; config.charName="MissionQA"; config.tutorialCompleted=1
  local function wait(test,seconds)
   local deadline=D.App.runningTime+(seconds or 6)
   while not test() do assert(D.App.runningTime<deadline,"UI path timed out"); D.sleep(0.05) end
  end
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function move(x)
   local e=assert(player());local deadline=D.App.runningTime+18
   local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud,'Academy HUD missing')
   local side=e.unit.x>x and 'Left' or 'Right';hud.move:emit(side,true)
   while math.abs(e.unit.x-x)>45 do assert(D.App.runningTime<deadline,'Physical academy move failed');D.sleep(.03)end
   hud.move:emit(side,false);D.sleep(.3)
  end
  require("Academy.Level.Arrive")()
  wait(function() return player() and not player().busy and world().data.navigationAttached end,16)
  local function door(route,target)
   local old=world(); move(route=="left" and 120 or route=="right" and old.sceneWidth-120 or old.center.x)
   local e=player(); local index
   assert(e.moveTargets,"No route sensor at "..old.tag.."/"..route.." x="..e.unit.x)
   for i=1,e.moveTargets.count do if e.moveTargets:get(i)==target then index=i; break end end
   assert(index and e.interaction.menu.enabled,"Expected academy route unavailable: "..target)
   e.interaction:emit("Tapped",index)
   wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3)
  end
  door("left","PassageA"); door("center","PassageC"); door("right","OperationRoom")
  local room=world(); assert(not room:getChildByTag("missionTerminal").menu.enabled,"Mission terminal usable from far away")
  move(room.sceneWidth/2); room:getChildByTag("missionTerminal"):emit("Tapped",1)
  wait(function() return room.missionBriefing end)
  local briefing=room.missionBriefing
  briefing.view.startButton:emit("Tapped"); wait(function() return briefing.phase=="briefing" end)
  assert(briefing.view.status.text:find("先进入训练室",1,true),"Untrained user did not receive guidance")
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionAttempts")==0,"Untrained launch created an attempt")
  -- Seed only this isolated QA profile with a model from the real demo fixture.
  local source=assert(D.Content:load(D.Path(root,"Test","training-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-game0%-training%-qa%-%d+%.db$"))
  assert(D.DB:exec("ATTACH DATABASE '"..source:gsub("'","''").."' AS trainingSource")>=0)
  local envelope=D.json.decode(D.DB:query("SELECT payload FROM trainingSource.Game0Training WHERE slot='main'")[1][1],32)
  D.DB:exec("DETACH DATABASE trainingSource"); local model=envelope.adopted; assert(model.sampleCount==7)
  local progress=require("Training.Progress"); assert(progress.load()); assert(progress.saveAsync(model,nil))
  -- Reopening the existing view through its real roster operation refreshes facts.
  briefing.view.rosterButton:emit("Tapped"); wait(function() return briefing.phase=="briefing" end)
  assert(not briefing.formation.learner and not assert(require("Mission.Service").open()):formation().learner,"Excluded member not persisted")
  briefing.view.startButton:emit("Tapped"); wait(function() return briefing.phase=="briefing" end)
  assert(briefing.view.status.text:find("编入队伍",1,true),"Missing formation gate guidance")
  briefing.view.rosterButton:emit("Tapped"); wait(function() return briefing.phase=="briefing" end)
  assert(briefing.formation.learner=="ninilite")
  briefing.view.startButton:emit("Tapped"); wait(function() return briefing.level end,10)
  local level=briefing.level; local hud=assert(D.Director.ui3D:getChildByTag("mission-hud"))
  D.sleep(1);assert(require("System.Music").inspect().playing and require("System.Music").inspect().path=="Music/战斗1.mp3"); hud.move:emit("Right",true); D.sleep(0.15); hud.move:emit("Right",false); D.emit("Skill.Began"); D.emit("Skill.Ended")
  wait(function() return level.phase=="result" end,65)
  D.sleep(.9);assert(not require("System.Music").inspect().playing,"Victory kept music")
  assert(level.battle.phase=="won" and level.battle.mentorHits>=1,"Public HUD battle did not win with mentor support")
  assert(level.result and level.result.againButton and level.result.baseButton,"Settlement UI missing")
  assert(briefing.service:summary().unlocks["library-lead"],"UI victory reward absent")
  -- Again opens the real briefing, then withdraw persists before showing result.
  level.result.againButton:emit("Tapped")
  wait(function() return D.Director.ui3D:getChildByTag("mission-briefing") end)
  local replay=assert(D.Director.ui3D:getChildByTag("mission-briefing").controller)
  replay.view.startButton:emit("Tapped"); wait(function() return replay.level end,10)
  local withdrawal=assert(D.Director.ui3D:getChildByTag("mission-controls")):getChildByTag("mission-withdraw")
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_ui_result BEFORE UPDATE ON Game0MissionAttempts BEGIN SELECT RAISE(ABORT,'QA result fault'); END")>=0)
  withdrawal:emit("Tapped"); wait(function() return replay.level.battle.phase=="save-error" end)
  D.sleep(.9);assert(not require("System.Music").inspect().playing,"Save error kept combat music")
  assert(replay.level.phase=="playing" and not replay.level.result,"Unsaved result shown as complete")
  assert(withdrawal.children.last.text=="重试保存","Save retry button unclear")
  assert(replay.service:summary().last.status=="active","Failed save changed persisted status")
  assert(D.DB:exec("DROP TRIGGER lsd.fail_ui_result")>=0)
  withdrawal:emit("Tapped"); wait(function() return replay.level.phase=="result" end)
  assert(replay.level.battle.phase=="aborted" and replay.service:summary().last.status=="aborted","Withdraw result not saved")
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks")==1,"Withdraw repeated reward")
  replay.level.result.baseButton:emit("Tapped")
  wait(function() return world().tag=="OperationRoom" and player() end)
  assert(world():getChildByTag("missionTerminal"),"Returned command room lost entry")
  D.sleep(.8);assert(require("System.Music").inspect().playing and require("System.Music").inspect().path=="Music/军事学园.mp3")
  return "PASS musicBattleVictorySaveErrorReturn=true route=PreparationRoom>PassageA>PassageC>OperationRoom untrainedGate=true formationGate=true formationSaved=true realModelSamples=7 hudSupport=true victorySettlement=true replay=true withdrawSaved=true saveRetry=true rewardOnce=true returnRoom=true"
 end,debug.traceback)
 local report="LSD_MISSION_MUSIC_UI_"..(ok and result or "FAIL "..tostring(result)).." runId="..runId
 print(report); D.Content:save(out,report.."\n")
end)
