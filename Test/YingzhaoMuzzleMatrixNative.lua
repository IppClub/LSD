-- Controlled geometry matrix only; deliberately positioned/frozen units.
-- No formal mission, save/model injection or natural victory claim.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-muzzle-matrix-result.json';local r={status='RUNNING',controlledFixture=true,osInput=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local stop=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<stop,'Muzzle matrix stalled');D.sleep(.02)end end
  for _,actor in ipairs({'ninilite','wuyun'})do
   local supplies=assert(require('Economy.CombatSession').virtual('muzzle-matrix:'..actor,{{actor=actor,item='emp',quantity=12}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},supplies,{virtual=true})
   require('Training.YingzhaoDemonstration').attach(b,actor);assert(b:start());local a=actor=='ninilite'and b.arena or b.wuyun;local other=actor=='ninilite'and b.wuyun or b.arena
   other.mode='review';other.student.x=3500;b.mentor.x=3500;local boss=b.enemies[1];boss.guard.nextAttack=math.huge;D.sleep(.5);boss.enemy.playable.speed=0
   for _,direction in ipairs({1,-1})do for _,distance in ipairs({800,1300,1900})do
    wait(function()return not a:isAttacking() and a:available('laser')and next(b.bossCombat.shots)==nil end)
    boss.enemy.x=direction==1 and 2500 or 1200;a.student.x=boss.enemy.x-direction*distance;a.student.velocityX=0;a.student.faceRight=direction==1;D.sleep(.1)
    local first=#b.bossTrace.steps;local hits=#b.bossTrace.hits;local used=supplies.emissions
    local A=require('Training.YingzhaoActions');local selected;local rejected={}
    for _,part in ipairs({'head','arms','forelegs'})do local plan,why=A.plan(b,a,part);if plan then selected=part;break else rejected[part]=why end end
    assert(selected,'No body part reachable in this geometry fixture')
    local accepted,why=A.request(b,a,'shoot@'..selected,'demo');assert(accepted,why)
    local step=b.bossTrace.steps[first+1];local point=D.json.encode(step.aim.point,false,true)
    wait(function()return not a:isAttacking()and next(b.bossCombat.shots)==nil end)
    local row={actor=actor,direction=direction,distance=distance,intended=selected,rejected=rejected,step=step,hits={}};for index=hits+1,#b.bossTrace.hits do row.hits[#row.hits+1]=b.bossTrace.hits[index]end;r.cases[#r.cases+1]=row;save()
    assert(step.emitted==1 and supplies.emissions==used+1 and require('Training.YingzhaoActions').validateStep(step))
    assert(point==D.json.encode(step.aim.point,false,true),'Committed point changed during attack')
    assert(#row.hits==1 and row.hits[1].part==selected and row.hits[1].source==actor,'Stationary reachable part was not hit at authored range/direction')
   end end
   assert(b:finish('aborted','Controlled muzzle matrix'));wait(function()return b.settled end)
   local resources=supplies:evidence();b.bossTrace.resources=resources
   local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-evaluation',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   local valid,why=require('Enemy.BigYingzhaoEvidence').validateEvaluation(e);assert(valid,why)
   b.world:removeFromParent();D.Director.ui3D:removeAllChildren()
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
