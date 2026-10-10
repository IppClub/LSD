-- Actual controlled demonstrations, trained rules and frozen candidate casts.
-- This proves the learning plumbing, not a natural Boss victory or model adoption.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-skill-policy-result.json';local r={status='RUNNING',actors={},notNaturalVictory=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-skill-policy-'..os.time()..'.db';assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  local P=require('Training.YingzhaoPolicy');local A=require('Training.YingzhaoActions');local I=require('Training.FlowerIdentity')
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local function wait(fn)local deadline=D.App.runningTime+14;while not fn()do assert(D.App.runningTime<deadline,'Skill policy timeout');D.sleep(.02)end end
  local function place(b,actor,direction)
   local boss=b.enemies[1];local update=boss.guard.update;boss.guard.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   local a=actor=='ninilite'and b.arena or b.wuyun;local other=actor=='ninilite'and b.wuyun or b.arena
   local bx=direction==1 and 2500 or 1340
   boss.enemy.x=bx;a.student.x=bx-direction*500;a.student.faceRight=direction==1;other.student.x=bx+direction*700;other.mode='review'
   b.mentor.x=bx-direction*240;b.mentor.faceRight=direction==1;return a
  end
  for _,actor in ipairs({'ninilite','wuyun'})do
   local skill=actor=='ninilite'and'fire'or'wind';local row={actor=actor,sources={},executions={}};r.actors[#r.actors+1]=row
   for episode=1,6 do
    local direction=episode%2==1 and 1 or -1
    local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor=actor,item='emp',quantity=2}},actor)
    local a=place(b,actor,direction);assert(b:start());D.sleep(.4)
    -- The real demonstration command must mark only the selected learner as demo.
    assert(b:command(skill));wait(function()return not b.magic:busy(skill)and not b.bossCombat:pendingActor(actor)end)
    assert(a:request('idle','demo'));D.sleep(.3);a.student:stop()
    assert(b:finish('aborted','Skill demonstration fixture'));wait(function()return b.phase=='aborted'end)
    local resources=b.supplies:evidence();b.bossTrace.resources=resources
    local e=D.json.decode(D.json.encode({schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator=actor,episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace},false,true),32)
    assert(require('Training.YingzhaoStore').saveAsync(e));row.sources[#row.sources+1]=e;save()
   end
   local data=assert(P.inspect(row.sources,actor,6,2));assert(data.actions[skill..'@left']==3 and data.actions[skill..'@right']==3 and data.actions.idle>=6)
   local legacy=assert(P.inspect(row.sources,actor,6,1));assert(not legacy.actions[skill..'@left']and not legacy.actions[skill..'@right'])
   assert(not P.inspect(row.sources,actor,5,2));row.samples=#data.samples
   local stored=assert(require('Training.YingzhaoPolicyStore').learnAsync(actor));local loaded=assert(require('Training.YingzhaoPolicyStore').loadLatestAsync(actor));assert(I.equal(loaded.model,stored.model))
   row.model=stored.model;row.candidateId=stored.id;assert(row.model.actionSetVersion==2 and row.model.featureSchemaVersion==6)
   local forged=D.json.decode(D.json.encode(row.model),32);forged.actionSetVersion=1;assert(not P.validate(forged),'Old model accepted skill labels')
   forged=D.json.decode(D.json.encode(row.model),32);forged.rules[1].action=(skill=='fire'and'wind'or'fire')..'@right';assert(not P.validate(forged),'Wrong role skill accepted')
   for _,direction in ipairs({1,-1})do
    local supplies=assert(require('Economy.CombatSession').virtual('skill-candidate:'..D.App.runningTime,{{actor=actor,item='emp',quantity=2}}))
    local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true});local a=place(b,actor,direction)
    D.sleep(.4);require('Training.YingzhaoTrial').attach(b,row.model);assert(b:start())
    wait(function()return #b.magic.logs>0 end);local log=b.magic.logs[1]
    row.latestAttempt={direction=direction,log=log,decisions=b.yingzhaoCandidateDecisions};save()
    assert(log.skill==skill and log.source=='candidate'and log.direction==direction,'Candidate chose a different skill or direction')
    wait(function()return log.endedAt and not b.magic:busy(skill)and not b.bossCombat:pendingActor(actor)end)
    assert(log.status=='completed'and log.releaseAt and (log.hits or 0)>0)
    D.sleep(.6);assert(#b.magic.logs==1,'Candidate bypassed cooldown')
    assert(#a.recorder.samples==0,'Candidate silently wrote demonstration samples')
    assert(b:finish('aborted','Candidate execution fixture'));wait(function()return b.phase=='aborted'end)
    local evidence={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-evaluation',episode=supplies:evidence().attempt,versions={resources=1,bigYingzhao=1},resources=supplies:evidence(),boss=b.bossTrace}
    assert(require('Enemy.BigYingzhaoEvidence').validateEvaluation(evidence))
    row.executions[#row.executions+1]={direction=direction,log=log,decisions=b.yingzhaoCandidateDecisions,trace=b.bossTrace};save()
   end
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
