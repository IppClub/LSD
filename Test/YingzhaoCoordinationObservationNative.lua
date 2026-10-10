-- Controlled real geometry observations, not a demonstration or natural win.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/yingzhao-coordination-observation-result.json'
local r={status='RUNNING',scope='controlled-real-observation-pair-no-training-no-adoption',snapshots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function wait(fn)local limit=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<limit,'Observation fixture stalled');D.sleep(.01)end end
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=model('ninilite'),wuyun=model('wuyun')};local original=D.json.encode(models,false,true)
  local supplies=assert(require('Economy.CombatSession').virtual('coordination-observation',{{actor='ninilite',item='emp',quantity=4},{actor='wuyun',item='blade',quantity=4}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true})
  require('Ground.BattleSupport').attach(b,require('Ground.LifeSupport').new(90,'defence'))
  wait(function()return b.arena.student.onSurface and b.wuyun.student.onSurface and b.mentor.onSurface end)
  assert(b:start());b.enemies[1].guard.nextAttack=math.huge
  local F=require('Training.YingzhaoFeatures')
  for _,mentorX in ipairs({1200,1800})do
   b.arena.student.x=1500;b.wuyun.student.x=3400;b.mentor.x=mentorX;b.bossCombat.boss.enemy.x=3000
   for _,u in ipairs({b.arena.student,b.wuyun.student,b.mentor})do u.velocity=D.Vec2.zero;u.faceRight=true end
   b.support:update(0,{b.mentor.x,b.arena.student.x,b.wuyun.student.x})
   local s=F.capture(b,b.arena.student,{},{});assert(F.validate(s),'Invalid real geometry observation')
   local key=assert(F.key(s,12));local projected=assert(F.project(s,12))
   r.snapshots[#r.snapshots+1]={observation=s,projected=projected,key=key,mentorDelta=b.mentor.x-b.arena.student.x,approachDirection=b.mentor.x<b.arena.student.x and'left'or'right'}
  end
  r.featureCount=#F.fields(12);r.sameProjection=r.snapshots[1].key==r.snapshots[2].key;r.differentFields={}
  for _,name in ipairs(F.fields(12))do if r.snapshots[1].projected[name]~=r.snapshots[2].projected[name]then r.differentFields[#r.differentFields+1]=name end end
  assert(r.snapshots[1].mentorDelta<0 and r.snapshots[2].mentorDelta>0)
  if F.version>=13 then
   local states={r.snapshots[1].observation,r.snapshots[2].observation}
   assert(r.sameProjection and #F.fields(12)==43 and #F.fields(13)==45)
   assert(F.key(states[1],13)~=F.key(states[2],13),'Mentor geometry still aliases')
   assert(states[1].mentorSide=='left'and states[2].mentorSide=='right'and states[1].mentorDistance=='near'and states[2].mentorDistance=='near')
   r.currentKeys={F.key(states[1],13),F.key(states[2],13)}
   local oldPath=assert(os.getenv('LSD_QA_COORDINATION_OLD_FEATURES'))
   local oldF=assert(load(assert(D.Content:load(oldPath)),'@'..oldPath))();assert(oldF.version==12)
   local I=require('Training.FlowerIdentity')
   for _,s in ipairs(states)do
    local oldState=D.json.decode(D.json.encode(s),32);oldState.featureSchemaVersion=12;oldState.coordination=nil;oldState.mentorSide=nil;oldState.mentorDistance=nil
    assert(oldF.validate(oldState)and F.validate(oldState))
    for version=1,12 do
     assert(I.equal(oldF.fields(version),F.fields(version)))
     assert(I.equal(oldF.project(oldState,version),F.project(s,version)))
     assert(oldF.key(oldState,version)==F.key(s,version))
    end
   end
   r.legacyFieldVersionsChecked=12

   local function clone(s)return D.json.decode(D.json.encode(s),32)end
   local forged=clone(states[1]);forged.mentorSide='right';assert(not F.validate(forged))
   forged=clone(states[1]);forged.coordination.mentorX=1800;assert(not F.validate(forged))
   r.rejectsForgedCoordination=true
   local Q=require('Training.YingzhaoQ');r.qChecks={}
   for _,actor in ipairs({'ninilite','wuyun'})do
    local q=Q.new(actor);assert(q.featureVersion==13)
    -- Controlled numerical transitions prove distinct state storage, not training benefit.
    for i,s in ipairs(states)do assert(q:update({state=s,action=i==1 and'bmove'or'fmove',reward=1,duration=.3,done=true,sealed=true}))end
    assert(q.states==2);local restored=assert(Q.restore(D.json.decode(D.json.encode(q:snapshot()),32),actor))
    assert(restored:choose(states[1],function()return true end,false,0)=='bmove')
    assert(restored:choose(states[2],function()return true end,false,0)=='fmove')
    local old=Q.new(actor,12);assert(old:update({state=states[1],action='idle',reward=1,duration=.3,done=true,sealed=true}))
    local legacy=assert(Q.restore(old:snapshot(),actor));assert(legacy:choose(states[2],function()return true end,false,0)=='idle')
    r.qChecks[#r.qChecks+1]={actor=actor,newStates=restored.states,oldStates=legacy.states,oldVersion=legacy.featureVersion,newVersion=restored.featureVersion}
   end
   local path=os.getenv('LSD_QA_COORDINATION_LEGACY_INPUT');assert(path,'Missing actual legacy sources')
   local input=D.json.decode(assert(D.Content:load(path)),64);local P=require('Training.YingzhaoPolicy');assert(P.validate(input.model))
   local rebuilt=assert(P.buildAsync(input.records,input.model.characterId,12,input.model.builderVersion,input.model.actionSetVersion))
   local function equal(a,c)
    if type(a)~=type(c)then return false end;if type(a)~='table'then return a==c end
    for k,v in pairs(a)do if not equal(v,c[k])then return false end end
    for k in pairs(c)do if a[k]==nil then return false end end;return true
   end
   assert(equal(rebuilt,input.model),'Old C4.5 rebuild changed')
   r.legacyCandidateRebuilt=true;r.legacySamples=rebuilt.sampleCount;r.legacySourceCount=#input.records
   for _,record in ipairs(input.records)do for _,step in ipairs(record.boss.steps)do
    local state=assert(F.project(step.before,13));assert(state.mentorSide=='unknown'and state.mentorDistance=='unknown','Legacy data fabricated teammate geometry')
   end end
   r.oldSourcesProjectUnknown=true
   local C=require('Training.YingzhaoCoordinationFeatures');r.distanceChecks={}
   for _,test in ipairs({{0,'overlap','close'},{120,'right','close'},{120.01,'right','near'},{700,'right','near'},{700.01,'right','far'},{-701,'left','far'}})do
    local projected=assert(C.project({schemaVersion=1,present=true,ownX=1000,mentorX=1000+test[1]}))
    assert(projected.mentorSide==test[2]and projected.mentorDistance==test[3]);r.distanceChecks[#r.distanceChecks+1]=projected
   end
   local absent=assert(C.project({schemaVersion=1,present=false,ownX=1000}));assert(absent.mentorSide=='unknown'and absent.mentorDistance=='unknown')
   assert(not C.project({schemaVersion=1,present=true,ownX=1000,mentorX=math.huge}));assert(not C.project({schemaVersion=1,present=false,ownX=1000,mentorX=1200}))
  end

  assert(original==D.json.encode(models,false,true));r.modelsUnchanged=true
  b:finish('aborted','Controlled coordination observation complete');wait(function()return b.settled end)
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
