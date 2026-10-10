local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/trial-hit-recovery-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local K=require('Combat.Displacement')
  local b=require('Trial.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m04-duel'})
  assert(b:begin());b.nextNpc=math.huge;b.npc.x=b.hero.x+180;D.sleep(.3)
  assert(b.hero.data.combatHasHit and b.npc.data.combatHasHit,'Missing original hit animation')
  local function wait(f,seconds)local deadline=D.App.totalTime+seconds;while not f()do assert(D.App.totalTime<deadline,'Trial recovery timeout');D.sleep(.02)end end
  assert(b:command('guard'));local hp=b.heroHP
  b:damage(b.hero,12,'npc');assert(b.heroHP==hp and not K.blocked(b.hero)and b.hero:isDoing('trialHeroGuard'))
  wait(function()return not b:heroBusy()end,4);r.guardPreserved=true
  b.nextNpc=0;assert(b.npc:start('trialNpcShot'));b.nextNpc=math.huge
  D.sleep(.02);local cast=b.activeCasts[b.npc];assert(cast and not cast.completedAt)
  b:damage(b.npc,14,'hero');assert(K.blocked(b.npc)and b.npc.playable.current=='hit')
  assert(cast.interruptedAt and cast.reason=='hit'and not cast.completedAt)
  wait(function()return not K.blocked(b.npc)end,4)
  assert(b.npc.playable.current==b.npc.data.combatRest);r.npcRecovered=true;r.cast=cast
  -- Real authored shot release and projectile collision, not direct damage injection.
  K.clear(b.npc);local before=b.npcHP;assert(b:command('shoot'))
  wait(function()return b.npcHP<before end,4)
  assert(K.blocked(b.npc)and b.npc.playable.current=='hit');r.projectileHit=true
  wait(function()return not K.blocked(b.npc)and not b:heroBusy()end,4)
  b:damage(b.hero,0,'npc');assert(not K.blocked(b.hero),'Zero damage triggered reaction')
  b:damage(b.hero,6,'npc');assert(K.blocked(b.hero));assert(not b:command('right'))
  wait(function()return not K.blocked(b.hero)end,4);r.heroRecovered=true
  b:damage(b.npc,1000,'hero');assert(b.npcHP==0 and not K.blocked(b.npc)and b.npc.playable.current=='lose')
  r.lethalPreserved=true;b.closed=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
