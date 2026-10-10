-- Earned factory victory copy; original Start/doors, full treatment and next-day messages.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','fresh-ruins-current-result.json');local evidence={status='RUNNING',osInput=false};local function save()D.Content:save(out,D.json.encode(evidence,false,true))end;save()
D.thread(function()
 local ok,result=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or '/private/tmp/lsd-zero-recovery-won-treatment-20261007/result.json'),32)
  assert(prior.status=='PASS'and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-recovery%-current%-%d+%.db$'))
  local source=prior.database;local db=D.Path(D.Content.writablePath,'fresh-ruins-current-'..id..'.db')
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db))
  evidence.database=db;evidence.source=source;save()
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
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
  local mid=D.Path(D.Content.writablePath,"lsd-fresh-ruins-twins-qa-"..id..".db"); assert(D.Content:copyAsync(db,mid)); evidence.midDatabase=mid;save()
  move(8500); wait(function() return c.found.menu.enabled end)
  for _,name in ipairs({"vika","vivi"}) do assert(c.escorted[name].walked>1000,"Twins were not physically escorted") end
  c.found:emit("Tapped",1); dialogue("ayan-found",7); wait(function() return c.stage==3 end)
  assert(story:summary().unlocks["ayan-diary-found"] and not story:summary().completed["ayan-recovery"] and c.body)
  wait(function() return c.recovery.menu.enabled end); c.recovery:emit("Tapped",1); wait(function() return world().companionPanel and world().companionPanel.phase=="information" end)
  local profile=world().companionPanel; profile.view.stationButton:emit("Tapped"); dialogue("ayan-diary",7)
  wait(function() return world().companionPanel.phase=="information" end); world().companionPanel.view.closeButton:emit("Tapped")
  wait(function() return c.recovery.menu.enabled end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_ayan_data BEFORE INSERT ON Game0StoryUnlocks WHEN NEW.id='ayan-data-recovered' BEGIN SELECT RAISE(ABORT,'QA Ayan data'); END")>=0)
  c.recovery:emit("Tapped",2); f=dialogue("ayan-recovery",8,"save-error")
  assert(c.body and not c.dataRecovery and not story:summary().completed["ayan-recovery"],"Data disappeared before save")
  D.DB:exec("DROP TRIGGER lsd.fail_ayan_data"); f.retryButton:emit("Tapped"); wait(function() return f.phase=="complete" and c.stage==4 and c.dataRecovery and c.dataRecovery.completedAt and not c.body and not player().busy end)
  assert(c.support.gold>0 and c.support.collected["ruins-gold-4"],"Actual route did not collect life-support supplies")
  assert(c.dataRecovery.completedAt-c.dataRecovery.startedAt>=1.39 and not c.diary.visible)
  for _,reward in ipairs({"ruins-twins-met","ayan-diary-found","ayan-diary-read","ayan-data-recovered"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1) end
  assert(models()==unchanged and #D.DB:query("SELECT source FROM lsd.Game0StorySupplies WHERE amount=1")==6)
  move(8800)
  wait(function() return world().ruinsExpedition and world().ruinsExpedition.phase=='exploring' and world().ruinsExpedition.returnRoute.menu.enabled end,30)
  world().ruinsExpedition.returnRoute:emit('Tapped',1)
  wait(function() return world().storyFlow and world().storyFlow.id=='ruins-ambush' and world().storyFlow.view.visible end)
  local f=world().storyFlow
  while f.phase=='dialogue' or f.phase=='saving' do if not f.view._advancing then f.view.confirm:emit('Tapped') end;D.sleep(.08) end
  assert(f.phase=='complete' and #f.view._reviews==5)
  wait(function()return world().ruinsReturn and world().ruinsReturn.supplyPanel end)
  local panel=world().ruinsReturn.supplyPanel
  assert(#panel.quote.lines==3,'Pursuit must charge only mentor and two tools')
  evidence.defaultBudget=panel.quote.total
  for i,target in ipairs({4,6,2})do
   local slot=require('Economy.Loadout').displaySlots('c0-m06')[i];local key=slot.actor..':'..slot.item
   while panel.values[key]~=target do panel.buttons[i][panel.values[key]<target and 1 or -1]:emit('Tapped')end
  end
  assert(panel.values['mentor:kinetic']==4 and panel.values['mentor:smoke']==6 and panel.values['mentor:flare']==2 and panel.quote.total==62)
  evidence.budget=panel.quote.total;save();panel.saveButton:emit('Tapped')
  wait(function() return D.Platformer.Data.store.world.pursuitLevel end,30)
  local c=D.Platformer.Data.store.world.pursuitLevel;local b=c.battle
  wait(function() return b.mentor.onSurface end)
  local hud=assert(D.Director.ui3D:getChildByTag('pursuit-hud'))
  hud.move:emit('Right',true)
  local shot=false;local initialFlare=false;local deadline=D.App.runningTime+100;evidence.controlLog={}
  while b.phase=='playing'or b.phase=='saving'do
   local now=D.App.runningTime;assert(now<deadline,'Pursuit escape stalled')
   if b.phase=='playing'then
    local nearest,lastEnemy
    for _,e in ipairs(b.enemies)do if e.hp>0 and not e.untargetable then local distance=math.abs(e.unit.x-b.mentor.x);nearest=math.min(nearest or math.huge,distance);lastEnemy=math.max(lastEnemy or -math.huge,e.unit.x)end end
    local busy=b.stamina.down or b.mentor:isDoing('groundMentorShot')or b.mentor:isDoing('pursuitTool')
    if not shot and b.mentor.x>=7350 and not busy then
     hud.weapon:emit('TapBegan');D.sleep(.04);hud.weapon:emit('TapEnded');shot=true;evidence.controlLog[#evidence.controlLog+1]={kind='shot',x=b.mentor.x,at=now-b.started}
    elseif shot and b.mentorHits>0 and not initialFlare and not busy then
     c.toolButtons.flare:emit('TapBegan');initialFlare=true;evidence.controlLog[#evidence.controlLog+1]={kind='first-flare',x=b.mentor.x,at=now-b.started}
    elseif not busy and nearest and nearest<800 and b.mentor.x>7800 and (not lastEnemy or lastEnemy<b.mentor.x or b.mentorHP<65)and not b:inSmoke(b.mentor.x)and now>=(b.toolReady.smoke or 0)and b.supplies:canSpend('mentor','smoke')then
     c.toolButtons.smoke:emit('TapBegan');evidence.controlLog[#evidence.controlLog+1]={kind='smoke',x=b.mentor.x,hp=b.mentorHP,at=now-b.started}
    elseif not busy and nearest and nearest<500 and b.mentor.x>8200 and now>=(b.toolReady.flare or 0)and b.supplies:canSpend('mentor','flare')then
     c.toolButtons.flare:emit('TapBegan');evidence.controlLog[#evidence.controlLog+1]={kind='flare',x=b.mentor.x,hp=b.mentorHP,at=now-b.started}
    end
    if b.mentorHP<=65 and not b.medicineBusy and (require('Story.Supplies').count('mentor','first-aid-water')or 0)>0 then c.toolButtons.medicine:emit('TapBegan');evidence.controlLog[#evidence.controlLog+1]={kind='medicine',x=b.mentor.x,at=now-b.started}end
   end
   D.sleep(.04)
  end
  evidence.report=b.report;evidence.outcome=b.phase;evidence.mentorHP=b.mentorHP;evidence.finalX=b.mentor.x;save()
  assert(b.phase=='won',b.reason..' HP='..b.mentorHP..' x='..b.mentor.x)
  wait(function() return c.result end)
  assert(not c.result.baseButton.visible and not c.result.baseButton.touchEnabled,'Victory exposes misleading return/retry controls')
  do
   local function bounds()
    local button=c.result.againButton;local buffer=D.App.bufferSize
    local low=button:convertToWorldSpace(D.Vec2.zero)+D.Vec2(buffer.width/2,buffer.height/2)
    local high=button:convertToWorldSpace(D.Vec2(button.width,button.height))+D.Vec2(buffer.width/2,buffer.height/2)
    return {low={x=low.x,y=low.y},high={x=high.x,y=high.y},width=buffer.width,height=buffer.height,attached=c.result.parent~=nil}
   end
   evidence.continueButtonBounds={first=bounds()};save()
   D.sleep(.1);local box=bounds();evidence.continueButtonBounds.afterSettled=box;save()
   assert(box.low.x>=0 and box.low.y>=0 and box.high.x<=box.width and box.high.y<=box.height,'Continue button clipped after layout settled')
  end
  for _,e in ipairs(b.escorts) do assert(e.walked>1000 and e.unit.x<=require('Ruins.Pursuit').safeX,'Escort did not walk to safety') end
  assert(story:summary().mission.unlocks['ruins-diversion-complete'])
  assert(models()==unchanged,'Pursuit changed learned models')
  local E=require('Economy.Store');assert(E.open()and not E.active())
  assert(E.wallet().available==prior.balance+b.report.economy.net)
  evidence.report=b.report;evidence.balance=E.wallet().available;evidence.sameJourney=true;save()
  c.result.againButton:emit('Tapped')
  wait(function()return world().tag=='OuterHeaven' and world().valleyVisit and player()end,30)
  evidence.stage='valley-arrival';save()
  return "PASS continuousRuinsIntoAmbush=true fullToolActions=true actualFourEscortEscape=true actualStart=true earnedRecoveryCopy=true physicalStationTrainRoute=true originalFormationThree=true distinctRuinsDeployment=true actualSignalLensAndWalk=true firstRemoteRejected=true originalTwins41=true realProjectileShieldBlock=true fullProceduralTwinPulse=true fullOriginalFireGuard=true twinsRollbackRetry=true physicalBothTwinsEscort=true originalAyanFound7=true realFullLosePose=true characterStoryTwoDiary7=true originalRecovery8=true dataRollbackBeforeVisual=true actualDataStream=true rewardsOnce=true modelsUnchanged=true suppliesPreserved=true"
 end,debug.traceback)
 evidence.status=ok and 'PASS'or'FAIL';evidence.detail=ok and result or nil;evidence.error=not ok and tostring(result)or nil;save();print('LSD_FRESH_RUINS_CURRENT_'..evidence.status)
end)
