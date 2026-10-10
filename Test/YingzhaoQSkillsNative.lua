-- Deterministic exploration selects real skills; no synthetic Q values or damage.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-skills-result.json';local r={status='RUNNING',cases={},notNaturalVictory=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-q-skills-'..os.time()..'.db';assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  local Q=require('Training.YingzhaoQ');local A=require('Training.YingzhaoActions');local Store=require('Training.YingzhaoQStore');local I=require('Training.FlowerIdentity')
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local function wait(fn)local deadline=D.App.runningTime+14;while not fn()do assert(D.App.runningTime<deadline,'Q skills timeout');D.sleep(.02)end end
  local function create(actor,direction)
   local supplies=assert(require('Economy.CombatSession').virtual('q-skills:'..D.App.runningTime,{{actor=actor,item='emp',quantity=2}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true});local boss=b.enemies[1];local update=boss.guard.update
   boss.guard.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   local a=actor=='ninilite'and b.arena or b.wuyun;local other=actor=='ninilite'and b.wuyun or b.arena;other.mode='review'
   local bx=direction==1 and 2500 or 1340;boss.enemy.x=bx;a.student.x=bx-direction*500;a.student.faceRight=direction==1;other.student.x=bx+direction*700
   b.mentor.x=bx-direction*240;b.mentor.faceRight=direction==1;D.sleep(.4)
   return b,a
  end
  for _,actor in ipairs({'ninilite','wuyun'})do for _,direction in ipairs({1,-1})do
   local skill=actor=='ninilite'and'fire'or'wind';local label=skill..(direction==1 and'@right'or'@left');local b,a=create(actor,direction)
   local session;local calls=0
   session=Q.attach(b,actor,{epsilon=1,random=function()
    calls=calls+1;if calls%2==1 then return 0 end
    local list={};local chosen
    for _,action in ipairs(session.q.actions)do if A.available(b,a,action,session.q.actionVersion)then list[#list+1]=action end end
    for i,action in ipairs(list)do if action==label then chosen=i;break elseif action=='idle'then chosen=i end end
    return (assert(chosen)-.5)/#list
   end})
   assert(b:start());wait(function()return #session.transitions>=1 end)
   local t=session.transitions[1];local step=b.bossTrace.steps[t.sourceStep]
   assert(t.action==label and step.skill.direction==direction and step.skill.status=='completed'and step.emitted==1)
   assert(t.ended>=step.ended and t.duration>=.9 and t.state.skillState=='ready')
   assert(t.nextState.skillState=='cooldown');for _,action in ipairs(t.nextActions)do assert(not action:match('^'..skill..'@'),'Cooling skill entered next-action mask')end
   local damage=0;for _,h in ipairs(b.bossTrace.hits)do if h.source==actor and h.at>t.started and h.at<=t.ended then damage=damage+h.healthDamage end end
   assert(damage>0 and math.abs(t.reward-(damage-t.deployment))<1e-6 and b.supplies.emissions==0)
   local updates=session.q.updates;assert(b:finish('aborted','Q skill fixture'));wait(function()return session.closed end)
   assert(session.q.updates==updates and session.discarded>=1 and session.model.actionSetVersion==2)
   local source=D.json.decode(D.json.encode({schemaVersion=2,kind='yingzhao-q-candidate',episode=session.combat.episode,model=session.model,transitions=session.transitions,combat=session.combat},false,true),32)
   r.latestSource=source;local rebuilt=Q.new(actor,source.model.featureSchemaVersion,source.model.actionSetVersion);for _,transition in ipairs(source.transitions)do assert(rebuilt:update(transition))end;r.latestRebuild=rebuilt:snapshot();save()
   local valid,why=Store.validate(source);assert(valid,why)
   local accepted,reason,id=Store.saveAsync(source);assert(accepted,reason);assert(I.equal(assert(Store.loadAsync(id)).model,source.model))
   local bad=D.json.decode(D.json.encode(source),32);bad.transitions[1].action=skill..(direction==1 and'@left'or'@right');local valid,why=Store.validate(bad);assert(not valid and why=='Q_SKILL_DIRECTION_MISMATCH')
   bad=D.json.decode(D.json.encode(source),32);bad.transitions[1].reward=bad.transitions[1].reward+1;assert(not Store.validate(bad))
   bad=D.json.decode(D.json.encode(source),32);bad.transitions[1].nextActions[#bad.transitions[1].nextActions+1]=label;valid,why=Store.validate(bad);assert(not valid and why=='Q_SKILL_AVAILABILITY_MISMATCH')
   bad=D.json.decode(D.json.encode(source),32);bad.model.actionSetVersion=1;assert(not Q.validate(bad.model))
   local row={actor=actor,direction=direction,id=id,source=source,damage=damage,reward=t.reward};r.cases[#r.cases+1]=row;save()
   local trial,learner=create(actor,direction);require('Training.YingzhaoTrial').attach(trial,source.model);assert(trial:start())
   wait(function()return #trial.magic.logs>0 end);local log=trial.magic.logs[1]
   assert(log.source=='candidate'and log.direction==direction and log.skill==skill)
   wait(function()return log.endedAt and not trial.magic:busy(skill)and not trial.bossCombat:pendingActor(actor)end)
   assert(log.status=='completed'and(log.hits or 0)>0 and not trial.yingzhaoQTraining and #learner.recorder.samples==0)
   assert(I.equal(trial.yingzhaoCandidate,source.model));assert(trial:finish('aborted','Frozen Q skill fixture'));wait(function()return trial.phase=='aborted'end)
   row.frozenCast=log;save()
  end end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
