-- Earned two-fight copy; original Start/doors, explicit mail forwarding and physical story-fragment unlock.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","medical-complete-resume-result.txt"); D.Content:save(out,"LSD_MEDICAL_COMPLETE_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","medical-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-medical%-visit%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-medical-complete-resume-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db)); assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t,label) local deadline=D.App.runningTime+(t or 20); while not f() do assert(D.App.runningTime<deadline,"After trial timeout "..(label or "")); D.sleep(0.02) end end
  require("Start"); wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end)
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); local story=assert(require("Story.Service").open()); assert(story:summary().completed["liyena-recognition"])
  local function move(x)
   local e=assert(player()); local deadline=D.App.runningTime+20
   while math.abs(e.unit.x-x)>25 do assert(D.App.runningTime<deadline,"After trial walk stalled"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.02) end
   e.keyLeft=false; e.keyRight=false; D.sleep(0.2)
  end
  local function door(side,target)
   local old=world(); move(side=="right" and old.sceneWidth-110 or 110); assert(player().interaction and player().moveTargets:get(1)==target)
   player().interaction:emit("Tapped",1); wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.4)
  end
  for _,node in ipairs({"medical-meeting","translator-request","translator-preparation"}) do assert(story:summary().completed[node]) end
  wait(function() return world().medicalVisit and world().medicalVisit.phase=="ready" end)
  local c=world().medicalVisit; assert(c.actors[1].name=="ninilite" and c.actors[2].name=="wuyun")
  local j=assert(require("Story.Journal").openAsync(world(),7)); j.view.researchButton:emit("Tapped")
  wait(function() return world().storyFlow and world().storyFlow.id=="translator-preparation" and world().storyFlow.view.visible end)
  local f=world().storyFlow; local deadline=D.App.runningTime+45
  while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Replay stalled"); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
  assert(f.phase=="complete" and #f.view._reviews==15)
  wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  for _,reward in ipairs({"medical-pair-met","translator-material-requested","factory-expedition-briefed"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(models()==unchanged and story:summary().mission.rewards["energy-site-secured"]==2)
  return "PASS actualStart=true earnedCompletedCopy=true allThreeNodesRestored=true originalPreparationCompanions=true journalSevenFullReplay=true unlocksOnce=true modelsUnchanged=true energyTwoPreserved=true"
 end,debug.traceback)
 local report="LSD_MEDICAL_COMPLETE_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
