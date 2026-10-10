-- Controlled actual animation-clock fixture; no save/model or victory proof.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/enemy-recovery-deadline-result.json'
local r={status='RUNNING',controlledFixture=true,naturalVictory=false};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  local E=require('Enemy.BigYingzhao');E.loadAsync();local rules=require('Enemy.BigYingzhaoRules')
  local record={enemy=E.create(b.world,7800),enemyHP=rules.maxHP};local host={world=b.world,phase='playing',targets=function()return {}end}
  local guard=E.new(host,record);local node=D.Node();node:addTo(b.world);node:schedule(function()guard:update(D.App.runningTime);return false end)
  local function wait(fn)local deadline=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<deadline,'Recovery deadline fixture stalled');D.sleep(.01)end end
  b.mentor:stop();b.mentor.position=D.Vec2(8600,b.world.offset+155)
  wait(function()return record.enemy.onSurface and b.mentor.onSurface end)
  assert(guard:attack('massive',b.mentor));local strike=guard.strike
  wait(function()return strike.completed~=nil end);local reserved=guard.nextAttack
  assert(strike.completed-strike.started>=strike.clips[1].duration-.02,'Full attack animation ended early')
  record.enemyHP=record.enemyHP-1 -- Controlled damage stimulus after completed authored clip.
  wait(function()return guard.reacting~=nil end);wait(function()return guard.reacting==nil end)
  r.completed=strike.completed;r.animationDuration=strike.clips[1].duration;r.attackStarted=strike.started;r.reservedDeadline=reserved;r.afterHitDeadline=guard.nextAttack;r.shortenedBy=reserved-guard.nextAttack;r.preserved=guard.nextAttack>=reserved-.02;r.hit=guard.hits[#guard.hits];save()
  if os.getenv('LSD_QA_EXPECT_RECOVERY_REPRO')=='1'then assert(not r.preserved,'Expected recovery shortening did not reproduce');r.reproduced=true
  else assert(r.preserved,'Hit reaction shortened the existing post-attack recovery deadline')end
  host.targets=function()return {{unit=b.mentor,hp=function()return 10000 end,damage=function()end,immovable=true}}end
  wait(function()return guard.strike~=strike end)
  r.nextAttackStarted=guard.strike.started;r.nextAttackSkill=guard.strike.skill;r.aiDeadlinePreserved=guard.strike.started>=reserved-.02;save()
  if r.reproduced then assert(not r.aiDeadlinePreserved,'Expected early AI attack did not reproduce')
  else assert(r.aiDeadlinePreserved,'AI restarted an attack before the reserved recovery deadline')end
  host.phase='ended';D.sleep(.1);node:removeFromParent();b:finish('aborted','Recovery fixture complete')
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
