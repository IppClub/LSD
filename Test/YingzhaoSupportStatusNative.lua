-- Actual earned branch, ordinary preparation/buttons; no HP/gold/story injection.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-support-status-result.json'
local r={status='RUNNING',osInput=false,screenshots={},checks={}};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32)
  local currentJourney=os.getenv('LSD_QA_CURRENT_JOURNEY_SUPPORT')=='1'
  if currentJourney then
   assert(prior.database and prior.sameJourneyBranch and prior.episodeSaved and prior.returnedToTrain and prior.outcome=='failed')
  else assert(prior.database and prior.checks.naturalFormalReportAndLedger and prior.outcome=='failed')end
  local db=D.Content.writablePath..'/yingzhao-support-status-'..os.time()..'.db';r.database=db;r.parentEvidence=parent
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync();save()
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Support status route timed out');D.sleep(.02)end end
  local E=require('Economy.Store');assert(E.open());local initial=E.wallet().available
  local function models()return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0YingzhaoAdoptionState ORDER BY actor')},false,true)end
  local originalModels=currentJourney and models()
  require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=4650,energySquad=true})
  local gate=assert(D.Platformer.Data.store.world.disarmGate);wait(function()return gate.menu.visible and gate.menu.menu.enabled end)
  gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end);local supply=gate.supplyPanel
  for i,key in ipairs({'mentor:kinetic','ninilite:emp','wuyun:emp','wuyun:blade'})do
   while supply.values[key]>3 do local amount=supply.values[key]-3>=5 and -5 or -1;supply.buttons[i][amount]:emit('Tapped')end
  end
  assert(supply.quote.total<=initial);supply.saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel end)
  local level=D.Platformer.Data.store.world.patrolLevel;local b=level.battle;D.sleep(.2)
  assert(b.support and b.support.gold>0 and b.support.machineHP==100)
  local function check()
   local expected=string.format('辅助机 %.0f / 100 · 金粉 %.1f · 维生场%s',b.support.machineHP,b.support.gold,b.support.active and '运行'or'停机')
   assert(level.status.text:find(expected,1,true),'Support values differ from actual state')
   assert(level.hud.aimHint.node.parent==level.hud and level.hud.aimHint.node.visible)
   assert(b.bossCombat.view.node.parent==level.controls and not b.bossCombat.view.closed)
   if os.getenv('LSD_QA_REQUIRE_BOSS_FRAME')=='1'then
    assert(b.cameraFrame and b.cameraFrame.extendedSky,'Original far sky not extended')
    assert(b.bossCombat.view.node.y-64>=D.App.bufferSize.height-level.headerHeight,'Armor panel covers combat viewport')
   end
  end
  local function shot(name)
   b.bossCombat:sample();local bounds={minX=math.huge,minY=math.huge,maxX=-math.huge,maxY=-math.huge}
   local head={minX=math.huge,minY=math.huge,maxX=-math.huge,maxY=-math.huge}
   for _,part in ipairs(b.bossCombat.armor.target.regions)do
    for _,v in ipairs(part.vertices)do
     for _,box in ipairs(part.id=='head'and{bounds,head}or{bounds})do
      box.minX=math.min(box.minX,v.x);box.maxX=math.max(box.maxX,v.x);box.minY=math.min(box.minY,v.y);box.maxY=math.max(box.maxY,v.y)
     end
    end
   end
   local projected={};local count=0
   for _,point in ipairs({{head.minX,head.minY},{head.maxX,head.maxY},{bounds.minX,bounds.minY},{bounds.maxX,bounds.maxY}})do
    local index=#projected+1;projected[index]={}
    b.world:convertToWindowSpace(D.Vec2(point[1],point[2]),function(p)projected[index]={x=p.x,y=p.y};count=count+1 end)
   end
   wait(function()return count==4 end)
   if os.getenv('LSD_QA_REQUIRE_BOSS_FRAME')=='1'then
    local ratio=D.App.bufferSize.height/D.App.winSize.height
    for i=1,2 do
     assert(projected[i].y*ratio>=level.headerHeight+8,'Boss head hidden above HUD')
     assert(projected[i].y*ratio<=D.App.bufferSize.height-80,'Boss head below viewport')
     assert(projected[i].x*ratio>=16 and projected[i].x*ratio<=D.App.bufferSize.width-16,'Boss head outside horizontal viewport')
    end
    assert(b.bossCombat.boss.enemy.unitDef.scale==1 and b.bossCombat.boss.enemy.unitDef.size.width==300 and b.bossCombat.boss.enemy.unitDef.size.height==500,'Boss authored size changed')
   end
   r.cameraSamples=r.cameraSamples or {};r.cameraSamples[#r.cameraSamples+1]={name=name,bounds=bounds,head=head,projected=projected,zoom=b.world.camera.zoom,cameraY=b.world.camera.position.y,headerHeight=level.headerHeight,modelScale=b.bossCombat.boss.enemy.unitDef.scale,buffer={width=D.App.bufferSize.width,height=D.App.bufferSize.height},window={width=D.App.winSize.width,height=D.App.winSize.height}}
   local p=D.Path(D.Content.writablePath,'yingzhao-support-'..name..'.tga');D.App:saveScreenshot(p);D.sleep(.1)
   if os.getenv('LSD_QA_BOSS_MARKER_READABILITY')=='1'then
    if level.supportWarning.visible then assert(level.supportWarning.y-level.supportWarning.height>=D.App.bufferSize.height-level.headerHeight+15,'Warning falls outside header background')end
    local m=assert(level.playerMarker,'Boss has no player marker');wait(function()return m.projection and D.App.runningTime-m.projection.at<.1 end)
    assert(not m.closed and m.node.visible and m.owner==b.mentor and math.abs(m.hpBar.scaleX-b.mentorHP/100)<.001,'Boss marker does not identify live mentor')
    r.markerSamples=r.markerSamples or {};r.markerSamples[#r.markerSamples+1]={name=name,x=m.node.x,y=m.node.y,hp=m.hpBar.scaleX,projection=m.projection}
   end
   r.screenshots[#r.screenshots+1]={name=name,path=p,width=D.App.bufferSize.width,height=D.App.bufferSize.height,status=level.status.text}
  end
  local original=D.App.winSize
  for _,size in ipairs({{960,540,'1920'},{683,384,'1366'}})do
   D.App.winSize=D.Size(size[1],size[2]);D.sleep(.3);check();shot(size[3]..'-ready')
  end
  level.start:emit('Tapped');wait(function()return b.phase=='playing'end);D.sleep(.3)
  if os.getenv('LSD_QA_BOSS_MARKER_READABILITY')=='1'then
   local shield=require('Ground.PhysicalShield')
   level.hud.move:emit('Left',true)
   wait(function()return shield.project(shield.observe(b.physicalShield,b.mentor.x,b.mentor.y-b.world.offset)).shieldState=='outside'or b.phase~='playing'end,8)
   level.hud.move:emit('Left',false);D.sleep(.05)
   assert(b.phase=='playing'and level.supportWarning.visible and level.supportWarning.text:find('导师在护盾外',1,true),'Actual mentor outside coverage cue missing')
   r.outsideCoverage={ownX=b.mentor.x,machineX=b.support.x,ownY=b.mentor.y-b.world.offset,radius=shield.rules.radius,text=level.supportWarning.text,charge=b.physicalShield.charge}
   assert(math.abs(r.outsideCoverage.ownX-r.outsideCoverage.machineX)>shield.rules.radius and b.physicalShield.charge>0)
   shot('1366-mentor-outside-shield')
  end
  if os.getenv('LSD_QA_ACTIVE_SUMMON_SHUTDOWN')=='1'then
   wait(function()
    for _,child in ipairs(b.bossCombat.boss.guard.hunt.children)do if child.guard.sequence.status=='playing'then r.activeSummonAtShutdown={skill=child.guard.strike.skill,status=child.guard.sequence.status};return true end end
   end,20)
   r.checks={actualEarnedBranch=true,normalPreparation=true,activeSummonAtShutdown=true};return
  end
  if os.getenv('LSD_QA_SUPPORT_FORMATION_WARNING')=='1'then
   local initialGold=b.support.gold
   level.hud.move:emit('Left',true)
   wait(function()return b.support.span>require('Ground.PhysicalShield').rules.radius*2 or b.phase~='playing'end,8)
   level.hud.move:emit('Left',false);D.sleep(.05)
   assert(b.phase=='playing' and level.status.text:find('队伍分散，G集合节省金粉',1,true),'Actual formation warning missing')
   local energy=b.support:energyObservation()
   assert(energy.rate>.83 and energy.powered and b.support.gold<initialGold,'Warning lacks actual separation/energy use')
   r.formationWarning={span=energy.span,rate=energy.rate,upkeepOnlySeconds=energy.seconds,gold=b.support.gold,text=level.status.text}
  end
  for _,size in ipairs({{960,540,'1920'},{683,384,'1366'}})do
   D.App.winSize=D.Size(size[1],size[2]);D.sleep(.3);check();shot(size[3]..'-playing')
  end
  if os.getenv('LSD_QA_REQUIRE_BOSS_FRAME')=='1'then
   local ammo=b.supplies:observation('mentor').ammo.kinetic
   r.aimInterruptions=0;local precision=false;local stop=D.App.runningTime+15
   while not precision do
    assert(D.App.runningTime<stop and b.phase=='playing','No normal precision opportunity before timeout')
    wait(function()return b.mentorAim.canStart()or b.phase~='playing'end,10)
    assert(b.phase=='playing');level.hud.weapon:emit('TapBegan');D.sleep(1.2)
    precision=b.mentorAim.held and level.hud.aimHint.phase=='precision'
    if not precision then r.aimInterruptions=r.aimInterruptions+1;D.emit('Skill.Ended',true);D.sleep(.05)end
   end
   check();shot('1366-precision-visible')
   D.emit('Skill.Ended',true);D.sleep(.15)
   assert(not b.mentorAim.held and b.supplies:observation('mentor').ammo.kinetic==ammo,'Camera UI cancellation spent mentor ammo')
   level.hud.move:emit('Left',true);D.sleep(.6);level.hud.move:emit('Left',false);D.sleep(.2)
   check();shot('1366-after-backstep');r.framingAndAimCancellation=true
  end
  if os.getenv('LSD_QA_SUPPORT_DANGER_WARNING')=='1'then
   wait(function()return b.support.machineHP<=70 or b.phase~='playing'end,90)
   assert(b.phase=='playing' and b.support.machineHP>0,'Machine fell before damage-warning observation')
   local warnings={}
   for _,size in ipairs({{960,540,'1920'},{683,384,'1366'}})do
    D.App.winSize=D.Size(size[1],size[2]);D.sleep(.2)
    assert(b.phase=='playing','Damage warning did not leave a playable protection window')
    local expected=b.support:warningText();assert(level.supportWarning.visible and level.supportWarning.text==expected,'Actual damaged-machine warning missing')
    assert(expected:find('机体',1,true),'Warning hid actual machine damage')
    warnings[#warnings+1]={machineHP=b.support.machineHP,gold=b.support.gold,shield=b.physicalShield.charge,text=expected}
    check();shot(size[3]..'-machine-damaged')
   end
   r.damageWarnings=warnings;r.naturalMachineDamage=true
  end
  local extra=tonumber(os.getenv('LSD_QA_SUPPORT_WAIT')or '0')
  if extra>0 then
   D.sleep(extra);assert(b.phase=='playing','Extended normal observation lost party before withdrawal')
   local partial=0
   for _,e in ipairs(b.physicalShield.events)do if e.kind=='impact'and e.absorbed>0 and e.remaining>0 then partial=partial+1 end end
   r.extendedObservation={seconds=extra,partialImpacts=partial,hp=b.mentorHP,gold=b.support.gold,charge=b.physicalShield.charge}
   r.extendedObservation.requiresPartial=os.getenv('LSD_QA_REQUIRE_PARTIAL_IMPACT')~='0'
   if r.extendedObservation.requiresPartial then assert(partial>0,'Extended normal encounter did not exercise partial protection')end;save()
  end
  level.withdraw:emit('Tapped');wait(function()return level.phase=='result'or level.phase=='save-error'end,45)
  assert(level.phase=='result'and level.result.resultLayout=='MissionFail')
  if os.getenv('LSD_QA_BOSS_MARKER_READABILITY')=='1'then assert(level.playerMarker.closed,'Boss player marker retained at result');r.playerMarkerClosed=true end
  assert(b.report.economy.income==0 and E.wallet().available==initial-b.report.economy.cost and not E.active())
  if os.getenv('LSD_QA_FLIGHT_READBACK')=='1'then
   local id=assert(tonumber(b.bossTrace.resources.attempt:match('^mission:(%d+)$')))
   local episode,why=require('Training.CombatStore').load(id);assert(episode,why)
   assert(episode.boss.flightVersion==1 and #episode.boss.flights>0 and require('Training.FlowerIdentity').equal(episode.boss.flights,D.json.decode(D.json.encode(b.bossTrace.flights,false,true),32)),'Saved flights differ')
   local summary=require('Training.YingzhaoContributions').summarize(episode.boss)
   assert(summary.actors.mentor.flights and require('Training.YingzhaoContributions').text(episode.boss):find('射弹记录',1,true))
   r.flightReadback={count=#episode.boss.flights,validated=true,contributions=summary.actors}
  end
  r.cost=b.report.economy.cost;r.balanceAfter=E.wallet().available;r.checks={actualEarnedBranch=true,normalPreparation=true,actualSupportValues=true,bothSizes=true,originalControlsAndArmor=true,withdrawalLedger=true}
  level.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world end);D.App.winSize=original;D.sleep(.2)
  if currentJourney then assert(models()==originalModels,'Support warning changed models or adoption');r.modelsUnchanged=true;r.currentJourneySource=true end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
