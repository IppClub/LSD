local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-damage-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  for _,victim in ipairs({'ninilite','mentor'})do
   local budget=assert(require('Economy.CombatSession').virtual('q-damage-'..victim,{{actor='wuyun',item='blade',quantity=1}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},budget,{virtual=true})
   local session=require('Training.YingzhaoQ').attach(b,'ninilite',{epsilon=1,random=function()return .999 end})
   assert(b:start());b.wuyun.mode='review';local boss=b.enemies[1];boss.guard.nextAttack=math.huge
   b.mentor.x=victim=='mentor'and 2250 or 1400;b.arena.student.x=victim=='ninilite'and 2250 or 1400;b.wuyun.student.x=1550
   D.sleep(.5)
   assert(boss.guard:attack('punch',victim=='mentor'and b.mentor or b.arena.student))
   local deadline=D.App.runningTime+8
   while boss.guard.busy do assert(D.App.runningTime<deadline);D.sleep(.02)end;boss.guard.nextAttack=math.huge
   local expected=victim=='ninilite'and -36 or -9
   local function total()local v=0;for _,t in ipairs(session.transitions)do v=v+t.reward end;return v end
   while math.abs(total()-expected)>1e-6 do if D.App.runningTime>=deadline then r.diagnostic={hp=b.arena.studentHP,mentorHP=b.mentorHP,vitals=b.bossTrace.vitals,transitions=session.transitions,steps=b.bossTrace.steps};error('Damage not assigned to Q transition')end;D.sleep(.02)end
   assert((victim=='mentor'and b.mentorHP or b.arena.studentHP)==82)
   assert(b:finish('aborted','Actual Q damage fixture'))
   while not session.closed do assert(D.App.runningTime<deadline);D.sleep(.02)end
   local record={schemaVersion=2,kind='yingzhao-q-candidate',episode='q-damage-'..victim,model=session.model,transitions=session.transitions,combat=session.combat}
   local valid,why=require('Training.YingzhaoQStore').validate(record);assert(valid,why)
   local events=session.combat.boss.vitals.events;assert(#events==1 and events[1].actor==victim and events[1].damage==18)
   local charged=0;for _,t in ipairs(session.transitions)do if t.reward~=0 then charged=charged+1;assert(t.reward==expected and t.action=='idle')end end
   assert(charged==1 and total()==expected,'Damage repeated or omitted')
   r.cases[#r.cases+1]={victim=victim,damage=18,reward=total(),chargedTransitions=charged,updates=session.q.updates,sourceVerified=true}
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
