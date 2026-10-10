local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-wuyun-training-result.json';local r={status='RUNNING',training={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/yingzhao-q-natural-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-q%-natural%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-wuyun-training-'..os.time()..'.db';r.database=db
  assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local models=assert(require('Training.FlowerPractice').models())
  local values=require('Economy.Loadout').defaults();values['wuyun:emp']=12;values['wuyun:blade']=6
  local _,loadout=require('Economy.Loadout').quote(values,{mentor=true,learner=true,wuyun=true});assert(loadout)
  local Store=require('Training.YingzhaoQStore');local Mentor=require('Training.YingzhaoMentor');local parent
  local companion=assert(Store.loadLatestAsync('ninilite'))
  for i=1,4 do
   local budget=assert(require('Economy.CombatSession').virtual('q-natural-'..i..':'..tostring(D.App.runningTime),loadout))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,budget,{virtual=true})
   require('Training.YingzhaoTrial').attach(b,companion.model)
   assert(not pcall(function()require('Training.YingzhaoQ').attach(b,'ninilite')end),'Frozen actor admitted training')
   local epsilon=math.max(.2,.8-(i-1)*.1)
   local s=require('Training.YingzhaoQ').attach(b,'wuyun',{model=parent and parent.model,epsilon=epsilon})
   assert(b:start());local started=D.App.runningTime;local assistance=Mentor.new()
   while not s.closed do assert(D.App.runningTime-started<200);Mentor.step(b,assistance);D.sleep(.1)end
   assert(require('Training.FlowerIdentity').equal(b.yingzhaoCandidates.ninilite,companion.model),'Companion mutated')
   assert(#b.arena.recorder.samples==0 and #b.wuyun.recorder.samples==0)
   assert(#s.transitions>0,'No natural learning transitions')
   local source={trainingProtocol={controller=Mentor.version,epsilon=epsilon,round=i,companionId=companion.id,companion=companion.model},schemaVersion=2,kind='yingzhao-q-candidate',episode=s.combat.episode,model=s.model,base=s.base,parentId=parent and parent.id,transitions=s.transitions,combat=s.combat}
   local accepted,why,id=Store.saveAsync(source);if not accepted then r.rejectedSource=source end;assert(accepted,why);parent=assert(Store.loadAsync(id))
   r.training[#r.training+1]={epsilon=epsilon,states=s.q.states,id=id,status=b.phase,seconds=D.App.runningTime-started,updates=#s.transitions,totalUpdates=s.model.updates,discarded=s.discarded,bossHP=b.enemies[1].enemyHP,cost=budget.ledger.spent,hp=s.combat.boss.vitals.final};save()
  end
  local report=require('Training.YingzhaoComparison').runAsync(models,parent.model,loadout,function(round)
   r.lastCompleted=round.mode;save()
  end,{companion=companion.model})
  local id,why=require('Training.YingzhaoComparisonStore').saveAsync(report);assert(id,why)
  assert(require('Training.FlowerIdentity').equal(assert(Store.loadAsync(parent.id)).model,parent.model))
  local fake=D.json.decode(D.json.encode(report),32);fake.rounds[2].companion=nil;assert(not require('Training.YingzhaoComparisonStore').validate(fake))
  assert(require('Training.FlowerIdentity').equal(assert(Store.loadAsync(companion.id)).model,companion.model))
  r.companionId=companion.id;r.report=report;r.saved=id;r.frozen=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
