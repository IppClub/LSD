-- Start continues a genuinely earned factory profile, then original academy routes.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","factory-resume-result.txt"); D.Content:save(out,"LSD_FACTORY_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","factory-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-factory%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-factory-resume-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Start")
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t) local deadline=D.App.runningTime+(t or 15); while not f() do assert(D.App.runningTime<deadline,"Factory resume wait"); D.sleep(0.05) end end
  wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end,30)
  local story=assert(require("Story.Service").open()); local facts=assert(story:summary()); assert(facts.completed["factory-encounter"] and facts.completed["factory-material"] and facts.completed["medical-notify"])
  local function move(x) local e=assert(player()); local deadline=D.App.runningTime+40; while math.abs(e.unit.x-x)>35 do assert(D.App.runningTime<deadline,"Factory resume physical walk"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.05) end; e.keyLeft=false; e.keyRight=false; D.sleep(0.4) end
  local function door(side,target)
   local old=world(); move(side=="center" and old.center.x or side=="left" and 110 or old.sceneWidth-110)
   local e=assert(player()); local index; assert(e.moveTargets)
   for i=1,e.moveTargets.count do if e.moveTargets:get(i)==target then index=i end end
   assert(index and e.interaction.menu.enabled,"Resume door unavailable"); e.interaction:emit("Tapped",index)
   wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3)
  end
  door("left","PassageA"); door("center","PassageC"); door("left","Station")
  move(world().sceneWidth-1800); world():getChildByTag("boardingTerminal"):emit("Tapped",1); wait(function() return world().tag=="TrainA" and player() end)
  move(world().sceneWidth-170); world():getChildByTag("groundDeploymentTerminal"):emit("Tapped",2); wait(function() return world().groundDeployment end)
  world().groundDeployment.view.startButton:emit("Tapped"); wait(function() return world().tag=="Factory" and world().factoryExpedition and player() end)
  local hp=require("Factory.Health").load(); assert(world().factoryExpedition.hp[2]==hp[2] and hp[2]<100,"Restart healed injury before treatment")
  local j=assert(require("Story.Journal").openAsync(world(),7)); assert(j.recordIds[3]=="factory-encounter"); j.view.archiveButton:emit("Tapped")
  wait(function() return world().storyFlow and world().storyFlow.id=="factory-encounter" and world().storyFlow.view.visible end)
  local f=world().storyFlow; local deadline=D.App.runningTime+35
  while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Resume Siren replay stalled"); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
  assert(f.phase=="complete" and #f.view._reviews==5)
  wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  for _,reward in ipairs({"factory-encounter-recorded","translator-clam-material","medical-treatment-requested"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE mission='c0-m05'")==1 and #D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0)
  return "PASS actualStart=true earnedFactoryCopy=true fullAcademyElevatorStationTrainRoute=true publicFactoryRedeployment=true allThreeNodesRestored=true injuryHPNotHealed=true sirenFullReplay=true allUnlocksOnce=true noForcedRebattle=true"
 end,debug.traceback)
 local report="LSD_FACTORY_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
