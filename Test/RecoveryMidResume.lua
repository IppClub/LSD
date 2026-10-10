-- Earned factory victory copy; original Start/doors, full treatment and next-day messages.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","recovery-mid-resume-result.txt"); D.Content:save(out,"LSD_RECOVERY_MID_RESUME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","recovery-mid-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-recovery%-treated%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-recovery-mid-resume-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t,msg) local deadline=D.App.runningTime+(t or 15); while not f() do assert(D.App.runningTime<deadline,msg or "Recovery route wait"); D.sleep(0.04) end end
  require("Start"); wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end,30)
  local story=assert(require("Story.Service").open())
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); local before=require("Factory.Health").load(); assert(before[2]<100 and story:summary().completed["medical-notify"])
  assert(not story:canRead("lin-investigation",world().tag))
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
  local facts=story:summary()
  assert(facts.completed["medical-treatment"] and not facts.completed["medical-recovery"] and not facts.completed["lin-investigation"])
  assert(#D.DB:query("SELECT source FROM lsd.Game0StorySupplies")==0)
  door("left","PassageA"); door("left","RestRoom")
  wait(function() return world().recoveryVisit and world().recoveryVisit.phase=="ready" end,20)
  local c=world().recoveryVisit
  assert(c.stage==2 and #c.doctors==0 and not world().medicalVisit and #c.logs==0 and c.hp[2]==before[2],"Treatment resumed incorrectly")
  local actors=D.Group({"name","unit"}); assert(not actors:find(function(e) return e.unit.world==world() and (e.name=="moyu" or e.name=="moling") end),"Departed doctors respawned")
  move(world().sceneWidth/2+850); wait(function() return c.view.menu.enabled end)
  c.view:emit("Tapped",1); dialogue("medical-recovery",2); wait(function() return c.stage==3 end)
  local hp=require("Factory.Health").load(); assert(hp[1]==100 and hp[2]==100 and hp[3]==100)
  local j=assert(require("Story.Journal").openAsync(world(),8)); j.view.stationButton:emit("Tapped"); dialogue("lin-investigation",7)
  wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  assert(#D.DB:query("SELECT recipient,item,amount FROM lsd.Game0StorySupplies WHERE amount=1")==6)
  wait(function() return c.view.menu.enabled end); c.view:emit("Tapped",1); dialogue("ruins-preparation",7); wait(function() return c.stage==4 end)
  door("right","PassageA"); door("center","PassageC"); door("left","Station")
  move(world().sceneWidth-650); wait(function() return world():getChildByTag("storyTerminal").menu.enabled end)
  world():getChildByTag("storyTerminal"):emit("Tapped",1); dialogue("ruins-station",10)
  for _,reward in ipairs({"swamp-poison-treated","party-recovered","investigation-supplies-received","ayan-search-briefed","ruins-search-departure"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(models()==unchanged)
  return "PASS actualStart=true earnedTreatedCheckpoint=true treatmentNotRepeated=true departedDoctorsNotRespawned=true noEarlyHealing=true explicitOvernight2=true allPartyRecovered=true explicitLin7=true sixRealSupplies=true originalBriefing7=true physicalStationDiscussion10=true unlocksOnce=true modelsUnchanged=true"
 end,debug.traceback)
 local report="LSD_RECOVERY_MID_RESUME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
