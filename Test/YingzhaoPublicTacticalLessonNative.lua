-- Public HUD teaching with real motion, authored attacks, finite virtual supplies.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-public-tactical-lesson-result.json'
local r={status='RUNNING',osInput=false,naturalVictory=false,notHumanDemonstration=true,publicTacticalLesson=true,characterId='wuyun',commands={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),64)
  local currentJourney=os.getenv('LSD_QA_CURRENT_JOURNEY_LESSON')=='1'
  if currentJourney then
   assert(prior.status=='PASS'and prior.currentJourneySource and prior.protectedStateUnchanged)
   assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-public%-post%-armor%-%d+%.db$'))
  else
   assert(prior.operationVariant=='visible-body-range-public-baseline-v20'and prior.outcome=='failed'and prior.checks.naturalFormalReportAndLedger)
   assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-boss%-natural%-%d+%.db$'))
  end
  r.currentJourneySource=currentJourney;r.parentDatabase=prior.database
  local db=D.Content.writablePath..'/yingzhao-public-tactical-lesson-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local S=require('Training.YingzhaoAdoptionStore');local I=require('Training.FlowerIdentity')
  local function protected()return {wallet=E.wallet().available,basic=D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),other=D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot'),missions=D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),ninilite=S.state('ninilite'),wuyun=S.state('wuyun')}end
  local before=protected();r.balance=before.wallet
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  local function wait(fn,t)local untilAt=D.App.runningTime+(t or 60);while not fn()do assert(D.App.runningTime<untilAt,'Tactical lesson UI timeout');D.sleep(.02)end end
  require('Training.Level')(nil,'wuyun');wait(controls)
  local menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('大英招示范'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout')end)
  local supply=D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout')
  while supply.values['wuyun:blade']<40 do supply.buttons[4][1]:emit('Tapped')end
  supply.saveButton:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoDemonstration end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle;local a=b.demonstrator;assert(a.character.id=='wuyun')
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  r.operationVariant='visible-contact-distance-public-lesson-v2'
  local spacingLesson=os.getenv('LSD_QA_REACH_SPACING')=='1'
  if spacingLesson then r.operationVariant='known-summon-latched-escape-public-lesson-v6' end
  local spacingTarget;local spacingUntil;local spacingDone={};local knownMeleeTarget;local escapeAction;local escapeSide
  local held;local healing=false;local nextAction=0;local stopAt=D.App.runningTime+60
  local function log(action,o)r.commands[#r.commands+1]={action=action,at=o.at,observed=o};if #r.commands%12==0 then save()end end
  local function motion(side,o)
   if held==side then return end
   if held then c.hud.move:emit(held,false)end;held=side
   if side then c.hud.move:emit(side,true)end
   log(side and('move-'..side)or'wait',o)
  end
  while b.phase=='playing'and D.App.runningTime<stopAt do
   local o=b.observeYingzhao(a.student);local direction
   local target=b:target(a.student)
   local face=target and target.enemy.x>=a.student.x
   -- Read the same present-time body segment as the blade, without applying damage.
   local contact=target and b.bossCombat:contact({x=a.student.x,y=a.student.y},{x=a.student.x+(face and 300 or -300),y=a.student.y})
   local bladeReach=contact and ((target==b.bossCombat.boss and not contact.enemy)or contact.enemy==target)
   local windInRange=target and require('Ground.Tactics').inWind(target.enemy.x,target.enemy.y,a.student.x,a.student.y,b.mentor.faceRight and 1 or -1)
   local windReady=o.skillState=='ready'and o.skillDefaultFacing=='toward'and windInRange and b.magic:available('wind')
   local wave=require('Enemy.GroundWave').escapeDirection(b.bossCombat.boss.guard,a.student,o.bossVisible)
   if spacingLesson and escapeAction and (o.bossAction~=escapeAction or o.bossWindow=='idle' or o.bossWindow=='recovery') then escapeAction=nil;escapeSide=nil end
   if wave then direction=wave
   elseif spacingLesson and escapeAction then direction=escapeSide
   elseif o.bossVisible and o.threat=='melee'then
    local toward=o.bossX>=o.ownX and 1 or -1
    -- A close advancing combo is crossed; otherwise open space early.
    direction=o.bossAction=='massive'and o.distance<=350 and toward or -toward
    -- Keep a visible attack's escape direction through its cue, avoiding
    -- alternating movement at the instantaneous threat-radius boundary.
    if spacingLesson then escapeAction=o.bossAction;escapeSide=direction end
   else
    local machineGap=b.support and math.abs(a.student.x-b.support.x)or 0
    if healing and(machineGap<=90 or o.ownHP>=90)then healing=false end
    if not healing and b.support and machineGap>180 and o.ownHP<75 then healing=true end
    if healing then direction=b.support.x>=a.student.x and 1 or -1
    elseif o.target=='summon'then
     local gap=o.targetX-o.ownX
     -- A real HUD spacing exercise after armor is learned from an actual hit.
     -- Preserve the source even if the moving reinforcement never opens a gap.
     if spacingLesson and knownMeleeTarget==target and not a:isAttacking() and o.targetArmor=='unarmored' and bladeReach and not spacingDone[target] then
      spacingDone[target]=true;spacingTarget=target;spacingUntil=D.App.runningTime+4.5
     end
     if spacingTarget==target and D.App.runningTime<spacingUntil then direction=gap>=0 and -1 or 1
     elseif math.abs(gap)>220 or not bladeReach then direction=gap>=0 and 1 or -1
     elseif math.abs(gap)<130 then direction=gap>=0 and -1 or 1 end
    elseif o.bossVisible and o.distance<450 then direction=o.bossX>=o.ownX and -1 or 1
    elseif o.bossVisible and(o.distance>520 or not bladeReach)then direction=o.bossX>=o.ownX and 1 or -1 end
    -- Stop through the actual HUD before a ready, reachable cast; do not queue it.
    if windReady and not a:isAttacking()and not healing and not(spacingTarget==target and spacingUntil and D.App.runningTime<spacingUntil)then direction=nil end
   end
   if direction and(direction<0 and o.ownX<=b.minX+25 or direction>0 and o.ownX>=b.maxX-25)then direction=nil end
   motion(direction and(direction>0 and'Right'or'Left')or nil,o)
   if not direction and not a:isAttacking()and D.App.runningTime>=nextAction then
    nextAction=D.App.runningTime+.3
    if windReady then log('wind',o);c.wind:emit('TapBegan')
    elseif a:available('melee')and target and bladeReach and (o.target=='summon'or o.target=='boss'and o.distance<=520 and(o.bossWindow=='idle'or o.bossWindow=='recovery'))then log('melee',o);c.melee:emit('TapBegan');if o.target=='summon' and o.targetArmor=='unarmored' then knownMeleeTarget=target end
    elseif a:available('laser')and o.target=='boss'and(o.bossWindow=='idle'or o.bossWindow=='recovery')then
     local part;for _,id in ipairs({'forelegs','head','arms','hindlegs','torso','flank'})do if o['part_'..id]~='exposed'and require('Training.YingzhaoActions').plan(b,a,id)then part=id;break end end
     if part then c.targetButtons[part]:emit('Tapped');log('shoot@'..part,o);c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')end
    end
   end
   D.sleep(.04)
  end
  if held then c.hud.move:emit(held,false)end
  if b.phase=='playing'then c.withdraw:emit('Tapped')end
  wait(function()return c.phase=='result'or c.phase=='save-error'end);assert(c.phase=='result',c.error)
  r.sourceId=assert(b.demonstrationSourceId);r.outcome=b.phase;r.seconds=b.report.seconds
  local source=assert(require('Training.YingzhaoStore').loadAsync(r.sourceId));r.source=source
  local data=assert(require('Training.YingzhaoSamples').extract({source},'wuyun'));r.samples=#data.samples;r.actions=data.actions
  local counts={threatMotion=0,cooldownMotion=0,summon=0,wind=0,melee=0,knownSummonDistantMotion=0,knownSummonReachableMelee=0}
  for _,s in ipairs(data.samples)do
   local moving=s.action=='fmove'or s.action=='bmove'
   if moving and(s.state.threat~='none'or s.state.waveReach=='approaching')then counts.threatMotion=counts.threatMotion+1 end
   if moving and s.state.skillCooldown~='ready'then counts.cooldownMotion=counts.cooldownMotion+1 end
   if s.state.target=='summon'then
    counts.summon=counts.summon+1
    if s.state.targetArmor=='unarmored' and s.state.meleeReach=='distant' and moving then counts.knownSummonDistantMotion=counts.knownSummonDistantMotion+1 end
    if s.state.targetArmor=='unarmored' and s.state.meleeReach=='reachable' and s.action=='melee' then counts.knownSummonReachableMelee=counts.knownSummonReachableMelee+1 end
   end
   if s.action:match('^wind@')then counts.wind=counts.wind+1 end
   if s.action=='melee'then counts.melee=counts.melee+1 end
  end
  r.coverage=counts;save()
  assert(counts.threatMotion>0 and counts.cooldownMotion>0 and counts.melee>0 and counts.wind>0,'Required tactical samples were not observed; retain source without learning')
  if spacingLesson then assert(counts.knownSummonDistantMotion>0 and counts.knownSummonReachableMelee>0,'Actual known-summon spacing coverage missing; retain source without learning') end
  c.result.baseButton:emit('Tapped');wait(controls)
  menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('学习最近示范'):emit('Tapped')
  wait(function()return controls().arena.mode~='building'end);assert(controls().arena.message:find('已保存',1,true),controls().arena.message)
  local candidate=assert(require('Training.YingzhaoPolicyStore').loadLatestAsync('wuyun'));assert(#candidate.model.sourceEpisodes==1 and candidate.model.sourceEpisodes[1]==source.episode)
  r.newCandidate=candidate.id;r.model=candidate.model;r.message=controls().arena.message
  assert(I.equal(before,protected()),'Teaching changed adoption, wallet, basic models or missions');r.protectedStateUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
