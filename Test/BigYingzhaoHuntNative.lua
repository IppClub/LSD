local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-hunt-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  local E=require('Enemy.BigYingzhao');E.loadAsync();local K=require('Combat.Displacement');local Patrol=require('Factory.PatrolBattle')
  local record={enemy=E.create(b.world,7800),enemyHP=1000};local hp=10000;local immovable=false;local incoming={}
  local host={world=b.world,phase='playing',enemies={record},targets=function()return {{unit=b.mentor,immovable=immovable,hp=function()return hp end,damage=function(n,context)assert(context.attackerId and context.strikeStarted<=D.App.runningTime and context.hitIndex>=1);incoming[#incoming+1]={attackerId=context.attackerId,strikeStarted=context.strikeStarted,hitIndex=context.hitIndex,skill=context.skill};hp=hp-n end}}end,target=Patrol.target,damage=Patrol.damage}
  local c=E.new(host,record);record.guard=c;c.nextAttack=math.huge
  local node=D.Node();node:addTo(b.world);node:schedule(function()c:update(D.App.runningTime);return false end)
  local function wait(fn)local stop=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<stop,'timeout');D.sleep(.01)end end
  local function setup(direction)
   K.clear(b.mentor);b.mentor:stop();b.mentor.velocity=D.Vec2.zero;b.mentor.position=D.Vec2(7800+direction*600,b.world.offset+155)
   record.enemy.position=D.Vec2(7800,b.world.offset+255);record.enemy.velocity=D.Vec2.zero;c.nextAttack=math.huge;c.nextReaction=0
   D.sleep(.5);wait(function()return record.enemy.onSurface and b.mentor.onSurface end)
  end
  for _,case in ipairs({{direction=1},{direction=-1},{direction=1,immovable=true}})do
   local direction=case.direction;immovable=not not case.immovable
   setup(direction);local before=hp;local targetX=b.mentor.x;assert(c:attack('hunt',b.mentor));local strike=c.strike
   D.sleep(.4);assert(#c.hunt.children==0 and hp==before,'Summon before pointing cue')
   wait(function()return not c.busy end);c.nextAttack=math.huge
   assert(strike.summons.spawned==2 and #host.enemies==3 and #c.hunt.children==2)
   assert(strike.completed-strike.started>=10/3-.02,'Hunt clipped')
   for _,child in ipairs(c.hunt.children)do
    assert(child.log.commandedAt and child.guard.strikes[1].skill=='jump');assert(child.guard.strikes[1].summonId==child.log.id);assert(child.combatSource=='yingzhao-summon-'..child.log.id)
    assert(host:damage(child.enemy,5)==5 and child.enemyHP==65,'Summon not damageable')
   end
   assert(hp<before,'Commanded pounces did not damage target')
   if immovable then
    assert(not K.blocked(b.mentor) and math.abs(b.mentor.x-targetX)<.1,'Commanded summons moved immovable target')
    for _,child in ipairs(c.hunt.children)do for _,s in ipairs(child.guard.strikes)do assert(not s.displacements,'Summon created immovable reaction')end end
   end
   local accepted,why=c:attack('hunt',b.mentor);assert(not accepted and why=='SUMMON_LIMIT')
   if direction==1 and not immovable then
    local first=c.hunt.children[1];assert(host:target(first.enemy)==first)
    host:damage(first.enemy,1000);wait(function()return #c.hunt.children==1 end);assert(first.log.ended-first.log.loseStarted>=first.guard.loseDuration-.005,'Summon death clipped');assert(#host.enemies==2 and not first.enemy.parent)
    assert(c:attack('hunt',b.mentor));wait(function()return not c.busy end);c.nextAttack=math.huge;assert(#c.hunt.children==2 and c.strike.summons.spawned==1,'Vacant slot not refilled')
    r.slotRefill=true
    b.world.camera.zoom=.8;b.world.camera.position=D.Vec2(8120,400);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-hunt.tga')
   end
   host.phase='ended';D.sleep(.1);assert(#c.hunt.children==0 and #host.enemies==1);r[immovable and 'immovable' or 'direction'..direction]={damage=before-hp,spawned=strike.summons.spawned}
   host.phase='playing'
  end
  immovable=false;setup(1);assert(c:attack('hunt',b.mentor));local interrupted=c.strike;D.sleep(.2);record.enemyHP=record.enemyHP-1;wait(function()return not c.busy and not c.reacting end);c.nextAttack=math.huge;assert(not interrupted.summons and #c.hunt.children==0);r.interrupted=true
  setup(1)
  local def=D.BodyDef();def.type='Static';def:attachPolygon(30,900);local wall=D.Body(def,b.world,D.Vec2(7880,b.world.offset+450));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world)
  assert(c:attack('hunt',b.mentor));wait(function()return not c.busy end);c.nextAttack=math.huge
  assert(c.strike.summons.spawned==0 and c.strike.summons.reason=='NO_SAFE_SPAWN'and #host.enemies==1);wall:removeFromParent();r.wallPreventsSummoning=true
  setup(1);assert(c:attack('hunt',b.mentor));wait(function()return #c.hunt.children==2 end);record.enemyHP=0;D.sleep(.1);assert(#c.hunt.children==0 and #host.enemies==1);wait(function()return c.dead end);r.commanderDeathCleanup=true
  local ids={};for _,e in ipairs(incoming)do if e.attackerId:match('^yingzhao%-summon%-')then ids[e.attackerId]=true end end
  local count=0;for _ in pairs(ids)do count=count+1 end;assert(count>=2,'Summon contacts collapsed to one source')
  r.incoming=incoming;r.distinctIncomingSummons=count;r.contactProvenance=true
  r.history=c.hunt.history;node:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
