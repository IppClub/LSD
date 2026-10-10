-- Controlled zero-energy start; actual environmental HP loss, not injected damage.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-hazard-boundaries-result.json'
local r={status='RUNNING',controlledFixture=true,osInput=false,naturalVictory=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local Store=require('Training.YingzhaoQStore');local I=require('Training.FlowerIdentity')
  local cold=os.getenv('LSD_QA_PARENT_Q')
  if cold then
   local prior=D.json.decode(D.Content:load(cold),64)
   assert(prior.status=='PASS'and prior.record.model.featureSchemaVersion>=11 and require('Training.YingzhaoQ').validate(prior.record.model))
   assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/q%-hazard%-boundaries%-%d+%.db$'))
   local db=D.Content.writablePath..'/q-hazard-boundaries-cold-'..os.time()..'.db';r.database=db
   assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db))
   assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
   local loaded,why=Store.loadAsync(prior.candidateId);assert(loaded,why)
   assert(I.equal(loaded.source,prior.record))
   assert(I.equal(assert(require('Training.YingzhaoQ').restore(loaded.model)):snapshot(),loaded.model))
   local forged=D.json.decode(D.json.encode(loaded.source),64)
   forged.transitions[1].reward=forged.transitions[1].reward+.5
   local valid,reason=Store.validate(forged);assert(not valid and reason=='Q_REWARD_SOURCE_MISMATCH')
   r.actualColdRead=true;r.rewardTamperingRejected=true;r.candidateId=loaded.id;r.record=loaded.source
   return
  end
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local supplies=assert(require('Economy.CombatSession').virtual('q-hazard-boundaries',{{actor='ninilite',item='emp',quantity=8}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},supplies,{virtual=true})
  require('Ground.BattleSupport').attach(b,require('Ground.LifeSupport').new(0,'defence'))
  b.enemies[1].guard.update=function()end
  local session=require('Training.YingzhaoQ').attach(b,'ninilite',{epsilon=1,random=function()return 0 end})
  assert(b:start());b.wuyun.mode='review';D.sleep(8)
  assert(b.phase=='playing'and b.arena.studentHP<100 and b.arena.studentHP>0)
  b:finish('aborted','Actual hazard reward boundary fixture')
  local stop=D.App.runningTime+10;while not session.closed do assert(D.App.runningTime<stop);D.sleep(.02)end
  local record={schemaVersion=2,kind='yingzhao-q-candidate',episode=session.combat.episode,model=session.model,base=session.base,transitions=session.transitions,combat=session.combat}
  r.record=record;r.ownHP=b.arena.studentHP;r.transitionCount=#record.transitions;save()
  assert(#record.transitions>=3)
  local damage=0;for _,event in ipairs(record.combat.boss.vitals.events)do if event.actor=='ninilite'then assert(event.kind=='support-hazard');damage=damage+event.damage end end
  assert(damage>0);r.actualHazardDamage=damage
  local valid,why=require('Training.YingzhaoQStore').validate(record);r.replayValid=valid;r.replayReason=why;save();assert(valid,why)
  r.rebuilt=assert(require('Training.YingzhaoRewards').rebuild(record.combat,'ninilite'))
  r.noInjectedHP=true
  local db=D.Content.writablePath..'/q-hazard-boundaries-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local accepted,why,id=Store.saveAsync(record);assert(accepted,why)
  r.candidateId=id;assert(I.equal(assert(Store.loadAsync(id)).source,record));r.actualArchiveSaved=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
