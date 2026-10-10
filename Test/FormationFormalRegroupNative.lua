-- Short formal component regression with actual adopted models and charged supplies.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/formation-formal-regroup-result.json'
local r={status='RUNNING',osInput=false,naturalVictory=false,formalComponentEncounter=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),32)
  assert(prior.operationVariant=='visible-remote-interior-no-chase-public-route-v11'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-boss%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/formation-formal-regroup-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local initial=E.wallet().available
  local S=require('Training.YingzhaoAdoptionStore');local I=require('Training.FlowerIdentity')
  local states={ninilite=S.state('ninilite'),wuyun=S.state('wuyun')}
  local function basic()return {D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot')}end
  local modelsBefore=basic()
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Formal report route timeout');D.sleep(.02)end end
  require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=4650,energySquad=true})
  local gate=assert(D.Platformer.Data.store.world.disarmGate);wait(function()return gate.menu.visible and gate.menu.menu.enabled end)
  gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end)
  local panel=gate.supplyPanel
  for _,entry in ipairs({{1,'mentor:kinetic',20},{2,'ninilite:emp',12},{3,'wuyun:emp',2},{4,'wuyun:blade',12}})do
   while panel.values[entry[2]]>entry[3]do local delta=panel.values[entry[2]]-entry[3]>=5 and -5 or -1;panel.buttons[entry[1]][delta]:emit('Tapped')end
  end
  assert(panel.quote.total<=initial);r.reservedBudget=panel.quote.total;panel.saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle
  for actor,id in pairs(prior.adoptions)do assert(b.yingzhaoDeployments[actor].id==id)end
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  r.arrivalPolicyProofs={};r.arrivalPolicyWindows={};local arrivals={}
  local function observeArrival()
   local now=D.App.runningTime
   for _,a in ipairs(b.learners)do
    local actor=a.character.id;local seen=arrivals[actor]
    if b.phase=='playing'and b.gatherMode=='normal'and b.gatherPlan and now<b.gatherUntil and a.regroupPlan==b.gatherPlan and a.regroupComplete and a.studentHP>0 then
     local decisions=b.yingzhaoDecisionsByActor[actor]
     if not seen or seen.plan~=b.gatherPlan then
      seen={plan=b.gatherPlan,at=now,deadline=b.gatherUntil,count=#decisions};arrivals[actor]=seen
      r.arrivalPolicyWindows[#r.arrivalPolicyWindows+1]={actor=actor,arrivalObserved=now-b.started,deadline=b.gatherUntil-b.started,availableSeconds=b.gatherUntil-now,decisionCount=#decisions}
     elseif not seen.proven then
      for i=seen.count+1,#decisions do
       local row=decisions[i]
       if row.at>=seen.at and row.at<seen.deadline then
        seen.proven=true;r.arrivalPolicyProofs[#r.arrivalPolicyProofs+1]={actor=actor,arrivalObserved=seen.at-b.started,decisionAt=row.at-b.started,deadline=seen.deadline-b.started,origin=row.origin,accepted=row.accepted,action=row.action,secondsBeforeDeadline=seen.deadline-row.at};break
       end
      end
     end
    end
   end
  end
  D.thread(function()while b.phase=='playing'do observeArrival();D.sleep(.02)end end)

  if os.getenv('LSD_QA_LONG_GATHER')=='1'then
   c.hud.move:emit('Left',true)
   wait(function()return b.mentor.x<b.minX+50 or b.phase~='playing'end,12)
   c.hud.move:emit('Left',false);assert(b.phase=='playing');D.sleep(.1)
   c.gather:emit('TapBegan');c.gather:emit('TapEnded');local plan=b.gatherPlan;local started=D.App.runningTime
   assert(b.gatherDuration>3 and b.gatherDuration<=12,'Distant gather kept fixed three-second deadline')
   r.longGather={duration=b.gatherDuration,plan={ninilite=plan.ninilite,wuyun=plan.wuyun},started=started}
   D.sleep(3.1)
   assert(b.phase=='playing'and b.gatherPlan==plan and D.App.runningTime<b.gatherUntil,'Order expired before distant regroup could finish')
   r.longGather.activeAfterThree=true
   if os.getenv('LSD_QA_CANCEL_GATHER')=='1'then
    local decisions={};for _,a in ipairs(b.learners)do decisions[a.character.id]=#b.yingzhaoDecisionsByActor[a.character.id]end
    c.controls:emit('KeyDown','G')
    wait(function()return b.gatherPlan==nil end,2)
    assert(not b:gatherActive()and b.gatherUntil==0,'Second G did not cancel the active order')
    -- A held key's repeated KeyDown must not create alternating orders.
    c.controls:emit('KeyDown','G');c.controls:emit('KeyDown','G');D.sleep(.25)
    assert(b.gatherPlan==nil,'Keyboard repeat restarted the cancelled order')
    c.controls:emit('KeyUp','G');D.sleep(1)
    local resumed=false
    for _,a in ipairs(b.learners)do if #b.yingzhaoDecisionsByActor[a.character.id]>decisions[a.character.id]then resumed=true end end
    assert(resumed,'Cancellation did not restore actual adopted decisions')
    c.controls:emit('KeyDown','G');wait(function()return b.gatherPlan~=nil end,2)
    assert(b:gatherActive(),'A new press could not restart gathering')
    wait(function()return c.gather.textLabel.text:find('取消',1,true)end,1)
    c.controls:emit('KeyUp','G');c.gather:emit('TapBegan');c.gather:emit('TapEnded')
    assert(b.gatherPlan==nil and not b:gatherActive(),'Touch button did not share cancellation behavior')
    wait(function()return c.gather.textLabel.text:find('集合 G',1,true)end,1)
    r.gatherCancellation={keyboardCancelled=true,repeatIgnored=true,adoptedDecisionsResumed=true,newPressRestarted=true,touchCancelled=true,buttonFeedback=true}
   end
   wait(function()
    if b.phase~='playing'or D.App.runningTime>=b.gatherUntil then return true end
    for _,a in ipairs(b.learners)do if not a.regroupComplete then return false end end
    return true
   end,13)
   assert(b.phase=='playing','Distant regroup lost party');r.longGather.arrived={}
   for _,a in ipairs(b.learners)do r.longGather.arrived[a.character.id]={x=a.student.x,target=plan[a.character.id],completed=a.regroupComplete==true}end
   local late=false;for _,step in ipairs(b.bossTrace.steps)do if step.origin=='command-gather'and step.started>=started-.1 and (step.ended or D.App.runningTime)>started+3 then late=true end end
   assert(late,'Extended order did not produce actual movement after three seconds')
   r.longGather.actualMovementAfterThree=true
   r.longGather.expired=D.App.runningTime>=b.gatherUntil
   r.longGather.completed=D.App.runningTime;save()
  end
  r.regroupSamples={};r.nearBackstepSamples=0;r.gatherCommands=0
  local untilAt=D.App.runningTime+24;local nextGather=0
  while b.phase=='playing'and D.App.runningTime<untilAt do
   if D.App.runningTime>=nextGather then
    c.gather:emit('TapBegan');c.gather:emit('TapEnded');r.gatherCommands=r.gatherCommands+1;nextGather=D.App.runningTime+3.2
   end
   if os.getenv('LSD_QA_RECOVER_HOLD')=='1'and not r.recoveryHold and b.support.gold>5 and (b.mentorHP<95 or b.arena.studentHP<95 or b.wuyun.studentHP<95)then
    local vitals=b.bossTrace.vitals
    r.recoveryHold={hpBefore={b.mentorHP,b.arena.studentHP,b.wuyun.studentHP},goldBefore=b.support.gold}
    c.gather:emit('TapBegan');D.sleep(.7);c.gather:emit('TapEnded')
    assert(b.phase=='playing'and b.gatherMode=='recover','A real touch hold did not enter recovery')
    local firstEvent=#vitals.events
    r.recoveryHold.hpAtRecoveryStart={b.mentorHP,b.arena.studentHP,b.wuyun.studentHP}
    local plan=b.gatherPlan;assert(plan._spacing<=require('Combat.Formation').recoverySpacing)
    r.recoveryHold.plan={ninilite=plan.ninilite,wuyun=plan.wuyun,spacing=plan._spacing}
    if os.getenv('LSD_QA_MOVING_RECOVERY')=='1' then
     local startX=b.mentor.x;local startTarget=b.gatherPlan.wuyun;local deadline=b.gatherUntil
     local side=b.bossCombat.boss.enemy.x>=startX and 'Left' or 'Right'
     c.hud.move:emit(side,true)
     local stop=D.App.runningTime+2.5
     while b.phase=='playing' and b:gatherActive() and math.abs(b.mentor.x-startX)<150 and D.App.runningTime<stop do D.sleep(.02) end
     c.hud.move:emit(side,false)
     r.movingRecovery={mentorDistance=math.abs(b.mentor.x-startX),targetDistance=math.abs(b.gatherPlan.wuyun-startTarget),deadlineUnchanged=b.gatherUntil==deadline};save()
     assert(r.movingRecovery.mentorDistance>=150,'Actual mentor motion did not reach the moving-recovery case')
     assert(r.movingRecovery.targetDistance>=100,'Recovery destinations stayed frozen while the mentor moved')
     assert(r.movingRecovery.deadlineUnchanged,'Moving recovery extended its bounded order')
    end
    local endAt=D.App.runningTime+13;local together=0
    while b.phase=='playing'and b:gatherActive()do
     assert(D.App.runningTime<endAt,'Recovery order did not release by its finite deadline')
     if math.abs(b.mentor.x-b.support.x)<=120 and math.abs(b.arena.student.x-b.support.x)<=120 and math.abs(b.wuyun.student.x-b.support.x)<=120 then together=together+1 end
     local healingObserved=false
     for i=firstEvent+1,#vitals.events do local event=vitals.events[i];if event.kind=='support-heal'and event.after>event.before then healingObserved=true;break end end
     if together>0 and healingObserved then
      -- The player can leave the tight formation once its actual benefit is
      -- visible, rather than stay inside incoming area attacks until expiry.
      c.gather:emit('TapBegan');c.gather:emit('TapEnded')
      assert(not b:gatherActive()and b.gatherPlan==nil,'Recovery could not be cancelled after healing')
      r.recoveryHold.cancelledAfterBenefit=true;break
     end
     D.sleep(.02)
    end
    assert(b.phase=='playing','Party or machine failed during recovery')
    local healing={};for i=firstEvent+1,#vitals.events do local event=vitals.events[i];if event.kind=='support-heal'and event.after>event.before then healing[#healing+1]={actor=event.actor,before=event.before,after=event.after,at=event.at}end end
    assert(#healing>0,'Held recovery produced no actual support healing')
    assert(together>0,'Recovery never brought all living actors into the real healing range')
    assert(b.support.gold<r.recoveryHold.goldBefore,'Recovery skipped real upkeep')
    r.recoveryHold.healing=healing;r.recoveryHold.allInRangeSamples=together
    r.recoveryHold.hpAfter={b.mentorHP,b.arena.studentHP,b.wuyun.studentHP};r.recoveryHold.goldAfter=b.support.gold
    r.recoveryHold.released=true;save();nextGather=D.App.runningTime+3.2
   end
   for _,a in ipairs(b.learners)do
    local u=a.student
    if a.regroupMoving and (u:isDoing(a.physical.fmove)or u:isDoing(a.physical.bmove))and math.abs(u.velocityX)>1 then
     local backward=u:isDoing(a.physical.bmove)
     local speed=backward and 120 or 240
     assert(math.abs(math.abs(u.velocityX)-speed)<1,'Formal regroup has wrong movement speed')
     if backward then r.nearBackstepSamples=r.nearBackstepSamples+1 end
     if #r.regroupSamples<500 then r.regroupSamples[#r.regroupSamples+1]={actor=a.character.id,at=D.App.runningTime-b.started,x=u.x,faceRight=u.faceRight,clip=u.playable.current,velocityX=u.velocityX,backward=backward}end
    end
   end
   D.sleep(.04)
  end
  if os.getenv('LSD_QA_RECOVER_HOLD')=='1'then assert(r.recoveryHold,'No naturally injured recovery window observed')end
  if os.getenv('LSD_QA_ARRIVAL_POLICY')=='1'then assert(#r.arrivalPolicyProofs>0,'Arrived actor did not resume actual adopted decisions before gather deadline')end
  r.encounterStatusBeforeExit=b.phase;save()
  -- Natural defeat may be finishing authored attack/lose animations here.
  -- Observe its terminal outcome; never recast settling as a withdrawal.
  if b.phase=='settling'then
   r.pendingOutcome=b.pendingStatus;r.pendingReason=b.reason;save()
   wait(function()return b.phase~='settling'end,45)
  end
  local expectedStatus=b.phase=='playing'and'aborted'or b.phase
  assert(expectedStatus=='aborted'or expectedStatus=='failed','Unexpected formal outcome')
  c.withdraw:emit('Tapped');wait(function()return c.phase=='result'or c.phase=='save-error'end,45);assert(c.phase=='result',c.error)
  assert(c.result.resultLayout=='MissionFail');c.result.reportButton:emit('Tapped');wait(function()return c.result.reportPanel end)
  assert(c.result.reportLabel.text:find('队伍贡献（耗材',1,true),'Formal report did not use contribution feedback')
  r.reportText=c.result.reportLabel.text;r.battle=b.report;r.cost=b.report.economy.cost;r.balanceAfter=E.wallet().available
  assert(r.balanceAfter==initial-r.cost and b.report.economy.income==0 and not E.active())
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));r.attempt=attempt
  r.episode=assert(require('Training.CombatStore').load(attempt));assert(require('Enemy.BigYingzhaoEvidence').validate(r.episode))
  assert(r.episode.boss.status==expectedStatus);r.contributions=require('Training.YingzhaoContributions').summarize(r.episode.boss)
  assert(r.contributions.totalCost==r.cost)
  c.result.reportPanel.backButton:emit('Tapped');assert(c.result.visible and not c.result.reportPanel)
  c.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world end)
  assert(I.equal(modelsBefore,basic())and I.equal(states.ninilite,S.state('ninilite'))and I.equal(states.wuyun,S.state('wuyun')))
  if not r.longGather then assert(r.nearBackstepSamples>0,'Formal regroup did not cover a near-enemy backstep')end
  r.nearBackstepCovered=r.nearBackstepSamples>0
  r.formalLedgerAndReport=true;r.normalReturn=true;r.adoptionsAndBasicModelsUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
