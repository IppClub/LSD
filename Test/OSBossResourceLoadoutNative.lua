-- Earned energy journey branch, physical public route, no HP/unlock/model injection.
local entry,qaResultName=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'os-boss-resource-loadout-result.json')
local r={status='RUNNING',osInput=true,scope='scripted-public-route/loadout setup; actual CUA start/combat/result-return only',stages={},samples={},events={}}
local function save()
 local record=r
 if r.status=='RUNNING'and r.stage=='ACTUAL_OS_BOSS_COMBAT'then
  -- Live observation needs the latest state, not a rewrite of every prior
  -- frame/key. Keep the full history in memory and persist it at settlement,
  -- return, or failure; never change simulation or truncate final evidence.
  record={}
  for key,value in pairs(r)do if key~='samples'and key~='events'then record[key]=value end end
  record.liveHistoryOmitted=true;record.sampleCount=#r.samples;record.eventCount=#r.events
 end
 D.Content:save(out,D.json.encode(record,false,true))
end
save()
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
  local mentorAmmo=tonumber(os.getenv('LSD_QA_BOSS_MENTOR_AMMO') or '140')
  assert(mentorAmmo and mentorAmmo%1==0 and mentorAmmo>=20 and mentorAmmo<=140,'Invalid public loadout quantity')
  local quantities={mentorAmmo,2,2,60}
  local defaultLoadout=os.getenv('LSD_QA_BOSS_DEFAULT_LOADOUT')=='1'
  local balancedLoadout=os.getenv('LSD_QA_BOSS_BALANCED_LOADOUT')=='1'
  assert(not (defaultLoadout and balancedLoadout),'Choose one public loadout')
  if balancedLoadout then quantities={100,10,2,36};r.balancedPublicLoadout=true end
  if defaultLoadout then
   quantities={}
   for i,slot in ipairs(require('Economy.Loadout').slots)do quantities[i]=slot.default end
   r.originalDefaultLoadout=true
  end
  -- Change carrying quantities through the original UI; retain real cost/misses.
  for i,target in ipairs(quantities)do
   local slot=require('Economy.Loadout').slots[i];local key=slot.actor..':'..slot.item
   while panel.values[key]~=target do panel.buttons[i][panel.values[key]<target and 1 or -1]:emit('Tapped')end
  end
  assert(panel.quote.total==((defaultLoadout or balancedLoadout) and 293 or 85+2*mentorAmmo))
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
  r.stage='READY_FOR_OS_START';save()
  r.defaultAppBootstrap=false;r.fullGameComplete=false;r.setupScripted=true;r.combatScripted=false
  -- Read-only keyboard observer; handler order is not a firing-rejection proof.
  local function firingState()
   return {aimAvailable=b.mentorAim.canStart(),aimHeld=b.mentorAim.held,
    mentorClip=b.mentor.playable.current,onSurface=b.mentor.onSurface,
    displacementBlocked=require('Combat.Displacement').blocked(b.mentor),
    shotPlaying=b.mentor:isDoing('groundMentorShot'),
    shotCooldown=math.max(0,b.nextMentorShot-D.App.runningTime),
    weaponDisarmed=b.mentor.data.weaponDisarmed==true,
    mentorX=b.mentor.x,niniX=b.arena.student.x,wuyunX=b.wuyun.student.x,
    machineX=support.x,bossX=b.enemies[1].enemy.x}
  end
  local node=D.Node();node.keyboardEnabled=true;node:addTo(D.Director.ui)
  for _,kind in ipairs({'KeyDown','KeyUp'})do node:slot(kind,function(key)
   r.events[#r.events+1]={kind=kind,key=key,at=D.App.runningTime,phase=b.phase,
    observerSnapshot=true,firingState=firingState()};save()
  end)end
  wait(function()return b.phase=='playing'end,300)
  r.stage='ACTUAL_OS_BOSS_COMBAT';save()
  local deadline=D.App.runningTime+300;local lastSaved=0
  while b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Actual OS Boss combat timed out')
   local enemy=b.enemies[1];local aim=b.mentorAim
   r.samples[#r.samples+1]={visibleWarning=require('Ground.BigYingzhaoLevel').supportWarningText(b),at=D.App.runningTime,phase=b.phase,mentorX=b.mentor.x,niniX=b.arena.student.x,wuyunX=b.wuyun.student.x,machineX=support.x,mentorHP=b.mentorHP,niniHP=b.arena.studentHP,wuyunHP=b.wuyun.studentHP,machineHP=support.machineHP,gold=support.gold,bossHP=enemy.enemyHP,bossX=enemy.enemy.x,bossClip=enemy.enemy.playable.current,bossFaceRight=enemy.enemy.faceRight,keyA=D.Keyboard:isKeyPressed('A'),keyD=D.Keyboard:isKeyPressed('D'),keyJ=D.Keyboard:isKeyPressed('J'),keyG=D.Keyboard:isKeyPressed('G'),aimHeld=aim.held,aimVisible=aim.line.visible,aimAngle=aim.angle,aimAvailable=aim.canStart(),mentorClip=b.mentor.playable.current,onSurface=b.mentor.onSurface,displacementBlocked=require('Combat.Displacement').blocked(b.mentor),shotPlaying=b.mentor:isDoing('groundMentorShot'),shotCooldown=math.max(0,b.nextMentorShot-D.App.runningTime),weaponDisarmed=b.mentor.data.weaponDisarmed==true,gathering=b:gatherActive(),gatherMode=b.gatherMode}
   r.current=r.samples[#r.samples]
   if D.App.runningTime-lastSaved>=1 then lastSaved=D.App.runningTime;save()end
   D.sleep(.05)
  end
  wait(function()return level.phase=='result'end,30)
  assert(b.report and not E.active()and(level.result.resultLayout=='Settlement'or level.result.resultLayout=='MissionFail'))
  r.battle=b.report;r.outcome=b.report.status;r.naturalVictory=r.outcome=='won';r.supportAfter=b.report.auxiliary;r.trace=b.bossTrace;r.vitals=b.bossTrace.vitals;r.balanceAfter=E.wallet().available
  assert(r.outcome=='won'or r.outcome=='failed','Unexpected real combat outcome')
  assert(r.balanceAfter==r.balanceBefore+(r.recoveryIncome or 0)+b.report.economy.net)
  assert(models()==original and equal(originalAdoptions,{ninilite=adoption.state('ninilite'),wuyun=adoption.state('wuyun')}),'Actual input changed adoption')
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));local episode=assert(require('Training.CombatStore').load(attempt));assert(episode.boss.status==r.outcome)
  r.episodeSaved=true;r.sameJourneyBranch=true;r.modelsUnchanged=true;r.stage='READY_FOR_OS_RESULT_RETURN'
  local kineticUsed=b.report.economy.lines[1].used;local shots=0
  for _,step in ipairs(b.bossTrace.steps)do if step.actor=='mentor'and step.action=='shoot'then shots=shots+(step.emitted or 0)end end
  r.mentorShots=shots;r.actualKineticUses=kineticUsed
  local jdown,jup
  for i,e in ipairs(r.events)do if e.kind=='KeyDown'and e.key=='J'and e.phase=='playing'then
   for n=i+1,#r.events do local up=r.events[n];if up.kind=='KeyUp'and up.key=='J'and up.phase=='playing'then jdown=e;jup=up;break end end
   if jup then break end
  end end
  assert(jdown and jup and kineticUsed>0,'No real combat key/release/paid firing')
  r.actualCombatKeys=true;r.resultScreenshot=D.Path(D.Content.writablePath,'actual-os-boss-result.tga');D.App:saveScreenshot(r.resultScreenshot);save()
  wait(function()return world()~=b.world and world().tag=='TrainA'end,300)
  r.returnedToTrain=true;node:removeFromParent();r.stage='ACTUAL_OS_BOSS_RETURNED';save()
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
