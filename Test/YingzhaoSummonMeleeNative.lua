-- Scripted command-path duels; real blade events, damage and resource ledger.
-- Controlled threat lessons and reinforcement duels; not a natural Boss victory.
local D=require('Dora');local entry,qaResultName=...;local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'yingzhao-summon-melee-result.json');local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Context lesson timeout');D.sleep(.02)end end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')};local Small=require('Enemy.SmallYingzhao')
  for _,active in ipairs({false,true})do for _,direction in ipairs({1,-1})do
   local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor='wuyun',item='blade',quantity=12},{actor='wuyun',item='emp',quantity=6}},'wuyun')
   local a=b.wuyun;local boss=b.enemies[1];assert(b:start());boss.guard.nextAttack=math.huge;b.arena.mode='review'
   local bossUpdate=boss.guard.update
   boss.guard.update=function(g,now)g.nextAttack=math.huge;bossUpdate(g,now);g.nextAttack=math.huge end
   local evades={}
   local function position(x)
    a.student:stop();a.student.velocity=D.Vec2.zero;a.student.position=D.Vec2(x,b.world.offset+155)
    D.sleep(.4);wait(function()return a.student.onSurface end)
   end
   local function evade(skill)
    require('Training.YingzhaoVitals').flush(b.bossTrace.vitals)
    local hp=a.studentHP;local x=a.student.x;local vitalStart=#b.bossTrace.vitals.events
    -- Respond at the visible cue; the original 100ms delay leaves a half-speed
    -- backstep inside the inclusive impact boundary on the current physics step.
    assert(boss.guard:attack(skill,a.student));D.sleep(.02)
    local before=b.observeYingzhao(a.student)
    assert(b:command(direction==1 and'left'or'right'))
    if skill=='wave'then wait(function()return b.observeYingzhao(a.student).waveReach=='clear'end)
    else wait(function()return not boss.guard.busy end)end
    a.student:stop();a.student.velocityX=0
    wait(function()return not boss.guard.busy and #boss.guard.waves==0 end)
    local row={skill=skill,before=before,damage=hp-a.studentHP,travel=math.abs(a.student.x-x),startX=x,endX=a.student.x,bossX=boss.enemy.x,impacts=boss.guard.strike.impacts,strikeStarted=boss.guard.strike.started,completed=boss.guard.strike.completed,phase=b.phase,vitals=b.bossTrace.vitals}
    evades[#evades+1]=row;r.evasionDiagnostics=r.evasionDiagnostics or {};r.evasionDiagnostics[#r.evasionDiagnostics+1]=row;save()
    require('Training.YingzhaoVitals').flush(b.bossTrace.vitals)
    -- Verify actual attack contact independently of persistent life-support hazards.
    local contacts=0;local strike=boss.guard.strike
    for _,impact in ipairs(strike.impacts or {})do for _,target in ipairs(impact.targets or {})do if target.actor=='wuyun'then contacts=contacts+1 end end end
    for _,target in ipairs(strike.wave and strike.wave.hits or {})do if target.actor=='wuyun'then contacts=contacts+1 end end
    row.attackContacts=contacts
    local damage,healing,hazard=0,0,0
    for index=vitalStart+1,#b.bossTrace.vitals.events do
     local event=b.bossTrace.vitals.events[index]
     if event.actor=='wuyun'then
      damage=damage+event.damage;healing=healing+event.healing
      if event.kind=='support-hazard'then hazard=hazard+event.damage end
     end
    end
    row.vitalStart=vitalStart;row.vitalEnd=#b.bossTrace.vitals.events;row.intervalDamage=damage;row.intervalHealing=healing;row.environmentDamage=hazard;save()
    assert(contacts==0,'Context evasion contacted the authored Boss attack')
    assert(math.abs(hp-a.studentHP-(damage-healing))<1e-4,'Evasion health ledger mismatch')
    assert(math.abs(damage-hazard)<1e-4,'Evasion took non-environment damage')
   end
   -- Equal 720-unit offsets from the actual Boss center in both directions.
   local childX=boss.enemy.x-direction*720
   a.student.position=D.Vec2(childX-direction*(active and 450 or 230),b.world.offset+155)
   b.mentor.x=direction==1 and 3200 or 400;b.arena.student.x=direction==1 and 3300 or 500
   position(1920-direction*250);evade('punch')
   local child={enemy=Small.create(b.world,childX),enemyHP=70};child.guard=Small.new(b,child);b.enemies[#b.enemies+1]=child
   local childPaused=true;local update=child.guard.update
   child.guard.update=function(g,now)if childPaused then g.nextAttack=math.huge end;update(g,now);if childPaused then g.nextAttack=math.huge end end
   position(childX-direction*230);evade('wave')
   position(childX-direction*(active and 450 or 230))
   childPaused=not active;if active then child.guard.nextAttack=0 end
   local started=D.App.runningTime
   while child.enemyHP>0 and a.studentHP>0 and D.App.runningTime-started<25 do
    if a:available('melee')and math.abs(a.student.x-child.enemy.x)<=300 then b:command('melee')
    elseif not a:isAttacking()and not require('Combat.Displacement').blocked(a.student)then b:command(child.enemy.x>=a.student.x and'right'or'left')end
    D.sleep(.1)
   end
   local deadline=D.App.runningTime+5;while a:isAttacking()do assert(D.App.runningTime<deadline);D.sleep(.02)end
   local damage,hits,spent=0,0,0
   for _,hit in ipairs(b.bossTrace.hits)do if hit.source=='wuyun'and hit.summoned then assert(hit.weapon=='blade');damage=damage+hit.healthDamage;hits=hits+1 end end
   for _,e in pairs(b.supplies.ledger.events)do if e.item=='blade'then spent=spent+e.count end end
   local row={evades=evades,active=active,direction=direction,hp=a.studentHP,enemyHP=child.enemyHP,seconds=D.App.runningTime-started,damage=damage,hits=hits,spent=spent,strikes=child.guard.strikes};r.cases[#r.cases+1]=row;save()
   assert(child.enemyHP==0 and a.studentHP>0,'Blade duel failed')
   assert(damage==70 and hits==4 and spent>=4,'Blade damage/resource accounting mismatch')
   if not active then assert(spent==4 and a.studentHP==100,'Static blade control failed')end
   position(1920-direction*900);evade('wave')
   local shotDeadline=D.App.runningTime+5
   while not a:available('laser')do assert(D.App.runningTime<shotDeadline);D.sleep(.02)end
   local chosen
   for _,part in ipairs({'head','forelegs','arms','hindlegs','torso','flank'})do
    if require('Training.YingzhaoActions').plan(b,a,part)then chosen=part;break end
   end
   assert(chosen,'No ranged Boss target after defeating reinforcement')
   assert(b:command('aim-part',chosen));assert(b:command('shoot'))
   while a:isAttacking()or b.bossCombat:pendingActor('wuyun')do assert(D.App.runningTime<shotDeadline);D.sleep(.02)end
   assert(b.supplies:observation('wuyun').ammo.emp==5);row.rangedPart=chosen
   b:finish('aborted','Reinforcement melee fixture');while b.phase=='settling'do D.sleep(.02)end
   local resources=b.supplies:evidence();b.bossTrace.resources=resources
   local source={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='wuyun',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   local data=assert(require('Training.YingzhaoPolicy').inspect({source},'wuyun'))
   row.source=source;row.samples=#data.samples;row.actions=data.actions;
   local shotCount=0;for action,count in pairs(data.actions)do if action:match('^shoot@')then shotCount=shotCount+count end end
   assert(shotCount==1 and data.actions.melee>=3 and (data.actions.bmove or 0)>=3,'Dual-weapon source missing actual action variety');save()
  end end
  r.notNaturalVictory=true;r.notHumanDemonstration=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
