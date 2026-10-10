-- Explicit opt-in to the experimental controller, in an isolated QA process.
package.loaded['Training.YingzhaoMentor']=require('Test.YingzhaoMentorClearanceV14')
-- Compare frozen old/new Wu policies with identical frozen Ni, mentor and loadout.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-mentor-clearance-trace-result.json';local r={status='RUNNING',rounds={},mentorTrace={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local origin='/private/tmp/lsd-combat-qa-3fx1bo45/save/yingzhao-mixed-natural-1791274631.db'
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-mentor-trace-'..os.time()..'.db';assert(D.Content:copyAsync(origin,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  require('Data.Config'):loadAsync();local models=assert(require('Training.FlowerPractice').models())
  local I=require('Training.FlowerIdentity');local policyStore=require('Training.YingzhaoPolicyStore');local sources=require('Training.YingzhaoStore')
  local old=assert(policyStore.loadLatestAsync('wuyun'));local companion=assert(policyStore.loadLatestAsync('ninilite'))
  assert(old.model.sampleCount==145 and old.model.actionSetVersion==1 and #old.model.sourceEpisodes==14 and companion.model.sampleCount==127)
  local function adopted()return D.json.decode(D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')}),32)end
  local previousPair=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-return-natural-20261006/result.json'),32);assert(previousPair.status=='PASS'and previousPair.candidate.sampleCount==193);old.model=previousPair.candidate
  local before=adopted();local economy=require('Economy.Store');assert(economy.open());local balance=economy.wallet().available
  local corpus=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-fresh-corpus-20261006/result.json'),32);assert(corpus.status=='PASS' and corpus.samples==177 and #corpus.records==18)
  local extra=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-range-lesson-20261006/result.json'),32);assert(extra.status=='PASS'and #extra.cases==2)
  for _,case in ipairs(extra.cases)do assert(case.samples>=8);corpus.records[#corpus.records+1]=case.source end
  local P=require('Training.YingzhaoPolicy')
  local frozen=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-range-natural-20261006/result.json'),32);assert(frozen.status=='PASS');local fresh={model=frozen.candidate}
  assert(fresh.model.sampleCount==197 and #fresh.model.sourceEpisodes==20)
  r.predictionAudit={}
  local previous=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-wind-natural-20261006/result.json'),32);assert(previous.status=='PASS')
  for _,cast in ipairs(previous.rounds[2].wind)do if cast.source=='candidate'then
   local action,why=P.predict(fresh.model,cast.before)
   r.predictionAudit[#r.predictionAudit+1]={before=cast.before,previous=cast.skill.direction,predicted=action,reason=why}
  end end
  assert(#r.predictionAudit==2)
  local unknown=0;for _,rule in ipairs(fresh.model.rules)do for _,condition in ipairs(rule.conditions)do if condition.name=='skillState'and condition.value=='unknown'then unknown=unknown+1 end end end
  r.rangeAudit={}
  for _,cast in ipairs(previousPair.rounds[2].wind)do if cast.source=='candidate'and not cast.skill.hits then local action,why=P.predict(fresh.model,cast.before);r.rangeAudit[#r.rangeAudit+1]={before=cast.before,predicted=action,reason=why}end end
  r.unknownSkillRules=unknown
  r.old=old.model;r.candidate=fresh.model;r.companion=companion.model;r.sources=20;r.samples=197;r.explicitCorpus=true;save()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-companion-readback-20261006/result.json'),32);assert(prior.status=='PASS')
  local battle
  local report=require('Training.YingzhaoComparison').runAsync(models,fresh.model,prior.report.loadout,function(round)
   local actions,failures,casts={},{},{}
   for _,d in ipairs(round.decisions)do local list=d.accepted and actions or failures;local key=d.accepted and d.action or d.reason or'unknown';list[key]=(list[key]or 0)+1 end
   for _,step in ipairs(round.trace.steps)do if step.action=='wind'then casts[#casts+1]={source=step.origin,skill=step.skill,before=step.before}end end
   r.rounds[#r.rounds+1]={mode=round.mode,status=round.status,seconds=round.seconds,hp=round.hp,cost=round.cost,armor=round.armorDamage,damage=round.healthDamage,actions=actions,failures=failures,wind=casts,strikes=battle.enemies[1].guard.strikes};save()
  end,{baseline=old.model,companion=companion.model,onBattle=function(b,mode)
   battle=b;local command=b.command;local nextAt=0
   b.command=function(self,name,...)
    local ok,why=command(self,name,...)
    if D.App.runningTime>=nextAt then
     nextAt=D.App.runningTime+.25;local boss=self.enemies[1];local nearby={}
     for _,e in ipairs(self.enemies)do if e~=boss and e.enemyHP>0 then nearby[#nearby+1]={x=e.enemy.x,hp=e.enemyHP,action=e.enemy.playable.current}end end
     r.mentorTrace[#r.mentorTrace+1]={mode=mode,at=D.App.runningTime,command=name,accepted=ok,reason=why,x=self.mentor.x,y=self.mentor.y,hp=self.mentorHP,bossX=boss.enemy.x,bossAction=boss.enemy.playable.current,escape=require('Enemy.GroundWave').escapeDirection(boss.guard,self.mentor,self.bossCombat.armor:available()),displaced=require('Combat.Displacement').blocked(self.mentor),nearby=nearby}
    end
    return ok,why
   end
  end})
  r.report=report;r.text=require('Training.YingzhaoComparison').text(report);save()
  local store=require('Training.YingzhaoComparisonStore');local valid,why=store.validate(report);assert(valid,why)
  assert(report.skillControl.independentActor=='wuyun')
  for _,round in ipairs(report.rounds)do for _,step in ipairs(round.trace.steps)do assert(not(step.actor=='wuyun'and step.action=='wind'and step.origin=='mentor-command'),'Mentor stole tested skill')end end
  r.saved=assert(store.saveAsync(report));assert(I.equal(assert(store.load(r.saved)),D.json.decode(D.json.encode(report,false,true),32)))
  local bad=D.json.decode(D.json.encode(report),32);bad.rounds[1].primaryModel=bad.candidate;assert(not store.validate(bad),'Replaced baseline accepted')
  bad=D.json.decode(D.json.encode(report),32);bad.rounds[1].decisions[1].action='fire@right';assert(not store.validate(bad),'Wu baseline accepted fire label')
  assert(store.validate(prior.report),'Legacy report rejected')
  local forged=D.json.decode(D.json.encode(report),32);forged.skillControl.independentActor='ninilite';assert(not store.validate(forged),'Wrong independent actor accepted')
  local checked=false;for _,round in ipairs(report.rounds)do for i,step in ipairs(round.trace.steps)do if step.actor=='wuyun'and step.action=='wind'then local fake=D.json.decode(D.json.encode(report),32);local index=round.mode=='baseline'and 1 or 2;fake.rounds[index].trace.steps[i].origin='mentor-command';assert(not store.validate(fake),'Mentor interference accepted');checked=true;break end end end;r.interferenceMutationChecked=checked
  assert(I.equal(before,adopted())and economy.wallet().available==balance);r.adoptionUnchanged=true;r.walletUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
