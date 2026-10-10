-- Scripted player demonstration through the public UI; never synthetic labels.
local entry,qaResultName=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(entry))
local out=root..'/Test/'..(qaResultName or 'yingzhao-public-wuyun-protection-result.json')
local r={status='RUNNING',osInput=false,notHumanDemonstration=true,naturalVictory=false,actor='wuyun',positions={},commands={},instructorScripted=true,teleportedActors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),32)
  assert(prior.outcome=='failed'and prior.episodeSaved and prior.returnedToTrain)
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-big%-yingzhao%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-public-wuyun-protection-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.parentDatabase=prior.database
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync();local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available
  local I=require('Training.FlowerIdentity');local Store=require('Training.YingzhaoPolicyStore')
  local tables={'Game0Training','Game0Training_wuyun','Game0YingzhaoAdoptions','Game0YingzhaoAdoptionState','Game0MissionAttempts','Game0SupplyAttempts','Game0SupplyWallet','Game0CombatEpisodes'}
  local function storedRows(name,sql)
   local present=assert(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name=?",{name}),'Schema read failed')
   if #present==0 then return {}end
   return assert(D.DB:query(sql or ('SELECT * FROM lsd.'..name)),'Protected table read failed: '..name)
  end
  local function protected()
   local state={};for _,name in ipairs(tables)do state[name]=storedRows(name)end
   state.niniliteCandidates=storedRows('Game0YingzhaoCandidates',"SELECT * FROM lsd.Game0YingzhaoCandidates WHERE actor='ninilite' ORDER BY id")
   state.comparisons=storedRows('Game0YingzhaoComparisons','SELECT * FROM lsd.Game0YingzhaoComparisons ORDER BY id');return state
  end
  local before=protected();local old=Store.loadLatestAsync('wuyun');r.oldCandidate=old and old.id
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Wuyun public lesson timeout');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'wuyun');wait(controls)
  local menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('大英招示范'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout')end)
  D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout').saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoDemonstration end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle;local a=assert(b.demonstrator)
  assert(a.character.id=='wuyun');c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  r.started=D.App.runningTime;local held;local nextPosition=0;local nextShot=0;local nextSkill=0
  local function motion(side)
   if held==side then return end
   if held then c.hud.move:emit(held,false)end;held=side
   r.commands[#r.commands+1]={at=D.App.runningTime,kind=side and'move-'..side or'wait',observed=b.observeYingzhao(a.student)}
   if side then c.hud.move:emit(side,true)end
  end
  local function stopInstructor()
   if b.mentor:isDoing('groundMentorMove')then b.mentor:stop();b.mentor.velocityX=0;require('CombatAnimation').rest(b.mentor)end
  end
  for _,destination in ipairs({650,1650,650})do
   local stageStarted=D.App.runningTime;local arrived
   while b.phase=='playing'and D.App.runningTime-r.started<36 and D.App.runningTime-stageStarted<12 do
    local now=D.App.runningTime;local gap=destination-b.mentor.x
    if math.abs(gap)<=25 then if not arrived then arrived=now end;stopInstructor()
    elseif not arrived and not require('Combat.Displacement').blocked(b.mentor)then
     require('Combat.Movement').command(b.mentor,gap>0 and'right'or'left')
    end
    local o=b.observeYingzhao(a.student);local boss=b.bossCombat.boss;local direction;local reason
    local wave=require('Enemy.GroundWave').escapeDirection(boss.guard,a.student,o.bossVisible)
    if wave then direction=wave;reason='visible-wave'
    elseif o.bossVisible and (o.bossFrontRange=='immediate'or o.bossFrontRange=='advance')and (o.bossAction=='massive'or o.bossAction=='punch')and o.bossWindow~='recovery'then
     direction=o.bossX>=o.ownX and -1 or 1;reason='visible-frontal-windup'
    elseif o.mentorDistance~='close'and o.mentorSide~='unknown'and o.mentorSide~='overlap'then
     direction=o.mentorSide=='right'and 1 or -1;reason='visible-mentor'
    end
    if direction and (direction<0 and o.ownX<=b.minX+25 or direction>0 and o.ownX>=b.maxX-25)then direction=nil;reason='arena-edge'end
    motion(direction and(direction>0 and'Right'or'Left')or nil)
    if not direction and not a:isAttacking()and not require('Combat.Displacement').blocked(a.student)then
     local target=b:target(a.student)
     if now>=nextSkill and target and b.magic:available('wind')and require('Ground.Tactics').inWind(target.enemy.x,target.enemy.y,a.student.x,a.student.y,b.mentor.faceRight and 1 or -1)then
      c.wind:emit('TapBegan');nextSkill=now+1
     elseif now>=nextShot and a:available('laser')and (o.bossWindow=='idle'or o.bossWindow=='recovery')then
      local part
      for _,id in ipairs({'head','forelegs','arms','hindlegs','torso','flank'})do
       if o['part_'..id]~='exposed'and require('Training.YingzhaoActions').plan(b,a,id)then part=id;break end
      end
      if part then c.targetButtons[part]:emit('Tapped');c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded');nextShot=now+.6 end
     end
    end
    if now>=nextPosition then
     r.positions[#r.positions+1]={at=now,mentorX=b.mentor.x,learnerX=a.student.x,bossX=o.bossX,reason=reason,direction=direction,threat=o.threat,bossAction=o.bossAction,bossWindow=o.bossWindow,mentorSide=o.mentorSide,mentorDistance=o.mentorDistance,hp=a.studentHP};nextPosition=now+.2
    end
    if arrived and now-arrived>=2 and o.mentorDistance=='close'then break end
    D.sleep(.04)
   end
   stopInstructor();motion(nil);if b.phase~='playing'then break end
  end
  stopInstructor();motion(nil)
  if b.phase=='playing'then c.withdraw:emit('Tapped')end;wait(function()return c.phase=='result'end)
  r.sourceId=assert(b.demonstrationSourceId);local source=assert(require('Training.YingzhaoStore').loadAsync(r.sourceId));r.source=source
  local data=assert(require('Training.YingzhaoSamples').extract({source},'wuyun'));r.newActions=data.actions;r.newSamples=#data.samples
  local coverage={retreat=0,approachMentor=0,closeIdle=0,attacks=0}
  for _,sample in ipairs(data.samples)do
   local step=source.boss.steps[sample.firstStep];local moving=sample.action=='fmove'or sample.action=='bmove';local dx=step.after.ownX-step.before.ownX
   if moving and math.abs(dx)>1 and dx*(step.before.bossX-step.before.ownX)<0 and (sample.state.threat~='none'or sample.state.waveReach=='approaching'or sample.state.bossAction=='massive'or sample.state.bossAction=='punch')then coverage.retreat=coverage.retreat+1 end
   if moving and math.abs(dx)>1 and sample.state.mentorDistance~='close'and (sample.state.mentorSide=='left'and dx<0 or sample.state.mentorSide=='right'and dx>0)then coverage.approachMentor=coverage.approachMentor+1 end
   if sample.action=='idle'and sample.state.mentorDistance=='close'then coverage.closeIdle=coverage.closeIdle+1 end
   if sample.action:match('^shoot@')or sample.action:match('^wind@')or sample.action=='melee'then coverage.attacks=coverage.attacks+1 end
  end
  r.coverage=coverage;save();assert(#data.samples>=6 and coverage.retreat>0,'Actual protection demonstration coverage missing; source retained without learning')
  c.result.baseButton:emit('Tapped');wait(controls)
  menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('学习部位'):emit('Tapped')
  wait(function()return controls().arena.mode~='building'end,60);assert(controls().arena.message:find('已保存',1,true),controls().arena.message)
  local candidate=assert(Store.loadLatestAsync('wuyun'));assert(not old or old.id~=candidate.id);r.newCandidate=candidate.id;r.model=candidate.model
  local included=false;for _,episode in ipairs(candidate.model.sourceEpisodes)do if episode==source.episode then included=true end end;assert(included)
  assert(I.equal(before,protected()),'Lesson changed adopted policies, other candidates, comparison, wallet or missions')
  r.protectedStateUnchanged=true;r.balanceAfter=E.wallet().available;r.message=controls().arena.message;save()
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
