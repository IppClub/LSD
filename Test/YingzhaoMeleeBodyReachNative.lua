-- Controlled frozen Boss geometry, actual authored blade release and ledger.
-- Positions and Boss pose are fixed explicitly; this cannot prove natural victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-melee-body-reach-result.json'
local r={status='RUNNING',controlledFixture=true,osInput=false,naturalVictory=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local stop=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<stop,'Blade body reach timeout');D.sleep(.02)end end
  local b=require('Training.BigYingzhaoPractice').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},{{actor='wuyun',item='blade',quantity=4}},'wuyun')
  local a=b.wuyun;local boss=b.bossCombat.boss
  assert(b:start());boss.guard.update=function()end;boss.enemy.velocity=D.Vec2.zero;boss.enemy.playable.speed=0;b.arena.mode='review'
  D.sleep(.5);wait(function()return a.student.onSurface end)
  local chosen
  local y=a.student.y
  for x=b.minX+30,b.maxX-30,10 do
   local face=boss.enemy.x>=x;local hit,terrain=b.bossCombat:contact({x=x,y=y},{x=x+(face and 300 or -300),y=y})
   if math.abs(x-boss.enemy.x)>320 and hit and not hit.enemy and not terrain and not hit.startedInside then chosen={x=x,y=y,face=face,part=hit.part,position=hit.position};break end
  end
  assert(chosen,'No exposed blade-reachable Boss contour outside center gate')
  a.student:stop();a.student.velocity=D.Vec2.zero;a.student.position=D.Vec2(chosen.x,chosen.y);a.student.faceRight=chosen.face;D.sleep(.2)
  local contact,terrain=b.bossCombat:contact({x=a.student.x,y=a.student.y},{x=a.student.x+(a.student.faceRight and 300 or -300),y=a.student.y})
  assert(contact and not contact.enemy and not terrain and math.abs(a.student.x-boss.enemy.x)>300)
  if os.getenv('LSD_QA_REACH_OBSERVATION')=='1'then
   local F=require('Training.YingzhaoFeatures');local I=require('Training.FlowerIdentity')
   local reachable=b.observeYingzhao(a.student);assert(F.validate(reachable)and reachable.meleeReach=='reachable')
   r.reachableObservation=reachable
   local distant
   for delta=40,200,10 do
    a.student.position=D.Vec2(chosen.x+(chosen.face and -delta or delta),chosen.y)
    local observation=b.observeYingzhao(a.student)
    if observation.targetDistance==reachable.targetDistance and observation.meleeReach=='distant'then distant=observation;break end
   end
   assert(distant,'No distinct contact state inside the old center-distance band')
   assert(F.validate(distant)and F.key(reachable,11)~=F.key(distant,11))
   r.distantObservation=distant;r.sameDistanceBand=reachable.targetDistance
   local forged=D.json.decode(D.json.encode(distant),32);forged.meleeReach='reachable';assert(not F.validate(forged))
   forged=D.json.decode(D.json.encode(reachable),32);forged.meleeProbe.segmentLength=600;assert(not F.validate(forged))
   local old=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),64)
   assert(old.status=='PASS'and old.model.featureSchemaVersion==10)
   local P=require('Training.YingzhaoPolicy');assert(P.validate(old.model))
   assert(I.equal(assert(P.buildAsync({old.source},'wuyun',10,old.model.builderVersion,old.model.actionSetVersion)),old.model))
   for _,step in ipairs(old.source.boss.steps)do
    assert(F.validate(step.before)and F.project(step.before,11).meleeReach=='unknown')
   end
   local Q=require('Training.YingzhaoQ')
   for _,version in ipairs({10,11})do
    local q=Q.new('wuyun',version);assert(q:update({state=reachable,action='melee',reward=1,nextState=distant,done=false,duration=1,nextActions={'fmove'},sealed=true}))
    local model=q:snapshot();assert(Q.validate(model)and Q.restore(model));r['qVersion'..version]=model
   end
   r.oldSourceAndModelCompatible=true;r.reachTamperingRejected=true
   a.student.position=D.Vec2(chosen.x,chosen.y);a.student.velocity=D.Vec2.zero
  end
  local before=#b.bossTrace.hits;local ammo=b.supplies:observation('wuyun').ammo.blade
  assert(b:command('melee'));wait(function()return not a:isAttacking()end)
  local row={centerDistance=math.abs(a.student.x-boss.enemy.x),expectedPart=contact.part,actualHits=#b.bossTrace.hits-before,spent=ammo-b.supplies:observation('wuyun').ammo.blade,steps=b.bossTrace.steps,hits=b.bossTrace.hits}
  r.cases[#r.cases+1]=row;save()
  assert(row.spent==1,'Blade release cost not recorded once')
  assert(row.actualHits==1,'Real body contact was rejected by center-distance gate')
  assert(b.bossTrace.hits[#b.bossTrace.hits].weapon=='blade'and b.bossTrace.hits[#b.bossTrace.hits].part==contact.part)
  -- A farther swing must still miss and consume exactly its actual release.
  local farX=chosen.x+(chosen.face and -400 or 400)
  assert(farX>b.minX and farX<b.maxX)
  a.student:stop();a.student.velocity=D.Vec2.zero;a.student.position=D.Vec2(farX,chosen.y)
  D.sleep(.2);wait(function()return a:available('melee')end)
  local beyond=b.bossCombat:contact({x=a.student.x,y=a.student.y},{x=a.student.x+(chosen.face and 300 or -300),y=a.student.y})
  assert(not beyond,'Out-of-reach control intersects a body')
  before=#b.bossTrace.hits;ammo=b.supplies:observation('wuyun').ammo.blade
  assert(b:command('melee'));wait(function()return not a:isAttacking()end)
  local miss={outOfReach=true,centerDistance=math.abs(a.student.x-boss.enemy.x),actualHits=#b.bossTrace.hits-before,spent=ammo-b.supplies:observation('wuyun').ammo.blade}
  r.cases[#r.cases+1]=miss;save();assert(miss.actualHits==0 and miss.spent==1,'Blade range or release charging changed')
  b:finish('aborted','Controlled blade body contact');wait(function()return b.phase~='settling'end)
  r.resources=b.supplies:evidence();r.geometryAuthoritative=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
