-- Same existing models and public route; medium-distance mentor covers urgent adds.
-- Scripted manual sweep uses visible state; no HP, wallet, aim or hit injection.
local standOff=true
local publicRoute=true
local interiorPilot=true
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-precision-team-cover-natural-result.json';local r={status='RUNNING',osInput=false,naturalVictory=false,checks={},formalComponentEncounter=not publicRoute,publicRouteEncounter=publicRoute,operationVariant=publicRoute and (standOff and 'visible-remote-intended-part-public-route-v9' or 'visible-midrange-idle-intended-part-public-route-v10') or standOff and 'visible-remote-intended-part-edge-flank-v8' or 'visible-intended-part-persistent-flank-v7'}
if interiorPilot then assert(publicRoute and standOff,'Interior pilot requires public remote route');r.operationVariant='visible-remote-interior-no-chase-public-route-v11';r.headAngularMargin=1.2;r.noChaseSummons=true end
r.operationVariant='visible-midrange-precision-team-cover-early-flank-public-route-v13';r.noChaseSummons=false;r.pilotParameters={bossNear=650,bossFar=900,urgentCoverRange=600,headAngularMargin=1.2,headPrecisionRequired=true,edgeFlankDistanceRestricted=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32)
  assert(prior.status=='PASS'and prior.algorithm=='yingzhao-c45'and prior.adoptedCheckpoint:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-ui%-adopted%-checkpoint%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-adopted-boss-natural-'..os.time()..'.db';r.database=db;r.parentEvidence=parent;save()
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.adoptedCheckpoint,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.YingzhaoAdoptionStore');local equal=require('Training.FlowerIdentity').equal
  local models=assert(require('Training.FlowerPractice').models());local first=assert(S.loadAsync('ninilite',models,'mission'));local firstState=S.state('ninilite');assert(first.id==prior.active and S.state('wuyun').current==0)
  local function basic()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local before=basic();local E=require('Economy.Store');assert(E.open());local initial=E.wallet().available
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Natural encounter route timed out');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'wuyun');wait(controls)
  local ui=controls();local menu=ui:getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位对照'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-budget')end);D.Director.ui3D:getChildByTag('yingzhao-comparison-budget').saveButton:emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-result')end,420)
  local v=D.Director.ui3D:getChildByTag('yingzhao-comparison-result');assert(v.saved,v.saveError or v.error)
  assert(v.report.candidate.characterId=='wuyun'and equal(v.report.companion,first.proof.candidate.model))
  for _,round in ipairs(v.report.rounds)do assert(equal(round.companion,first.proof.candidate.model)and #round.companionDecisions>0)end
  assert(equal(v.report.setup.states.ninilite,firstState));r.comparisonId=v.saved;r.checks.actualCompanionCompared=true;save();v.backButton:emit('Tapped');wait(controls)
  ui=controls();menu=ui:getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位成果'):emit('Tapped')
  wait(function()local v=D.Director.ui3D:getChildByTag('yingzhao-adoption');return v and not v.state.busy end)
  local p=D.Director.ui3D:getChildByTag('yingzhao-adoption').state;assert(p.bundle and p.adopt.visible);p.adopt:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end)
  local second=assert(S.loadAsync('wuyun',models,'mission'));assert(p.already and equal(firstState,S.state('ninilite'))and S.loadAsync('ninilite',models,'mission').id==first.id);r.adoptions={ninilite=first.id,wuyun=second.id};r.checks.roleIsolatedAdoption=true;save();p.back:emit('Tapped')
  local expeditionSupport
  if publicRoute then
   -- Leave through the actual training button and walk every public door.
   -- Expedition fuel and the four gold drops are earned by this traversal.
   wait(controls);controls():getChildByTag('training-menu'):getChildByTag('返回训练室'):emit('Tapped')
   local function currentWorld()return D.Platformer.Data.store.world end
   local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==currentWorld()end)end
   wait(function()return currentWorld()and currentWorld().tag=='TrainingRoom'and player()and not player().busy end)
   r.publicRoute={};local function routeStage(name)r.publicRoute[#r.publicRoute+1]={scene=name,at=D.App.runningTime};save()end
   routeStage('TrainingRoom')
   local function routeMove(x)
    local p=assert(player());local h;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then h=n end end);assert(h)
    local side=p.unit.x<x and 'Right'or'Left';h.move:emit(side,true)
    wait(function()return math.abs(p.unit.x-x)<35 end,45);h.move:emit(side,false);D.sleep(.3)
   end
   local function door(side,target)
    local old=currentWorld();routeMove(side=='left'and 120 or side=='right'and old.sceneWidth-120 or old.center.x)
    local p=player();local index;for i=1,p.moveTargets.count do if p.moveTargets:get(i)==target then index=i end end
    assert(index and p.interaction.menu.enabled,'Missing public door '..target);p.interaction:emit('Tapped',index)
    wait(function()return currentWorld()~=old and currentWorld().tag==target and player()end);D.sleep(.3);routeStage(target)
   end
   door('left','PassageB');door('left','PreparationRoom');door('left','PassageA');door('center','PassageC');door('left','Station')
   routeMove(currentWorld().sceneWidth-1800);currentWorld():getChildByTag('boardingTerminal'):emit('Tapped',1)
   wait(function()return currentWorld().tag=='TrainA'and player()end);routeStage('TrainA');routeMove(currentWorld().sceneWidth-170)
   currentWorld():getChildByTag('groundDeploymentTerminal'):emit('Tapped',1);wait(function()return currentWorld().groundDeployment end)
   local deployment=currentWorld().groundDeployment;assert(deployment.team and deployment.view.secondCard)
   if not deployment.formation.wuyun then deployment.view.secondCard.children.first:emit('Tapped');wait(function()return deployment.formation.wuyun end)end
   deployment.view.startButton:emit('Tapped');wait(function()return currentWorld().tag=='AbandonedCity'and currentWorld().energySquad and player()end)
   routeStage('AbandonedCity');routeMove(4650)
   local expedition=assert(currentWorld().groundExpedition);expeditionSupport=expedition.support
   r.routeSupport={gold=expeditionSupport.gold,spent=expeditionSupport.spent,machineHP=expeditionSupport.machineHP,collected=expedition.collected,collectedIDs=D.json.decode(D.json.encode(expeditionSupport.collected),32),hp={table.unpack(expeditionSupport.hp)}}
   assert(E.wallet().available==initial and basic()==before,'Walking changed wallet or adopted basic models');r.checks.publicExpeditionNoWalletOrModelInjection=true;save()
  else require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=4650,energySquad=true})end
  local world=D.Platformer.Data.store.world;local gate=assert(world.disarmGate)
  wait(function()return gate.menu.visible and gate.menu.menu.enabled end);gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end)
  local supply=gate.supplyPanel;r.loadoutBefore=D.json.decode(D.json.encode(supply.values),32)
  -- Normal public quantity buttons, not a database/configuration write.
  while supply.values['mentor:kinetic']<60 do local delta=60-supply.values['mentor:kinetic']>=5 and 5 or 1;supply.buttons[1][delta]:emit('Tapped')end
  r.selectedLoadout=D.json.decode(D.json.encode(supply.values),32);r.reservedBudget=supply.quote.total;save()
  assert(supply.quote.total<=E.wallet().available);supply.saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel end);local level=D.Platformer.Data.store.world.patrolLevel;local b=level.battle
  assert(b.bossCombat.view.node.parent==level.controls and not b.bossCombat.view.closed,'Boss status view lost ownership during adoption loading')
  if publicRoute then assert(b.support==expeditionSupport,'Formal Boss replaced earned expedition support')end
  assert(b.phase=='ready'and b.scenario.timeLimit==180 and b.bossCombat.boss.enemyHP==1000 and b.bossCombat.boss.enemy.unitDef.scale==1,'Authored Boss rules changed')
  r.authoredRules={maxHP=b.bossCombat.boss.enemyHP,scale=b.bossCombat.boss.enemy.unitDef.scale,timeLimit=b.scenario.timeLimit};save()
  for actor,id in pairs(r.adoptions)do assert(b.yingzhaoDeployments[actor].status=='adopted'and b.yingzhaoDeployments[actor].id==id and b.yingzhaoCandidates[actor].characterId==actor)end
  level.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  local function shownTarget(delta)
   local origin=require('Combat.Muzzle').manualPreview(b.world,b.mentor,b.mentorAim.angle,b.mentor.faceRight)
   local theta=-math.rad(b.mentorAim.angle+(delta or 0));local facing=b.mentor.faceRight and 1 or -1
   local hit,terrain=b.bossCombat:contact(origin,{x=origin.x+facing*2400*math.cos(theta),y=origin.y+2400*math.sin(theta)})
   if terrain or not hit then return end
   return hit.enemy and 'summon' or hit.part
  end
  local pilot={};r.previewReleases={};r.pilotTrace={};local nextPilotSample=0;r.flanks={};r.reorientationReleases={};local deadline=D.App.runningTime+210;r.manualPlans={};local nextGather=0;local previousCue
  local function move(direction)level.hud.move:emit('Right',direction==1);level.hud.move:emit('Left',direction==-1)end
  while b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Natural adopted battle timed out')
   if b.phase=='playing'then
    local boss=b.bossCombat.boss;local visible=b.bossCombat.armor:available();local target=visible and boss or b:target(b.mentor)
    -- Observe imminent summoned attackers before choosing boss stand-off movement.
    local coverTarget,coverDistance
    for _,enemy in ipairs(b.enemies)do
     if enemy~=boss and enemy.enemyHP>0 and enemy.enemy.visible and enemy.enemy.opacity>.1 then
      local distance=math.abs(enemy.enemy.x-b.mentor.x)
      if (distance<500 or math.abs(enemy.enemy.x-b.machine.x)<450)and(not coverDistance or distance<coverDistance)then coverTarget=enemy;coverDistance=distance end
     end
    end
    -- Move within normal firing range of urgent adds threatening the team or machine.
    if coverTarget and not pilot.flank then target=coverTarget end
    if D.App.runningTime>=nextPilotSample then
     nextPilotSample=D.App.runningTime+.25
     r.pilotTrace[#r.pilotTrace+1]={at=D.App.runningTime-b.started,x=b.mentor.x,hp=b.mentorHP,held=b.mentorAim.held,shot=b.mentorAim.shot,canStart=b.mentorAim.canStart(),faceRight=b.mentor.faceRight,clip=b.mentor.playable.current,bossX=boss.enemy.x,bossClip=boss.enemy.playable.current,cover=coverTarget~=nil,flank=pilot.flank or 0,angle=b.mentorAim.angle,machineX=b.machine.x,machineHP=b.support.machineHP,gold=b.support.gold,niniliteX=b.arena.student.x,wuyunX=b.wuyun.student.x}
    end
    if target then
     local dx=target.enemy.x-b.mentor.x;local targetingBoss=target==boss;local near,far=targetingBoss and 650 or 0,targetingBoss and 900 or 600
     local direction
     local observation=b.observeYingzhao(b.mentor)
     if pilot.flank and ((b.mentor.x-boss.enemy.x)*pilot.flank>=near or pilot.flank>0 and b.mentor.x>=b.maxX-50 or pilot.flank<0 and b.mentor.x<=b.minX+50)then
      local log=r.flanks[#r.flanks];log.ended=D.App.runningTime-b.started;log.endX=b.mentor.x;log.bossEndX=boss.enemy.x
      level.gather:emit('TapBegan');pilot.flank=nil;save()
     end
     local bossDX=boss.enemy.x-b.mentor.x
     local atEdge=bossDX>0 and b.mentor.x<=b.minX+300 or bossDX<0 and b.mentor.x>=b.maxX-300
     if visible and not pilot.flank and atEdge and (observation.bossAction=='idle' or observation.bossAction=='hunt')then
      -- Use the existing release button before crossing the target. Keeping
      -- a held aim locks tutorial facing, so it cannot turn after the crossing.
      -- Any successful release is an ordinary shot with ordinary ammo cost.
      if b.mentorAim.held then
       r.reorientationReleases[#r.reorientationReleases+1]={at=D.App.runningTime-b.started,reason='before-flank',angle=b.mentorAim.angle,x=b.mentor.x,faceRight=b.mentor.faceRight}
       level.hud.weapon:emit('TapEnded');pilot.aim=nil
      end
      pilot.flank=bossDX>0 and 1 or -1;r.flanks[#r.flanks+1]={started=D.App.runningTime-b.started,direction=pilot.flank,x=b.mentor.x,bossX=boss.enemy.x,cue=observation.bossAction};level.gather:emit('TapBegan');nextGather=D.App.runningTime+3;save()
     end
     local escape=require('Enemy.GroundWave').escapeDirection(boss.guard,b.mentor,visible)
     if pilot.flank then direction=pilot.flank elseif escape then direction=escape elseif math.abs(dx)>far then direction=dx>0 and 1 or -1 elseif math.abs(dx)<near then direction=dx>0 and -1 or 1 end
     if direction and(direction<0 and b.mentor.x<=b.minX+20 or direction>0 and b.mentor.x>=b.maxX-20)then direction=nil end
     if not escape and not pilot.flank and (b.mentorAim.held or b.mentorAim.canStart()and math.abs(dx)>=near and math.abs(dx)<=far)then direction=nil end
     if direction then
      -- Moving does not require firing a partially aimed shot.
      move(direction)
     else
      move(0)
      if b.mentorAim.held then
       if pilot.aim then
        for _,enemy in ipairs(b.enemies)do if enemy~=boss and enemy.enemyHP>0 and enemy.enemy.visible and enemy.enemy.opacity>.1 and (math.abs(enemy.enemy.x-b.mentor.x)<350 or math.abs(enemy.enemy.x-b.machine.x)<450)then
         local cover=require('Training.YingzhaoActions').plan(b,{student=b.mentor},'summon',true);if cover and cover.faceRight==b.mentor.faceRight then pilot.aim=cover end
        end end
        -- A visible moving target can leave the angle solved when the hold began.
        -- Re-observe its geometry; the HUD still sweeps and releases normally.
        local displayedPart=shownTarget() -- capture nil as one value, rather than an empty return list
        local current=require('Training.YingzhaoActions').plan(b,{student=b.mentor},pilot.aim.intent,true)
        local safelyInside=not interiorPilot or pilot.aim.intent~='head' or shownTarget(-1.2)=='head' and shownTarget(1.2)=='head'
        local changedSide=current and current.faceRight~=b.mentor.faceRight
        local lostGeometry=not current and D.App.runningTime-b.mentorAim.started>1
        if changedSide or lostGeometry then
         r.reorientationReleases[#r.reorientationReleases+1]={at=D.App.runningTime-b.started,reason=changedSide and 'target-changed-side' or 'target-left-reachable-cone',angle=b.mentorAim.angle,x=b.mentor.x,faceRight=b.mentor.faceRight}
         level.hud.weapon:emit('TapEnded');pilot.aim=nil;save()
        elseif current and (standOff or pilot.aim.intent=='summon' or b.observeYingzhao(b.mentor).bossAction=='idle')and current.faceRight==b.mentor.faceRight and D.App.runningTime-b.mentorAim.started>.16 and displayedPart==pilot.aim.intent and safelyInside and (pilot.aim.intent~='head' or b.mentorAim.precision)then
         r.previewReleases[#r.previewReleases+1]={at=D.App.runningTime-b.started,angle=b.mentorAim.angle,shownPart=displayedPart,plannedPart=pilot.aim.intent,precision=b.mentorAim.precision}
         level.hud.weapon:emit('TapEnded');pilot.aim=nil
        end
       end
      elseif b.mentorAim.canStart()then
       local observation=b.observeYingzhao(b.mentor);local parts={};local urgent=false
       for _,enemy in ipairs(b.enemies)do if enemy~=boss and enemy.enemyHP>0 and enemy.enemy.visible and enemy.enemy.opacity>.1 then
        if math.abs(enemy.enemy.x-b.machine.x)<450 or math.abs(enemy.enemy.x-b.mentor.x)<350 then urgent=true end
       end end
       if urgent then parts[#parts+1]='summon'end
       -- Probe the head, then use its observed armor state; no guaranteed hit,
       -- hidden HP/armor access, or changes to a learner's chosen action.
       if observation.part_head~='armored'then parts[#parts+1]='head'end
       for _,part in ipairs({'forelegs','arms','hindlegs','torso','flank'})do if observation['part_'..part]=='exposed'then parts[#parts+1]=part end end
       if observation.part_head=='armored'then parts[#parts+1]='head'end
       parts[#parts+1]='summon';parts[#parts+1]='forelegs'
       local aim;for _,part in ipairs(parts)do aim=require('Training.YingzhaoActions').plan(b,{student=b.mentor},part,true);if aim then break end end
       if aim then
        if b.mentor.faceRight~=aim.faceRight then move(aim.faceRight and 1 or -1)
        else pilot.aim=aim;level.hud.weapon:emit('TapBegan');if #r.manualPlans<200 then r.manualPlans[#r.manualPlans+1]={part=aim.intent,angle=aim.angle,at=D.App.runningTime-b.started}end end
       end
      end
     end
     -- Let the public regroup finish before issuing another finite cast.
     if pilot.flank and D.App.runningTime>=nextGather then level.gather:emit('TapBegan');nextGather=D.App.runningTime+3 end
     if not pilot.flank and D.App.runningTime>=(b.gatherUntil or 0)then
      for _,a in ipairs(b.learners)do
       local enemy=b:target(a.student)
       local inRange=enemy and (a.character.id=='ninilite' or require('Ground.Tactics').inWind(enemy.enemy.x,enemy.enemy.y,a.student.x,a.student.y,a.student.faceRight and 1 or -1))
       if a.studentHP>0 and not a:isAttacking()and inRange then (a.character.id=='ninilite'and level.fire or level.wind):emit('TapBegan')end
      end
     end
     -- Use the existing finite regroup button only when a visible spread is
     -- wasting the life field; never move learners or override their models.
     if standOff and not pilot.flank and D.App.runningTime>=nextGather then
      local xs={b.mentor.x,b.arena.student.x,b.wuyun.student.x}
      if math.max(table.unpack(xs))-math.min(table.unpack(xs))>420 then
       level.gather:emit('TapBegan');nextGather=D.App.runningTime+6
      end
     end
     local machineEscape=require('Enemy.GroundWave').escapeDirection(boss.guard,b.machine,visible)
     local observation=b.observeYingzhao(b.mentor);local clip=boss.enemy.playable.current
     local closeStrike=visible and(clip=='punch'or clip=='massive')and math.abs(boss.enemy.x-b.machine.x)<850
     local cue=(machineEscape or closeStrike)and(clip..':'..tostring(observation.bossTiming and observation.bossTiming.started))or nil
     if cue and cue~=previousCue and D.App.runningTime>=nextGather then level.gather:emit('TapBegan');previousCue=cue;nextGather=D.App.runningTime+3 end
     if not cue then previousCue=nil end
    end
   end
   D.sleep(.02)
  end
  move(0);if b.mentorAim.held then level.hud.weapon:emit('TapEnded')end
  r.outcome=b.phase;r.bossHP=b.bossCombat.boss.enemyHP;r.battle=b.report;r.naturalVictory=b.phase=='won';save()
  local resource=b.supplies:evidence();b.bossTrace.resources=resource
  r.uncommittedEpisode={schemaVersion=1,closed=true,trainable=false,episode=resource.attempt,versions={resources=1,bigYingzhao=1},resources=resource,boss=b.bossTrace}
  local valid,why=require('Enemy.BigYingzhaoEvidence').validate(r.uncommittedEpisode);r.episodeValidation={ok=valid,reason=why};save()
  r.decisions={};for actor in pairs(r.adoptions)do local rows=b.yingzhaoDecisionsByActor[actor];assert(#rows>0);local accepted=0;for _,d in ipairs(rows)do assert(d.origin=='adopted');if d.accepted then accepted=accepted+1 end end;r.decisions[actor]={count=#rows,accepted=accepted}end
  wait(function()return level.phase=='result'or level.phase=='save-error'end,45);assert(level.phase=='result',level.error);assert(level.result.resultLayout==(b.phase=='won'and'Settlement'or'MissionFail'))
  for actor,id in pairs(r.adoptions)do assert(b.report.learners[actor].training.adoptionId==id and b.report.learners[actor].training.domain=='big-yingzhao')end
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));local episode=assert(require('Training.CombatStore').load(attempt));for actor,id in pairs(r.adoptions)do assert(episode.boss.deployments[actor].id==id)end
  assert(E.wallet().available==initial+b.report.economy.net and not E.active()and basic()==before);r.cost=b.report.economy.cost;r.balanceAfter=E.wallet().available;r.checks.naturalFormalReportAndLedger=true;save()
  level.result.baseButton:emit('Tapped');wait(function()
   local w=D.Platformer.Data.store.world
   return w and w~=b.world and w.tag=='TrainA'and D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end)
  end)
  r.checks.normalTrainReturn=true;save()
  assert(b.phase=='won','Natural adopted Boss encounter failed: '..tostring(b.reason))
  require('Training.Level')(nil,'wuyun');wait(controls);ui=controls();menu=ui:getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位成果'):emit('Tapped')
  wait(function()local v=D.Director.ui3D:getChildByTag('yingzhao-adoption');return v and not v.state.busy end);p=D.Director.ui3D:getChildByTag('yingzhao-adoption').state;assert(p.current.id==second.id and p.rollback.visible);p.rollback:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end)
  assert(S.state('wuyun').current==0 and equal(S.state('ninilite'),firstState)and S.loadAsync('ninilite',models,'mission').id==first.id and basic()==before);r.checks.secondRollbackPreservesFirst=true;p.back:emit('Tapped')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
