local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-vitals-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},assert(require('Economy.CombatSession').virtual('vitals-reward',{{actor='wuyun',item='blade',quantity=1}})),{virtual=true});assert(b:start())
  b.arena.mode='review';b.wuyun.mode='review';local boss=b.enemies[1];boss.guard.nextAttack=math.huge
  b.mentor.x=2250;b.arena.student.x=1400;b.wuyun.student.x=1550;D.sleep(.5)
  assert(boss.guard:attack('punch',b.mentor));local stop=D.App.runningTime+6
  while boss.guard.busy do assert(D.App.runningTime<stop);D.sleep(.02)end
  assert(b.mentorHP==82,'Real punch did not hit')
  b:finish('aborted','Vitals fixture');local V=require('Training.YingzhaoVitals');assert(V.validate(b.bossTrace.vitals))
  local v=b.bossTrace.vitals;assert(#v.events==1 and v.events[1].actor=='mentor'and v.events[1].skill=='punch'and v.events[1].damage==18)
  local fake=D.json.decode(D.json.encode(v),32);fake.final.mentor=100;assert(not V.validate(fake));fake=D.json.decode(D.json.encode(v),32);fake.events[2]=fake.events[1];assert(not V.validate(fake))
  local resource=b.supplies:evidence();b.bossTrace.resources=resource
  local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-evaluation',episode=resource.attempt,versions={resources=1,bigYingzhao=1},resources=resource,boss=b.bossTrace}
  local R=require('Training.YingzhaoRewards');local mentor=assert(R.rebuild(e,'mentor'));assert(mentor.ownDamage==18 and mentor.allyDamage==0 and mentor.total==-36 and not mentor.terminal)
  local ni=assert(R.rebuild(e,'ninilite'));assert(ni.ownDamage==0 and ni.allyDamage==18 and ni.total==-9)
  fake=D.json.decode(D.json.encode(e),32);fake.boss.vitals.events[2]=fake.boss.vitals.events[1];assert(not R.rebuild(fake,'mentor'))
  r.rewards={mentor=mentor,ninilite=ni};r.vitals=v;r.realPunch=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
