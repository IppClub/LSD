-- Isolated earned recovery save; actual route, shield/projectile, story rollback/retry and scene GC.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=root..'/Test/ruins-cleanup-result.json'
local r={status='RUNNING'};local weak=setmetatable({},{__mode='v'});D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","recovery-resume-fixture.txt")))
  assert(D.Path:getPath(source)=="/Users/Jin/Workspace/Dora" and D.Path:getFilename(source):match("^lsd%-recovery%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ruins-route-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t,msg) local deadline=D.App.runningTime+(t or 15); while not f() do assert(D.App.runningTime<deadline,msg or "Recovery route wait"); D.sleep(0.04) end end
  require("Start"); wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end,30)
  local story=assert(require("Story.Service").open())
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); local before=require("Factory.Health").load(); assert(before[2]==100 and story:summary().completed["ruins-station"])
  assert(not story:canRead("ayan-diary",world().tag))
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
  door("left","PassageA"); door("center","PassageC"); door("left","Station")
  move(world().sceneWidth-1800); wait(function() return world():getChildByTag("boardingTerminal").menu.enabled end)
  world():getChildByTag("boardingTerminal"):emit("Tapped",1); wait(function() return world().tag=="TrainA" end)
  move(world().sceneWidth-170); wait(function() return world():getChildByTag("groundDeploymentTerminal").menu.enabled end)
  world():getChildByTag("groundDeploymentTerminal"):emit("Tapped",3)
  wait(function() return world().groundDeployment and world().groundDeployment.phase=="briefing" end)
  local deployment=world().groundDeployment; assert(deployment.team and deployment.formation.learner and deployment.formation.wuyun)
  deployment.view.startButton:emit("Tapped"); wait(function() return world().tag=="AbandonedCity" and world().ruinsSearch and world().ruinsExpedition and world().ruinsExpedition.phase=="exploring" end,30)
  local c=world().ruinsExpedition; assert(c.stage==1 and c.body and c.bodyPose.completedAt and not world().groundExpedition)
  local remote,why=require("Story.Flow").openAsync("ruins-twins",world()); assert(not remote and why=="DISCOVERY_LOCATION_REQUIRED")
  local lens=assert(require("Ground.NightLens").openAsync(world())); assert(lens.locations[2].x==6200 and lens.locations[3].x==8500)
  lens.view.archiveButton:emit("Tapped"); assert(not world().nightLensTarget,"Unconfirmed Ayan direction leaked")
  lens.view.researchButton:emit("Tapped"); assert(world().nightLensTarget.id=="signal"); lens.view.closeButton:emit("Tapped")
  move(6200); wait(function() return c.twins.menu.enabled end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_twins BEFORE INSERT ON Game0StoryUnlocks WHEN NEW.id='ruins-twins-met' BEGIN SELECT RAISE(ABORT,'QA twins'); END")>=0)
  c.twins:emit("Tapped",1); local f=dialogue("ruins-twins",41,"save-error")
  local hit=assert(c.confrontation); assert(hit.blocked and hit.actualTarget=="mentor" and hit.hpBefore==hit.hpAfter and hit.attackAt>hit.startedAt and hit.hitAt>hit.attackAt and hit.completedAt-hit.startedAt>=1.19)
  assert(hit.guardAt and hit.guardCompletedAt and hit.guardCompletedAt-hit.startedAt>=hit.guardDuration-0.06)
  assert(not story:summary().completed["ruins-twins"] and c.stage==1 and player().busy)
  D.DB:exec("DROP TRIGGER lsd.fail_twins"); f.retryButton:emit("Tapped"); wait(function() return f.phase=="complete" and c.stage==2 end)
  r.confrontation=hit;weak[1]=c
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear()
 end,debug.traceback)
 D.sleep(.5);collectgarbage('collect');D.sleep(.2);collectgarbage('collect')
 r.retained=weak[1]~=nil;r.status=ok and not r.retained and 'PASS' or 'FAIL';r.error=not ok and result or r.retained and 'Ruins action registry retained expedition' or nil
 D.Content:save(out,D.json.encode(r,false,true))
end)
