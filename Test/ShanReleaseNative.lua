local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={status='RUNNING'};local out=root..'/Test/shan-release-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local B=require('Ruins.Pursuit');local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f)local deadline=D.App.runningTime+8;while not f()do assert(D.App.runningTime<deadline);D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  b.mentorHP=10000;wait(function()return b.mentor.onSurface end)
  local e=b.enemies[2];local tactics=require('Enemy.ShanTactics')
  assert(tactics.context(e,b.enemies).supported)
  assert(tactics.choose(tactics.context(e,b.enemies),400,1)=='litter')
  local function spec(name)for _,s in ipairs(B.attackSpecs.xiaoshanxiao)do if s.name==name then return s end end end
  local before=#b.hostileProjectiles
  e.sequence=0;e.nextAttack=0;wait(function()return e.busy end);local strike=e.strikes[#e.strikes];assert(strike.kind=='litter');wait(function()return not e.busy end);e.nextAttack=math.huge
  assert(#strike.impacts==2 and #b.hostileProjectiles-before==2 and strike.completed-strike.started>=strike.duration-.02)
  assert(e.unit.playable.current==e.unit.data.combatRest)
  assert(strike.releases[1].hand=='rear' and strike.releases[2].hand=='front')
  r.releases=strike.releases
  r.litter={duration=strike.duration,elapsed=strike.completed-strike.started,impacts=strike.impacts,projectiles=2}
  b.enemies[1].hp=0;b.enemies[3].hp=0
  assert(not tactics.context(e,b.enemies).supported and tactics.choose(tactics.context(e,b.enemies),150,1)=='evade')
  e.unit.position=D.Vec2(7600,b.world.offset+155);b.mentor.position=D.Vec2(7400,b.world.offset+155);D.sleep(.15)
  local start=e.unit.x;e.sequence=0;e.nextAttack=0;wait(function()return e.busy end);strike=e.strikes[#e.strikes];assert(strike.kind=='evade');wait(function()return not e.busy end);e.nextAttack=math.huge
  assert(e.unit.x>start+80 and #strike.impacts==0 and strike.completed-strike.started>=strike.duration-.02)
  r.evade={distance=e.unit.x-start,duration=strike.duration,elapsed=strike.completed-strike.started}
  assert(b:enemyStrike(e,spec('litter')));strike=e.strikes[#e.strikes];D.sleep(.2);local count=#b.hostileProjectiles
  b:finish('aborted','QA');wait(function()return not e.busy end);D.sleep(1.3)
  assert(#b.hostileProjectiles==count and strike.cancelled=='BATTLE_ENDED');r.cancelled=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
