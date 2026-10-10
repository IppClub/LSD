-- Real aim solver, terrain and visibility; fixture observations are not training.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-reachability-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},nil,{virtual=true})
  local F=require('Training.YingzhaoFeatures');F.version=5;local A=require('Training.YingzhaoActions');assert(F.version==5 and #F.fields(4)==21 and #F.fields(5)==28)
  assert(b:start());for _,a in ipairs(b.learners)do a.mode='review'end
  local boss=b.enemies[1];boss.guard.nextAttack=math.huge;b.arena.student.x=1000;b.wuyun.student.x=300;b.mentor.x=400
  D.sleep(.5);boss.enemy.playable.speed=0;local owner=b.arena.student
  local function observe()
   local s=b.observeYingzhao(owner);assert(F.validate(s))
   for _,id in ipairs(F.aimParts)do assert((s['aim_'..id]=='reachable')==(A.plan(b,{student=owner},id)~=nil),'Observation/solver mismatch')end
   return s
  end
  local open=observe();assert(open.aim_head=='reachable'and open.aim_summon=='blocked');r.open=open
  local def=D.BodyDef();def.type='Static';def:attachPolygon(30,1700)
  local wall=D.Body(def,b.world,D.Vec2(1450,b.world.offset+850));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world);D.sleep(.05)
  local covered=observe();assert(covered.aim_head=='blocked'and F.key(open)~=F.key(covered));assert(F.key(open,4)==F.key(covered,4),'Legacy projection changed with new facts');r.covered=covered
  wall:removeFromParent();D.sleep(.05);assert(observe().aim_head=='reachable')
  boss.enemy.opacity=0;local hidden=observe();for _,id in ipairs(F.parts)do assert(hidden['aim_'..id]=='blocked')end
  boss.enemy.x=2800;local moved=observe();assert(F.key(hidden)==F.key(moved),'Hidden location leaked through reachability')
  local forged=D.json.decode(D.json.encode(hidden),32);forged.aim_head='reachable';assert(not F.validate(forged))
  boss.enemy.x=1920;boss.enemy.opacity=1
  local child={enemy=require('Enemy.SmallYingzhao').create(b.world,1350),enemyHP=70};child.guard=require('Enemy.SmallYingzhao').new(b,child);child.guard.nextAttack=math.huge;b.enemies[#b.enemies+1]=child;D.sleep(.3)
  local summon=observe();assert(summon.aim_summon=='reachable');r.summon=summon
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-context-melee-20261006/result.json'),32);assert(prior.status=='PASS')
  local old=prior.cases[1].source.boss.steps[1].before;assert(old.featureSchemaVersion==4 and F.validate(old))
  local projected=assert(F.project(old,5));for _,id in ipairs(F.aimParts)do assert(projected['aim_'..id]=='unknown')end
  local timings={};local sum=0
  for i=1,100 do
   D.sleep(.02);local t=D.App.elapsedTime;b.observeYingzhao(owner);local ms=(D.App.elapsedTime-t)*1000;timings[#timings+1]=ms;sum=sum+ms
  end
  table.sort(timings);r.captureElapsedMs={mean=sum/#timings,p95=timings[95],max=timings[100],samples=#timings,scope='stationary-scene-one-observation-per-frame'}
  r.partTimings={}
  for _,id in ipairs(F.aimParts)do
   local sum=0
   for i=1,10 do D.sleep(.02);local t=D.App.elapsedTime;A.plan(b,{student=owner},id);sum=sum+(D.App.elapsedTime-t)*1000 end
   r.partTimings[id]=sum/10
  end
  local solver=require('Combat.PartAim');local originalSolve=solver.solve;local comparisons=0
  for _,x in ipairs({450,1000,1550,2250,2800,3350})do
   for _,childX in ipairs({1350,2400})do
    owner.x=x;child.enemy.x=childX;D.sleep(.03)
    for _,id in ipairs(F.aimParts)do
     local fast,fastWhy=A.plan(b,{student=owner},id)
     solver.solve=function(origin,face,part,regions,blocked,center)return originalSolve(origin,face,part,regions,blocked,center)end
     local exact,exactWhy=A.plan(b,{student=owner},id);solver.solve=originalSolve
     assert((fast~=nil)==(exact~=nil)and fastWhy==exactWhy,'Preflight changed availability')
     if fast then assert(math.abs(fast.angle-exact.angle)<1e-8 and math.abs(fast.distance-exact.distance)<1e-8,'Preflight changed chosen ray')end
     comparisons=comparisons+1
    end
   end
  end
  r.exactRayComparisons=comparisons
  r.oldProjectionUnknown=true;r.legacyKeysPreserved=true;r.notTraining=true
  b:finish('aborted','Reachability fixture complete')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
