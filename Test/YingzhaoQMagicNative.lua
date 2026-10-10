local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-magic-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local budget=assert(require('Economy.CombatSession').virtual('q-magic',{{actor='wuyun',item='blade',quantity=1}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},budget,{virtual=true})
  local s=require('Training.YingzhaoQ').attach(b,'ninilite',{epsilon=1,random=function()return .999 end})
  assert(b:start());b.wuyun.mode='review';local boss=b.enemies[1];boss.guard.nextAttack=math.huge;boss.guard.nextReaction=math.huge
  b.mentor.x=2250;b.mentor.faceRight=true;b.arena.student.x=1800;b.wuyun.student.x=2100;D.sleep(.5)
  assert(b:command('fire'));local deadline=D.App.runningTime+12
  while b.magic:busy('fire')or next(b.bossCombat.shots)~=nil do assert(D.App.runningTime<deadline);D.sleep(.02)end
  local damage=0;for _,hit in ipairs(b.bossTrace.hits)do assert(hit.source=='ninilite'and hit.weapon=='fire'and not hit.step);damage=damage+hit.healthDamage end
  assert(damage>0,'Real fire did not hit')
  D.sleep(.5);assert(b:finish('aborted','Q magic source fixture'))
  while not s.closed do assert(D.App.runningTime<deadline);D.sleep(.02)end
  local record={schemaVersion=2,kind='yingzhao-q-candidate',episode='q-magic',model=s.model,transitions=s.transitions,combat=s.combat}
  r.source=record;r.damage=damage
  local total=0;for _,t in ipairs(s.transitions)do total=total+t.reward end;r.reward=total
  local valid,why=require('Training.YingzhaoQStore').validate(record);assert(valid,why)
  assert(math.abs(total-damage)<1e-6,'Magic credit omitted or repeated')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
