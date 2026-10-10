local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/medium-yingzhao-shoot-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  for i,e in ipairs(b.escorts)do e.unit.x=1500-i*150 end
  D.Cache:loadAsync('spine:zhongyingzhao-weapon.skel|zhongyingzhao.atlas')
  local E=require('Enemy.MediumYingzhao');local Disarm=require('Combat.Disarm');local K=require('Combat.Displacement')
  local rec={enemy=E.create(b.world,7800),enemyHP=100};local hp=1000;local ap=100
  local host={world=b.world,phase='playing',targets=function()return {{unit=b.mentor,hp=function()return hp end,damage=function(n)hp=hp-n end,damageArmor=function(n)ap=math.max(0,ap-n)end}}end}
  local c=E.new(host,rec);c.nextAttack=math.huge
  local node=D.Node();node:addTo(b.world);node:schedule(function()c:update(D.App.runningTime);return false end)
  local function wait(fn)local deadline=D.App.runningTime+5;while not fn()do assert(D.App.runningTime<deadline,'timeout');D.sleep(.01)end end
  local learner=require('Training.Arena').createAsync({world=b.world,manualUpdate=true,characterId='wuyun',origin=2000,actionPrefix='stolenShotWu_'})
  learner.mode='demo'
  for _,case in ipairs({{d=300},{d=-300},{d=500},{d=-500},{d=1200},{d=-1200},{d=500,dodge=true},{d=500,wall=true},{d=500,release=true},{d=500,expire=true},{d=500,interrupt=true},{d=500,emp=true},{d=-500,emp=true}})do
   K.clear(b.mentor);b.mentor:stop();b.mentor.velocity=D.Vec2.zero;rec.enemy.velocity=D.Vec2.zero
   rec.enemy.position=D.Vec2(7800,b.world.offset+215);b.mentor.position=D.Vec2(7800+case.d,b.world.offset+155)
   c.nextAttack=math.huge;D.sleep(.5);wait(function()return rec.enemy.onSurface and b.mentor.onSurface end)
   c.lease=assert(Disarm.take(case.emp and learner.student or b.mentor,rec.enemy,{leftAuthored=true,duration=case.expire and .5 or 6}));rec.enemy.data.combatRest='gunidle'
   require('CombatAnimation').rest(rec.enemy);D.sleep(.3)
   local wall
   if case.wall then local def=D.BodyDef();def.type='Static';def:attachPolygon(35,900);wall=D.Body(def,b.world,D.Vec2(7800+case.d/2,b.world.offset+450));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world)end
   local before,beforeAP=hp,ap;local beforeCasings={};for _,v in ipairs(c.casings or {})do beforeCasings[v]=true end;assert(c:attack('shoot',b.mentor));local s=c.strike;D.sleep(.1);assert(hp==before and #s.impacts==0,'Early damage')
   if case.dodge then b.mentor.x=b.mentor.x+800 end
   if case.release then Disarm.release(c.lease,'QA_EARLY_RETURN')end
   if case.interrupt then rec.enemyHP=rec.enemyHP-1 end
   wait(function()return not c.busy and not c.reacting end);c.nextAttack=math.huge;D.sleep(.3)
   local row={case=case,damage=before-hp,armorDamage=beforeAP-ap,strike=s};r.cases[#r.cases+1]=row;save()
   if case.release or case.interrupt or case.expire then assert(#s.impacts==0 and hp==before,'Cancelled shot emitted')
   elseif case.dodge or case.wall then assert(#s.impacts==1 and s.impacts[1].emitted and hp==before,'Shot followed dodge')
   else
    assert(#s.impacts==1 and s.impacts[1].emitted and s.hits==1 and before-hp==(case.emp and 0 or 15),'Real shot missed')
    assert(s.impacts[1].at-s.started>=1/3-.02 and s.impacts[1].hitAt>s.impacts[1].at,'No projectile travel')
    assert(s.completed-s.started>=1.075,'Truncated shooting clip')
    if case.emp then assert(beforeAP-ap==35,'EMP armor semantics');for _,v in ipairs(c.casings)do assert(beforeCasings[v],'EMP emitted a casing')end else assert(beforeAP==ap,'Kinetic invented armor damage')end
   end
   if wall then wall:removeFromParent()end
   Disarm.release(c.lease,'QA_RETURN');D.sleep(.4);assert(not c.shotAim,'Aim did not recover')
  end
  rec.enemy.position=D.Vec2(7800,b.world.offset+215);b.mentor.position=D.Vec2(8300,b.world.offset+155);D.sleep(.5)
  c.lease=assert(Disarm.take(b.mentor,rec.enemy,{leftAuthored=true,duration=6}));c.nextAttack=0
  wait(function()return c.busy end);assert(c.strike.skill=='shoot','Armed AI did not use range')
  local auto=c.strike;wait(function()return not c.busy end);c.nextAttack=math.huge;assert(auto.hits==1,'Autonomous shot missed');r.armedAI=true
  Disarm.release(c.lease,'QA_RETURN');D.sleep(.4)
  b.mentor.x=9000;c.lease=assert(Disarm.take(b.mentor,rec.enemy,{leftAuthored=true,duration=6}));D.sleep(.3)
  assert(c:attack('shoot',b.mentor));wait(function()return #c.strike.impacts>0 end)
  local before=hp;host.phase='ended';D.sleep(.6);assert(hp==before and not c.lease.active,'Battle exit left an active shot or weapon');r.exitClearsFlight=true
  assert(#c.projectiles==0 and #c.casings==0,'Battle effect leak')
  node:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
