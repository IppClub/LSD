local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-combat-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  D.Cache:loadAsync({'spine:dayingzhao','spine:xiaoyingzhao'});local E=require('Enemy.BigYingzhao');local K=require('Combat.Displacement')
  local record={enemy=E.create(b.world,7800),enemyHP=1000};local other=require('Enemy.SmallYingzhao').create(b.world,8100);other.group=1
  local hp={10000,10000};local units={b.mentor,other};local targets={}
  for i,u in ipairs(units)do targets[i]={unit=u,hp=function()return hp[i]end,damage=function(n)hp[i]=hp[i]-n end}end
  local host={world=b.world,phase='playing',targets=function()return {targets[1],targets[2],targets[1]}end}
  local c=E.new(host,record);c.nextAttack=math.huge
  local node=D.Node();node:addTo(b.world);node:schedule(function()c:update(D.App.runningTime);return false end)
  local function wait(fn)local stop=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<stop,'timeout');D.sleep(.01)end end
  local function setup(direction)
   for i,u in ipairs(units)do K.clear(u);u:stop();u.velocity=D.Vec2.zero;u.position=D.Vec2(7800+direction*(i==1 and 250 or 320),b.world.offset+(i==1 and 155 or 105))end
   record.enemy.velocity=D.Vec2.zero;record.enemy.position=D.Vec2(7800,b.world.offset+255);c.nextAttack=math.huge;c.nextReaction=0
   D.sleep(.5);wait(function()return record.enemy.onSurface and units[1].onSurface and units[2].onSurface end)
  end
  for _,case in ipairs({{skill='punch',dir=1},{skill='punch',dir=-1},{skill='punch',dir=1,dodge=true},{skill='massive',dir=1},{skill='massive',dir=-1},{skill='massive',dir=1,interrupt=true}})do
   setup(case.dir);local before={hp[1],hp[2]};local x=record.enemy.x;assert(c:attack(case.skill,b.mentor));local strike=c.strike
   D.sleep(.1);assert(hp[1]==before[1]and hp[2]==before[2],'Windup must not damage')
   if case.dodge then for _,u in ipairs(units)do u.x=7800-case.dir*600 end end
   if case.interrupt then record.enemyHP=record.enemyHP-1 end
   wait(function()return not c.busy and not c.reacting end);c.nextAttack=math.huge
   if case.interrupt then assert(strike.cancelled=='HIT'and strike.hits==0)
   else
    for _,clip in ipairs(strike.clips)do assert(clip.ended and clip.ended-clip.started>=clip.duration-.02,'Truncated attack')end
    assert(#strike.impacts==(case.skill=='massive'and 3 or 1))
    if case.dodge then assert(strike.hits==0)
    elseif case.skill=='punch'then assert(strike.hits==2 and before[1]-hp[1]==18 and before[2]-hp[2]==18,'Area hit/duplicate target')
    else assert(strike.hits>=2 and strike.displacements and #strike.displacements>=2,'No visible group launch');assert((record.enemy.x-x)*case.dir>100,'No forward travel')end
   end
   assert(record.enemy.playable.current=='idle','Recovery did not return to idle')
   r.cases[#r.cases+1]={skill=case.skill,direction=case.dir,dodge=case.dodge,cancelled=strike.cancelled,hits=strike.hits,travel=record.enemy.x-x,clips=strike.clips,impacts=strike.impacts,displacements=strike.displacements};save()
  end
  setup(1);assert(c:attack('massive',b.mentor));local strike=c.strike;D.sleep(.1);host.phase='ended';D.sleep(.3);assert(strike.cancelled=='BATTLE_ENDED'and strike.hits==0);r.exitCancelled=true
  host.phase='playing';setup(1);assert(c:attack('punch',b.mentor));local dying=c.strike;D.sleep(.1);record.enemyHP=0;wait(function()return c.dead end);assert(dying.cancelled=='DEFEATED'and dying.hits==0);assert(c.loseEnded-c.loseStarted>=c.loseDuration-.02);r.fullDeath=true
  node:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
