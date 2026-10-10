-- Real lethal attack / machine bomb / public withdrawal, no user database.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","energy-outcomes-result.txt"); D.Content:save(out,"LSD_ENERGY_OUTCOMES_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","wuyun-training-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-wuyun%-training%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-energy-outcomes-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local Progress=require("Training.Progress"); local wp=Progress.forCharacter("wuyun"); assert(Progress.load() and wp.load())
  local models={ninilite=Progress.adopted,wuyun=wp.adopted}; local before=D.json.encode(models,false,true)
  local service=assert(require("Mission.Service").open()); local formation={mentor=true,learner="ninilite",wuyun=true}
  assert(not service:beginAsync("c0-m03",models,{mentor=true,learner="ninilite"}))
  local wrong,err=service:beginAsync("c0-m03",{ninilite=models.ninilite,wuyun=models.ninilite},formation); assert(not wrong and err=="TRAINING_REQUIRED_wuyun")
  assert(service:saveFormationAsync(formation) and service:formation().wuyun)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_second_roster BEFORE INSERT ON Game0MissionSecondLearner BEGIN SELECT RAISE(ABORT,'QA roster fault'); END")>=0)
  assert(not service:saveFormationAsync({mentor=true})); assert(service:formation().learner and service:formation().wuyun)
  D.DB:exec("DROP TRIGGER lsd.fail_second_roster")
  local function wait(f) local deadline=D.App.runningTime+15; while not f() do assert(D.App.runningTime<deadline,"Energy outcome timed out"); D.sleep(0.05) end end
  local function start(variant) return require("Ground.EnergyLevel").openAsync(service,assert(service:beginAsync("c0-m03",models,formation)),variant and require("Ground.LifeSupport").new(45,variant) or nil) end
  local c=start(); local b=c.battle
  b.mentorHP=1; b.mentor.position=D.Vec2(b.central.enemy.x-120,b.arena.world.offset+155)
  b.central.studentHP=1; assert(b.central.enemyCombat:start("blow")); local strike=b.central.enemyStrike
  wait(function() return b.phase=="failed" and c.result end)
  assert(strike.attackAt and strike.damage==20 and b.mentorHP==0 and not service:summary().unlocks["energy-site-secured"])
  c=start("mobility"); b=c.battle; assert(b.supportView.actor.variant=="mobility"); b.support.machineHP=1
  assert(b.central.enemyCombat:start("bomb")); strike=b.central.enemyStrike
  wait(function() return b.phase=="failed" and c.result end)
  assert(strike.explodedAt and strike.projectile and b.support.machineHP==0 and not service:summary().unlocks["energy-site-secured"])
  wait(function() return b.supportView.actor.completed.lose and b.supportView.actor.model.speed==0 end)
  c=start(); b=c.battle; c.withdraw:emit("Tapped"); wait(function() return b.phase=="aborted" and c.result end)
  assert(not service:summary().unlocks["energy-site-secured"] and not require("Story.Service").open():summary().unlocks["city-energy-recovered"])
  assert(Progress.load() and wp.load() and D.json.encode({ninilite=Progress.adopted,wuyun=wp.adopted},false,true)==before)
  local rows=D.DB:query("SELECT status FROM lsd.Game0MissionAttempts WHERE mission='c0-m03' ORDER BY id"); assert(#rows==3 and rows[1][1]=="failed" and rows[2][1]=="failed" and rows[3][1]=="aborted")
  return "PASS missingSecondRejected=true crossCharacterRejected=true atomicTwoCardFormation=true realLethalMelee=true noRevive=true physicalBombMachineDestroyed=true mobilityVisual=true fullMachineLose=true publicWithdrawal=true noMissionReward=true noEnergyReward=true bothModelsPreserved=true attempts=3"
 end,debug.traceback)
 local report="LSD_ENERGY_OUTCOMES_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
