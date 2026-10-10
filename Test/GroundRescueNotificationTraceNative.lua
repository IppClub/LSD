-- Actual deployment/roam from the earned train profile, no user DB or invented completion.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ground-rescue-notification-trace-result.json")
local evidence={status='RUNNING',osInput=false};local function save()D.Content:save(out,D.json.encode(evidence,false,true))end;save()
D.thread(function()
 local ok,result=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or root..'/Test/fresh-train-current-result.json'),32)
  assert(prior.status=='PASS' and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-train%-current%-%d+%.db$'))
  local source=prior.database;local db=D.Path(D.Content.writablePath,'fresh-ground-trace-'..id..'.db')
  assert(not D.Content:exist(db) and not D.DB:existDB('lsd') and D.Content:copyAsync(source,db))
  evidence.database=db;evidence.source=source;save()
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local service=assert(require("Story.Service").open()); assert(service:summary().completed["mail-two"])
  -- Observation only: retain all production action, timing, movement and save behavior.
  local trace={plays={},ends={},rests={}}
  evidence.rescueTrace=trace
  local observedRescue
  local Animation=require("CombatAnimation")
  local originalPlay,originalRest=Animation.play,Animation.rest
  Animation.play=function(u,name,...)
   local duration=originalPlay(u,name,...)
   if u==observedRescue and name=="melee" then trace.plays[#trace.plays+1]={at=D.App.runningTime,name=name,duration=duration} end
   return duration
  end
  Animation.rest=function(u,...)
   if u==observedRescue then trace.rests[#trace.rests+1]={at=D.App.runningTime} end
   return originalRest(u,...)
  end
  local Battle=require("Ground.Battle")
  local originalArrive=Battle.arriveRescuer
  Battle.arriveRescuer=function(b,...)
   originalArrive(b,...)
   observedRescue=b.rescue
   observedRescue.playable:slot("AnimationEnd",function(name)
    if name=="melee" then trace.ends[#trace.ends+1]={at=D.App.runningTime,name=name,count=b.rescueCompleted,ownedAction=observedRescue:isDoing("groundRescueMelee"),phase=b.phase} end
   end)
  end
  require("Start")
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(test,t)
   local endAt=D.App.runningTime+(t or 12)
   while not test() do assert(D.App.runningTime<endAt,"Ground route wait timed out"); D.sleep(0.05) end
  end
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
  local function door(route,target)
   local old=world(); move(route=="left" and 120 or route=="right" and old.sceneWidth-120 or old.center.x)
   local e=player(); local index; assert(e.moveTargets,"Missing story route sensor")
   for i=1,e.moveTargets.count do if e.moveTargets:get(i)==target then index=i; break end end
   assert(index and e.interaction.menu.enabled,"Story destination missing: "..target); e.interaction:emit("Tapped",index)
   wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3)
  end
  local function finish(flow)
   wait(function() return flow.view.visible end)
   local endAt=D.App.runningTime+25
   while flow.phase=="dialogue" or flow.phase=="saving" do
    assert(D.App.runningTime<endAt,"Ground Yarn stalled")
    if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit("Tapped") end
    D.sleep(0.1)
   end
   assert(flow.phase=="complete")
  end
  wait(function()return world() and world().tag=='PreparationRoom' and player() and not player().busy end,30)
  door('left','PassageA');door('center','PassageC');door('left','Station')
  move(world().sceneWidth-1800);world():getChildByTag('boardingTerminal'):emit('Tapped',1)
  wait(function()return world().tag=='TrainA' and player()end);D.sleep(.5)
  assert(not service:canRead("ground-arrival","TrainA"),"Remote ground story accepted")
  local terminal=assert(world():getChildByTag("groundDeploymentTerminal")); assert(not terminal.menu.enabled)
  move(world().sceneWidth-170)
  terminal:emit("Tapped",1); wait(function() return world().groundDeployment end)
  local deploy=world().groundDeployment; assert(player().busy)
  deploy.view.rosterButton:emit("Tapped"); wait(function() return deploy.phase=="briefing" and not deploy.formation.learner end)
  deploy.view.startButton:emit("Tapped"); assert(deploy.phase=="briefing" and world().tag=="TrainA","Unformed squad deployed")
  deploy.view.rosterButton:emit("Tapped"); wait(function() return deploy.phase=="briefing" and deploy.formation.learner end)
  deploy.view.startButton:emit("Tapped"); wait(function() return world().tag=="AbandonedCity" and player() and world().groundExpedition end)
  D.sleep(0.7)
  local expedition=world().groundExpedition; local support=expedition.support
  assert(world():getChildByTag("ground-auxiliary") and support.active and support.spent>0)
  move(900); world():getChildByTag("storyTerminal"):emit("Tapped",1); wait(function() return world().storyFlow end)
  local before=support.gold; D.sleep(0.5); assert(math.abs(support.gold-before)<0.01,"Story drains life support")
  finish(world().storyFlow); assert(service:summary().completed["ground-arrival"] and not player().busy)
  move(1150); assert(support.collected["survey-gold-1"],"Physical pickup failed")
  local journal=assert(require("Story.Journal").openAsync(world(),2)); before=support.gold; D.sleep(0.4)
  assert(math.abs(support.gold-before)<0.01 and #journal.recordIds==4,"Journal doesn't pause support or list ground nodes")
  journal.view.closeButton:emit("Tapped")
  move(2450); assert(world():getChildByTag("ground-boss")); world():getChildByTag("ground-contact"):emit("Tapped",1)
  wait(function() return world().storyFlow.id=="ground-contact" end); finish(world().storyFlow)
  assert(service:summary().completed["ground-contact"] and not player().busy and expedition.collected>=3)
  local original=D.json.encode(assert(require('Training.Progress').adopted),false,true)
  local story=service
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_ground_reward BEFORE INSERT ON Game0MissionUnlocks BEGIN SELECT RAISE(ABORT,'QA ground reward fault'); END")>=0)
  world():getChildByTag("ground-contact"):emit("Tapped",2)
  wait(function() return expedition.supplyPanel end)
  local budget=expedition.supplyPanel;assert(budget.quote.total<=prior.balance,'Earned wallet cannot cover ground budget')
  evidence.budget=budget.quote;save();budget.saveButton:emit('Tapped')
  wait(function() return world().groundBattle end); local level=world().groundBattle; local b=level.battle
  D.sleep(0.4); local hud=D.Director.ui3D:getChildByTag("ground-battle-hud")
  hud.move:emit("Right",true); D.sleep(0.15); hud.move:emit("Right",false)
  hud.weapon:emit("TapBegan"); D.sleep(0.05); hud.weapon:emit("TapEnded")
  D.Director.ui3D:getChildByTag("ground-battle-gather"):emit("TapBegan")
  wait(function() return b.phase~="playing" and b.phase~="saving" end,65)
  assert(b.phase=="save-error","Expected actual rescue save error, got "..b.phase.." / "..tostring(b.reason))
  assert(b.rescue and b.rescueHits>0 and b.rescueCompleted>=b.rescueHits and b.arena.metrics.hits>0 and b.arena.metrics.fallback==0,"Rescue didn't execute full actual actions")
  assert(not story:summary().mission.unlocks["wuyun-rescued"] and not story:canRead("ground-rescue","AbandonedCity"),"Partial rescue reward persisted")
  D.DB:exec("DROP TRIGGER lsd.fail_ground_reward"); b:saveResult()
  wait(function() return b.phase=="won" and level.result end)
  assert(b.rescueCompleted==#trace.plays,"Owned rescue completion count differs from actual finite plays")
  local report=b.report;assert(b.support==support,'Exploration support reset at battle entry'); assert(report.mentorHits>0,"Public mentor shooting had no real hit")
  assert(story:summary().mission.unlocks["wuyun-rescued"])
  assert(require("Training.Progress").load() and D.json.encode(require("Training.Progress").adopted,false,true)==original,"Battle overwrote learned model")
  level.result.baseButton:emit("Tapped"); wait(function() return world().storyFlow and world().storyFlow.id=="ground-rescue" end)
  finish(world().storyFlow); wait(function() return world().tag=="RestRoom" and player() end)
  wait(function() return D.Group({"name","unit"}):find(function(e) return e.name=="wuyun" and e.storyCompanion and e.unit.world==world() end) end)
  move(world().sceneWidth/2); world():getChildByTag("storyTerminal"):emit("Tapped",1)
  wait(function() return world().storyFlow and world().storyFlow.id=="wuyun-rest" end); finish(world().storyFlow)
  assert(story:summary().unlocks["chapter-one-complete"] and not player().busy)
  local count=#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks")
  assert(b.service:finishAsync(b.attempt,"won",report) and #D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks")==count)
  local journal=assert(require("Story.Journal").openAsync(world(),3)); assert(#journal.recordIds==4); journal.view.closeButton:emit("Tapped")
  local E=require('Economy.Store');assert(E.open() and not E.active());assert(E.wallet().available==prior.balance-report.economy.cost+report.economy.income)
  evidence.balance=E.wallet().available;evidence.battle=report;evidence.sameJourney=true;evidence.stage='chapter-one-complete';save()
  return "PASS earnedSurveyCopy=true physicalFrontier=true publicBattle=true publicMentorMoveShootGather=true actualBigBoss=true learnerModelActions=true limitedEnergy=true auxiliaryCarried=true physicalWuyunMelee=true fullRescueAnimations=true saveFaultRollback=true retry=true rewardOnce=true modelUnchanged=true rescueYarn=true actualRestRoom=true wuyunEntity=true restYarn=true chapterOneRecord=true journalPageThree=true report="..D.json.encode(report)
 end,debug.traceback)
 evidence.status=ok and 'PASS' or 'FAIL';evidence.detail=ok and result or nil;evidence.error=not ok and tostring(result) or nil
 save();print('LSD_FRESH_GROUND_CURRENT_'..evidence.status)
end)
