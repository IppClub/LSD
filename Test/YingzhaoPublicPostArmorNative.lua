-- Public demonstration/learning route with an actual copied failed save.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-public-post-armor-result.json'
local r={status='RUNNING',osInput=false,notHumanDemonstration=true,naturalVictory=false,commands={}}
local activeLevel
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),32)
  local currentJourney=os.getenv('LSD_QA_CURRENT_JOURNEY_LESSON')=='1'
  local continuingLesson=os.getenv('LSD_QA_CONTINUING_PUBLIC_LESSON')=='1'
  assert(not (currentJourney and continuingLesson),'Select a journey or an existing public lesson')
  if continuingLesson then
   assert(prior.status=='PASS'and prior.protectedStateUnchanged)
   assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-public%-post%-armor%-%d+%.db$')or prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-public%-post%-armor%-compare%-%d+%.db$'))
   r.continuingPublicLesson=true
  elseif currentJourney then
   assert(prior.sameJourneyBranch and prior.outcome=='failed'and prior.episodeSaved and prior.returnedToTrain)
   assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-big%-yingzhao%-current%-%d+%.db$'))
  else
   assert((prior.operationVariant=='visible-remote-interior-no-chase-public-route-v11'or prior.operationVariant=='visible-boss-center-release-public-route-v18')and prior.outcome=='failed')
   assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-boss%-natural%-%d+%.db$'))
  end
  r.currentJourneySource=currentJourney;r.parentDatabase=prior.database
  local db=D.Content.writablePath..'/yingzhao-public-post-armor-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Public post-armor route timeout');D.sleep(.02)end end
  local I=require('Training.FlowerIdentity');local S=require('Training.YingzhaoAdoptionStore');local E=require('Economy.Store');assert(E.open())
  local function protected()return {basic=D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),other=D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot'),missions=D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),wallet=E.wallet().available,ninilite=S.state('ninilite'),wuyun=S.state('wuyun')}end
  local before=protected();r.balanceBefore=before.wallet
  local store=require('Training.YingzhaoPolicyStore');local old=store.loadLatestAsync('ninilite');if not currentJourney then assert(old)end;r.oldCandidate=old and old.id
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'ninilite');wait(controls)
  local menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('大英招示范'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout')end)
  D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout').saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoDemonstration end)
  local c=D.Platformer.Data.store.world.patrolLevel;activeLevel=c;local b=c.battle;local a=b.demonstrator
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  local function record(name)r.commands[#r.commands+1]={name=name,at=D.App.runningTime-b.started,observed=b.observeYingzhao(a.student)};save()end
  local function shoot(part)
   local sampled=0
   wait(function()
    if b.phase~='playing'then return true end
    if os.getenv('LSD_QA_REAR_FLANK_LESSON')=='1'then
     local o=b.observeYingzhao(a.student)
     if D.App.runningTime>=sampled then
      r.firingWindowSamples=r.firingWindowSamples or {};r.firingWindowSamples[#r.firingWindowSamples+1]={at=D.App.runningTime-b.started,observation=o,available=a:available('laser'),planned=require('Training.YingzhaoActions').plan(b,a,part)~=nil};sampled=D.App.runningTime+.25;save()
     end
     if o.bossWindow~='recovery'and o.bossWindow~='idle'then return false end
     -- Only the original part solver determines reachability. Boss facing
     -- alone cannot reject an authored pose that exposes this region.
     if part=='flank'and not o.bossVisible then return false end
    end
    return a:available('laser')and require('Training.YingzhaoActions').plan(b,a,part)
   end,20)
   assert(b.phase=='playing','Natural demonstration ended before action');c.targetButtons[part]:emit('Tapped');record('shoot@'..part)
   local count=#b.bossTrace.steps;c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')
   local emittedStep
   wait(function()
    for i=count+1,#b.bossTrace.steps do local step=b.bossTrace.steps[i]
     if step.actor=='ninilite'and step.action=='shoot'and step.origin=='demo'and step.aim and step.aim.intent==part then emittedStep=i;break end
    end
    return emittedStep and not a:isAttacking()and not b.bossCombat:pendingActor('ninilite')
   end)
   r.shotDiagnostics=r.shotDiagnostics or {};local step=b.bossTrace.steps[emittedStep];local hits,flights={},{}
   for _,hit in ipairs(b.bossTrace.hits)do if hit.step==emittedStep then hits[#hits+1]=hit end end
   for _,flight in ipairs(b.bossTrace.flights or {})do if flight.step==emittedStep then flights[#flights+1]=flight end end
   r.shotDiagnostics[#r.shotDiagnostics+1]={requested=part,stepId=emittedStep,step=step,hits=hits,flights=flights};save()
  end
  local farCoordination=os.getenv('LSD_QA_FAR_COORDINATION_LESSON')=='1'
  if farCoordination then
   assert(os.getenv('LSD_QA_COORDINATION_LESSON')=='1')
   r.farCoordinationLesson=true;r.instructorPrelude={started=D.App.runningTime-b.started,startX=b.mentor.x,destination=b.minX+50}
   local node=D.Node();node:addTo(b.world)
   local endAt=D.App.runningTime+10
   node:schedule(function()
    if b.phase~='playing'or D.App.runningTime>=endAt or b.mentor.x<=b.minX+60 then
     if b.mentor:isDoing('groundMentorMove')then b.mentor:stop();b.mentor.velocityX=0;require('CombatAnimation').rest(b.mentor)end
     r.instructorPrelude.finished=D.App.runningTime-b.started;r.instructorPrelude.endX=b.mentor.x;return true
    end
    if not require('Combat.Displacement').blocked(b.mentor)then require('Combat.Movement').command(b.mentor,'left')end
    return false
   end)
  end
  local exposedCounter=os.getenv('LSD_QA_EXPOSED_ARMS_COUNTEREXAMPLE')=='1'
  if exposedCounter then
   local focus=os.getenv('LSD_QA_COUNTER_PART')or'arms'
   assert(({arms=true,head=true,forelegs=true,hindlegs=true,torso=true,flank=true})[focus],'Unknown counterexample part')
   r.counterPart=focus;r.knownArmsLesson=true;r.exposedPartCounterexamples={}
   if focus=='arms'then r.exposedArmsCounterexamples=r.exposedPartCounterexamples end
   local function rearPosition()
    if os.getenv('LSD_QA_REAR_FLANK_LESSON')~='1'then return end
    assert(focus=='flank');r.rearPositioning=r.rearPositioning or {};local started=D.App.runningTime;local held;local side;local sampled=0
    local function move(side)
     if held==side then return end;if held then c.hud.move:emit(held,false)end;held=side
     if side then record('move-'..side);c.hud.move:emit(side,true)end
    end
    while b.phase=='playing'and D.App.runningTime-started<18 do
     local o=b.observeYingzhao(a.student)
     if o.bossVisible then
      r.rearLessonSide=r.rearLessonSide or(o.bossFaceRight and -1 or 1);side=r.rearLessonSide
      local rear=side
      local gap=(o.ownX-o.bossX)*rear
      if D.App.runningTime>=sampled then r.rearMovementSamples=r.rearMovementSamples or {};r.rearMovementSamples[#r.rearMovementSamples+1]={at=D.App.runningTime-b.started,ownX=o.ownX,bossX=o.bossX,bossFaceRight=o.bossFaceRight,chosenSide=side,window=o.bossWindow};sampled=D.App.runningTime+.25;save()end
      if gap>=900 and gap<=1450 then move(nil);r.rearPositioning[#r.rearPositioning+1]={at=D.App.runningTime-b.started,ownX=o.ownX,bossX=o.bossX,bossFaceRight=o.bossFaceRight,gap=gap};save();return end
      local desired=math.max(b.minX+30,math.min(b.maxX-30,o.bossX+rear*1200));move(desired>o.ownX and'Right'or'Left')
     else move(nil)end
     D.sleep(.04)
    end
    move(nil);error('Normal movement did not establish a rear firing position')
   end
   for i=1,8 do if b.observeYingzhao(a.student)['part_'..focus]=='exposed'then break end;rearPosition();shoot(focus)end
   assert(b.observeYingzhao(a.student)['part_'..focus]=='exposed','Real shots did not expose '..focus)
   local held
   local function motion(side)
    if held==side then return end
    if held then c.hud.move:emit(held,false)end;held=side
    if side then c.hud.move:emit(side,true)end
   end
   for i=1,4 do
    local chosen;local deadline=D.App.runningTime+12
    while b.phase=='playing'and not chosen and D.App.runningTime<deadline do
     local o=b.observeYingzhao(a.student)
     if a:available('laser')and o['part_'..focus]=='exposed'and o['aim_'..focus]=='reachable'then
      for _,part in ipairs({'head','arms','forelegs','hindlegs','torso','flank'})do
       if part~=focus and o['part_'..part]~='exposed'and require('Training.YingzhaoActions').plan(b,a,part)then chosen=part;break end
      end
     end
     if chosen then motion(nil)
     else
      local toward=o.bossX>=o.ownX and 1 or -1
      local side=o.bossDistance=='near'and -toward or nil
      if side and(side<0 and o.ownX>b.minX+25 or side>0 and o.ownX<b.maxX-25)then motion(side>0 and'Right'or'Left')else motion(nil)end
      D.sleep(.04)
     end
    end
    motion(nil)
    assert(chosen and b.phase=='playing','No actual reachable exposed-'..focus..' counterexample window')
    local o=b.observeYingzhao(a.student)
    assert(o['part_'..focus]=='exposed'and o['aim_'..focus]=='reachable'and o['part_'..chosen]~='exposed')
    r.exposedPartCounterexamples[#r.exposedPartCounterexamples+1]={focus=focus,part=chosen,observed=o,at=D.App.runningTime-b.started};save()
    shoot(chosen)
   end
  else
  for i=1,5 do if b.observeYingzhao(a.student).part_head=='exposed'then break end;shoot('head')end
  assert(b.observeYingzhao(a.student).part_head=='exposed','Public shots did not expose head')
  r.headExposed=true;save()
  if os.getenv('LSD_QA_KNOWN_ARMS_LESSON')=='1'then
   -- Obtain armor knowledge by real aimed contact before teaching the switch.
   for i=1,3 do if b.observeYingzhao(a.student).part_arms~='unknown'then break end;shoot('arms')end
   assert(b.observeYingzhao(a.student).part_arms~='unknown','No actual arm observation')
   r.knownArmsLesson=true
   for i=1,4 do
    local part
    wait(function()
     if b.phase~='playing'then return true end
     if not a:available('laser')then return false end
     local o=b.observeYingzhao(a.student)
     for _,id in ipairs({'forelegs','arms','hindlegs','torso','flank'})do
      if o['part_'..id]~='exposed'and require('Training.YingzhaoActions').plan(b,a,id)then part=id;return true end
     end
     return false
    end,20)
    assert(b.phase=='playing'and part,'No reachable armored part before demonstration ended');shoot(part)
   end
  end
  -- Demonstrate a different target after the head is known exposed.
  if not r.knownArmsLesson then for i=1,2 do
   if os.getenv('LSD_QA_FRONT_RANGE_LESSON')=='1'and b.observeYingzhao(a.student).part_forelegs=='exposed'then break end
   shoot('forelegs')
  end end
  end
  local coordinationLesson=os.getenv('LSD_QA_COORDINATION_LESSON')=='1'
  local rangeLesson=os.getenv('LSD_QA_FRONT_RANGE_LESSON')=='1'
  assert(not(coordinationLesson and rangeLesson),'Select one movement lesson')
  if rangeLesson then
   r.frontRangeLesson=true;r.operationVariant='visible-frontal-range-aligned-fire-protection-public-lesson-v2'
   local held;local escapeSide;local escapeAction;local nextShot=0;local stopAt=D.App.runningTime+40
   local function motion(side)
    if held==side then return end
    if held then c.hud.move:emit(held,false)end;held=side
    record(side and('move-'..side)or'wait');if side then c.hud.move:emit(side,true)end
   end
   while b.phase=='playing'and D.App.runningTime<stopAt do
    local o=b.observeYingzhao(a.student);assert(o.featureSchemaVersion==require('Training.YingzhaoFeatures').version)
    local direction;local wave=require('Enemy.GroundWave').escapeDirection(b.bossCombat.boss.guard,a.student,o.bossVisible)
    if escapeAction and(o.bossAction~=escapeAction or o.bossWindow=='idle'or o.bossWindow=='recovery')then escapeAction=nil;escapeSide=nil end
    local toward=o.bossVisible and(o.bossX>=o.ownX and 1 or -1)
    if wave then direction=wave
    elseif escapeAction then direction=escapeSide
    elseif toward and(o.bossAction=='punch'or o.bossAction=='massive')and(o.bossFrontRange=='immediate'or o.bossFrontRange=='advance')then
     direction=o.bossAction=='massive'and o.bossFrontRange=='immediate'and toward or -toward
     escapeAction=o.bossAction;escapeSide=direction
    elseif toward and o.distance<900 then direction=-toward
    elseif toward and o.distance>1100 then direction=toward end
    if direction and(direction<0 and o.ownX<=b.minX+25 or direction>0 and o.ownX>=b.maxX-25)then direction=nil end
    motion(direction and(direction>0 and'Right'or'Left')or nil)
    if not a:isAttacking()and D.App.runningTime>=nextShot then
     if not direction and o.target=='boss'and o.skillDefaultFacing=='toward'and(o.skillControl.mentorFaceRight and o.fireAimRight or o.fireAimLeft)=='aligned'and b.magic:available('fire')then
      record('fire');c.fire:emit('TapBegan');nextShot=D.App.runningTime+.4
     elseif not direction and a:available('laser')and(o.bossWindow=='idle'or o.bossWindow=='recovery')then
      local part
      for _,id in ipairs({'forelegs','arms','hindlegs','torso','flank','head'})do if o['part_'..id]~='exposed'and require('Training.YingzhaoActions').plan(b,a,id)then part=id;break end end
      if part then c.targetButtons[part]:emit('Tapped');record('shoot@'..part);c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded');nextShot=D.App.runningTime+.4 end
     end
    end
    D.sleep(.04)
   end
   if held then c.hud.move:emit(held,false)end
  elseif coordinationLesson then
   r.coordinationLesson=true;r.operationVariant='actual-moving-instructor-public-learner-coordination-v1'
   r.instructorScripted=true;r.teleportedActors={};r.coordinationPositions={};r.instructorCommands={}
   local Movement=require('Combat.Movement');local K=require('Combat.Displacement');local held
   local function motion(side)
    if held==side then return end
    if held then c.hud.move:emit(held,false)end;held=side
    record(side and('move-'..side)or'wait');if side then c.hud.move:emit(side,true)end
   end
   local function stopInstructor()
    if b.mentor:isDoing('groundMentorMove')then b.mentor:stop();b.mentor.velocityX=0;require('CombatAnimation').rest(b.mentor)end
   end
   if farCoordination then
    -- Position preparation uses the ordinary learner executor and remains
    -- explicitly scripted/excluded; it is not relabelled as demonstration.
    r.scriptedPositionPreparation={started=D.App.runningTime-b.started,startX=a.student.x,mentorX=b.mentor.x,teleport=false,origin='qa-positioning'}
    r.scriptedPositionPreparation.samples={}
    local endAt=D.App.runningTime+8
    while b.phase=='playing'and a.student.x-b.mentor.x<850 and D.App.runningTime<endAt do
     if not K.blocked(a.student)and not a:isAttacking()then
      local target=b:target(a.student);local face=true;if target then face=require('Training.YingzhaoActions').movementFaceRight(a.student,target.enemy)end
      local action=face and'fmove'or'bmove';local ok,why=a:request(action,'qa-positioning',face)
      r.scriptedPositionPreparation.samples[#r.scriptedPositionPreparation.samples+1]={at=D.App.runningTime-b.started,x=a.student.x,mentorX=b.mentor.x,velocityX=a.student.velocityX,faceRight=a.student.faceRight,requestedFace=face,action=action,accepted=ok,reason=why,onSurface=a.student.onSurface,blocked=K.blocked(a.student),clip=a.student.playable.current,hp=a.studentHP}

     end
     D.sleep(.04)
    end
    if not K.blocked(a.student)and not a:isAttacking()then a:request('idle','qa-positioning')end
    r.scriptedPositionPreparation.finished=D.App.runningTime-b.started;r.scriptedPositionPreparation.endX=a.student.x;r.scriptedPositionPreparation.finalGap=a.student.x-b.mentor.x
    assert(b.phase=='playing'and r.scriptedPositionPreparation.finalGap>750,'Real movement did not establish a far-left instructor; retain failed source')
   end
   local started=D.App.runningTime;local sampled=0
   for _,destination in ipairs(farCoordination and {b.minX+50,1700,650}or{650,1700,650})do
    local stageStart=D.App.runningTime;local arrived
    while b.phase=='playing'and D.App.runningTime-started<32 and D.App.runningTime-stageStart<12 do
     local now=D.App.runningTime;local gap=destination-b.mentor.x
     if math.abs(gap)<=25 then if not arrived then arrived=now end;stopInstructor()
     elseif not arrived and not K.blocked(b.mentor)then
      local direction=gap>0 and'right'or'left';local ok,why=Movement.command(b.mentor,direction)
      if #r.instructorCommands==0 or r.instructorCommands[#r.instructorCommands].direction~=direction then
       r.instructorCommands[#r.instructorCommands+1]={at=now-b.started,destination=destination,direction=direction,accepted=ok,reason=why,x=b.mentor.x}
      end
     end
     local o=b.observeYingzhao(a.student);local direction
     local wave=require('Enemy.GroundWave').escapeDirection(b.bossCombat.boss.guard,a.student,o.bossVisible)
     if wave then direction=wave
     elseif o.bossVisible and o.threat=='melee'and(o.bossWindow=='imminent'or o.bossImpactLead=='urgent')and o.bossFrontRange=='immediate'then direction=o.bossX>=o.ownX and -1 or 1
     elseif o.mentorDistance~='close'and o.mentorSide~='unknown'and o.mentorSide~='overlap'then direction=o.mentorSide=='right'and 1 or -1 end
     if direction and(direction<0 and o.ownX<=b.minX+25 or direction>0 and o.ownX>=b.maxX-25)then direction=nil end
     motion(direction and(direction>0 and'Right'or'Left')or nil)
     if now>=sampled then
      r.coordinationPositions[#r.coordinationPositions+1]={at=now-b.started,mentorX=b.mentor.x,learnerX=a.student.x,mentorSide=o.mentorSide,mentorDistance=o.mentorDistance,learnerDirection=direction,mentorVelocity=b.mentor.velocityX,learnerVelocity=a.student.velocityX,bossAction=o.bossAction,threat=o.threat,wave=wave,arrived=arrived~=nil};sampled=now+.2
     end
     if arrived and now-arrived>=1.5 and(not farCoordination or o.mentorDistance=='close')then break end
     D.sleep(.04)
    end
    stopInstructor();motion(nil)
    if b.phase~='playing'then break end
   end
   stopInstructor();motion(nil)
  else
  -- Finite public move/release gestures record both movement and waiting.
  for _,side in ipairs({'Left','Right','Left','Right'})do
   assert(b.phase=='playing');record('move-'..side);c.hud.move:emit(side,true);D.sleep(.4);c.hud.move:emit(side,false);D.sleep(.5)
  end
  end
  if b.phase=='playing'then c.withdraw:emit('Tapped')end;wait(function()return c.phase=='result'end)
  assert(c.battle.demonstrationSourceId and c.result.resultLayout=='MissionFail');r.sourceId=c.battle.demonstrationSourceId
  local source=assert(require('Training.YingzhaoStore').loadAsync(r.sourceId));r.source=source
  local data=assert(require('Training.YingzhaoSamples').extract({source},'ninilite'));r.newActions=data.actions;r.newSamples=#data.samples
  local changed=0;for _,sample in ipairs(data.samples)do if sample.state.part_head=='exposed'and sample.action~='shoot@head'then changed=changed+1 end end
  assert(exposedCounter and #r.exposedPartCounterexamples>=2 or not exposedCounter and changed>=6,'Too few post-armor demonstrations');r.postArmorSamples=changed
  if coordinationLesson then
   local counts={leftApproach=0,rightApproach=0,closeIdle=0,threatMotion=0,leftFarApproach=0,rightFarApproach=0}
   for _,sample in ipairs(data.samples)do
    local step=source.boss.steps[sample.firstStep];local moving=sample.action=='fmove'or sample.action=='bmove'
    local travel=step.after.ownX-step.before.ownX
    if moving and sample.state.mentorDistance~='close'and step.before.threat=='none'and step.before.waveReach=='clear'then
     if sample.state.mentorSide=='left'and travel< -1 then counts.leftApproach=counts.leftApproach+1;if sample.state.mentorDistance=='far'then counts.leftFarApproach=counts.leftFarApproach+1 end end
     if sample.state.mentorSide=='right'and travel>1 then counts.rightApproach=counts.rightApproach+1;if sample.state.mentorDistance=='far'then counts.rightFarApproach=counts.rightFarApproach+1 end end
    end
    if sample.action=='idle'and sample.state.mentorDistance=='close'then counts.closeIdle=counts.closeIdle+1 end
    if moving and(sample.state.threat~='none'or sample.state.waveReach=='approaching')then counts.threatMotion=counts.threatMotion+1 end
   end
   r.coordinationCoverage=counts;save()
   assert(counts.leftApproach>0 and counts.rightApproach>0,'Actual two-direction approach coverage missing; retain source without adoption')
   if farCoordination then assert(counts.leftFarApproach>0,'Actual far-left approach coverage missing; retain source without adoption')end
  end
  if rangeLesson then
   local counts={advanceMotion=0,immediateMotion=0,outsideAttack=0,earlyThreatMotion=0}
   for _,sample in ipairs(data.samples)do
    local moving=sample.action=='bmove'or sample.action=='fmove'
    if moving and sample.state.bossFrontRange=='advance'then counts.advanceMotion=counts.advanceMotion+1 end
    if moving and sample.state.bossFrontRange=='immediate'then counts.immediateMotion=counts.immediateMotion+1 end
    if moving and sample.state.threat=='melee'and sample.state.bossWindow=='early'then counts.earlyThreatMotion=counts.earlyThreatMotion+1 end
    if sample.state.bossFrontRange=='outside'and(sample.action:match('^shoot@')or sample.action:match('^fire@'))then counts.outsideAttack=counts.outsideAttack+1 end
   end
   r.rangeCoverage=counts;save()
   assert(counts.advanceMotion>0 and counts.outsideAttack>0,'Actual frontal retreat or outside attack coverage missing; retain source without adopting')
  end
  if r.knownArmsLesson then
   for _,command in ipairs(r.commands)do
    local part=command.name:match('^shoot@(.+)$')
    if part then assert(command.observed['part_'..part]~='exposed','Demonstration requested EMP on known exposed part')end
   end
   r.noKnownExposedEMP=true
   local count=0
   for _,sample in ipairs(data.samples)do
    if sample.state.part_head=='exposed'and sample.state.part_arms~='unknown'and sample.action:match('^shoot@')and sample.action~='shoot@head'then count=count+1 end
   end
   r.knownArmsSwitchSamples=count;assert(exposedCounter and #r.exposedPartCounterexamples>=2 or not exposedCounter and count>=2,'Actual known-part switch coverage missing')
  end

  if os.getenv('LSD_QA_SUPPORT_LESSON')=='1'then
   assert(source.boss.supportAccountingVersion==1 and source.boss.supportAccounting.closed)
   local actual=0;for _,step in ipairs(source.boss.steps)do
    if step.actor=='ninilite'and step.before and step.before.featureSchemaVersion==10 and step.before.supportState then actual=actual+1 end
   end
   assert(actual>=6,'Missing actual support observations in public demonstration')
   r.actualSupportObservations=actual;r.supportAccounting=source.boss.supportAccounting
  end
  c.result.baseButton:emit('Tapped');wait(controls)
  menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag(rangeLesson and'学习最近示范'or'学习部位'):emit('Tapped')
  wait(function()return controls().arena.mode~='building'end,60);assert(controls().arena.message:find('已保存',1,true),controls().arena.message)
  local candidate=assert(store.loadLatestAsync('ninilite'));assert(not old or candidate.id~=old.id);r.newCandidate=candidate.id;r.model=candidate.model
  local included=false;for _,episode in ipairs(candidate.model.sourceEpisodes)do if episode==source.episode then included=true end end;assert(included,'New public demonstration missing from candidate')
  r.predictions={};local P=require('Training.YingzhaoPolicy')
  for _,sample in ipairs(data.samples)do local step=source.boss.steps[sample.firstStep];if sample.state.part_head=='exposed'then r.predictions[#r.predictions+1]={demonstrated=sample.action,before=old and P.predict(old.model,step.before)or nil,after=P.predict(candidate.model,step.before)}end end
  assert(I.equal(before,protected()),'Public demonstration/learning changed adopted models, wallet or missions')
  r.protectedStateUnchanged=true;r.message=controls().arena.message;save()
 end,debug.traceback)
 if not ok and activeLevel then
  local withdrew=activeLevel.battle.phase=='playing'
  if withdrew then activeLevel.withdraw:emit('Tapped')end
  -- Natural failure also enters asynchronous settlement. Publishing FAIL here
  -- would let the runner terminate Dora before the observation is saved.
  local stop=D.App.runningTime+20
  while activeLevel.phase~='result'and activeLevel.phase~='save-error'and D.App.runningTime<stop do D.sleep(.02)end
  r.failedLessonWithdrawn=withdrew and activeLevel.phase=='result'
  r.failedLessonSettled=activeLevel.phase=='result';r.failedLessonSettlementPhase=activeLevel.phase
  r.failedLessonTrace=activeLevel.battle.bossTrace
  r.failedLessonSourceId=activeLevel.battle.demonstrationSourceId
 end
 if not ok and activeLevel then r.terminalBattle={phase=activeLevel.battle.phase,report=activeLevel.battle.report,trace=activeLevel.battle.bossTrace};save()end
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
