-- Actual theft -> create space -> turn -> shoot -> original weapon return.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/medium-yingzhao-flow-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  for i,e in ipairs(b.escorts)do e.unit.x=1500-i*150 end
  D.Cache:loadAsync('spine:zhongyingzhao-weapon.skel|zhongyingzhao.atlas')
  local E=require('Enemy.MediumYingzhao');local Disarm=require('Combat.Disarm')
  local rec={enemy=E.create(b.world,7800),enemyHP=100};local hp=1000
  local host={world=b.world,phase='playing',targets=function()return {{unit=b.mentor,hp=function()return hp end,damage=function(n)hp=hp-n end}}end}
  local c=E.new(host,rec);c.nextAttack=math.huge
  local node=D.Node();node:addTo(b.world);node:schedule(function()c:update(D.App.runningTime);return false end)
  local function wait(fn,seconds)local endAt=D.App.runningTime+(seconds or 12);while not fn()do assert(D.App.runningTime<endAt,'flow timeout');D.sleep(.01)end end
  for _,distance in ipairs({420,-420})do
   c.nextAttack=math.huge;c.spacingRetry=0;b.mentor:stop();b.mentor.velocity=D.Vec2.zero;rec.enemy.velocity=D.Vec2.zero
   rec.enemy.position=D.Vec2(7800,b.world.offset+215);b.mentor.position=D.Vec2(7800+distance,b.world.offset+155)
   D.sleep(.5);wait(function()return rec.enemy.onSurface and b.mentor.onSurface end)
   local before=hp;assert(c:attack('rob',b.mentor));local rob=c.strike;wait(function()return rob.completed end)
   assert(c.lease and c.lease.active and rob.disarmed,'No actual stolen weapon')
   wait(function()return c.strike~=rob and c.strike.skill=='shoot'end)
   local shot=c.strike;c.nextAttack=math.huge
   wait(function()return shot.completed end);c.nextAttack=math.huge
   local move=c.spacingMoves[#c.spacingMoves];local row={distance=distance,rob=rob,shot=shot,move=move,hpDamage=before-hp};r.cases[#r.cases+1]=row;save()
   assert(move.endX and math.abs(move.endX-move.startX)>200,'No visible spacing after theft')
   assert(shot.hits==1 and before-hp==15,'Theft did not produce a real shot')
   assert((move.endX-move.startX)*distance<0,'Moved towards target while making space')
   wait(function()return not c.lease.active end);assert(not b.mentor.data.weaponDisarmed);D.sleep(.4)
  end
  -- Block the escape side: never keep running into the wall.
  c.nextAttack=math.huge;c.spacingRetry=0;rec.enemy.position=D.Vec2(7800,b.world.offset+215);b.mentor.position=D.Vec2(8100,b.world.offset+155);D.sleep(.5)
  c.lease=assert(Disarm.take(b.mentor,rec.enemy,{leftAuthored=true,duration=6}))
  local def=D.BodyDef();def.type='Static';def:attachPolygon(20,900);local wall=D.Body(def,b.world,D.Vec2(7720,b.world.offset+450));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world)
  c.nextAttack=0;wait(function()return c.busy end)
  local move=c.spacingMoves[#c.spacingMoves];assert(move.reason=='WALL' and math.abs(move.endX-move.startX)<10);r.wallAvoided=true
  wait(function()return not c.busy end);c.nextAttack=math.huge;Disarm.release(c.lease,'QA_RETURN');wall:removeFromParent()
  local platformDef=D.BodyDef();platformDef.type='Static';platformDef:attachPolygon(80,30)
  local platform=D.Body(platformDef,b.world,D.Vec2(7800,b.world.offset+500));platform.group=D.Platformer.Data.groupTerrain;platform:addTo(b.world)
  rec.enemy.position=D.Vec2(7800,b.world.offset+735);rec.enemy.velocity=D.Vec2.zero;D.sleep(.5);wait(function()return rec.enemy.onSurface end)
  c.spacingRetry=0;c.lease=assert(Disarm.take(b.mentor,rec.enemy,{leftAuthored=true,duration=6}));c.nextAttack=0;wait(function()return c.busy end)
  move=c.spacingMoves[#c.spacingMoves];assert(move.reason=='LEDGE' and math.abs(move.endX-move.startX)<10,'Retreated off platform');r.ledgeAvoided=true
  host.phase='ended';D.sleep(.1);platform:removeFromParent();node:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
