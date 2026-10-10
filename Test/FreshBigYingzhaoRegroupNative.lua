-- Earned energy journey branch, physical public route, no HP/unlock/model injection.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/fresh-big-yingzhao-regroup-result.json'
local r={status='RUNNING',osInput=false,stages={}};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/fresh-disarm-current-result.json'),32)
  assert(prior.status=='PASS'and prior.sameJourneyBranch and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-disarm%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/fresh-big-yingzhao-current-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  r.database=db;r.source=prior.database
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available;assert(r.balanceBefore==prior.balanceAfter)
  local S=assert(require('Mission.Service').open());assert(S:summary().unlocks['yingzhao-route-cleared'])
  local function models()return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local original=models()
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
  gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end)
  local panel=gate.supplyPanel;assert(panel.quote.total<=E.wallet().available);r.budget=panel.quote.total;panel.saveButton:emit('Tapped')
  wait(function()return world().patrolLevel end);local level=world().patrolLevel;local b=level.battle
  assert(b.bossCombat and not b.supplies.isVirtual and not b.yingzhaoDemonstration);
  local statusView=b.bossCombat.view;r.partsView={initialUnknown=true,checked=0}
  for _,id in ipairs(statusView.partOrder)do assert(statusView.partLabels[id].text:find('未观察'));assert(not statusView.observedParts[id])end;stage('formal-boss-ready');r.partsView.screenshots={}
  local function screenshot(name)
   local path=D.Content.writablePath..'/boss-parts-'..name..'.tga';D.App:saveScreenshot(path);r.partsView.screenshots[#r.partsView.screenshots+1]=path;D.sleep(.05)
  end
  for _,size in ipairs({D.Size(683,384),D.Size(960,540)})do D.App.winSize=size;D.sleep(.4);screenshot('unknown-'..math.floor(D.App.bufferSize.width))end
  assert(level.headerHeight==255);level.start:emit('Tapped');wait(function()return level.headerHeight==125 end,3)
  local deadline=D.App.runningTime+210;local pilot={};local nextGather=0;local nextSample=0;r.controls={};r.positions={};r.aimGuard={blockedChecks=0,heldChecks=0,resumedShots=0};r.regroup={roles={},modelAfterReach={}};r.edgeGather={checked=0,compressedObserved=false}
  local function control(kind,extra)if #r.controls<100 then r.controls[#r.controls+1]={kind=kind,at=D.App.runningTime-b.started,extra=extra}end end
  local function turnMove(direction)
   level.hud.move:emit('Right',direction==1);level.hud.move:emit('Left',direction==-1)
  end
  while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Natural formal Boss battle stalled')
   if b.phase=='playing'then
    if not r.regroup.started then
     level.gather:emit('TapBegan');r.regroup.started=D.App.runningTime
     for _,a in ipairs(b.learners)do r.regroup.roles[a.character.id]={before=a.metrics.modelActions}end
    end
    assert(level.headerHeight==125,'Battle instructions did not contract')
    for _,a in ipairs(b.learners)do
     local row=r.regroup.roles[a.character.id]
     if a.regroupComplete and not row.reached then row.reached=D.App.runningTime;row.actionsAtReach=a.metrics.modelActions end
     if row.reached and D.App.runningTime<r.regroup.started+3 and a.metrics.modelActions>row.actionsAtReach then
      row.resumedBeforeDeadline=true;row.resumedAt=row.resumedAt or D.App.runningTime
      for _,step in ipairs(b.bossTrace.steps)do if step.actor==a.character.id and step.started>row.reached and step.origin=='model'then r.regroup.modelAfterReach[a.character.id]=true end end
     end
    end
    if r.regroup.modelAfterReach.ninilite and r.regroup.modelAfterReach.wuyun and not r.regroup.screenshot then
     screenshot('compact-header-early-model-resume');r.regroup.screenshot=true;save()
    end
    if b.gatherPlan and D.App.runningTime<b.gatherUntil then
     r.edgeGather.checked=r.edgeGather.checked+1
     if b.gatherPlan._compressed and not r.edgeGather.compressedObserved then
      D.sleep(.04);assert(level.status.text:find('退路窄'),'Compressed regroup has no readable warning')
      r.edgeGather.compressedObserved=true;r.edgeGather.spacing=b.gatherPlan._spacing
      r.edgeGather.targets={ninilite=b.gatherPlan.ninilite,wuyun=b.gatherPlan.wuyun}
      screenshot('compressed-rear-slots-warning');save()
     end
    end
    local latest={};for _,hit in ipairs(b.bossTrace.hits)do if hit.target=='big-yingzhao'then latest[hit.part]=hit.apAfter end end
    for _,id in ipairs(statusView.partOrder)do
     local seen=statusView.observedParts[id];assert((latest[id]~=nil)==(seen~=nil),'Unobserved armor was revealed')
     if seen then assert(seen.ap==latest[id],'Part display differs from last actual hit');r.partsView.checked=r.partsView.checked+1 end
    end
    if latest.forelegs==0 and not r.partsView.broken then
     r.partsView.broken=true;r.partsView.brokenLabel=statusView.partLabels.forelegs.text;assert(r.partsView.brokenLabel:find('已破甲'))
     r.stage='broken-part-visual';screenshot('actual-broken-forelegs');save()
    end
    local blocked=require('Combat.Displacement').blocked(b.mentor)
    if blocked and b.mentor.onSurface then
     r.aimGuard.blockedChecks=r.aimGuard.blockedChecks+1
     assert(not b.mentorAim.canStart(),'Grounded hit reaction exposed available aim')
     level.hud.weapon:emit('TapBegan');assert(not b.mentorAim.held,'Hit reaction accepted new manual aim')
    end
    if blocked and b.mentorAim.held then r.aimGuard.heldChecks=r.aimGuard.heldChecks+1 end
    local boss=b.bossCombat.boss;local target=b:target(b.mentor)
    local visible=b.bossCombat.armor:available();local anchor=visible and boss or target
    if anchor then
     local dx=anchor.enemy.x-b.mentor.x;local minX,maxX=b.minX or 1200,b.maxX or 3300
     local near,far=visible and 1250 or 350,visible and 1550 or 600
     if pilot.flank and ((b.mentor.x-anchor.enemy.x)*pilot.flank>=near or (pilot.flank>0 and b.mentor.x>=maxX-50)or(pilot.flank<0 and b.mentor.x<=minX+50))then pilot.flank=nil end
     if visible and not pilot.flank and math.abs(dx)<near and ((dx>0 and b.mentor.x<=minX+80)or(dx<0 and b.mentor.x>=maxX-80))then pilot.flank=dx>0 and 1 or -1 end
     local escape=require('Enemy.GroundWave').escapeDirection(boss.guard,b.mentor,visible)
     local direction
     if escape and (escape>0 and maxX-b.mentor.x or b.mentor.x-minX)>20 then direction=escape;pilot.flank=nil
     elseif pilot.flank then direction=pilot.flank
     elseif math.abs(dx)>far then direction=dx>0 and 1 or -1
     elseif math.abs(dx)<near then direction=dx>0 and -1 or 1 end
     -- A target distance is advisory: make room for actual manual aim/release.
     -- Never keep pressing against an arena edge or cancel every held sweep.
     if direction and ((direction<0 and b.mentor.x<=minX+20)or(direction>0 and b.mentor.x>=maxX-20))then direction=nil end
     if not escape and b.mentorAim.held then direction=nil end
     if not escape and math.abs(dx)>550 and b.mentorAim.canStart()and D.App.runningTime>=(pilot.nextAim or 0)then direction=nil end
     if D.App.runningTime>=nextSample and #r.positions<400 then
      r.positions[#r.positions+1]={at=D.App.runningTime-b.started,x=b.mentor.x,bossX=boss.enemy.x,dx=dx,direction=direction or 0,escape=escape,held=b.mentorAim.held,canAim=b.mentorAim.canStart(),faceRight=b.mentor.faceRight}
      nextSample=D.App.runningTime+.25
     end
     if direction then
      if b.mentorAim.held then level.hud.weapon:emit('TapEnded')end
      turnMove(direction)
     else
      turnMove(0)
      if b.mentorAim.held then
       local aim=pilot.aim
       if not aim or D.App.runningTime-b.mentorAim.started>1.2 then level.hud.weapon:emit('TapEnded');pilot.aim=nil
       elseif D.App.runningTime-b.mentorAim.started>.16 and math.abs(b.mentorAim.angle-aim.angle)<3 then
        if r.aimGuard.blockedChecks>0 then r.aimGuard.resumedShots=r.aimGuard.resumedShots+1 end;control('manual-release',{part=aim.intent,angle=b.mentorAim.angle});level.hud.weapon:emit('TapEnded');pilot.aim=nil;pilot.nextAim=D.App.runningTime+1.05
       end
      elseif b.mentorAim.canStart()then
       local observation=b.observeYingzhao(b.mentor);local parts={};local added={}
       local urgent=false
       for _,enemy in ipairs(b.enemies)do if enemy~=boss and enemy.enemyHP>0 and enemy.enemy.visible and enemy.enemy.opacity>.1 then
        for _,t in ipairs(b:targets())do if t.hp()>0 and math.abs(t.unit.x-enemy.enemy.x)<450 then urgent=true end end
       end end
       if urgent then parts[#parts+1]='summon';added.summon=true end
       for _,part in ipairs(require('Training.YingzhaoFeatures').parts)do if observation['part_'..part]=='exposed'then parts[#parts+1]=part;added[part]=true end end
       for _,part in ipairs({'head','forelegs','arms','hindlegs','torso','flank','summon'})do if not added[part]then parts[#parts+1]=part end end
       local aim
       for _,part in ipairs(parts)do aim=require('Training.YingzhaoActions').plan(b,{student=b.mentor},part);if aim then break end end
       if aim then
        if b.mentor.faceRight~=aim.faceRight then turnMove(aim.faceRight and 1 or -1)
        else pilot.aim=aim;level.hud.weapon:emit('TapBegan');control('manual-aim',{part=aim.intent,angle=aim.angle})end
       end
      end
     end
     for _,a in ipairs({b.arena,b.wuyun})do
      if a.studentHP>0 and not a:isAttacking()and not a.student:isDoing(a.physical.fmove)and not a.student:isDoing(a.physical.bmove)and b.observeYingzhao(a.student).threat=='none'then
       (a.character.id=='ninilite'and level.fire or level.wind):emit('TapBegan')
      end
     end
     if level.gather and D.App.runningTime>=nextGather and (b.arena.studentHP<70 or b.wuyun.studentHP<70)then level.gather:emit('TapBegan');nextGather=D.App.runningTime+3.2;control('gather')end
    end
   end;D.sleep(.02)
  end
  r.battle=b.report;r.mentorShots=0;for _,step in ipairs(b.bossTrace.steps)do if step.actor=='mentor'and step.action=='shoot'then r.mentorShots=r.mentorShots+1 end end;r.outcome=b.phase;r.bossHP=b.bossCombat.boss.enemyHP;r.trace={steps=#b.bossTrace.steps,hits=#b.bossTrace.hits};save()
  wait(function()return level.phase=='result'or level.phase=='save-error'end)
  assert(level.phase=='result',level.error);assert(not E.active()and E.wallet().available==r.balanceBefore+b.report.economy.net)
  assert(level.result.resultLayout==(b.phase=='won'and'Settlement'or'MissionFail'))
  assert(models()==original,'Formal Boss changed adopted models')
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));local episode=assert(require('Training.CombatStore').load(attempt));assert(episode.boss.status==b.phase)
  r.balanceAfter=E.wallet().available;r.episodeSaved=true;r.sameJourneyBranch=true;save()
  assert(r.regroup.modelAfterReach.ninilite and r.regroup.modelAfterReach.wuyun,'Regroup did not restore model actions before deadline');assert(r.partsView.broken and r.partsView.checked>0,'No actual armor break displayed');r.partsView.labels={};for _,id in ipairs(statusView.partOrder)do r.partsView.labels[id]=statusView.partLabels[id].text end;assert(r.aimGuard.blockedChecks>0,'No natural grounded hit reaction observed');assert(r.aimGuard.resumedShots>0,'No manual aim resumed after natural hit reaction')
  level.result.baseButton:emit('Tapped');wait(function()return world()~=b.world and world().tag=='TrainA'end)
  r.returnedToTrain=true;r.stage='aim-guard-returned';r.naturalWin=b.phase=='won'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save();print('LSD_FRESH_BIG_YINGZHAO_REGROUP_'..r.status)
end)
