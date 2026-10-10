local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/q-session-native-result.json';local r={status='RUNNING',rounds={}}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  for _,character in ipairs({'ninilite','wuyun'})do
   local a=require('Training.Arena').createAsync({characterId=character,enemySpeed=0,enemyMaxHP=1000,roundLimit=12})
   local calls=0;local count=#a.character.actions
   local session,why=a:beginQRound({distance=260,epsilon=1,random=function()
    calls=calls+1;if calls%2==1 then return 0 end
    return ((math.floor(calls/2)-1)%count+.1)/count
   end});assert(session,why)
   assert(not a:request('laser','demo'),'Manual demonstration contaminated exploration')
   local candidate,blockedReason=a:finishDemoAsync();assert(not candidate and blockedReason=='Q_TRAINING_ACTIVE')
   local deadline=D.App.runningTime+16
   while not session.closed and D.App.runningTime<deadline do D.sleep(.05)end
   assert(session.closed,'Training did not terminate')
   assert(session.reason=='TIMEOUT' or session.reason=='DEFEAT',session.reason)
   local actions={};local total=0
   for i,step in ipairs(session.steps)do
    assert(step.sealed and not step.truncated and step.duration>0 and step.rewardPolicy=='unarmored-v1')
    assert(step.components.healthDamage>=0 and step.components.damageTaken>=0)
    assert(not step.done or i==#session.steps)
    if i>1 then assert(math.abs(step.started-session.steps[i-1].finished)<.0001,'Decision gap')end
    actions[step.action]=(actions[step.action]or 0)+1;total=total+step.components.healthDamage
   end
   assert(actions.laser and actions.fmove and actions.bmove and actions.idle,'Missing action coverage')
   if character=='wuyun'then assert(actions.melee,'Missing melee')end
   assert(session.model.updates==#session.steps and #session.steps>=5)
   assert(session.model:snapshot().rewardPolicy=='unarmored-v1' and session.model:snapshot().discountTimeUnit=='seconds')
   assert(math.abs(total-(a.enemyMaxHP-a.enemyHP))<.001,'Damage attribution mismatch')
   assert(#a.recorder.samples==0 and a.candidate==nil and a.adopted==nil,'Training silently became adopted model')
   r.rounds[#r.rounds+1]={character=character,steps=#session.steps,actions=actions,damage=total,updates=session.model.updates,reason=session.reason}
   a:beginDemo(260);a.partObservation=function()return 'tail','intact'end
   local blocked,reason=a:beginQRound({random=function()return .1 end});assert(not blocked and reason=='REWARD_ADAPTER_REQUIRED')
   a.partObservation=nil
   local interrupted=assert(a:beginQRound({epsilon=1,random=function()return .9 end}))
   while not interrupted.pending do D.sleep(.05)end
   local updates=interrupted.model.updates;a:beginDemo(260)
   assert(interrupted.closed and interrupted.reason=='ROUND_RESET' and interrupted.model.updates==updates)
   assert(interrupted.steps[#interrupted.steps].truncated)
   save()
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
