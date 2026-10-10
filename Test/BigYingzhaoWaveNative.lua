local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-wave-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  D.Cache:loadAsync('spine:dayingzhao');local E=require('Enemy.BigYingzhao');local K=require('Combat.Displacement')
  local record={enemy=E.create(b.world,7800),enemyHP=1000};local hp=10000
  local target={unit=b.mentor,hp=function()return hp end,damage=function(n)hp=hp-n end}
  local host={world=b.world,phase='playing',targets=function()return {target,target}end};local c=E.new(host,record);c.nextAttack=math.huge
  local airborne=false;local node=D.Node();node:addTo(b.world);node:schedule(function()
   if airborne then b.mentor.y=b.world.offset+650;b.mentor.velocity=D.Vec2.zero end
   c:update(D.App.runningTime);return false
  end)
  local function wait(fn)local stop=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<stop,'timeout');D.sleep(.01)end end
  for _,case in ipairs({{dir=1},{dir=-1},{dir=1,wall=true},{dir=1,air=true},{dir=1,interrupt=true},{dir=1,exit=true},{dir=1,death=true}})do
   K.clear(b.mentor);b.mentor:stop();b.mentor.velocity=D.Vec2.zero;b.mentor.position=D.Vec2(7800+case.dir*800,b.world.offset+155)
   record.enemy.position=D.Vec2(7800,b.world.offset+255);record.enemy.velocity=D.Vec2.zero;host.phase='playing';c.nextReaction=0;c.nextAttack=math.huge;D.sleep(.5)
   wait(function()return record.enemy.onSurface and b.mentor.onSurface end)
   wait(function()return D.App.runningTime>=c.nextWave end)
   local wall
   if case.wall then local def=D.BodyDef();def.type='Static';def:attachPolygon(30,900);wall=D.Body(def,b.world,D.Vec2(8200,b.world.offset+450));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world)end
   airborne=case.air;local before=hp;assert(c:attack('wave',b.mentor));local strike=c.strike
   D.sleep(2);assert(hp==before and not strike.wave,'Wave released during windup')
   if case.interrupt then record.enemyHP=record.enemyHP-1;wait(function()return not c.reacting and not c.busy end);assert(not strike.wave and strike.cancelled=='HIT')
   else
    wait(function()return strike.wave end)
    if case.dir==1 and not(case.wall or case.air or case.exit or case.death)then
     b.world.camera.zoom=.8;b.world.camera.position=D.Vec2(8170,400);D.sleep(.35);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-wave-flight.tga')
    end
    if case.exit then host.phase='ended'elseif case.death then record.enemyHP=0 end
    wait(function()return #c.waves==0 end)
    if case.exit or case.death then assert(hp==before);assert(strike.wave.reason==(case.exit and 'BATTLE_ENDED'or'DEFEATED'))
    elseif case.wall then assert(hp==before and strike.wave.reason=='WALL')
    elseif case.air then assert(hp==before and strike.wave.reason=='RANGE')
    else assert(before-hp==16 and #strike.wave.hits==1,'Wave duplicated or missed damage');assert(strike.displacements and #strike.displacements==1)end
    if not case.exit and not case.death then wait(function()return not c.busy end);assert(strike.completed-strike.started>=4-.02)end
   end
   airborne=false;if wall then wall:removeFromParent()end;c.nextAttack=math.huge
   r.cases[#r.cases+1]={direction=case.dir,wall=case.wall,air=case.air,exit=case.exit,death=case.death,damage=before-hp,cancelled=strike.cancelled,wave=strike.wave,clips=strike.clips};save()
  end
  wait(function()return c.dead end);r.fullDeath=true;assert(#c.waves==0);node:removeFromParent();b:finish('aborted','QA complete')
  -- Real physics terrain with a gap; one delayed 0.8s update must not bridge it.
  local world=D.PhysicsWorld();world:addTo(D.Director.entry)
  local function platform(x,width)
   local def=D.BodyDef();def.type='Static';def:attachPolygon(width,20)
   local body=D.Body(def,world,D.Vec2(x,-10));body.group=D.Platformer.Data.groupTerrain;body:addTo(world);return body
  end
  platform(0,500);platform(1000,500);D.sleep(.1)
  local ctrl={world=world,unit={x=0,y=250,unitDef={size=D.Size(300,500)},order=0},direction=1,record={enemyHP=100},battle={world=world,phase='playing',targets=function()return {}end}}
  local wave=require('Enemy.GroundWave').new(ctrl,{started=D.App.runningTime,hits=0})
  wave:update(wave.last+.8);assert(not wave.active and wave.record.reason=='GAP'and wave.travel<=250,'Delayed wave crossed gap')
  r.gapDelayed=wave.record
  local cleanup=require('Enemy.GroundWave').new(ctrl,{started=D.App.runningTime,hits=0});cleanup:stop('CLEANUP');assert(not cleanup.visual.parent and not cleanup.active);r.visualCleanup=true
  world:removeFromParent()
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
