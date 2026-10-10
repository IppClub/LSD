-- Earned factory victory copy; original Start/doors, full treatment and next-day messages.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","recovery-complete-resume-result.txt"); D.Content:save(out,"LSD_RECOVERY_COMPLETE_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","recovery-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-recovery%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-recovery-complete-resume-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t,msg) local deadline=D.App.runningTime+(t or 15); while not f() do assert(D.App.runningTime<deadline,msg or "Recovery route wait"); D.sleep(0.04) end end
  require("Start"); wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end,30)
  local story=assert(require("Story.Service").open())
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); local before=require("Factory.Health").load(); assert(before[1]==100 and before[2]==100 and before[3]==100 and story:summary().completed["medical-notify"])
  assert(story:canRead("lin-investigation",world().tag))
  local function move(x) local e=assert(player()); local deadline=D.App.runningTime+30; while math.abs(e.unit.x-x)>30 do assert(D.App.runningTime<deadline,"Recovery physical walk stalled"); e.keyLeft=e.unit.x>x; e.keyRight=e.unit.x<x; D.sleep(0.04) end; e.keyLeft=false; e.keyRight=false; D.sleep(0.3) end
  local function door(side,target)
   local old=world(); move(side=="center" and old.center.x or side=="left" and 110 or old.sceneWidth-110)
   local e=assert(player()); local index; assert(e.moveTargets)
   for i=1,e.moveTargets.count do if e.moveTargets:get(i)==target then index=i end end
   assert(index and e.interaction.menu.enabled); e.interaction:emit("Tapped",index); wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3)
  end
  local function dialogue(node,count,expected)
   wait(function() return world().storyFlow and world().storyFlow.id==node and world().storyFlow.view.visible end,20,node)
   local f=world().storyFlow; local deadline=D.App.runningTime+60
   while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Recovery Yarn stalled "..node); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
   assert(f.phase==(expected or "complete") and #f.view._reviews==count,"Incomplete recovery Yarn "..node.." "..f.phase.." rows="..#f.view._reviews)
   return f
  end
  for _,node in ipairs({"medical-treatment","medical-recovery","lin-investigation","ruins-preparation","ruins-station"}) do assert(story:summary().completed[node]) end
  local stocks=D.json.encode(D.DB:query("SELECT source,recipient,item,amount FROM lsd.Game0StorySupplies ORDER BY recipient,item"),false,true)
  assert(#D.DB:query("SELECT source FROM lsd.Game0StorySupplies WHERE amount=1")==6)
  door("left","PassageA"); door("left","RestRoom")
  wait(function() return world().recoveryVisit and world().recoveryVisit.phase=="ready" end,20)
  local c=world().recoveryVisit; assert(c.stage==4 and #c.doctors==0 and #c.logs==0 and not world().medicalVisit)
  local function replay(page,button,node,count)
   local j=assert(require("Story.Journal").openAsync(world(),page)); j.view[button]:emit("Tapped"); dialogue(node,count)
   wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  end
  replay(8,"researchButton","medical-treatment",18)
  replay(8,"archiveButton","medical-recovery",2)
  replay(8,"stationButton","lin-investigation",7)
  replay(9,"mailButton","ruins-preparation",7)
  replay(9,"researchButton","ruins-station",10)
  assert(c.stage==4 and #c.doctors==0 and #c.logs==0,"Replays repeated medical action")
  assert(stocks==D.json.encode(D.DB:query("SELECT source,recipient,item,amount FROM lsd.Game0StorySupplies ORDER BY recipient,item"),false,true),"Replays changed supplies")
  local hp=require("Factory.Health").load(); assert(hp[1]==100 and hp[2]==100 and hp[3]==100)
  for _,reward in ipairs({"swamp-poison-treated","party-recovered","investigation-supplies-received","ayan-search-briefed","ruins-search-departure"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(models()==unchanged)
  return "PASS actualStart=true earnedCompletedCopy=true allFiveNodesRestored=true doctorsNotRespawned=true noRepeatedTreatmentActions=true journalFullFiveReplays=true suppliesUnchanged=true allPartyRecovered=true unlocksOnce=true modelsUnchanged=true"
 end,debug.traceback)
 local report="LSD_RECOVERY_COMPLETE_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
