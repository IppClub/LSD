-- Actual battle driven by the real seven-demonstration model built by TrainingArena.
-- Independent QA DB; this proves runtime composition, not the public mission UI.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local runId=tostring(os.time()); local output=D.Path(root,"Test","mission-battle-result.txt")
D.Content:save(output,"LSD_MISSION_BATTLE_RUNNING runId="..runId.."\n")
local database=D.Path(D.Content.writablePath,"lsd-mission-battle-qa-"..runId..".db")
assert(not D.Content:exist(database) and not D.DB:existDB("lsd"))
assert(D.DB:exec("ATTACH DATABASE '"..database:gsub("'","''").."' AS lsd")>=0)
D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","training-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-game0%-training%-qa%-%d+%.db$"),"Not an isolated real training fixture")
  assert(D.DB:exec("ATTACH DATABASE '"..source:gsub("'","''").."' AS trainingSource")>=0)
  local rows=assert(D.DB:query("SELECT payload FROM trainingSource.Game0Training WHERE slot='main'"))
  local envelope=assert(D.json.decode(rows[1][1],32)); D.DB:exec("DETACH DATABASE trainingSource")
  local model=envelope.adopted; assert(model.sampleCount==7,"Missing actual demonstration model")
  local service=assert(require("Mission.Service").open())
  local formation={mentor=true,learner="ninilite"}
  local attempt=assert(service:beginAsync("c0-m01",model,formation))
  local battle=require("Mission.Battle").createAsync(service,attempt,"charM")
  D.sleep(1); assert(battle:command("right")); D.sleep(0.15); assert(battle:command("stop"))
  assert(battle.mentor.x>520,"Mentor did not physically move")
  assert(battle:command("shoot"),"Mentor shot rejected")
  local deadline=D.App.runningTime+60
  while (battle.phase=="playing" or battle.phase=="saving") and D.App.runningTime<deadline do D.sleep(0.1) end
  assert(battle.phase=="won","Learned squad failed: "..tostring(battle.reason).." phase="..battle.phase)
  assert(#battle.rounds==2 and battle.rounds[1].metrics.hits>=2 and battle.rounds[2].metrics.hits>=2,"Learner absent from victory")
  assert(battle.mentorHits>=1,"Real mentor projectile failed to hit")
  assert(service:summary().unlocks["library-lead"],"Actual victory reward missing")
  local originalHits=battle.rounds[1].metrics.hits+battle.rounds[2].metrics.hits
  local poor=D.json.decode(D.json.encode(model,false,true)); poor.rules={{conditions={},action="idle"}}
  local second=assert(service:beginAsync("c0-m01",poor,formation))
  battle=require("Mission.Battle").createAsync(service,second,"charF")
  local repaired=false; deadline=D.App.runningTime+60
  while (battle.phase=="playing" or battle.phase=="saving") and D.App.runningTime<deadline do
   if not repaired and battle.phase=="playing" and battle.relayHP<100 then
    assert(battle:command("repair"),"Repair support failed"); repaired=true
    assert(battle.repairs==1,"Repair pack not consumed")
   end
   D.sleep(0.1)
  end
  assert(battle.phase=="failed","Idle-only model unexpectedly completed mission")
  assert(repaired,"Repair path not exercised")
  assert(service:summary().last.status=="failed","Failure outcome not saved")
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks")==1,"Failure changed one-time unlock count")
  return "PASS realModelSamples=7 learnerHits="..originalHits.." mentorProjectile=true waves=2 idleModelFailed=true repair=true resultsSaved=true"
 end,debug.traceback)
 local report="LSD_MISSION_BATTLE_"..(ok and result or "FAIL "..tostring(result)).." runId="..runId
 print(report); D.Content:save(output,report.."\n")
end)
