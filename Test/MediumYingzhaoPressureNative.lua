-- Repeated hits still damage; only repeated flinches receive a bounded grace.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/medium-yingzhao-pressure-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  D.Cache:loadAsync('spine:zhongyingzhao-weapon.skel|zhongyingzhao.atlas')
  local E=require('Enemy.MediumYingzhao');local rec={enemy=E.create(b.world,7800),enemyHP=100}
  b.mentor.position=D.Vec2(7950,b.world.offset+155);b.mentor:stop();b.mentor.velocity=D.Vec2.zero
  local host={world=b.world,phase='playing',targets=function()return {{unit=b.mentor,hp=function()return 100 end,damage=function()end}}end}
  local c=E.new(host,rec);c.nextAttack=math.huge
  local tick=D.Node();tick:addTo(b.world);tick:schedule(function()c:update(D.App.runningTime);return false end)
  local function wait(fn)local deadline=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<deadline,'pressure timeout');D.sleep(.01)end end
  D.sleep(.5);wait(function()return b.mentor.onSurface and rec.enemy.onSurface end)
  assert(c:attack('rob',b.mentor));local first=c.strike;D.sleep(.1);rec.enemyHP=99
  wait(function()return not c.busy and not c.reacting end);assert(first.cancelled=='HIT' and not first.disarmed,'First windup stopped being interruptible')
  c.nextAttack=math.huge;assert(c:attack('rob',b.mentor));local second=c.strike;local damage=0
  while not second.disarmed do
   D.sleep(.2);rec.enemyHP=rec.enemyHP-1;damage=damage+1
   assert(damage<20 and not second.cancelled,'Repeated flinch prevented theft')
  end
  assert(rec.enemyHP==99-damage,'Flinch protection reduced damage');r.damageDuringGrace=damage;r.first=first;r.second=second
  -- Even within that flinch grace, one further hit must return the weapon.
  rec.enemyHP=rec.enemyHP-1;wait(function()return not c.lease.active end);assert(not b.mentor.data.weaponDisarmed);r.returnedOnDamage=true
  local before=#c.hits;D.sleep(math.max(0,c.nextReaction-D.App.runningTime)+.05);rec.enemyHP=rec.enemyHP-1
  wait(function()return #c.hits>before end);assert(c.hits[#c.hits].reacted,'Flinch protection never expired');r.recoveryBounded=true;r.hits=c.hits
  host.phase='ended';D.sleep(.1);tick:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
