-- Earned energy journey branch, physical public route, no HP/unlock/model injection.
local entry,qaResultName=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'fresh-big-yingzhao-current-result.json')
local r={status='RUNNING',osInput=false,stages={}};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or root..'/Test/fresh-disarm-current-result.json'),32)
  local exploratory=os.getenv('LSD_QA_EXPLORATORY_ADOPTED_CHECKPOINT')=='1'
  local source=prior.database
  if exploratory then
   assert(prior.status=='PASS'and prior.exploratoryDeployment and prior.publicRollbackVerified and prior.protectedStateUnchanged and prior.stableBenefitProven==false)
   source=assert(prior.adoptedCheckpoint)
   assert(source:match('^/private/tmp/lsd%-combat%-qa%-.+/save/current%-tactical%-adopted%-checkpoint%-%d+%.db$'))
   assert(require('Training.YingzhaoPolicy').validate(prior.model,'ninilite'),'Invalid legally adopted candidate')
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
  local wholeRecovery=os.getenv('LSD_QA_BOSS_WHOLE_RECOVERY')=='1'
  assert(not wholeRecovery or safeFlank and proactiveFlank,'Whole recovery requires visible flank control')
  local machineWaveLead=os.getenv('LSD_QA_BOSS_MACHINE_WAVE_LEAD')=='1'
  local closeCross=os.getenv('LSD_QA_BOSS_CLOSE_RECOVERY_CROSS')=='1'
  local recoveryOutput=os.getenv('LSD_QA_BOSS_RECOVERY_OUTPUT')=='1'
  local boundedRecovery=os.getenv('LSD_QA_BOSS_BOUNDED_RECOVERY')=='1'
  local resourceRecovery=os.getenv('LSD_QA_BOSS_RESOURCE_RECOVERY')=='1'
  local arrivedRecoveryCast=os.getenv('LSD_QA_BOSS_ARRIVED_RECOVERY_CAST')=='1'
  assert(not boundedRecovery or wholeRecovery and recoveryOutput,'Bounded recovery requires the matching whole-party midrange operation')
  assert(not recoveryOutput or not closeCross and not machineWaveLead,'Recovery output is a distinct operation comparison')
  assert(not closeCross or proactiveFlank and safeFlank,'Close recovery crossing requires visible committed flank control')
  assert(not closeCross or not machineWaveLead,'Close recovery crossing is a distinct operation comparison')
  assert(not proactiveFlank or safeFlank,'Proactive flank requires visible recovery timing')
  local travelPriority=os.getenv('LSD_QA_BOSS_TRAVEL_PRIORITY')=='1'
  assert(not arrivedRecoveryCast or wholeRecovery and travelPriority,'Arrived casting requires matching whole-party transfer controls')
  local machineProtection=os.getenv('LSD_QA_BOSS_MACHINE_PROTECTION')=='1'
  local coverControl=os.getenv('LSD_QA_BOSS_REINFORCEMENT_COVER')=='1'
  local waveControl=os.getenv('LSD_QA_BOSS_WAVE_CONTROL')=='1'
  local formationControl=waveControl or os.getenv('LSD_QA_BOSS_FORMATION_CONTROL')=='1'
  local visibleProtection=formationControl or os.getenv('LSD_QA_BOSS_VISIBLE_PROTECTION')=='1'
  assert(not resourceRecovery or visibleProtection and not boundedRecovery,'Resource recovery is a distinct visible-protection operation')
  local outputLoadout=os.getenv('LSD_QA_BOSS_OUTPUT_LOADOUT')=='1'
  local balancedLoadout=os.getenv('LSD_QA_BOSS_BALANCED_LOADOUT')=='1'
  local compareTransfer=os.getenv('LSD_QA_BOSS_TRANSFER_COMPARISON')=='1'
  assert(not(balancedLoadout and outputLoadout),'Choose one public loadout')
  local quantities=outputLoadout and {140,12,2,60}or {60,24,6,40}
  if balancedLoadout then quantities={100,10,2,36};r.balancedPublicLoadout=true end
  -- Change carrying quantities through the original UI; retain real cost/misses.
  for i,target in ipairs(quantities)do
   local slot=require('Economy.Loadout').slots[i];local key=slot.actor..':'..slot.item
   while panel.values[key]~=target do panel.buttons[i][panel.values[key]<target and 1 or -1]:emit('Tapped')end
  end
  assert(panel.quote.total==(balancedLoadout and 293 or outputLoadout and 405 or 289))
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
  r.supportBefore={gold=support.gold,machineHP=support.machineHP,spent=support.spent};D.App:saveScreenshot(root..'/Test/boss-support-ready.tga');D.sleep(.2);stage('formal-boss-ready');level.start:emit('Tapped')
  if machineProtection then
   wait(function()return b.phase=='playing'end);D.sleep(.1)
   r.machineWarningChecks={screenshots={},scope='actual-formal-starting-position-not-victory'}
   local previous=D.App.winSize
   for _,size in ipairs({{960,540,'1920'},{683,384,'1366'}})do
    D.App.winSize=D.Size(size[1],size[2]);D.sleep(.15)
    local expected=require('Ground.BigYingzhaoLevel').supportWarningText(b)
    local label=assert(level.supportWarning)
    assert(expected:find('Boss正面',1,true)and label.text==expected and label.visible)
    assert(label.y-label.height>=level.controls.height-level.headerHeight,'Machine warning extends below header')
    local path=D.Path(D.Content.writablePath,'machine-front-warning-'..size[3]..'.tga');D.App:saveScreenshot(path);D.sleep(.05)
    r.machineWarningChecks.screenshots[#r.machineWarningChecks.screenshots+1]={path=path,text=label.text,machineHP=support.machineHP,width=D.App.bufferSize.width,height=D.App.bufferSize.height}
   end
   D.App.winSize=previous;D.sleep(.1);save()
  end
  local teamRecovery=visibleProtection or os.getenv('LSD_QA_TEAM_RECOVERY')=='1'
  local warningQA=os.getenv('LSD_QA_SUPPORT_WARNING_CAPTURE')=='1'
  r.warningChecks=warningQA and {scope='actual-support-display-not-victory',bossOriginalScale=b.bossCombat.boss.enemy.unitDef.scale,screenshots={}}or nil
  local originalSize=D.App.winSize
  local damageCaptured=false
  local frames,playingFrames={},0;local skipFramesUntil=D.App.runningTime+2
  if warningQA then
   local monitor=D.Node();monitor:addTo(level.controls)
   monitor:schedule(function(dt)
    if b.phase=='playing'then
     playingFrames=playingFrames+1
     if D.App.runningTime>=skipFramesUntil then frames[#frames+1]=dt end
    end
    return false
   end)
  end
  r.operationVariant=waveControl and 'visible-authored-wave-impact-aim-latched-flank-public-route-v3'or formationControl and 'visible-spread-aware-long-range-gather-public-route-v1'or visibleProtection and 'visible-melee-windup-recovery-output-budget-public-route-v1'or teamRecovery and 'visible-nearby-hold-recovery-public-route-v1' or 'original-public-boss-current'
  if travelPriority then r.operationVariant=r.operationVariant..'-gather-travel-before-cast-v1' end
  if machineProtection then r.operationVariant=r.operationVariant..'-proactive-machine-transfer-safe-cover-v1' end
  if coverControl then r.operationVariant=r.operationVariant..'-visible-reinforcement-cover-v1' end
  if safeFlank then r.operationVariant=r.operationVariant..'-visible-recovery-flank-reachable-escape-priority-v2' end
  if manualAim then r.operationVariant=r.operationVariant..'-original-manual-preview-muzzle-v1' end
  assert(not previewRay or manualAim,'Visible ray release requires original manual muzzle')
  if previewRay then r.operationVariant=r.operationVariant..'-visible-preview-ray-release-v1' end
  if closeCross then r.operationVariant=r.operationVariant..'-close-visible-recovery-cross-v1' end
  if recoveryOutput then r.operationVariant=r.operationVariant..'-midrange-visible-recovery-output-v1' end
  if wholeRecovery then r.operationVariant=r.operationVariant..'-whole-recovery-party-wave-cast-defer-v1' end
  if boundedRecovery then r.operationVariant=r.operationVariant..'-injury-only-recovery-public-cancel-v1' end
  if resourceRecovery then r.operationVariant=r.operationVariant..'-injury80-recovery85-public-cancel-v1' end
  r.boundedRecovery=boundedRecovery
  r.resourceRecovery=resourceRecovery
  r.arrivedRecoveryCast=arrivedRecoveryCast;r.arrivedRecoveryCastStarts={}
  if arrivedRecoveryCast then r.operationVariant=r.operationVariant..'-public-cast-after-individual-arrival-v1' end
  r.wholeRecovery=wholeRecovery
  r.previewRayRelease=previewRay
  r.manualPreviewAim=manualAim
  r.safeFlank=safeFlank
  r.proactiveFlank=proactiveFlank
  r.machineWaveLead=machineWaveLead
  r.closeRecoveryCross=closeCross
  r.recoveryOutput=recoveryOutput
  r.outputLoadout=outputLoadout
  local gatherHeldUntil
  local deadline=D.App.runningTime+210;local pilot={};local nextGather=0;local nextSample=0;r.controls={};r.positions={}
  local function control(kind,extra)if #r.controls<100 then r.controls[#r.controls+1]={kind=kind,at=D.App.runningTime-b.started,extra=extra}end end
  local function turnMove(direction)
   level.hud.move:emit('Right',direction==1);level.hud.move:emit('Left',direction==-1)
  end
  while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Natural formal Boss battle stalled')
   if b.phase=='playing'then
    if os.getenv('LSD_QA_BOSS_RECOVERY_WARNING_CAPTURE')=='1'then
     local expected=require('Ground.BigYingzhaoLevel').supportWarningText(b)
     for _,cue in ipairs({{'连斩正在推进','advancing'},{'收招，整队仍在正面','recovery'},{'连招尚未结束','follow-up'},{'队员处于波技能路径','party-wave'},{'Boss收招停顿','post-opening'}})do
      r.recoveryWarningScreenshots=r.recoveryWarningScreenshots or {}
      if expected:find(cue[1],1,true)and not r.recoveryWarningScreenshots[cue[2]]then
       local previous=D.App.winSize;local shots={}
       for _,size in ipairs({{960,540,'1920'},{683,384,'1366'}})do
        D.App.winSize=D.Size(size[1],size[2]);D.sleep(.05)
        local text,danger=require('Ground.BigYingzhaoLevel').supportWarningText(b);local label=assert(level.supportWarning)
        assert(label.visible and label.text==text,'Actual recovery warning label stale or hidden')
        assert(label.y-label.height>=level.controls.height-level.headerHeight,'Recovery warning below header')
        local path=D.Path(D.Content.writablePath,'boss-'..cue[2]..'-warning-'..size[3]..'.tga')
        D.App:saveScreenshot(path);D.sleep(.05)
        shots[#shots+1]={path=path,text=text,danger=danger,machineHP=support.machineHP,width=D.App.bufferSize.width,height=D.App.bufferSize.height}
       end
       D.App.winSize=previous;D.sleep(.05);r.recoveryWarningScreenshots[cue[2]]=shots;save()
      end
     end
    end
    if os.getenv('LSD_QA_BOSS_WAVE_WARNING_CAPTURE')=='1'and not r.waveWarningScreenshots then
     local text=require('Ground.BigYingzhaoLevel').supportWarningText(b)
     if text:find('波技能路径',1,true)then
      r.waveWarningScreenshots={};local previous=D.App.winSize
      for _,size in ipairs({{960,540,'1920'},{683,384,'1366'}})do
       D.App.winSize=D.Size(size[1],size[2]);D.sleep(.05)
       local current,red=require('Ground.BigYingzhaoLevel').supportWarningText(b)
       local label=assert(level.supportWarning)
       assert(current:find('波技能路径',1,true)and label.text==current and label.visible and red,'Actual wave warning not displayed')
       assert(label.y-label.height>=level.controls.height-level.headerHeight,'Wave warning clipped below header')
       local path=D.Path(D.Content.writablePath,'machine-wave-warning-'..size[3]..'.tga');D.App:saveScreenshot(path);D.sleep(.05)
       r.waveWarningScreenshots[#r.waveWarningScreenshots+1]={path=path,text=current,machineHP=support.machineHP,width=D.App.bufferSize.width,height=D.App.bufferSize.height}
      end
      D.App.winSize=previous;D.sleep(.05);save()
     end
    end
    if warningQA and support.machineHP>0 and support.machineHP<=70 and not damageCaptured then
     skipFramesUntil=D.App.runningTime+3
     for _,size in ipairs({{960,540,'1920'},{683,384,'1366'}})do
      D.App.winSize=D.Size(size[1],size[2]);D.sleep(.15)
      assert(b.phase=='playing','No playable damaged-machine warning window')
      local label=assert(level.supportWarning);local expected=require('Ground.BigYingzhaoLevel').supportWarningText(b)
      assert(label.visible and label.text==expected and expected:find('机体',1,true),'Damaged-machine warning missing')
      local supply=b.supplies:statusText():gsub(' · 已用成本 ','\n已用成本 ')
      assert(level.status.text:find(supply,1,true),'Cached HUD lost actual ammo/cost text')
      assert(label.y-label.height>=level.controls.height-level.headerHeight,'Warning extends below header')
      local path=D.Path(D.Content.writablePath,'boss-damage-warning-'..size[3]..'.tga');D.App:saveScreenshot(path);D.sleep(.05)
      r.warningChecks.screenshots[#r.warningChecks.screenshots+1]={path=path,machineHP=support.machineHP,gold=support.gold,text=label.text,width=D.App.bufferSize.width,height=D.App.bufferSize.height}
     end
     damageCaptured=true;save()
    end
    local boss=b.bossCombat.boss;local target=b:target(b.mentor)
    local visible=b.bossCombat.armor:available();local anchor=visible and boss or target
    if anchor then
     local dx=anchor.enemy.x-b.mentor.x;local minX,maxX=b.minX or 1200,b.maxX or 3300
     local near,far=visible and(machineProtection and 1100 or formationControl and 1500 or visibleProtection and 700 or teamRecovery and 600 or 1250)or 350,visible and(machineProtection and 1350 or formationControl and 1850 or visibleProtection and 1000 or teamRecovery and 850 or 1550)or 600
     if machineWaveLead and visible then near,far=1350,1550 end
     if closeCross and visible then near,far=500,750 end
     if recoveryOutput and visible then near,far=950,1150 end
     if pilot.flank and ((b.mentor.x-anchor.enemy.x)*pilot.flank>=near or (pilot.flank>0 and b.mentor.x>=maxX-50)or(pilot.flank<0 and b.mentor.x<=minX+50))then pilot.flank=nil end
     local bossTiming,bossWindow=require('Training.YingzhaoTiming').capture(boss.guard,visible,D.App.runningTime)
     local recoveryTail,recoveryReason
     if bossTiming then recoveryTail,recoveryReason=require('Training.YingzhaoTiming').recoveryTail(bossTiming,D.App.runningTime)end
     local crossingLowerBound=0
     local crossDirection=dx>0 and 1 or -1
     -- Best-case time merely to pass the current boss centre: omit body
     -- clearance, backstep, attack locks and boss movement. Never call safe.
     for _,role in ipairs({{b.mentor,270},{b.arena.student,240},{b.wuyun.student,240}})do
      if role[1].entity and (role[1]==b.mentor and b.mentorHP>0 or role[1]==b.arena.student and b.arena.studentHP>0 or role[1]==b.wuyun.student and b.wuyun.studentHP>0)then
       crossingLowerBound=math.max(crossingLowerBound,math.max(0,(boss.enemy.x-role[1].x)*crossDirection)/role[2])
      end
     end
     local mayFlank=not safeFlank or (wholeRecovery and recoveryTail~=nil and recoveryTail>=crossingLowerBound or not wholeRecovery and bossWindow=='recovery')
     -- Start crossing during the visible recovery before retreat reaches the edge.
     local edgeMargin=closeCross and maxX-minX or proactiveFlank and 600 or 80
     if mayFlank and visible and not pilot.flank and math.abs(dx)<(closeCross and near+300 or near) and ((dx>0 and b.mentor.x<=minX+edgeMargin)or(dx<0 and b.mentor.x>=maxX-edgeMargin))then
      pilot.flank=dx>0 and 1 or -1
      if proactiveFlank then r.proactiveFlankStarts=(r.proactiveFlankStarts or 0)+1 end
     end
     local escape=require('Enemy.GroundWave').escapeDirection(boss.guard,b.mentor,visible)
     local partyWaveEscape,partyWaveActors
     if wholeRecovery then
      partyWaveActors={}
      for _,t in ipairs(b:targets())do if t.hp()>0 then
       local direction=require('Enemy.GroundWave').escapeDirection(boss.guard,t.unit,visible)
       if direction then partyWaveEscape=partyWaveEscape or direction;partyWaveActors[#partyWaveActors+1]=t.unit.entity.name end
      end end
      if partyWaveEscape then escape=partyWaveEscape end
     end
     local earlyWave=false
     if not machineWaveLead and waveControl and visible and boss.enemy.playable.current=='wave'then
      local timing=require('Training.YingzhaoTiming').capture(boss.guard,true,D.App.runningTime)
      local stage=timing and require('Enemy.BigYingzhaoTimeline').stages(timing.skill)[timing.stage]
      local lead=stage and stage.impacts and stage.impacts[1]-(D.App.runningTime-timing.started)
      earlyWave=type(lead)=='number'and lead>1.3
      r.visibleWaveTimingChecks=(r.visibleWaveTimingChecks or 0)+1
      -- Present clip timing only; an early authored wave permits a shot before
      -- moving, while a live approaching front still owns the escape cue.
      local liveFront=false
      for _,wave in ipairs(boss.guard.waves)do
       if wave.active and wave.visual.parent and wave.visual.visible and (b.mentor.x-wave.x)*wave.direction>=-150 and math.abs(b.mentor.x-wave.x)<=600 then liveFront=true end
      end
      if earlyWave and not liveFront and not partyWaveEscape and(b.mentorAim.held or b.mentorAim.canStart()and D.App.runningTime>=(pilot.nextAim or 0))then
       escape=nil;r.earlyWaveAimWindows=(r.earlyWaveAimWindows or 0)+1
      end
     end
     -- Use the same authored visible telegraph/front against the machine body.
     local machineWaveEscape=machineWaveLead and require('Enemy.GroundWave').escapeDirection(boss.guard,b.machine,visible)
     if machineWaveEscape then escape=machineWaveEscape;r.machineWaveEscapeWindows=(r.machineWaveEscapeWindows or 0)+1 end
     local meleeCue=false
     if visibleProtection and visible and (not recoveryOutput or bossWindow~='recovery')then
      local clip=boss.enemy.playable.current;local face=boss.enemy.faceRight and 1 or -1
      local frontal=(b.mentor.x-boss.enemy.x)*face>=-100
      meleeCue=frontal and ((clip=='massive'and math.abs(dx)<=1000)or(clip=='punch'and math.abs(dx)<=600))
      if meleeCue then escape=face end
     end
     -- Latch visible close reinforcements until separated; this is a player
     -- input priority, not a learned label or hidden target lookup.
     local urgent=false;local nearby={}
     for _,enemy in ipairs(b.enemies)do
      if enemy~=boss and enemy.enemyHP>0 and enemy.enemy.visible and enemy.enemy.opacity>.1 then
       local nearest=math.huge
       for _,t in ipairs(b:targets())do if t.hp()>0 then nearest=math.min(nearest,math.abs(t.unit.x-enemy.enemy.x))end end
       if nearest<=(coverControl and 350 or 450)or coverControl and pilot.cover and pilot.cover[enemy]and nearest<=700 then nearby[enemy]=true;urgent=true end
      end
     end
     pilot.cover=nearby
     local coverAim=coverControl and urgent and require('Training.YingzhaoActions').plan(b,{student=b.mentor},'summon',manualAim)
     local closeFront=false
     for _,wave in ipairs(boss.guard.waves)do
      if wave.active and wave.visual.parent and wave.visual.visible and (b.mentor.x-wave.x)*wave.direction>=-150 and math.abs(b.mentor.x-wave.x)<=600 then closeFront=true end
     end
     local direction
     local escapeReachable=escape and (escape>0 and maxX-b.mentor.x or b.mentor.x-minX)>80
     if safeFlank and escape and not escapeReachable then
      r.unreachableEscapeWindows=(r.unreachableEscapeWindows or 0)+1
      if pilot.flank and mayFlank and not partyWaveEscape then escape=nil end
     end
     if proactiveFlank and pilot.flank and not closeFront and not partyWaveEscape then
      direction=pilot.flank
      r.committedFlankWindows=(r.committedFlankWindows or 0)+1
     elseif safeFlank and escape and escapeReachable then
      direction=escape;pilot.flank=nil
      r.flankEscapePriorityWindows=(r.flankEscapePriorityWindows or 0)+1
     elseif waveControl and pilot.flank then direction=pilot.flank
     elseif earlyWave and not escape and not pilot.flank then direction=nil
     elseif escape and (escape>0 and maxX-b.mentor.x or b.mentor.x-minX)>20 then direction=escape;pilot.flank=nil
     elseif pilot.flank then direction=pilot.flank
     elseif math.abs(dx)>far then direction=dx>0 and 1 or -1
     elseif math.abs(dx)<near then direction=dx>0 and -1 or 1 end
     if not machineWaveEscape and not pilot.flank and coverAim and (not machineProtection or math.abs(dx)>1000)and not meleeCue and not closeFront and (b.mentorAim.held or b.mentorAim.canStart()and D.App.runningTime>=(pilot.nextAim or 0))then
      direction=nil;r.reinforcementAimWindows=(r.reinforcementAimWindows or 0)+1
     end
     -- A target distance is advisory: make room for actual manual aim/release.
     -- Never keep pressing against an arena edge or cancel every held sweep.
     if direction and ((direction<0 and b.mentor.x<=minX+20)or(direction>0 and b.mentor.x>=maxX-20))then direction=nil end
     if not escape and not pilot.flank and b.mentorAim.held then direction=nil end
     local machineOutside=not machineWaveLead or math.abs(b.machine.x-boss.enemy.x)>require('Enemy.GroundWave').range+b.machine.unitDef.size.width/2+95
     if not escape and machineOutside and not pilot.flank and math.abs(dx)>=1100 and b.mentorAim.canStart()and D.App.runningTime>=(pilot.nextAim or 0)then direction=nil end
     if D.App.runningTime>=nextSample and #r.positions<(wholeRecovery and 1000 or 400)then
      r.positions[#r.positions+1]={bossTiming=bossTiming,recoveryTail=recoveryTail,recoveryReason=recoveryReason,crossingLowerBound=crossingLowerBound,partyWaveActors=partyWaveActors,partyWaveEscape=partyWaveEscape,machineWaveEscape=machineWaveEscape,machineOutside=machineOutside,bossWindow=bossWindow,flank=pilot.flank,gatherMode=b.gatherMode,gatherActive=b:gatherActive(),niniliteCasting=b.magic:busy('fire'),wuyunCasting=b.magic:busy('wind'),niniliteX=b.arena.student.x,wuyunX=b.wuyun.student.x,machineX=b.support.x,at=D.App.runningTime-b.started,x=b.mentor.x,bossX=boss.enemy.x,dx=dx,direction=direction or 0,escape=escape,held=b.mentorAim.held,canAim=b.mentorAim.canStart(),faceRight=b.mentor.faceRight}
      nextSample=D.App.runningTime+.25
     end
     if direction then
      if b.mentorAim.held then level.hud.weapon:emit('TapEnded')end
      turnMove(direction)
     else
      turnMove(0)
      if b.mentorAim.held then
       local aim=pilot.aim
       local rayWindow=false
       if previewRay and aim and D.App.runningTime-b.mentorAim.started>.16 then
        rayWindow=true
        for _,delta in ipairs({-.3,0,.3})do
         local angle=b.mentorAim.angle+delta
         local origin=require('Combat.Muzzle').manualPreview(b.world,b.mentor,angle,b.mentor.faceRight)
         local theta=-math.rad(angle);local face=b.mentor.faceRight and 1 or -1
         local hit,terrain=b.bossCombat:contact(origin,{x=origin.x+face*2400*math.cos(theta),y=origin.y+2400*math.sin(theta)})
         if terrain or not hit or (aim.intent=='summon'and not hit.enemy)or(aim.intent~='summon'and(hit.enemy or hit.part~=aim.intent))then rayWindow=false;break end
        end
        r.previewRayChecks=(r.previewRayChecks or 0)+1
       end
       if not aim or D.App.runningTime-b.mentorAim.started>1.2 then
        if previewRay then r.previewRayTimeouts=(r.previewRayTimeouts or 0)+1 end
        level.hud.weapon:emit('TapEnded');pilot.aim=nil
       elseif D.App.runningTime-b.mentorAim.started>.16 and (previewRay and rayWindow or not previewRay and math.abs(b.mentorAim.angle-aim.angle)<3)then
        control('manual-release',{part=aim.intent,angle=b.mentorAim.angle,visibleRayWindow=previewRay and rayWindow or nil});level.hud.weapon:emit('TapEnded');pilot.aim=nil;pilot.nextAim=D.App.runningTime+1.05
        if previewRay then r.previewRayReleases=(r.previewRayReleases or 0)+1 end
       end
      elseif b.mentorAim.canStart()then
       local observation=b.observeYingzhao(b.mentor);local parts={};local added={}
       if urgent then parts[#parts+1]='summon';added.summon=true end
       for _,part in ipairs(require('Training.YingzhaoFeatures').parts)do if observation['part_'..part]=='exposed'then parts[#parts+1]=part;added[part]=true end end
       for _,part in ipairs({'head','forelegs','arms','hindlegs','torso','flank','summon'})do if not added[part]then parts[#parts+1]=part end end
       local aim
       for _,part in ipairs(parts)do aim=require('Training.YingzhaoActions').plan(b,{student=b.mentor},part,manualAim);if aim then break end end
       if aim then
        if b.mentor.faceRight~=aim.faceRight then turnMove(aim.faceRight and 1 or -1)
        else pilot.aim=aim;level.hud.weapon:emit('TapBegan');control('manual-aim',{part=aim.intent,angle=aim.angle})end
       end
      end
     end
     for _,a in ipairs({b.arena,b.wuyun})do
      local skill=a.character.id=='ninilite'and'fire'or'wind'
      local skillObservation=formationControl and b.observeYingzhao(a.student)
      local aimAligned=not formationControl or skill=='wind'and target and require('Ground.Tactics').inWind(target.enemy.x,target.enemy.y,a.student.x,a.student.y,b.mentor.faceRight and 1 or -1)or skill=='fire'and(skillObservation.skillControl.mentorFaceRight and skillObservation.fireAimRight or skillObservation.fireAimLeft)=='aligned'
      -- Transfer still owns the cast until this actor arrives. A completed
      -- recovery position permits the player's existing skill button input.
      local movingOrder=wholeRecovery and (pilot.flank~=nil or b:gatherActive()and (not arrivedRecoveryCast or not a.regroupComplete))or travelPriority and require('Combat.Formation').owns(a,b,D.App.runningTime)and not a.regroupComplete
      if movingOrder and aimAligned then r.deferredSkillWindows=(r.deferredSkillWindows or 0)+1 end
      if not movingOrder and aimAligned and a.studentHP>0 and (visibleProtection and b.magic:available(skill)or not visibleProtection and not a:isAttacking()and not a.student:isDoing(a.physical.fmove)and not a.student:isDoing(a.physical.bmove))then
       local previous=b.magic.activeLogs[skill];
       (a.character.id=='ninilite'and level.fire or level.wind):emit('TapBegan')
       local started=b.magic.activeLogs[skill]
       if arrivedRecoveryCast and b.gatherMode=='recover'and b:gatherActive()and a.regroupComplete and started and started~=previous then
        r.arrivedRecoveryCastStarts[#r.arrivedRecoveryCastStarts+1]={skill=skill,at=D.App.runningTime,step=started.step,gatherMode=b.gatherMode,regroupComplete=a.regroupComplete}
       end
      end
     end
     local danger=false
     for _,a in ipairs(b.learners)do if a.studentHP>0 and b.observeYingzhao(a.student).threat~='none'then danger=true end end
     if gatherHeldUntil and D.App.runningTime>=gatherHeldUntil then level.gather:emit('TapEnded');gatherHeldUntil=nil end
     local machineCue=machineProtection and require('Ground.BigYingzhaoLevel').supportWarningText(b):find('Boss正面',1,true)~=nil
     local recoveryThreshold=boundedRecovery and 70 or 80
     local injured=b.mentorHP<recoveryThreshold or b.arena.studentHP<recoveryThreshold or b.wuyun.studentHP<recoveryThreshold
     local recoveryActive=b.gatherMode=='recover'and b:gatherActive()
     -- A player can stop healing once the visible team is healthy enough.
     -- Use the same public G press; never clear orders or set actor state.
     local recovered=b.mentorHP>=85 and b.arena.studentHP>=85 and b.wuyun.studentHP>=85
     if (boundedRecovery or resourceRecovery)and recoveryActive and recovered and not gatherHeldUntil and not partyWaveEscape and not meleeCue and not pilot.flank then
      level.gather:emit('TapBegan');level.gather:emit('TapEnded');nextGather=D.App.runningTime+2
      control('recovery-cancel',{cue='visible-team-recovered',mentorHP=b.mentorHP,niniliteHP=b.arena.studentHP,wuyunHP=b.wuyun.studentHP})
      assert(not b:gatherActive(),'Public recovery cancellation did not release the order')
      recoveryActive=false
     end
     local injuryOnly=boundedRecovery or resourceRecovery
     local requestRecovery=injuryOnly and injured or not injuryOnly and (injured or meleeCue or machineCue)
     if teamRecovery and level.gather and requestRecovery and(not formationControl or not b:gatherActive())and support.gold>0 and support.machineHP>0 and not recoveryActive and not gatherHeldUntil and D.App.runningTime>=nextGather then
      level.gather:emit('TapBegan');gatherHeldUntil=D.App.runningTime+.7;nextGather=D.App.runningTime+3
      control('recovery-hold',{cue=machineCue and'visible-machine-front-risk'or meleeCue and'visible-melee-windup'or'visible-injury',mentorHP=b.mentorHP,niniliteHP=b.arena.studentHP,wuyunHP=b.wuyun.studentHP})
     elseif formationControl and level.gather and support.gold>0 and support.machineHP>0 and support:energyObservation().span>500 and not b:gatherActive()and not gatherHeldUntil and D.App.runningTime>=nextGather then
      level.gather:emit('TapBegan');level.gather:emit('TapEnded');nextGather=D.App.runningTime+1
      control('spread-gather',{span=support.span,rate=support:energyRate(),mentorX=b.mentor.x,bossX=boss.enemy.x})
     elseif level.gather and danger and(not formationControl or not b:gatherActive())and not recoveryActive and not gatherHeldUntil and D.App.runningTime>=nextGather then level.gather:emit('TapBegan');level.gather:emit('TapEnded');nextGather=D.App.runningTime+2.5
      local plan=b.gatherPlan;local away=boss.enemy.x>=b.mentor.x and -1 or 1
      -- A second short press cancels an active gather through the public UI.
      -- Preserve that input and record cancellation instead of indexing nil.
      if plan then
       for _,id in ipairs({'ninilite','wuyun'})do assert((plan[id]-b.mentor.x)*away>=0,'Regroup sent ally toward visible Boss')end
       control('gather',{cue='visible-threat',mentorDistance=math.abs(dx),mentorX=b.mentor.x,bossX=boss.enemy.x,targets={ninilite=plan.ninilite,wuyun=plan.wuyun},compressed=plan._compressed})
      else control('gather-cancel',{cue='visible-threat'})end
     end
    end
   end;D.sleep(.02)
  end
  if gatherHeldUntil then level.gather:emit('TapEnded')end
  r.gatherClearedPending=b.gatherClearedPending or 0;r.vitals=b.bossTrace.vitals;r.supportAfter=b.report and b.report.auxiliary;r.battle=b.report;r.mentorShots=0;for _,step in ipairs(b.bossTrace.steps)do if step.actor=='mentor'and step.action=='shoot'then r.mentorShots=r.mentorShots+1 end end;r.outcome=b.phase;r.bossHP=b.bossCombat.boss.enemyHP;r.trace={steps=#b.bossTrace.steps,hits=#b.bossTrace.hits};save()
  wait(function()return level.phase=='result'or level.phase=='save-error'end)
  assert(level.phase=='result',level.error);assert(not E.active()and E.wallet().available==r.balanceBefore+(r.recoveryIncome or 0)+b.report.economy.net)
  assert(level.result.resultLayout==(b.phase=='won'and'Settlement'or'MissionFail'))
  assert(models()==original,'Formal Boss changed basic models')
  assert(equal(originalAdoptions,{ninilite=adoption.state('ninilite'),wuyun=adoption.state('wuyun')}),'Formal Boss changed adoption states')
  if exploratory then
   r.policyDecisions=b.yingzhaoDecisionsByActor.ninilite
   assert(#r.policyDecisions>0)
   for _,decision in ipairs(r.policyDecisions)do assert(decision.origin=='adopted')end
   assert(b.report.learners.ninilite.training.adoptionId==prior.active)
   r.deploymentVerified=true
  end
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));local episode=assert(require('Training.CombatStore').load(attempt));assert(episode.boss.status==b.phase)
  r.balanceAfter=E.wallet().available;r.episodeSaved=true;r.sameJourneyBranch=true;save()
  level.result.baseButton:emit('Tapped');wait(function()return world()~=b.world and world().tag=='TrainA'end)
  r.returnedToTrain=true;r.stage='boss-returned';r.naturalVictory=b.phase=='won';save()
  if compareTransfer then
   r.trace=b.bossTrace;r.combatScripted=true;r.setupScripted=true;r.fullGameComplete=false
   r.transferComparison={travelPriority=travelPriority,scope='same earned checkpoint/public inputs; natural outcome retained, not actual OS or stable victory'}
   assert(b.phase=='won'or b.phase=='failed','Transfer comparison did not settle naturally')
   save();return
  end
  if warningQA then
   assert(damageCaptured and #r.warningChecks.screenshots==2,'Actual machine damage was not visually verified')
   r.warningChecks.actualDamage=true;r.warningChecks.modelsAndLedgerPreserved=true
   assert(r.warningChecks.bossOriginalScale==1,'Warning changed authored Boss scale')
   assert(playingFrames>100 and (b.supportWarningWrites or 0)<playingFrames and (level.statusWrites or 0)<playingFrames,'HUD still rebuilds unchanged text every frame')
   table.sort(frames);local sum,slow=0,0
   for _,dt in ipairs(frames)do sum=sum+dt;if dt>1/30 then slow=slow+1 end end
   assert(#frames>100,'No sustained frame samples outside capture/resize')
   r.warningChecks.displayUpdates={playingFrames=playingFrames,statusWrites=level.statusWrites,warningWrites=b.supportWarningWrites}
   r.warningChecks.performance={frames=#frames,mean=sum/#frames,p95=frames[math.ceil(#frames*.95)],p99=frames[math.ceil(#frames*.99)],max=frames[#frames],over33ms=slow,scope='this-encounter-only'}
   r.naturalVictory=b.phase=='won';D.App.winSize=originalSize;return
  end
  assert(b.phase=='won','Natural formal Boss did not win: '..b.reason)
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save();print('LSD_FRESH_BIG_YINGZHAO_CURRENT_'..r.status)
end)
