local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/medium-yingzhao-combat-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  D.Cache:loadAsync('spine:zhongyingzhao-weapon.skel|zhongyingzhao.atlas');local E=require('Enemy.MediumYingzhao');local K=require('Combat.Displacement')
  local record={enemy=E.create(b.world,7800),enemyHP=100};local hp=10000
  local host={world=b.world,phase='playing',targets=function()return {{unit=b.mentor,hp=function()return hp end,damage=function(n)hp=hp-n end}}end}
  local c=E.new(host,record);c.nextAttack=math.huge
  local node=D.Node();node:addTo(b.world);node:schedule(function()c:update(D.App.runningTime);return false end)
  local function wait(fn)local stop=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<stop,'timeout');D.sleep(.01)end end
  local function setup(distance)
   K.clear(b.mentor);b.mentor:stop();b.mentor.velocity=D.Vec2.zero;record.enemy.velocity=D.Vec2.zero
   record.enemy.position=D.Vec2(7800,b.world.offset+215);b.mentor.position=D.Vec2(7800+distance,b.world.offset+155)
   c.nextAttack=math.huge;D.sleep(.5);wait(function()return record.enemy.onSurface and b.mentor.onSurface end)
  end
  for _,case in ipairs({{d=420,hit=true},{d=-420,hit=true},{d=150,hit=true},{d=-150,hit=true},{d=900,hit=false},{d=420,hit=false,dodge=true},{d=420,hit=false,behind=true},{d=420,hit=false,interrupt=true}})do
   setup(case.d);local gun=b.mentor.playable:getSlot('pistol');local originalScale=gun.scaleX;local before=hp;local x=record.enemy.x
   assert(c:attack('rob',b.mentor));local strike=c.strike;D.sleep(.1);assert(not b.mentor.data.weaponDisarmed)
   if case.dodge then b.mentor.x=record.enemy.x+1000 end
   if case.behind then b.mentor.x=record.enemy.x-500 end
   if case.interrupt then record.enemyHP=record.enemyHP-1 end
   wait(function()return not c.busy and not c.reacting end);c.nextAttack=math.huge
   r.lastAttempt={distance=case.d,strike=strike,enemyX=record.enemy.x,targetX=b.mentor.x,enemyY=record.enemy.y,targetY=b.mentor.y,weapon=b.mentor.data.combatWeaponAsset};save()
   assert((strike.disarmed==true)==case.hit,'Rob outcome '..case.d)
   assert(hp==before,'Theft invented damage')
   if case.hit then
    assert(c.lease.active and b.mentor.data.weaponDisarmed and gun.scaleX==0)
    assert(not b.mentor:start('groundMentorShot'),'Disarmed owner fired');require('Combat.Disarm').release(c.lease,'QA_RETURN');assert(gun.scaleX==originalScale and b.mentor.playable:getSlot('pistol')==gun and not b.mentor.data.weaponDisarmed,'Original weapon not restored')
   end
   if not case.interrupt then for _,clip in ipairs(strike.clips)do assert(clip.ended and clip.ended-clip.started>=clip.duration-.035)end else assert(strike.cancelled=='HIT')end
   r.cases[#r.cases+1]={distance=case.d,dodge=case.dodge,behind=case.behind,disarmed=strike.disarmed or false,travel=record.enemy.x-x,clips=strike.clips,cancelled=strike.cancelled};save()
  end
  setup(150);assert(c:attack('punch',b.mentor));local strike=c.strike;local before=hp
  wait(function()return not c.busy end);c.nextAttack=math.huge;assert(strike.hits==1 and before-hp==10);r.punch=true
  setup(150);assert(c:attack('rob',b.mentor));wait(function()return c.lease and c.lease.active end);record.enemyHP=record.enemyHP-1
  wait(function()return not c.lease.active and not c.reacting end);c.nextAttack=math.huge;assert(not b.mentor.data.weaponDisarmed);r.hitReturnsWeapon=true
  setup(150);assert(c:attack('rob',b.mentor));wait(function()return c.lease and c.lease.active end);record.enemyHP=0
  wait(function()return c.dead end);assert(not b.mentor.data.weaponDisarmed and not c.lease.active);r.deathReturnsWeapon=true
  node:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
