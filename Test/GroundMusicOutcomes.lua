-- Failure must come from actual boss impacts; it must not unlock the rescue story.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ground-music-outcomes-result.txt"); D.Content:save(out,"LSD_GROUND_MUSIC_OUTCOMES_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","ground-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-ground%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ground-music-outcomes-qa-"..id..".db")
  assert(not D.Content:exist(db) and not D.DB:existDB("lsd") and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync(); assert(require("Training.Progress").load()); local model=require("Training.Progress").adopted
  local service=assert(require("Mission.Service").open()); local formation=assert(service:formation())
  local story=assert(require("Story.Service").open()); local stamp=D.DB:query("SELECT completedAt FROM lsd.Game0StoryNodes WHERE id='ground-contact'")[1][1]
  D.DB:exec("DELETE FROM lsd.Game0StoryNodes WHERE id='ground-contact'")
  local blocked,why=service:beginAsync("c0-m02",model,formation); assert(not blocked and why=="STORY_LOCKED")
  D.DB:exec("INSERT INTO lsd.Game0StoryNodes VALUES ('ground-contact',"..stamp..")")
  local function wait(b,status)
   local untilTime=D.App.runningTime+10
   while b.phase~=status do assert(D.App.runningTime<untilTime,"Ground outcome wrong "..b.phase.." "..tostring(b.reason)); D.sleep(0.05) end
  end
  local first=assert(service:beginAsync("c0-m02",model,formation)); local level=require("Ground.Level").openAsync(service,first)
  local button
  D.Director.ui3D.children:each(function(n) if n.children then local b=n:getChildByTag("ground-battle-withdraw"); if b then button=b end end end)
  assert(button):emit("Tapped"); wait(level.battle,"aborted"); assert(not story:canRead("ground-rescue","AbandonedCity"))
  D.sleep(.9);assert(not require('System.Music').inspect().playing,'Ground abort kept music')
  local second=assert(service:beginAsync("c0-m02",model,formation)); local b=require("Ground.Level").openAsync(service,second).battle
  D.sleep(0.3);assert(require("System.Music").inspect().playing and require("System.Music").inspect().path=="Music/战斗1.mp3"); local a=b.arena; a.mode="demo"; a.student:stop(); require("CombatAnimation").rest(a.student); a.studentHP=10
  a.student.position=D.Vec2(a.enemy.x-200,a.student.y); b.mentor.x=a.student.x-200
  assert(a.enemyCombat:start("trample")); local strike=a.enemyStrike
  wait(b,"failed"); assert(strike.attackAt and a.studentHP==0 and not b.rescue,"Failure wasn't actual melee damage")
  D.sleep(.9);assert(not require("System.Music").inspect().playing,"Ground defeat kept music")
  assert(not story:summary().mission.unlocks["wuyun-rescued"])
  local third=assert(service:beginAsync("c0-m02",model,formation)); local c=require("Ground.Level").openAsync(service,third,require("Ground.LifeSupport").new(45,"cargo")).battle; assert(c.supportView.actor.variant=="cargo")
  D.sleep(0.3); a=c.arena; a.mode="demo"; a.student:stop(); require("CombatAnimation").rest(a.student); c.support.machineHP=8
  a.student.x=a.enemy.x+550; c.mentor.x=a.enemy.x-150
  D.sleep(0.1); assert(a.enemyCombat:start("shot")); strike=a.enemyStrike
  wait(c,"failed"); assert(strike.attackAt and (strike.projectileHits or 0)>0 and c.support.machineHP==0 and not c.rescue,"Machine failure wasn't physical bullet damage")
  local poseDeadline=D.App.runningTime+8; while not c.supportView.actor.completed.lose do assert(D.App.runningTime<poseDeadline,"Physical machine lose animation incomplete"); D.sleep(.05) end
  assert(c.supportView.actor.model.speed==0)
  assert(not story:summary().mission.unlocks["wuyun-rescued"] and not story:canRead("ground-rescue","AbandonedCity"))
  assert(require("Training.Progress").load() and require("Training.Progress").adopted.sampleCount==model.sampleCount)
  local rows=D.DB:query("SELECT status FROM lsd.Game0MissionAttempts WHERE mission='c0-m02'")
  assert(#rows==3 and rows[1][1]=="aborted" and rows[2][1]=="failed" and rows[3][1]=="failed")
  return "PASS musicAbortAndDefeat=true storyGate=true publicWithdraw=true physicalMeleeFailure=true noHealingRevive=true physicalBulletMachineFailure=true cargoVisual=true fullMachineLose=true rescueLocked=true noReward=true modelPreserved=true attempts=3"
 end,debug.traceback)
 local report="LSD_GROUND_MUSIC_OUTCOMES_"..(ok and result or "FAIL "..tostring(result)); print(report); D.Content:save(out,report.." runId="..id.."\n")
end)
