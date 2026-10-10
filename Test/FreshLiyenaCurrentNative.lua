-- Earned academy copy, original doors/terminal/HUD, two real fights and Yarn.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","fresh-liyena-current-result.json"); local evidence={status='RUNNING',osInput=false};local function save()D.Content:save(out,D.json.encode(evidence,false,true))end;save()
D.thread(function()
 local ok,result=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or root..'/Test/fresh-ayan-current-result.json'),32)
  assert(prior.status=='PASS'and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-ayan%-current%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'fresh-liyena-current-'..id..'.db')
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(prior.database,db))
  evidence.database=db;evidence.source=prior.database;save()
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t,label) local deadline=D.App.runningTime+(t or 20); while not f() do assert(D.App.runningTime<deadline,"Liyena timeout: "..(label or "")); D.sleep(0.02) end end
  require("Start"); wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end)
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); local story=assert(require("Story.Service").open())
  local earnedEnergy=story:summary().mission.rewards["energy-site-secured"];assert(earnedEnergy==1)
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
   local old=world(); move(side=="right" and old.sceneWidth-110 or 110)
   assert(player().interaction and player().moveTargets:get(1)==target)
   player().interaction:emit("Tapped",1); wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.4)
  end
  door("right","PassageB"); door("right","TrainingRoom"); move(935)
  local locked,why=require("Trial.Level").openAsync(world(),true); assert(not locked and why=="COOP_REQUIRED")
  assert(not require("Story.Flow").openAsync("liyena-challenge",world()),"Remote challenge accepted")
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_trial_unlock BEFORE INSERT ON Game0MissionUnlocks BEGIN SELECT RAISE(ABORT,'QA trial fault'); END")>=0)
  world():getChildByTag("trainingTerminal"):emit("Tapped",2)
  wait(function() return world().tag=="VRTraining" and world().trialBattle and world().trialBattle.hud end,20,"coop open")
  local coop=world().trialBattle; assert(not coop.battle.duel and #coop.battle.enemies==3 and not D.Director.ui3D:getChildByTag("ayan-visit-guidance"))
  local function fight(c)
   assert(c.battle.phase=="ready" and c.beginButton.visible)
   local frozen=D.json.encode({c.battle.heroHP,c.battle.npcHP,c.battle.npc.x},false,true); D.sleep(0.8)
   assert(D.json.encode({c.battle.heroHP,c.battle.npcHP,c.battle.npc.x},false,true)==frozen and #c.battle.casts==0,"Combat started before player readiness")
   c.beginButton:emit("Tapped"); assert(c.battle.phase=="playing")
   local deadline=D.App.runningTime+90
   while c.battle.phase=="playing" do
    assert(D.App.runningTime<deadline,"Actual trial stalled")
    local b=c.battle
    if not b.duel then
     local t=b:target(b.hero); if t and math.abs(t.x-b.hero.x)>520 then c.hud.move:emit(t.x>b.hero.x and "Right" or "Left",true)
     else c.hud.move:emit("Right",false); c.hud.move:emit("Left",false); c.hud.weapon:emit("TapBegan");c.hud.weapon:emit("TapEnded") end
    else c.hud.weapon:emit("TapBegan");c.hud.weapon:emit("TapEnded") end
    D.sleep(0.08)
   end
   wait(function() return c.battle.phase~="saving" end,8,"save")
   assert(c.battle.pendingStatus=="won","Actual fight failed: "..c.battle.reason.." HP="..c.battle.heroHP.."/"..c.battle.npcHP)
   for _,cast in ipairs(c.battle.casts) do
    assert(cast.completedAt or cast.interruptedAt,"Unaccounted animation interruption")
    if cast.completedAt then assert(cast.completedAt-cast.startedAt>=cast.duration-0.06,"Truncated character animation"); assert(cast.releaseAt and cast.releaseAt>cast.startedAt and cast.releaseAt<cast.completedAt,"Missing actual attack event") end
   end
  end
  fight(coop); assert(coop.battle.phase=="save-error" and not story:summary().mission.unlocks["liyena-coop-complete"])
  assert(coop.battle.heroHits>=2 and coop.battle.npcHits>=2)
  D.DB:exec("DROP TRIGGER lsd.fail_trial_unlock"); coop.withdraw:emit("Tapped"); wait(function() return coop.result end,8,"retry result")
  local mid=D.Path(D.Content.writablePath,"lsd-fresh-liyena-coop-qa-"..id..".db"); assert(D.Content:copyAsync(db,mid)); evidence.coopDatabase=mid;save()
  assert(models()==unchanged)
  coop.result.againButton:emit("Tapped")
  local function dialogue(node,count)
   wait(function() return world().storyFlow and world().storyFlow.id==node and world().storyFlow.view.visible end,12,node)
   local f=world().storyFlow; local deadline=D.App.runningTime+30
   while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Yarn stalled"); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
   assert(f.phase=="complete" and #f.view._reviews==count,"Incomplete Yarn "..node)
  end
  dialogue("liyena-challenge",4)
  wait(function() return world().trialBattle and world().trialBattle.battle.duel and world().trialBattle.hud end,15,"duel open")
  local duel=world().trialBattle; fight(duel); wait(function() return duel.result end,8,"duel result")
  assert(duel.battle.heroHits>=20 and duel.battle.npcHits>0 and story:summary().mission.unlocks["liyena-duel-complete"])
  local duelMid=D.Path(D.Content.writablePath,"lsd-fresh-liyena-duel-qa-"..id..".db"); assert(D.Content:copyAsync(db,duelMid)); evidence.duelDatabase=duelMid;save()
  duel.result.againButton:emit("Tapped"); dialogue("liyena-recognition",5)
  wait(function() return world().tag=="TrainingRoom" and player() end,15,"return room")
  assert(story:summary().completed["liyena-recognition"] and #D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='liyena-recognized'")==1)
  assert(models()==unchanged and story:summary().mission.rewards["energy-site-secured"]==earnedEnergy)
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0)
  local E=require('Economy.Store');assert(E.open()and not E.active()and E.wallet().available==prior.balance);evidence.balance=E.wallet().available;evidence.sameJourney=true;evidence.stage='liyena-recognized';evidence.coop=coop.battle.report;evidence.duel=duel.battle.report;save()
  return "PASS actualStart=true originalAcademyDoors=true physicalTerminal=true duelGate=true twoRealFights=true readinessBeforeCombat=true authoredAttackFrames=true fullNormalAnimations=true cooperationBothParticipate=true transactionRollbackRetry=true completeYarn=true recognitionAfterWon=true rewardOnce=true modelRowsUnchanged=true originalRoomReturn=true coop="..D.json.encode(coop.battle.report,false,true).." duel="..D.json.encode(duel.battle.report,false,true)
 end,debug.traceback)
 evidence.status=ok and 'PASS'or'FAIL';evidence.detail=ok and result or nil;evidence.error=not ok and tostring(result)or nil
 save();print('LSD_FRESH_LIYENA_CURRENT_'..evidence.status)
end)
