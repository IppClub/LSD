-- Explicit outcome fixtures: prepared abort and actual low-life defeat, no fake win.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","factory-music-outcomes-result.txt"); D.Content:save(out,"LSD_FACTORY_MUSIC_OUTCOMES_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","factory-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-factory%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-factory-music-outcomes-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local service=assert(require("Mission.Service").open()); local progress=require("Training.Progress"); local wp=progress.forCharacter("wuyun")
  local models={ninilite=progress.load() and progress.adopted,wuyun=wp.load() and wp.adopted}; local formation=assert(service:formation())
  local function wait(f,t) local deadline=D.App.runningTime+(t or 10); while not f() do assert(D.App.runningTime<deadline,"Factory outcomes wait"); D.sleep(0.05) end end
  local prior=#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='factory-site-secured'")
  local function open() local attempt=assert(service:beginAsync("c0-m05",models,formation)); return require("Factory.Level").openAsync(service,attempt) end
  local music=require('System.Music')
  local c=open(); local b=c.battle; local hp=require("Factory.Health").load()
  D.sleep(2); assert(b.phase=="ready" and not b.started and b.mentorHP==hp[1] and b.arena.studentHP==hp[2] and b.wuyun.studentHP==hp[3])
  assert(music.inspect().playing and music.inspect().path=='Music/战斗准备.mp3')
  local camera=b.arena.world.camera; local half=D.View.size.width/(2*camera.zoom)
  for _,unit in ipairs({b.mentor,b.arena.student,b.wuyun.student,b.roots[1].enemy,b.roots[2].enemy,b.roots[3].enemy}) do assert(math.abs(unit.x-camera.position.x)+130<half,"Factory ready camera clipped actor") end
  c.withdraw:emit("Tapped"); wait(function() return b.phase=="aborted" and c.result end)
  D.sleep(.9);assert(not music.inspect().playing,'Prepared abort kept music')
  assert(b.report.seconds==0 and b.report.mentorHits==0 and b.report.learners.ninilite.hits==0 and b.report.learners.wuyun.hits==0)
  assert(D.DB:query("SELECT status FROM lsd.Game0MissionAttempts WHERE id=?",{b.attempt.id})[1][1]=="aborted")
  c=open(); b=c.battle; b.arena.studentHP=1; c.start:emit("Tapped"); D.sleep(.1);assert(music.inspect().playing and music.inspect().path=="Music/战斗1.mp3"); wait(function() return b.phase=="failed" and c.result end)
  D.sleep(.9);assert(not music.inspect().playing,'Defeat kept battle music')
  assert(b.arena.studentHP==0 and b.injury and b.report.confusions>0,"Low-life fixture was not defeated by real vines")
  assert(b.arena.student.playable.current=="lose" or b.arena.student.data.combatCompletedName=="lose","Defeated learner did not play authored defeat")
  assert(D.DB:query("SELECT status FROM lsd.Game0MissionAttempts WHERE id=?",{b.attempt.id})[1][1]=="failed")
  -- Isolate the mentor's optional equipment adapter with an explicit virus fixture.
  c=open(); b=c.battle; c.start:emit("Tapped")
  local target
  for _,record in ipairs(b.targets()) do if record.unit==b.mentor then target=record end end
  assert(b.effects:apply(target,"virus",4,{kind="QA-virus-adapter"}))
  local before=b.wuyun.studentHP
  assert(b:command("shoot")); wait(function() return (b.friendlyHits or 0)>0 end,3)
  assert(b.wuyun.studentHP==before-15,"Mentor virus did not redirect real projectile damage")
  c.withdraw:emit("Tapped"); wait(function() return b.phase=="aborted" and c.result end)
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='factory-site-secured'")==prior and #D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0)
  return "PASS musicReadyBattleDefeatAbort=true earnedWinCopy=true injuryHPPreserved=true sixActorsReadyFramed=true readyNoAI=true publicAbortZeroSeconds=true lowLifeFixture=true realVineDefeat=true authoredDefeatPose=true mentorVirusStatusFixture=true mentorRealFriendlyProjectile=true failureAndAbortCommitted=true noNewRewards=true noActiveResidue=true"
 end,debug.traceback)
 local report="LSD_FACTORY_MUSIC_OUTCOMES_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
