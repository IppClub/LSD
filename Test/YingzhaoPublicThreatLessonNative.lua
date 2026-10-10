-- Public demonstration/learning route with an actual copied failed save.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-public-threat-lesson-result.json'
local r={status='RUNNING',osInput=false,notHumanDemonstration=true,naturalVictory=false,commands={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),32)
  assert(prior.operationVariant=='visible-remote-interior-no-chase-public-route-v11'and prior.outcome=='failed')
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-boss%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-public-threat-lesson-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Public threat lesson route timeout');D.sleep(.02)end end
  local I=require('Training.FlowerIdentity');local S=require('Training.YingzhaoAdoptionStore');local E=require('Economy.Store');assert(E.open())
  local function protected()return {basic=D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),other=D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot'),missions=D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),wallet=E.wallet().available,ninilite=S.state('ninilite'),wuyun=S.state('wuyun')}end
  local before=protected();r.balanceBefore=before.wallet
  local store=require('Training.YingzhaoPolicyStore');local old=assert(store.loadLatestAsync('ninilite'));r.oldCandidate=old.id
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'ninilite');wait(controls)
  local menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('大英招示范'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout')end)
  D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout').saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoDemonstration end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle;local a=b.demonstrator
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  local function record(name)r.commands[#r.commands+1]={name=name,at=D.App.runningTime-b.started,observed=b.observeYingzhao(a.student)};save()end
  local function shoot(part)
   wait(function()return b.phase~='playing'or a:available('laser')and require('Training.YingzhaoActions').plan(b,a,part)end,20)
   assert(b.phase=='playing','Natural demonstration ended before action');c.targetButtons[part]:emit('Tapped');record('shoot@'..part)
   local count=#b.bossTrace.steps;c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')
   wait(function()return #b.bossTrace.steps>count and not a:isAttacking()and not b.bossCombat:pendingActor('ninilite')end)
  end
  for i=1,5 do if b.observeYingzhao(a.student).part_head=='exposed'then break end;shoot('head')end
  assert(b.observeYingzhao(a.student).part_head=='exposed','Public shots did not expose head')
  r.headExposed=true;save()
  -- A contextual lesson through existing HUD controls, using visible observations.
  -- Do not change positions, Boss attacks, damage, armor, cooldowns or models.
  local untilAt=D.App.runningTime+65;local held
  r.lesson={commands={},waveRetreatRequests=0,skillRequests=0,armoredTargetRequests=0}
  local function motion(side)
   if held==side then return end
   if held then c.hud.move:emit(held,false)end
   held=side
   if side then c.hud.move:emit(side,true)end
  end
  while b.phase=='playing'and D.App.runningTime<untilAt do
   local obs=b.observeYingzhao(a.student)
   local dangerous=obs.waveReach=='approaching'or obs.threat=='melee'or obs.threat=='rear'
   if dangerous and obs.bossVisible then
    local side=obs.ownX<obs.bossX and 'Left'or'Right'
    if not a:isAttacking()then
     motion(side)
     r.lesson.commands[#r.lesson.commands+1]={action='retreat',side=side,at=obs.at,threat=obs.threat,waveReach=obs.waveReach}
     if obs.waveReach=='approaching'then r.lesson.waveRetreatRequests=r.lesson.waveRetreatRequests+1 end
    end
   else
    motion(nil)
    if not a:isAttacking()then
     local aligned=obs.skillControl and (obs.skillControl.mentorFaceRight and obs.fireAimRight or obs.fireAimLeft)=='aligned'
     local vulnerable=obs.target=='summon'or obs.part_head=='exposed'
     if obs.skillState=='ready'and aligned and vulnerable then
      record('fire');c.fire:emit('TapBegan');r.lesson.skillRequests=r.lesson.skillRequests+1
     elseif a:available('laser')then
      local part
      for _,id in ipairs({'head','forelegs','arms','hindlegs','torso','flank'})do
       if obs['part_'..id]~='exposed'and require('Training.YingzhaoActions').plan(b,a,id)then part=id;break end
      end
      if part then
       c.targetButtons[part]:emit('Tapped');record('shoot@'..part)
       c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')
       r.lesson.armoredTargetRequests=r.lesson.armoredTargetRequests+1
      end
     end
    end
   end
   D.sleep(.04)
  end
  motion(nil);save()
  c.withdraw:emit('Tapped');wait(function()return c.phase=='result'end)
  assert(c.battle.demonstrationSourceId and c.result.resultLayout=='MissionFail');r.sourceId=c.battle.demonstrationSourceId
  local source=assert(require('Training.YingzhaoStore').loadAsync(r.sourceId));r.source=source
  local data=assert(require('Training.YingzhaoSamples').extract({source},'ninilite'));r.newActions=data.actions;r.newSamples=#data.samples
  local changed=0;for _,sample in ipairs(data.samples)do if sample.state.part_head=='exposed'and sample.action~='shoot@head'then changed=changed+1 end end
  r.postArmorSamples=changed
  r.lesson.actualThreatRetreatSamples=0;r.lesson.actualWaveRetreatSamples=0;r.lesson.actualSkillSamples=0
  for _,sample in ipairs(data.samples)do
   if sample.action=='bmove'and(sample.state.waveReach=='approaching'or sample.state.threat=='melee'or sample.state.threat=='rear')then r.lesson.actualThreatRetreatSamples=r.lesson.actualThreatRetreatSamples+1 end
   if sample.action=='bmove'and sample.state.waveReach=='approaching'then r.lesson.actualWaveRetreatSamples=r.lesson.actualWaveRetreatSamples+1 end
   if sample.action:match('^fire@')then r.lesson.actualSkillSamples=r.lesson.actualSkillSamples+1 end
  end
  assert(r.lesson.actualThreatRetreatSamples>0,'No actual visible-threat retreat sample; retain source but do not build a candidate')
  c.result.baseButton:emit('Tapped');wait(controls)
  menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('学习部位'):emit('Tapped')
  wait(function()return controls().arena.mode~='building'end,60);assert(controls().arena.message:find('已保存',1,true),controls().arena.message)
  local candidate=assert(store.loadLatestAsync('ninilite'));assert(candidate.id~=old.id);r.newCandidate=candidate.id;r.model=candidate.model
  local included=false;for _,episode in ipairs(candidate.model.sourceEpisodes)do if episode==source.episode then included=true end end;assert(included,'New public demonstration missing from candidate')
  r.predictions={};local P=require('Training.YingzhaoPolicy')
  for _,sample in ipairs(data.samples)do local step=source.boss.steps[sample.firstStep];if sample.state.part_head=='exposed'then r.predictions[#r.predictions+1]={demonstrated=sample.action,before=P.predict(old.model,step.before),after=P.predict(candidate.model,step.before)}end end
  assert(I.equal(before,protected()),'Public demonstration/learning changed adopted models, wallet or missions')
  r.protectedStateUnchanged=true;r.message=controls().arena.message;save()
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
