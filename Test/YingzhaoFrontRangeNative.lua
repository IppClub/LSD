-- Explicitly positioned virtual geometry: observation/compatibility evidence,
-- never a natural victory or a demonstrated/adopted gameplay model.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-front-range-result.json'
local r={status='RUNNING',controlledFixture=true,naturalVictory=false,osInput=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local F=require('Training.YingzhaoFeatures');local R=require('Training.YingzhaoRangeFeatures');local T=require('Enemy.BigYingzhaoTimeline')
  assert(T.meleeReach==360 and T.meleeVerticalReach==330)
  assert(T.meleeReach+T.massiveMotion.speed*(T.massiveMotion.finish-T.massiveMotion.start)==840)
  -- Exact inclusivity, mirrored facings, vertical and invisible boundaries.
  for _,face in ipairs({true,false})do for _,case in ipairs({{-1,'rear'},{0,'immediate'},{360,'immediate'},{360.01,'advance'},{800,'advance'},{840,'advance'},{840.01,'outside'},{1100,'outside'}})do
   local raw=R.capture({x=2000+case[1]*(face and 1 or -1),y=255},{x=2000,y=255,faceRight=face},true)
   assert(R.project(raw).bossFrontRange==case[2]);r.cases[#r.cases+1]={raw=raw,expected=case[2]}
  end end
  for _,dy in ipairs({-330,330,-330.01,330.01})do
   local raw=R.capture({x=2100,y=255+dy},{x=2000,y=255,faceRight=true},true)
   assert(R.project(raw).bossFrontRange==(math.abs(dy)<=330 and'immediate'or'vertical'))
  end
  local hidden=R.capture({}, {},false);assert(R.project(hidden).bossFrontRange=='unknown');hidden.bossX=2000;assert(not R.project(hidden))
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Training.BigYingzhaoPractice').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},{{actor='ninilite',item='emp',quantity=8}},'ninilite')
  assert(b:start());local boss=b.bossCombat.boss;boss.guard.update=function()end;b.arena.mode='review';b.wuyun.mode='review'
  D.sleep(.4);local unit=b.arena.student
  boss.enemy:stop();boss.enemy.velocity=D.Vec2.zero;boss.enemy.faceRight=true
  local bx=boss.enemy.x;local y=unit.y
  assert(bx+1100<b.maxX,'Controlled positions outside arena')
  local states={}
  for _,distance in ipairs({800,1100})do
   unit:stop();unit.velocity=D.Vec2.zero;unit.position=D.Vec2(bx+distance,y)
   local s=b.observeYingzhao(unit);assert(F.validate(s));assert(s.bossDistance=='far')
   assert(s.bossFrontRange==(distance==800 and'advance'or'outside'));states[#states+1]=s
  end
  boss.enemy.visible=false
  local hiddenObservation=b.observeYingzhao(unit);assert(F.validate(hiddenObservation)and hiddenObservation.bossFrontRange=='unknown'and hiddenObservation.bossRange.bossX==nil)
  r.hiddenObservation=hiddenObservation;boss.enemy.visible=true
  r.observations=states;assert(F.key(states[1],12)~=F.key(states[2],12))
  for _,mutate in ipairs({function(s)s.bossFrontRange='immediate'end,function(s)s.bossRange.ownX=s.bossRange.ownX+1 end,function(s)s.bossRange.faceRight=not s.bossRange.faceRight end,function(s)s.bossVisible=false end})do
   local forged=D.json.decode(D.json.encode(states[1]),64);mutate(forged);assert(not F.validate(forged))
  end
  local old=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),64)
  assert(old.status=='PASS'and old.model.featureSchemaVersion==11)
  local P=require('Training.YingzhaoPolicy');local I=require('Training.FlowerIdentity')
  assert(P.validate(old.model))
  assert(I.equal(assert(P.buildAsync({old.source},'ninilite',11,old.model.builderVersion,old.model.actionSetVersion)),old.model))
  for _,step in ipairs(old.source.boss.steps)do
   assert(F.validate(step.before));assert(F.project(step.before,12).bossFrontRange=='unknown')
   local key=assert(F.key(step.before,11));local projected=assert(F.key(step.before,12));assert(projected==key..'|unknown')
  end
  -- Actual new-schema C4.5 path consumes archived older demonstrations without
  -- manufacturing range labels; unknown stays explicit and no model is adopted.
  r.projectedModel=assert(P.buildAsync({old.source},'ninilite',12,old.model.builderVersion,old.model.actionSetVersion))
  assert(P.validate(r.projectedModel));r.oldModelRebuiltIdentically=true
  local Q=require('Training.YingzhaoQ')
  for _,version in ipairs({11,12})do
   local q=Q.new('ninilite',version)
   assert(q:update({state=states[1],action='bmove',reward=1,nextState=states[2],done=false,duration=1,nextActions={'idle'},sealed=true}))
   local model=q:snapshot();assert(Q.validate(model));assert(I.equal(assert(Q.restore(model)):snapshot(),model));r['qVersion'..version]=model
  end
  b:finish('aborted','Controlled visible front range boundaries');r.schema=F.version;r.noAdoption=true;r.tamperingRejected=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
