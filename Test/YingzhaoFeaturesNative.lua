-- Observation fixture: pose/visibility/contact controls are not training samples.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-features-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},assert(require('Economy.CombatSession').virtual('features-fixture',{{actor='wuyun',item='blade',quantity=1}})),{virtual=true});local F=require('Training.YingzhaoFeatures');local p=b.bossCombat;local boss=b.enemies[1]
  -- Keep this contact/visibility fixture at its explicit historical geometry.
  boss.enemy.x=2500;b.mentor.x=1900;b.arena.student.x=1700;b.wuyun.student.x=1850
  assert(b:start());boss.guard.nextAttack=math.huge;for _,a in ipairs(b.learners)do a.mode='review'end
  D.sleep(.4);local first=b.observeYingzhao(b.mentor);assert(F.validate(first));for _,id in ipairs(F.parts)do assert(first['part_'..id]=='unknown')end
  local hit=assert(p:contact({x=1900,y=b.world.offset+155},{x=2700,y=b.world.offset+155}))
  assert(p:apply(hit,'feature-emp-1','ninilite',require('Combat.WeaponProfiles').laser));local seen=b.observeYingzhao(b.mentor);assert(F.validate(seen)and seen['part_'..hit.part]=='armored')
  assert(p:apply(hit,'feature-emp-2','ninilite',require('Combat.WeaponProfiles').laser));local broken=b.observeYingzhao(b.mentor);assert(F.validate(broken)and broken['part_'..hit.part]=='exposed'and seen['part_'..hit.part]=='armored')
  boss.enemy.opacity=0;local hidden=b.observeYingzhao(b.mentor);assert(F.validate(hidden)and hidden.target=='none'and not hidden.bossX)
  assert(b:command('gather'));local plan=D.json.encode(b.gatherPlan);boss.enemy.x=3100;assert(b:command('gather'));assert(D.json.encode(b.gatherPlan)==plan,'Gather leaked invisible Boss position');b.gatherUntil=0
  local shifted=b.observeYingzhao(b.mentor);assert(F.key(hidden)==F.key(shifted),'Hidden relocation leaked into features')
  shifted.bossX=3100;assert(not F.validate(shifted));boss.enemy.x=2500
  local warning=D.DrawNode();warning:addTo(b.world);boss.guard.hero={closed=false,warning=warning,destination={x=2000,direction=-1}}
  local warned=b.observeYingzhao(b.mentor);assert(F.validate(warned)and warned.threat=='rear'and not warned.bossX);boss.guard.hero=nil;warning:removeFromParent()
  local child={enemy=require('Enemy.SmallYingzhao').create(b.world,2200),enemyHP=70};child.guard=require('Enemy.SmallYingzhao').new(b,child);child.guard.nextAttack=math.huge;b.enemies[2]=child;D.sleep(.2)
  local summon=b.observeYingzhao(b.mentor);assert(summon.target=='summon'and summon.targetArmor=='unknown')
  local contact=assert(p:contact({x=1900,y=child.enemy.y},{x=2400,y=child.enemy.y}));assert(contact.enemy==child)
  assert(p:apply(contact,'feature-summon','ninilite',require('Combat.WeaponProfiles').laser));summon=b.observeYingzhao(b.mentor);assert(F.validate(summon)and summon.targetArmor=='unarmored'and child.enemyHP==70)
  local beforeMove=#b.bossTrace.steps;b.arena.student.faceRight=false;assert(b.arena.student:start(b.arena.physical.fmove));D.sleep(.15);b.arena.student:stop()
  local move=b.bossTrace.steps[beforeMove+1];assert(move and move.action=='fmove'and move.ended and move.before.ownX-move.after.ownX>10 and F.validate(move.after));r.movement=move
  local owner=b.arena.student;boss.enemy.opacity=1;boss.enemy.x=owner.x+700
  child.enemy.x=owner.x-180;owner.faceRight=false;local split=b.observeYingzhao(owner)
  child.enemy.x=owner.x+180;owner.faceRight=true;local same=b.observeYingzhao(owner)
  assert(F.validate(split)and F.validate(same))
  assert(F.key(split)~=F.key(same),'Opposite-side and same-side threats collapse to the same learned state')
  assert(F.key(split,1)==F.key(same,1),'Legacy feature projection changed')
  assert(split.targetBossSide=='opposite'and same.targetBossSide=='same')
  local altered=D.json.decode(D.json.encode(same),32);altered.targetBossSide='opposite';assert(not F.validate(altered))
  local legacy=D.json.decode(D.json.encode(same),32);legacy.featureSchemaVersion=1;legacy.targetBossSide=nil;legacy.targetX=nil
  assert(F.validate(legacy)and F.project(legacy,2).targetBossSide=='unknown','Missing old geometry was invented')
  r.split=split;r.same=same;r.legacyProjection=true
  r.unknown=first;r.observed=seen;r.broken=broken;r.hidden=hidden;r.warning=warned;r.summon=summon
  local forged=D.json.decode(D.json.encode(seen),32);forged.part_forelegs='exposed';assert(not F.validate(forged))
  forged=D.json.decode(D.json.encode(seen),32);forged.targetDistance='near mid';assert(not F.validate(forged))
  -- Visible travelling waves remain observable while the Boss is hidden.
  local savedWaves=boss.guard.waves;local visual=D.DrawNode();visual:addTo(b.world)
  boss.enemy.opacity=0;boss.guard.waves={{active=true,visual=visual,x=800,direction=1,travel=900}}
  owner.x=1000;local front=b.observeYingzhao(owner);assert(F.validate(front)and front.waveReach=='approaching'and not front.bossVisible)
  owner.x=1400;local beyond=b.observeYingzhao(owner);assert(F.validate(beyond)and beyond.waveReach=='clear')
  owner.x=1000;visual.visible=false;assert(b.observeYingzhao(owner).waveReach=='clear')
  boss.guard.waves=savedWaves;visual:removeFromParent()
  local oldV2=D.json.decode(D.json.encode(front),32);oldV2.featureSchemaVersion=2;oldV2.waveReach=nil
  assert(F.validate(oldV2)and F.project(oldV2,3).waveReach=='unknown')
  assert(F.key(oldV2,2)==F.key(front,2))
  r.waveReach={front=front.waveReach,beyond=beyond.waveReach,old='unknown'}
  assert(b:finish('aborted','Observation fixture complete'));r.notTraining=not b.bossTrace.trainable
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
