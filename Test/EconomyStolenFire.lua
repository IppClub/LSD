-- Actual theft -> create space -> turn -> shoot -> original weapon return.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/economy-stolen-fire-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local dest=D.Content.writablePath..'/economy-stolen-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local Store=require('Economy.Store');assert(Store.open());assert(Store.beginAsync('stolen',{{actor='mentor',item='kinetic',quantity=2}},0))
  local supplies=assert(require('Economy.CombatSession').open('stolen'))
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  for i,e in ipairs(b.escorts)do e.unit.x=1500-i*150 end
  D.Cache:loadAsync('spine:zhongyingzhao-weapon.skel|zhongyingzhao.atlas')
  local E=require('Enemy.MediumYingzhao');local Disarm=require('Combat.Disarm')
  local rec={enemy=E.create(b.world,7800),enemyHP=100};local hp=1000
  local host={supplies=supplies,world=b.world,phase='playing',targets=function()return {{unit=b.mentor,hp=function()return hp end,damage=function(n)hp=hp-n end}}end}
  local c=E.new(host,rec);c.nextAttack=math.huge
  local node=D.Node();node:addTo(b.world);node:schedule(function()c:update(D.App.runningTime);return false end)
  local function wait(fn,seconds)local endAt=D.App.runningTime+(seconds or 12);while not fn()do assert(D.App.runningTime<endAt,'flow timeout');D.sleep(.01)end end
  for index,distance in ipairs({420,-420,420})do
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
   if index<3 then
    assert(shot.hits==1 and before-hp==15,'Theft did not produce a real shot')
   else assert(shot.hits==0 and before==hp and c.supplyFailure=='OUT_OF_SUPPLIES','Empty stolen gun fired')end
   local ledger=assert(Store.load('stolen'));assert(ledger.stock['mentor:kinetic'].used==math.min(index,2))
   for _,event in pairs(ledger.events)do assert(event.owner=='mentor' and event.performer=='enemy:1' and event.item=='kinetic')end
   assert((move.endX-move.startX)*distance<0,'Moved towards target while making space')
   wait(function()return not c.lease.active end);assert(not b.mentor.data.weaponDisarmed);D.sleep(.4)
  end
  assert(Store.load('stolen').stock['mentor:kinetic'].remaining==0);assert(supplies.emissions==2)
  r.maxCommitMs=supplies.maxCommitSeconds*1000;r.cost=Store.load('stolen').spent
  host.phase='ended';node:removeFromParent();b:finish('aborted','QA complete');assert(Store.settleAsync('stolen','aborted'))
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
