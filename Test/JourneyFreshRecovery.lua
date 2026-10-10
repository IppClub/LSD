-- Earned factory victory copy; original Start/doors, full treatment and next-day messages.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","fresh-factory-recovery-route-result.txt"); D.Content:save(out,"LSD_FRESH_FACTORY_RECOVERY_ROUTE_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","fresh-factory-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-fresh%-factory%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-fresh-factory-recovery-route-qa-"..id..".db")
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
  -- Exercise the real factory constructor on an isolated render node, using
  -- the earned DB state; no edits to the party, story or mission records.
  local function supportCheck(recovered)
   local scene=D.Node();scene.offset=0
   local hp=require('Factory.Health').load()
   local support,view=require('Factory.Support').create(scene,hp)
   assert(support.variant=='mobility','Saved factory machine lost')
   if recovered then
    assert(not support.maxHP,'Recovered party still has injury ceiling')
    support.hp[2]=94
    support:update(1,{0,0,0});support:update(1,{0,0,0})
    assert(support.hp[2]==100,'Post-recovery life field cannot fully heal')
   else
    assert(support.maxHP and support.maxHP[2]==math.min(90,hp[2]))
    local injured=support.hp[2]
    support:update(1,{0,0,0});support:update(1,{0,0,0})
    assert(support.hp[2]==injured,'Life field bypassed medical overnight')
   end
   scene:cleanup()
  end
  supportCheck(false)

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
  door("left","PassageA"); door("left","RestRoom")
  wait(function() return world().recoveryVisit and world().recoveryVisit.phase=="ready" end,20)
  local c=world().recoveryVisit; assert(c.stage==1 and #c.doctors==2 and c.hp[2]==before[2])
  local remote,why=require("Story.Flow").openAsync("medical-treatment",world()); assert(not remote and why=="DISCOVERY_LOCATION_REQUIRED")
  local j=assert(require("Story.Journal").openAsync(world(),8)); assert(j.recordIds[2]=="medical-treatment" and j.recordIds[4]=="lin-investigation")
  j.view.researchButton:emit("Tapped"); assert(j.phase=="journal" and not story:summary().completed["medical-treatment"]); j.view.closeButton:emit("Tapped")
  move(world().sceneWidth/2+850); wait(function() return c.view.menu.enabled end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_treatment BEFORE INSERT ON Game0StoryUnlocks WHEN NEW.id='swamp-poison-treated' BEGIN SELECT RAISE(ABORT,'QA treatment'); END")>=0)
  c.view:emit("Tapped",1); local f=dialogue("medical-treatment",18,"save-error")
  assert(not story:summary().completed["medical-treatment"] and require("Factory.Health").load()[2]==before[2] and player().busy)
  local prose=""; for _,row in ipairs(f.view._reviews) do prose=prose..row.text end
  assert(prose:find("沼泽花妖的毒素",1,true) and prose:find("民族奇闻志异",1,true) and prose:find("明天就可以痊愈",1,true))
  D.DB:exec("DROP TRIGGER lsd.fail_treatment"); f.retryButton:emit("Tapped"); wait(function() return f.phase=="complete" and c.stage==2 and #c.doctors==0 and c.pending==0 end,20)
  assert(require("Factory.Health").load()[2]==before[2],"Treatment skipped the overnight")
  supportCheck(false)
  assert(#c.logs==2)
  for _,log in ipairs(c.logs) do assert(log.completedAt and log.completedAt-log.startedAt>=log.duration-0.06 and not log.interruptedAt,"Truncated original physician comp") end
  for _,name in ipairs({"moyu","moling"}) do assert(c.departed[name].walked>500 and c.departed[name].completedAt,"Doctor did not physically leave") end
  local mid=D.Path(D.Content.writablePath,"lsd-fresh-factory-recovery-treated-qa-"..id..".db"); assert(D.Content:copyAsync(db,mid)); D.Content:save(D.Path(root,"Test","fresh-factory-recovery-mid-resume-fixture.txt"),mid)
  wait(function() return c.view.menu.enabled end); c.view:emit("Tapped",1); dialogue("medical-recovery",2)
  wait(function() return c.stage==3 end); local hp=require("Factory.Health").load(); assert(hp[1]==100 and hp[2]==100 and hp[3]==100 and not story:summary().completed["lin-investigation"])
  supportCheck(true)
  j=assert(require("Story.Journal").openAsync(world(),8))
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_supplies BEFORE INSERT ON Game0StorySupplies BEGIN SELECT RAISE(ABORT,'QA supplies'); END")>=0)
  j.view.stationButton:emit("Tapped"); f=dialogue("lin-investigation",7,"save-error")
  assert(not story:summary().completed["lin-investigation"] and #D.DB:query("SELECT source FROM lsd.Game0StorySupplies")==0 and not story:summary().unlocks["investigation-supplies-received"],"Message and supplies were not atomic")
  D.DB:exec("DROP TRIGGER lsd.fail_supplies"); f.retryButton:emit("Tapped"); wait(function() return f.phase=="complete" and world().storyJournal.phase=="journal" end)
  world().storyJournal.view.closeButton:emit("Tapped"); wait(function() return c.view.menu.enabled end)
  assert(#D.DB:query("SELECT recipient,item,amount FROM lsd.Game0StorySupplies WHERE amount=1")==6)
  c.view:emit("Tapped",1); dialogue("ruins-preparation",7); wait(function() return c.stage==4 end)
  door("right","PassageA"); door("center","PassageC"); door("left","Station")
  move(world().sceneWidth-650); wait(function() return world():getChildByTag("storyTerminal").menu.enabled end)
  world():getChildByTag("storyTerminal"):emit("Tapped",1); dialogue("ruins-station",10)
  j=assert(require("Story.Journal").openAsync(world(),8)); j.view.stationButton:emit("Tapped"); dialogue("lin-investigation",7)
  wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  assert(#D.DB:query("SELECT recipient,item,amount FROM lsd.Game0StorySupplies WHERE amount=1")==6 and models()==unchanged)
  for _,reward in ipairs({"swamp-poison-treated","party-recovered","investigation-supplies-received","ayan-search-briefed","ruins-search-departure"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  D.Content:save(D.Path(root,"Test","fresh-factory-recovery-resume-fixture.txt"),db)
  return "PASS factoryMobilityPersists=true fieldCannotSkipTreatmentOrOvernight=true recoveredFieldHealsTo100=true actualStart=true earnedFactoryWinCopy=true physicalRestRoomDoors=true fullOriginalTreatment18=true firstRemoteRejected=true treatmentRollbackRetry=true bothOriginalPhysicianActionsComplete=true actualDoctorDeparture=true noEarlyHealing=true explicitOvernight=true partyRestored=true explicitLinMessage7=true messageSuppliesAtomicRollbackRetry=true eachActorTwoRealSupplies=true originalBriefing7=true physicalStationRoute=true originalStationDiscussion10=true replayNoDuplicateSupplies=true unlocksOnce=true modelRowsUnchanged=true"
 end,debug.traceback)
 local report="LSD_FRESH_FACTORY_RECOVERY_ROUTE_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
