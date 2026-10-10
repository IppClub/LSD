-- Actual native clocks with isolated host/targets; no save or natural-win proof.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-recovery-cadence-result.json'
local r={status='RUNNING',controlledFixture=true,naturalVictory=false,cases={}};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  local E=require('Enemy.BigYingzhao');E.loadAsync();local rules=require('Enemy.BigYingzhaoRules')
  local record={enemy=E.create(b.world,7800),enemyHP=rules.maxHP};local host={world=b.world,phase='playing',targets=function()return {}end};local guard=E.new(host,record)
  local node=D.Node();node:addTo(b.world);node:schedule(function()guard:update(D.App.runningTime);return false end)
  local function wait(fn)local deadline=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<deadline,'Heavy recovery cadence stalled');D.sleep(.01)end end
  b.mentor:stop();b.mentor.position=D.Vec2(8600,b.world.offset+155);wait(function()return record.enemy.onSurface and b.mentor.onSurface end)
  assert(rules.maxHP==1000 and record.enemy.unitDef.scale==1 and rules.waveCooldown==11)
  assert(guard:recoveryDuration('hero')==4 and guard:recoveryDuration('wave')==.9 and guard:recoveryDuration('hunt')==.9)
  for _,case in ipairs({{skill='punch',recovery=2.2},{skill='massive',recovery=4}})do
   host.phase='playing';host.targets=function()return {}end;assert(guard:attack(case.skill,b.mentor));local strike=guard.strike
   wait(function()return strike.completed~=nil end);assert(strike.completed-strike.started>=strike.clips[1].duration-.02)
   assert(strike.recoveryDuration==case.recovery and math.abs(strike.recoveryUntil-strike.completed-case.recovery)<.001 and guard.nextAttack==strike.recoveryUntil)
   host.targets=function()return {{unit=b.mentor,hp=function()return 10000 end,damage=function()end,immovable=true}}end
   wait(function()return guard.strike~=strike end);local nextStrike=guard.strike;assert(nextStrike.started>=strike.recoveryUntil-.02)
   r.cases[#r.cases+1]={skill=case.skill,started=strike.started,completed=strike.completed,duration=strike.clips[1].duration,recovery=case.recovery,recoveryUntil=strike.recoveryUntil,nextStarted=nextStrike.started,nextSkill=nextStrike.skill};save()
   host.phase='ready';D.sleep(.15);wait(function()return not guard.busy and not guard.reacting end)
  end
  r.maxHP=rules.maxHP;r.scale=record.enemy.unitDef.scale;r.waveCooldown=rules.waveCooldown;r.heroRecovery=guard:recoveryDuration('hero');r.defaultRecovery=guard:recoveryDuration('wave')
  host.phase='ended';D.sleep(.1);node:removeFromParent();b:finish('aborted','Heavy recovery fixture complete')
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
