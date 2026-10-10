-- Earned energy journey branch, physical public route, no HP/unlock/model injection.
local entry,qaResultName=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'native-boss-input-observation-result.json')
local r={status='RUNNING',osInput=true,scope='actual-J-hold-release-only; public-route-and-start-use-engine-events',stages={},samples={},events={}};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or root..'/Test/fresh-disarm-current-result.json'),32)
  local exploratory=os.getenv('LSD_QA_EXPLORATORY_ADOPTED_CHECKPOINT')=='1'
  local source=prior.database
  if exploratory then
   assert(prior.status=='PASS'and prior.exploratoryDeployment and prior.publicRollbackVerified and prior.protectedStateUnchanged and prior.stableBenefitProven==false)
   source=assert(prior.adoptedCheckpoint)
   assert(source:match('^/private/tmp/lsd%-combat%-qa%-.+/save/current%-tactical%-adopted%-checkpoint%-%d+%.db$'))
   assert(prior.model.characterId=='ninilite'and prior.model.sampleCount==12)
   r.exploratoryDeployment=true;r.stableBenefitProven=false;r.parentEvidence=os.getenv('LSD_QA_PARENT_RESULT')
  else
   assert(prior.sameJourneyBranch and (prior.status=='PASS' or prior.status=='FAIL') and (source:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-disarm%-current%-%d+%.db$')or source:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-big%-yingzhao%-current%-%d+%.db$')))
   if prior.status=='FAIL'then assert(prior.outcome=='failed' and prior.episodeSaved)end
  end
  local db=D.Content.writablePath..'/fresh-big-yingzhao-current-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  r.database=db;r.source=source
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available;assert(r.balanceBefore==prior.balanceAfter)
  local S=assert(require('Mission.Service').open());assert(S:summary().unlocks['yingzhao-route-cleared'])
  local function models()return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local original=models()
  local adoption=require('Training.YingzhaoAdoptionStore');local equal=require('Training.FlowerIdentity').equal
  local originalAdoptions={ninilite=adoption.state('ninilite'),wuyun=adoption.state('wuyun')}
  if exploratory then
   local saved=assert(adoption.loadAsync('ninilite',assert(require('Training.FlowerPractice').models()),'mission'))
   assert(saved.id==prior.active and equal(saved.proof.candidate.model,prior.model))
   assert(originalAdoptions.wuyun.current==0)
  end
  local function stage(name)r.stage=name;r.stages[#r.stages+1]={name=name,at=D.App.runningTime,balance=E.wallet().available};save()end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Disarm journey stalled at '..tostring(r.stage));D.sleep(.02)end end
  local function world()return D.Platformer.Data.store.world end
  local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world()end)end
  local function hud()local h;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then h=n end end);return assert(h)end
  local function move(x)local p=player();local h=hud();local side=p.unit.x<x and 'Right'or'Left';h.move:emit(side,true);wait(function()return math.abs(p.unit.x-x)<35 end,45);h.move:emit(side,false);D.sleep(.3)end
  local function door(side,target)
   local old=world();move(side=='left'and 120 or side=='right'and old.sceneWidth-120 or old.center.x)
   local p=player();local index;for i=1,p.moveTargets.count do if p.moveTargets:get(i)==target then index=i end end
   assert(index and p.interaction.menu.enabled,'Missing public route '..target);p.interaction:emit('Tapped',index)
   wait(function()return world()~=old and world().tag==target end);D.sleep(.3);stage(target)
  end
  require('Start');wait(function()return world()and world().tag=='PreparationRoom'and player()and not player().busy end);stage('resumed')
  door('left','PassageA');door('center','PassageC');door('left','Station')
  move(world().sceneWidth-1800);world():getChildByTag('boardingTerminal'):emit('Tapped',1)
  wait(function()return world().tag=='TrainA'end);move(world().sceneWidth-170)
  world():getChildByTag('groundDeploymentTerminal'):emit('Tapped',1);wait(function()return world().groundDeployment end)
  local deployment=world().groundDeployment;assert(deployment.team and deployment.view.secondCard)
  if not deployment.formation.wuyun then deployment.view.secondCard.children.first:emit('Tapped');wait(function()return deployment.formation.wuyun end)end
  deployment.view.startButton:emit('Tapped');wait(function()return world().tag=='AbandonedCity'and world().energySquad and world().disarmGate end)
  move(4650);local gate=world().disarmGate;wait(function()return gate.menu.visible and gate.menu.menu.enabled end);stage('public-disarm-site')
  local expeditionSupport=assert(world().groundExpedition.support)
  gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end)
  local panel=gate.supplyPanel
  local previewRay=os.getenv('LSD_QA_BOSS_PREVIEW_RAY_RELEASE')=='1'
  local manualAim=os.getenv('LSD_QA_BOSS_MANUAL_PREVIEW_AIM')=='1'
  local safeFlank=os.getenv('LSD_QA_BOSS_SAFE_FLANK')=='1'
  local proactiveFlank=os.getenv('LSD_QA_BOSS_PROACTIVE_FLANK')=='1'
  local machineWaveLead=os.getenv('LSD_QA_BOSS_MACHINE_WAVE_LEAD')=='1'
  local closeCross=os.getenv('LSD_QA_BOSS_CLOSE_RECOVERY_CROSS')=='1'
  local recoveryOutput=os.getenv('LSD_QA_BOSS_RECOVERY_OUTPUT')=='1'
  assert(not recoveryOutput or not closeCross and not machineWaveLead,'Recovery output is a distinct operation comparison')
  assert(not closeCross or proactiveFlank and safeFlank,'Close recovery crossing requires visible committed flank control')
  assert(not closeCross or not machineWaveLead,'Close recovery crossing is a distinct operation comparison')
  assert(not proactiveFlank or safeFlank,'Proactive flank requires visible recovery timing')
  local travelPriority=os.getenv('LSD_QA_BOSS_TRAVEL_PRIORITY')=='1'
  local machineProtection=os.getenv('LSD_QA_BOSS_MACHINE_PROTECTION')=='1'
  local coverControl=os.getenv('LSD_QA_BOSS_REINFORCEMENT_COVER')=='1'
  local waveControl=os.getenv('LSD_QA_BOSS_WAVE_CONTROL')=='1'
  local formationControl=waveControl or os.getenv('LSD_QA_BOSS_FORMATION_CONTROL')=='1'
  local visibleProtection=formationControl or os.getenv('LSD_QA_BOSS_VISIBLE_PROTECTION')=='1'
  local outputLoadout=os.getenv('LSD_QA_BOSS_OUTPUT_LOADOUT')=='1'
  local quantities=outputLoadout and {140,12,2,60}or {60,24,6,40}
  -- Change carrying quantities through the original UI; retain real cost/misses.
  for i,target in ipairs(quantities)do
   local slot=require('Economy.Loadout').slots[i];local key=slot.actor..':'..slot.item
   while panel.values[key]~=target do panel.buttons[i][panel.values[key]<target and 1 or -1]:emit('Tapped')end
  end
  assert(panel.quote.total==(outputLoadout and 405 or 289))
  if panel.quote.total>E.wallet().available then
   panel.saveButton:emit('Tapped');wait(function()return not panel.saving end);assert(not E.active(),'Insufficient budget started a Boss attempt')
   panel.recoveryButton:emit('Tapped');local v=assert(panel.recoveryPanel);local before=E.wallet().available
   while E.wallet().available<panel.quote.total do
    local state=v.state;assert(state.eligible,'Recovery ceiling cannot fund loadout')
    v.buttons[require('Economy.Recovery').tasks[state.stage+1].item]:emit('Tapped')
    wait(function()return not v.busy and (v.state.stage~=state.stage or v.state.round~=state.round)end)
   end
   r.recoveryIncome=E.wallet().available-before;v.backButton:emit('Tapped');assert(panel.visible)
  end
  assert(panel.quote.total<=E.wallet().available);r.budget=panel.quote.total;r.loadout=panel.quote;save();panel.saveButton:emit('Tapped')
  wait(function()return world().patrolLevel end);local level=world().patrolLevel;local b=level.battle
  assert(b.bossCombat and not b.supplies.isVirtual and not b.yingzhaoDemonstration)
  if exploratory then
   local deployed=assert(b.yingzhaoDeployments.ninilite)
   assert(deployed.status=='adopted'and deployed.id==prior.active and equal(b.yingzhaoCandidates.ninilite,prior.model))
   assert(b.yingzhaoDeployments.wuyun.status=='NOT_ADOPTED')
   r.readyDeployment=deployed;save()
  end
  local support=expeditionSupport
  assert(b.support==support and b.machine and b.supportView.actor.variant==support.variant)
  assert(b.supportView.machine.order<b.mentor.order and b.supportView.machine.order<b.arena.student.order and b.supportView.machine.order<b.wuyun.student.order)
  local goldBefore=support.gold;D.sleep(.6);assert(support.gold==goldBefore,'Ready battle drained support')
  r.supportBefore={gold=support.gold,machineHP=support.machineHP,spent=support.spent};D.App:saveScreenshot(root..'/Test/boss-support-ready.tga');D.sleep(.2);stage('formal-boss-ready')
  local directory=assert(os.getenv('LSD_QA_OS_OBSERVATION_DIRECTORY'))
  assert(directory:match('^/private/tmp/lsd%-os%-boss%-input%-'))
  r.stage='READY_FOR_OS_START';save()
  assert(D.Content:save(directory..'/prepared.json',D.json.encode({status='READY',stage=r.stage},false,true)))
  wait(function()return b.phase=='playing'end,120)
  local node=D.Node();node.keyboardEnabled=true;node:addTo(D.Director.ui3D)
  local function emitted()
   local count=0;for _,step in ipairs(b.bossTrace.steps)do if step.actor=='mentor'and step.action=='shoot'then count=count+(step.emitted or 0)end end;return count
  end
  for _,event in ipairs({'KeyDown','KeyUp'})do node:slot(event,function(key)
   if key=='J'and b.phase=='playing'then r.events[#r.events+1]={event=event,key=key,at=D.App.runningTime,angle=b.mentorAim.angle,held=b.mentorAim.held,emitted=emitted()}end
  end)end
  r.stage='READY_FOR_OS_AIM';r.initialMentorEmitted=emitted();save()
  assert(D.Content:save(directory..'/ready.json',D.json.encode({status='READY',stage=r.stage},false,true)))
  local deadline=D.App.runningTime+90
  while not D.Content:exist(directory..'/done.json')do
   assert(b.phase=='playing','Battle ended before manual aim observation')
   assert(D.App.runningTime<deadline,'OS aim driver did not complete')
   r.samples[#r.samples+1]={at=D.App.runningTime,keyJ=D.Keyboard:isKeyPressed('J'),held=b.mentorAim.held,precision=b.mentorAim.precision,angle=b.mentorAim.angle,lineVisible=b.mentorAim.line.visible,emitted=emitted(),canStart=b.mentorAim.canStart(),mentorX=b.mentor.x,mentorHP=b.mentorHP}
   D.sleep(.02)
  end
  wait(function()return not b.mentorAim.shot and not b.mentor:isDoing('groundMentorShot')end,8)
  local down,up
  for _,event in ipairs(r.events)do if event.event=='KeyDown'and not down then down=event elseif event.event=='KeyUp'and down then up=event;break end end
  assert(down and up and up.at-down.at>=1.5,'No actual sustained J interval')
  local held,precise=0,0;local first,last
  for _,sample in ipairs(r.samples)do
   if sample.at>=down.at+.1 and sample.at<=up.at-.1 then
    assert(sample.keyJ and sample.held and sample.lineVisible,'Held key/preview did not stay active')
    assert(sample.emitted==r.initialMentorEmitted,'Shot emitted before release')
    held=held+1
    if sample.precision then precise=precise+1;first=first or sample;last=sample end
   end
  end
  assert(held>20 and precise>10 and first and last and math.abs(last.angle-first.angle)>10,'No measured slow precision sweep')
  assert(emitted()==r.initialMentorEmitted+1,'Release did not emit exactly one real mentor shot')
  assert(not b.mentorAim.held and not b.mentorAim.line.visible,'Release did not hide preview')
  r.actualHeldSeconds=up.at-down.at;r.heldSamples=held;r.precisionSamples=precise;r.precisionTravel={seconds=last.at-first.at,degrees=last.angle-first.angle};r.mentorEmitted=emitted();r.releaseShotVerified=true
  D.App:saveScreenshot(directory..'/after-aim.tga');D.sleep(.2);node:removeFromParent();save()
  -- Close the paid attempt through the original withdraw/settlement UI.
  level.withdraw:emit('Tapped');wait(function()return level.phase=='result'end,30)
  assert(not E.active()and b.report and level.result.resultLayout=='MissionFail')
  r.battle=b.report;r.balanceAfter=E.wallet().available;r.trace=b.bossTrace
  assert(models()==original,'Input observation changed basic models')
  assert(equal(originalAdoptions,{ninilite=adoption.state('ninilite'),wuyun=adoption.state('wuyun')}),'Input observation changed adoption')
  r.modelsUnchanged=true;r.outcome=b.report.status;r.naturalVictory=false
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
