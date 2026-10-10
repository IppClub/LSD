-- Controlled native timing fixture, not a natural victory or trained-model test.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/big-yingzhao-wave-cadence-result.json'
local r={status='RUNNING',controlledFixture=true,naturalVictory=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  local E=require('Enemy.BigYingzhao');E.loadAsync()
  local rules=require('Enemy.BigYingzhaoRules');local record={enemy=E.create(b.world,7800),enemyHP=rules.maxHP}
  local host={world=b.world,phase='playing',targets=function()return {{unit=b.mentor,hp=function()return 10000 end,damage=function()end,immovable=true}}end}
  local c=E.new(host,record);c.nextAttack=math.huge;c.nextHunt=math.huge;c.nextHero=math.huge
  b.mentor:stop();b.mentor.position=D.Vec2(8600,b.world.offset+155)
  local node=D.Node();node:addTo(b.world);node:schedule(function()c:update(D.App.runningTime);return false end)
  local function wait(fn)local stop=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<stop,'timeout');D.sleep(.01)end end
  wait(function()return record.enemy.onSurface and b.mentor.onSurface end)
  assert(c:chooseSkill(800,b.mentor)=='wave'and c:approachRange()==1000)
  -- Failed starts must not consume a cooldown.
  host.phase='ready';assert(not c:attack('wave',b.mentor));assert(c.nextWave==0);host.phase='playing'
  assert(c:attack('wave',b.mentor));local first=c.strike;local reserved=c.nextWave
  assert(math.abs(reserved-first.started-rules.waveCooldown)<.001)
  assert(c:chooseSkill(800,b.mentor)=='massive'and c:approachRange()==650)
  D.sleep(.3);record.enemyHP=record.enemyHP-1
  wait(function()return not c.busy and not c.reacting end)
  assert(first.cancelled=='HIT'and not first.wave and c.nextWave==reserved)
  local accepted,why=c:attack('wave',b.mentor);assert(not accepted and why=='COOLDOWN'and #c.strikes==1)
  -- Summon priority remains available while the ranged skill is cooling down.
  c.nextHunt=0;assert(c:chooseSkill(800,b.mentor)=='hunt');c.nextHunt=math.huge
  r.interrupted={started=first.started,cancelled=first.cancelled,nextWave=reserved,rejectedAt=D.App.runningTime}
  wait(function()return D.App.runningTime>=reserved-.15 end)
  assert(D.App.runningTime<reserved);accepted,why=c:attack('wave',b.mentor);assert(not accepted and why=='COOLDOWN')
  wait(function()return D.App.runningTime>=reserved end)
  assert(c:chooseSkill(800,b.mentor)=='wave'and c:approachRange()==1000)
  assert(c:attack('wave',b.mentor));local second=c.strike
  D.sleep(2);assert(not second.wave,'Emission occurred before authored impact')
  wait(function()return not c.busy end)
  assert(second.wave and second.impacts[1].at-second.started>=2.3-.02)
  assert(second.completed-second.started>=4-.02,'Authored recovery clipped')
  assert(second.started-first.started>=rules.waveCooldown-.001)
  assert(c.nextWave==second.started+rules.waveCooldown)
  accepted,why=c:attack('wave',b.mentor);assert(not accepted and why=='COOLDOWN')
  r.completed={started=second.started,impactAt=second.impacts[1].at,completed=second.completed,nextWave=c.nextWave}
  r.cooldown=rules.waveCooldown;r.strikes=c.strikes;r.maxHP=rules.maxHP;r.scale=record.enemy.unitDef.scale
  host.phase='ended';D.sleep(.1);node:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
