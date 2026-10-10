local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-natural-result.json';local r={status='RUNNING',training={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-q-natural-'..os.time()..'.db';r.database=db
  assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local models=assert(require('Training.FlowerPractice').models())
  local _,loadout=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true});assert(loadout)
  local Store=require('Training.YingzhaoQStore');local Mentor=require('Training.YingzhaoMentor');local parent
  for i=1,8 do
   local budget=assert(require('Economy.CombatSession').virtual('q-natural-'..i..':'..tostring(D.App.runningTime),loadout))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,budget,{virtual=true})
   local epsilon=math.max(.2,.8-(i-1)*.1)
   local s=require('Training.YingzhaoQ').attach(b,'ninilite',{model=parent and parent.model,epsilon=epsilon})
   assert(b:start());local started=D.App.runningTime;local assistance=Mentor.new()
   while not s.closed do assert(D.App.runningTime-started<200);Mentor.step(b,assistance);D.sleep(.1)end
   assert(#s.transitions>0,'No natural learning transitions')
   local source={trainingProtocol={controller=Mentor.version,epsilon=epsilon,round=i},schemaVersion=2,kind='yingzhao-q-candidate',episode=s.combat.episode,model=s.model,base=s.base,parentId=parent and parent.id,transitions=s.transitions,combat=s.combat}
   local accepted,why,id=Store.saveAsync(source);if not accepted then r.rejectedSource=source end;assert(accepted,why);parent=assert(Store.loadAsync(id))
   r.training[#r.training+1]={epsilon=epsilon,states=s.q.states,id=id,status=b.phase,seconds=D.App.runningTime-started,updates=#s.transitions,totalUpdates=s.model.updates,discarded=s.discarded,bossHP=b.enemies[1].enemyHP,cost=budget.ledger.spent,hp=s.combat.boss.vitals.final};save()
  end
  local report=require('Training.YingzhaoComparison').runAsync(models,parent.model,loadout,function(round)
   r.lastCompleted=round.mode;save()
  end)
  local id,why=require('Training.YingzhaoComparisonStore').saveAsync(report);assert(id,why)
  assert(require('Training.FlowerIdentity').equal(assert(Store.loadAsync(parent.id)).model,parent.model))
  r.report=report;r.saved=id;r.frozen=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
