-- Authored native event + real projectile and full animation, controlled world.
local D=require('Dora');local P=D.Platformer
local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/patrol-release-outcome-result.json'
local r={status='RUNNING',cases={},osInput=false,controlledFixture=true,formalMission=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local Scene=require('Scene.Factory');Scene:loadAsync();D.Cache:loadAsync('spine:charM')
  local Guard=require('Factory.PatrolGuard')
  local function wait(f,seconds)
   local deadline=D.App.runningTime+seconds
   while not f()do assert(D.App.runningTime<deadline,'Native event/animation timed out');D.sleep(.01)end
  end
  for _,kind in ipairs({'alive','defeated-before-release','ended-before-release'})do
   D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();P.Data.store:clear()
   P.Data:setRelation(1,2,'Enemy');P.Data:setRelation(1,3,'Neutral');P.Data:setShouldContact(1,3,false);P.Data:setShouldContact(3,P.Data.groupTerrain,true)
   local world=Scene();world:addTo(D.Director.entry);P.Data.store.world=world
   local def=D.Dictionary();def.playable='spine:charM';def.bodyType='Dynamic';def.size=D.Size(100,300);def.density=1;def.friction=1;def.linearAcceleration=D.Vec2(0,-15);def.defaultFaceRight=true;def.actions=D.Array({})
   local marker=D.Node();D.Entity({releaseTarget=marker})
   local entity=assert(D.Group({'releaseTarget'}):find(function(e)return e.releaseTarget==marker end))
   local target=assert(P.Unit(def,world,entity,D.Vec2(1800,world.offset+155)))
   target.group=1;target.playable.y=-150;target:addTo(world);target.playable:play('prepare',true)
   local b={phase='playing',world=world,projectiles={},hp=100}
   function b:targets()return{{unit=target,hp=function()return self.hp end,damage=function(n)self.hp=self.hp-n end}}end
   local record={enemy=Guard.create(world,2200),enemyHP=100};local guard=Guard.new(b,record)
   guard.nextAttack=math.huge
   world:schedule(function()guard:update(D.App.runningTime);return false end)
   D.sleep(.3);assert(guard:shoot(target));local strike=guard.strike
   D.sleep(.3)
   assert(not strike.releaseEventAt and not strike.releaseAt and #b.projectiles==0 and b.hp==100,'Early projectile')
   if kind=='defeated-before-release'then record.enemyHP=0
   elseif kind=='ended-before-release'then b.phase='won' end
   wait(function()return strike.completed end,3);guard.nextAttack=math.huge
   assert(strike.completed-strike.started>=strike.duration-.035,'Attack was truncated')
   assert(strike.releaseEventAt and strike.releaseEventAt-strike.started>=.78 and strike.releaseEventAt<strike.completed,'Authored event absent/outside attack')
   if kind=='alive'then
    D.sleep(.3);assert(strike.releaseAt and not strike.releaseCancelled and #b.projectiles==1 and strike.hits==1 and b.hp==94,'Real projectile did not hit exactly once')
    assert(strike.releaseEventHP==100 and strike.releaseEventPhase=='playing')
    assert(record.enemy.playable.current=='prepare','No prepare recovery')
   else
    assert(not strike.releaseAt and #b.projectiles==0 and strike.hits==0 and b.hp==100,'Cancelled event emitted damage')
    if kind=='defeated-before-release'then
     assert(strike.releaseCancelled=='DEFEATED' and strike.releaseEventHP==0 and strike.releaseEventPhase=='playing')
     wait(function()return guard.dead end,3)
     assert(guard.loseStarted>=strike.completed and guard.loseEnded-guard.loseStarted>=guard.loseDuration-.035,'Defeat cut attack/death short')
    else assert(strike.releaseCancelled=='BATTLE_ENDED' and strike.releaseEventHP==100 and strike.releaseEventPhase=='won') end
   end
   r.cases[#r.cases+1]={kind=kind,strike=strike,projectiles=#b.projectiles,targetHP=b.hp,loseStarted=guard.loseStarted,loseEnded=guard.loseEnded,loseDuration=guard.loseDuration};save()
   world:unschedule();world:removeFromParent()
  end
  r.scope='Real factory guard ModelEvent, physical projectile hit, suppressed projectile reasons, full shoot/lose durations; controlled states, not formal journey replay'
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
