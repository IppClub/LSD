local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/small-yingzhao-combat-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  D.Cache:loadAsync('spine:xiaoyingzhao');local E=require('Enemy.SmallYingzhao');local K=require('Combat.Displacement')
  local record={enemy=E.create(b.world,7800),enemyHP=100};local hp=10000;local immovable=false;local forced={}
  local host={world=b.world,phase='playing',targets=function()return {{unit=b.mentor,immovable=immovable,hp=function()return hp end,damage=function(n)hp=hp-n end,onForcedMovement=function(e)forced[#forced+1]=e end}}end}
  local c=E.new(host,record);c.nextAttack=math.huge
  local node=D.Node();node:addTo(b.world);node:schedule(function()c:update(D.App.runningTime);return false end)
  local function wait(fn)local stop=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<stop,'timeout');D.sleep(.01)end end
  local function setup(distance)
   K.clear(b.mentor);b.mentor:stop();b.mentor.velocity=D.Vec2.zero;record.enemy.velocity=D.Vec2.zero
   record.enemy.position=D.Vec2(7800,b.world.offset+105);b.mentor.position=D.Vec2(7800+distance,b.world.offset+155)
   c.nextAttack=math.huge;D.sleep(.5);wait(function()return record.enemy.onSurface and b.mentor.onSurface end)
  end
  for _,case in ipairs({{skill='kick',d=150,hit=true},{skill='kick',d=-150,hit=true},{skill='jump',d=285,hit=true},{skill='jump',d=-285,hit=true},{skill='kick',d=150,hit=true,immovable=true},{skill='jump',d=-285,hit=true,immovable=true},{skill='jump',d=700,hit=false},{skill='kick',d=150,hit=false,dodge=true},{skill='jump',d=285,hit=false,interrupt=true},{skill='kick',d=150,hit=false,behind=true}})do
   immovable=not not case.immovable;setup(case.d);local before=hp;local targetX=b.mentor.x;local forcedBefore=#forced;local x=record.enemy.x;assert(c:attack(case.skill,b.mentor));local strike=c.strike
   D.sleep(.1);assert(hp==before,'windup damaged target')
   if case.behind then b.mentor.x=record.enemy.x-300 end
   if case.dodge then b.mentor.x=b.mentor.x+700 end
   if case.interrupt then record.enemyHP=record.enemyHP-1 end
   wait(function()return not c.busy and not c.reacting end);c.nextAttack=math.huge;D.sleep(.1)
   assert(strike.hits==(case.hit and 1 or 0),case.skill..' distance '..case.d..' hits '..strike.hits)
   assert(before-hp==(case.hit and (case.skill=='kick' and 12 or 10) or 0))
   if case.interrupt then assert(strike.cancelled=='HIT') else for _,clip in ipairs(strike.clips)do assert(clip.ended and clip.ended-clip.started>=clip.duration-.02)end end
   if case.hit then
    if immovable then assert(not strike.displacements and not K.blocked(b.mentor) and #forced==forcedBefore and math.abs(b.mentor.x-targetX)<.1,'Immovable target entered character reaction')
    else assert(strike.displacements and #strike.displacements==1 and #forced>forcedBefore,'Character displacement trace missing')end
   end
   r.cases[#r.cases+1]={skill=case.skill,distance=case.d,immovable=immovable,hits=strike.hits,travel=record.enemy.x-x,cancelled=strike.cancelled,clips=strike.clips,impacts=strike.impacts,displacements=strike.displacements};save()
  end
  immovable=false;setup(600);c.nextAttack=0;local x=record.enemy.x;D.sleep(.5);assert(record.enemy.x>x+30 and record.enemy.playable.current=='move');r.approachTravel=record.enemy.x-x
  local count=#c.strikes;wait(function()return #c.strikes>count end);assert(c.strike.skill=='jump');wait(function()return not c.busy end);r.autoSelectedPounce=true
  c.nextAttack=math.huge;setup(285);assert(c:attack('jump',b.mentor));local strike=c.strike;D.sleep(.1);host.phase='ended';D.sleep(1);assert(strike.cancelled=='BATTLE_ENDED' and strike.hits==0);r.exitCancelled=true
  host.phase='playing';setup(285);assert(c:attack('jump',b.mentor));local dyingStrike=c.strike;D.sleep(.1);record.enemyHP=0;wait(function()return c.dead end);assert(c.loseEnded-c.loseStarted>=c.loseDuration-.02);r.fullDeath=true;assert(dyingStrike.cancelled=='DEFEATED' and dyingStrike.hits==0);r.deathCancelled=true
  node:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
