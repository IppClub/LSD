local D=require('Dora');local P=D.Platformer;local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test','patrol-guard-physics-result.txt');D.Content:save(out,'LSD_PATROL_PHYSICS_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local Scene=require('Scene.Factory');Scene:loadAsync();D.Cache:loadAsync('spine:charM')
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();P.Data.store:clear();P.Data:setRelation(1,2,'Enemy');P.Data:setRelation(1,3,'Neutral');P.Data:setShouldContact(1,3,false);P.Data:setShouldContact(3,P.Data.groupTerrain,true)
  local w=Scene();w:addTo(D.Director.entry);P.Data.store.world=w
  local def=D.Dictionary();def.playable='spine:charM';def.bodyType='Dynamic';def.size=D.Size(100,300);def.density=1;def.friction=1;def.linearAcceleration=D.Vec2(0,-15);def.defaultFaceRight=true;def.actions=D.Array({})
  D.Entity({patrolPhysicsTarget=true});local entity=assert(D.Group({'patrolPhysicsTarget'}):find(function(e)return e.patrolPhysicsTarget end));local target=P.Unit(def,w,entity,D.Vec2(1800,w.offset+155));target.group=1;target.playable.y=-150;target:addTo(w);target.playable:play('prepare',true)
  local b={phase='playing',world=w,projectiles={},hp=100};function b:targets()return{{unit=target,hp=function()return self.hp end,damage=function(n)self.hp=self.hp-n end}}end
  local Guard=require('Factory.PatrolGuard');local rec={enemy=Guard.create(w,2200),enemyHP=100};local g=Guard.new(b,rec);g.nextAttack=math.huge
  w:schedule(function()g:update(D.App.runningTime);return false end);D.sleep(1)
  assert(g:shoot(target));local first=g.strike;D.sleep(.78);assert(b.hp==100 and not first.releaseAt,'Damage before rifle frame')
  while not first.completed do D.sleep(.01)end;D.sleep(.3);assert(first.hits==1 and b.hp==94,'Native bullet failed physical hit')
  g.nextAttack=math.huge;assert(g:shoot(target));local second=g.strike;target.position=D.Vec2(1800,1300)
  while not second.completed do D.sleep(.01)end;g.nextAttack=math.huge;D.sleep(.3);assert(second.releaseAt and second.hits==0 and b.hp==94,'Rifle hit target outside collision lane')
  rec.enemyHP=0;local began=D.App.runningTime;while not g.dead do assert(D.App.runningTime-began<3,'Defeat stalled');D.sleep(.01)end
  assert(g.loseEnded-g.loseStarted>=1.55 and rec.enemy.group==3,'Defeat collision/animation incomplete')
  return string.format('PASS nativeShotFrame=%.4f noEarlyDamage=true physicalHit=true outOfLaneMiss=true fullShotBeforeRecovery=true fullLose=true neutralCorpse=true',first.impactOffset)
 end,debug.traceback)
 local report='LSD_PATROL_PHYSICS_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
