local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-hero-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  local E=require('Enemy.BigYingzhao');E.loadAsync();local K=require('Combat.Displacement')
  local record={enemy=E.create(b.world,7800),enemyHP=1000};local hp=10000
  local target={unit=b.mentor,hp=function()return hp end,damage=function(n)hp=hp-n end}
  local extraTargets={}
  local host={world=b.world,phase='playing',targets=function()local all={target,target};for _,t in ipairs(extraTargets)do all[#all+1]=t end;return all end};local c=E.new(host,record);c.nextAttack=math.huge
  local node=D.Node();node:addTo(b.world);node:schedule(function()c:update(D.App.runningTime);return false end)
  local function wait(fn)local stop=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<stop,'timeout');D.sleep(.01)end end
  local function setup(direction)
   K.clear(b.mentor);b.mentor:stop();b.mentor.velocity=D.Vec2.zero;b.mentor.position=D.Vec2(7800+direction*600,b.world.offset+155)
   record.enemy.position=D.Vec2(7800,b.world.offset+255);record.enemy.velocity=D.Vec2.zero;c.nextAttack=math.huge;c.nextReaction=0;host.phase='playing'
   D.sleep(.5);wait(function()return record.enemy.onSurface and b.mentor.onSurface end)
  end
  for _,case in ipairs({{dir=1},{dir=-1},{dir=1,dodge=true},{dir=1,interrupt=true},{dir=1,exit=true},{dir=1,wall=true}})do
   setup(case.dir);local before=hp;local startX=record.enemy.x;assert(c:attack('hero',b.mentor));local strike=c.strike;local hero=c.hero
   D.sleep(1.4);assert(hp==before and record.enemy.opacity<.1 and hero.warning.parent,'Retreat not warned/invisible');assert((record.enemy.x-startX)*case.dir<0,'Not retreating')
   local wall
   if case.dodge then b.mentor.x=7800-case.dir*1600 end
   if case.interrupt then record.enemyHP=record.enemyHP-1
   elseif case.exit then host.phase='ended'
   elseif case.wall then local def=D.BodyDef();def.type='Static';def:attachPolygon(30,900);wall=D.Body(def,b.world,D.Vec2(hero.destination.x,b.world.offset+450));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world)end
   if not(case.interrupt or case.exit or case.wall)then
    wait(function()return hero.entered end);assert(math.abs(record.enemy.x-hero.destination.x)<40,'Wrong rear entry');assert(hp==before,'Teleport damaged target')
    if case.dir==1 and not case.dodge then b.world.camera.zoom=.75;b.world.camera.position=D.Vec2(8200,400);D.sleep(.25);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-hero-charge.tga')end
   end
   wait(function()return not c.busy and not c.reacting and hero.closed end);c.nextAttack=math.huge
   assert(record.enemy.opacity==1 and not hero.warning.parent,'Hero state leaked')
   if case.interrupt or case.exit or case.wall then assert(hp==before and strike.cancelled==(case.interrupt and 'HIT'or case.exit and 'BATTLE_ENDED'or'UNSAFE_REENTRY'))
   else
    assert(#strike.clips==5 and #strike.impacts==4 and strike.completed-strike.started>=5.86,'Sequence truncated')
    for _,clip in ipairs(strike.clips)do assert(clip.ended and clip.ended-clip.started>=clip.duration-.025)end
    if case.dodge then assert(hp==before,'Locked assault tracked dodge')else assert(before-hp==8 and strike.hits==1,'Rush duplicated/missed hit')end
    assert(record.enemy.faceRight==(case.dir<0),'Idle facing wrong after inverse authored clip')
   end
   if wall then wall:removeFromParent()end
   r.cases[#r.cases+1]={direction=case.dir,dodge=case.dodge,damage=before-hp,cancelled=strike.cancelled,hero=strike.hero,clips=strike.clips,impacts=strike.impacts};save()
  end
  setup(1)
  local damages={0,0};local Small=require('Enemy.SmallYingzhao')
  for i,x in ipairs({8000,7700})do local u=Small.create(b.world,x);u.group=1;extraTargets[i]={unit=u,hp=function()return 100-damages[i]end,damage=function(n)damages[i]=damages[i]+n end}end
  D.sleep(.4);local before=hp;assert(c:attack('hero',b.mentor));local multi=c.strike
  wait(function()return not c.busy end);c.nextAttack=math.huge
  assert(hp<before and damages[1]>0 and damages[2]>0,'Wide assault missed its spaced targets')
  r.multipleTargets={mentor=before-hp,others=damages,hits=multi.hits,impacts=multi.impacts}
  for _,t in ipairs(extraTargets)do local entity=t.unit.entity;t.unit:removeFromParent();entity:destroy()end;extraTargets={}
  setup(1)
  local def=D.BodyDef();def.type='Static';def:attachPolygon(30,900);local wall=D.Body(def,b.world,D.Vec2(8830,b.world.offset+450));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world)
  D.sleep(.05) -- Let the newly added native physics fixture enter the broad phase.
  local accepted,why=c:attack('hero',b.mentor);assert(not accepted and why=='NO_SAFE_REENTRY');wall:removeFromParent();r.blockedBeforeStart=true
  setup(1);assert(c:attack('hero',b.mentor));D.sleep(1.4);record.enemyHP=0;wait(function()return c.dead end);assert(record.enemy.opacity==1 and c.hero.closed and not c.hero.warning.parent);r.deathCleanup=true
  node:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
