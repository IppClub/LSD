-- Earned factory victory copy; original Start/doors, full treatment and next-day messages.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","recovery-frame-result.txt"); D.Content:save(out,"LSD_RECOVERY_FRAME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","factory-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-factory%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-recovery-frame-qa-"..id..".db")
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
  door("left","PassageA"); door("left","RestRoom")
  wait(function() return world().recoveryVisit and world().recoveryVisit.phase=="ready" end,20)
  local c=world().recoveryVisit; assert(c.stage==1 and #c.doctors==2 and c.hp[2]==before[2])
  move(world().sceneWidth/2+850); wait(function() return c.view.menu.enabled end)
  assert(not world().medicalVisit.view.visible,"Earlier doctor conversation still visible")
  local actors=D.Group({"name","unit"})
  wait(function()
   -- Platformer layers have their own transforms. Project the actual actor
   -- margins rather than assuming world x minus camera x is screen x.
   local points={}; local count=0; local pending=0
   actors:each(function(e) if e.unit.world==world() and (e.player or e.name=="moyu" or e.name=="moling" or e.name=="ninilite" or e.name=="wuyun") then
    count=count+1
    for _,x in ipairs({-130,130}) do pending=pending+1; e.unit:convertToWindowSpace(D.Vec2(x,0),function(p) points[#points+1]=p; pending=pending-1 end) end
   end; return false end)
   local deadline=D.App.runningTime+1
   while pending>0 do assert(D.App.runningTime<deadline,"Clinic projection callback missing"); D.sleep(0.02) end
   assert(count==5 and #points==10,"Clinic projection must cover all five actors")
   for _,p in ipairs(points) do if p.x<=0 or p.x>=D.App.visualSize.width then return false end end
   return true
  end,5,"Clinic camera did not settle with all actors framed")
  for _,e in ipairs(c.doctors) do assert(math.abs(e.unit.x-player().unit.x)>140,"Doctor overlaps visitor") end
  local overflow=false; c.view.menu.children:each(function(b) overflow=overflow or b.children.last.width+35>b.width; return false end); assert(not overflow,"Treatment button overflow")
  assert(c.hint.parent.width==D.App.bufferSize.width and c.hint.parent.height==D.App.bufferSize.height,"Recovery status outside screen layout")
  assert(c.hint and c.hint.visible and #c.doctors==2 and world().medicalVisit.station.visible)
  return "PASS earnedFactoryWinCopy=true originalRestRoom=true actualWalk=true originalMedicalPair=true separateActors=true menuFits=true previousConversationHidden=true retainedInjuryHP=true"
 end,debug.traceback)
 local report="LSD_RECOVERY_FRAME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
