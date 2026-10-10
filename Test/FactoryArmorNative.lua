-- Public factory HUD aiming, with isolated save and stationary combat fixtures.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
local out=root..'/Test/factory-armor-native-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-ruins-route-qa-1791013294.db'
  local dest=D.Content.writablePath..'/factory-aim-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local function model(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  D.App.winSize=D.Size(683,384)
  local c=require('Factory.Level').openAsync({finishAsync=function()return true end},{mission='c0-m05',models={ninilite=model('ninilite','laser'),wuyun=model('wuyun','melee')}})
  local b=c.battle;local combat=b.partCombat
  local function wait(f,t)local deadline=D.App.runningTime+(t or 6);while not f()do assert(D.App.runningTime<deadline,'Factory armor timeout '..#combat.events);D.sleep(.01)end end
  D.sleep(.1);c.start:emit('Tapped')
  for _,a in ipairs(b.learners)do a.nextDecision=math.huge end
  for _,e in ipairs(b.roots)do e.enemyCombat:close()end
  for i=1,2 do b.roots[i].enemyHP=0;b.roots[i].enemy.x=7500 end
  b.mentor.x=5350;b.arena.student.x=5300;b.wuyun.student.x=5400
  D.sleep(.1)
  assert(b:damageEnemy(b.roots[3].enemy,100)==0,'Legacy HP bypass remains')
  local function fire(a)
   local count=#combat.events
   if a then a.student.faceRight=true;wait(function()return a.student.onSurface and D.App.runningTime>=a.nextShot and not a:isAttacking()end);assert(a.student:start(a.physical.laser))
   else wait(function()return b.mentor.onSurface and D.App.runningTime>=b.nextMentorShot and not b.mentor:isDoing('groundMentorShot')end);assert(b:command('shoot'))end
   wait(function()return #combat.events>count end)
   return combat.events[#combat.events]
  end
  local emp=fire(b.arena);assert(emp.weapon=='emp' and emp.armorDamage==35 and emp.healthDamage==0,'EMP did not remove only armor')
  local kinetic=fire();assert(kinetic.weapon=='kinetic' and kinetic.armorDamage==0 and kinetic.healthDamage>0,'Kinetic altered armor')
  assert(emp.credit.armor==35 and emp.credit.health==0 and kinetic.credit.health==kinetic.healthDamage)
  r.emp=emp;r.kinetic=kinetic
  local broken
  for i=1,5 do local e=fire(b.arena);if e.armorBroken then broken=e;break end end
  assert(broken,'No local armor break');r.broken=broken
  local exposed=fire();assert(exposed.healthDamage>kinetic.healthDamage,'Broken part did not expose HP');r.exposed=exposed;assert(exposed.credit.assist and exposed.credit.assist.actor=='ninilite','No real break cooperation credit')
  b.wuyun.student.x=b.roots[3].enemy.x-190;b.wuyun.student.faceRight=true;D.sleep(.1)
  wait(function()return b.wuyun.student.onSurface and D.App.runningTime>=b.wuyun.nextShot end)
  local before=#combat.events;assert(b.wuyun.student:start(b.wuyun.physical.melee));wait(function()return #combat.events>before end)
  assert(combat.events[#combat.events].weapon=='blade');r.blade=combat.events[#combat.events]
  D.sleep(.1);assert(c.status.text:find('护甲') or c.status.text:find('已破甲'))
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/factory-armor-view.tga');D.sleep(.1)
  local function launch()
   local a=b.arena;wait(function()return a.student.onSurface and D.App.runningTime>=a.nextShot and not a:isAttacking()end)
   a.student.faceRight=true;local count=#a.projectiles;assert(a.student:start(a.physical.laser));wait(function()return #a.projectiles>count end)
  end
  wait(function()return next(combat.shots)==nil end)
  -- At authored scale, petals can reach the old wall at x=5500. Move
  -- the shooter and blocker ahead of the complete boss, then verify ordering.
  b.arena.student.x=4800;D.sleep(.1)
  local def=D.BodyDef();def.type='Static';def:attachPolygon(10,180,1,0,0)
  local wall=D.Body(def,b.arena.world,D.Vec2(5000,b.arena.student.y));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.arena.world);D.sleep(.1)
  local count=#combat.events;launch();D.sleep(1.2);assert(#combat.events==count,'Projectile crossed terrain');wall:removeFromParent();r.terrain=true
  local position=b.roots[3].enemy.position;launch();b.roots[3].enemy.position=position+D.Vec2(0,3000);D.sleep(1.2)
  assert(#combat.events==count,'Projectile followed a target moved out of its path');b.roots[3].enemy.position=position;b.roots[3].enemy.velocityY=0;r.movingMiss=true

  launch();c.withdraw:emit('Tapped');wait(function()return b.phase=='aborted'end)
  D.sleep(.3);assert(#combat.events==count,'Late hit after withdrawal')

  assert(combat.closed and next(combat.shots)==nil and combat.target.closed)
  assert(#b.report.partHits==#combat.events and b.report.partArmor);r.closed=true
  local episode=b.combatEpisode;assert(require('Training.CombatStore').validate(episode))
  assert(episode.versions.observation==6 and episode.versions.partSet==2 and episode.versions.action==4)
  local count=0;local actors={}
  for _,step in ipairs(episode.steps)do
   assert(require('Training.FlowerFeatures').validate(step.observation));actors[step.action.actor]=true
   for _,hit in ipairs(step.hits)do count=count+1;assert(hit.source==step.action.actor)end
  end
  assert(count==#combat.events and actors.mentor and actors.ninilite and actors.wuyun)
  assert(episode.steps[1].observation.part_left=='unknown' and episode.steps[1].nextObservation.part_left=='armored')
  local invalid=D.json.decode(D.json.encode(episode));invalid.steps[1].observation.phase='future';assert(not require('Training.CombatStore').validate(invalid))
  invalid=D.json.decode(D.json.encode(episode));invalid.versions.partSet=1;assert(not require('Training.CombatStore').validate(invalid))
  invalid=D.json.decode(D.json.encode(episode));invalid.steps[1].hits[1].credit.armor=999;assert(not require('Training.CombatStore').validate(invalid),'Forged contribution accepted')
  r.journal={steps=#episode.steps,hits=count,version=episode.versions.observation,unknownBeforeHit=true}


 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
