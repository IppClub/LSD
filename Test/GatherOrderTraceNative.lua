-- Actual native gathering; controlled placement/injury, no formal save or victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/gather-order-trace-result.json'
local r={status='RUNNING',osInput=false,controlledFixture=true,formalMission=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local function wait(f,t)local endAt=D.App.runningTime+t;while not f()do assert(D.App.runningTime<endAt,'Gather trace stalled');D.sleep(.01)end end
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=model('ninilite'),wuyun=model('wuyun')};local original=D.json.encode(models)
  local supply=assert(require('Economy.CombatSession').virtual('gather-order-trace',{{actor='ninilite',item='emp',quantity=1},{actor='wuyun',item='blade',quantity=1}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supply,{virtual=true})
  require('Ground.BattleSupport').attach(b,require('Ground.LifeSupport').new(90,'defence'))
  wait(function()return b.mentor.onSurface and b.arena.student.onSurface and b.wuyun.student.onSurface end,8)
  b.mentor.x=1320;b.arena.student.x=1000;b.wuyun.student.x=1100
  assert(b:start());b.enemies[1].guard.nextAttack=math.huge
  assert(b:command('gather'));local first=b.bossTrace.gathers[1]
  assert(first.mode=='normal'and first.initialPlan.anchor==1320)
  wait(function()return first.ended end,8)
  assert(first.reason=='ARRIVED'and first.arrivals.ninilite and first.arrivals.wuyun)
  for _,v in pairs(first.arrivals)do assert(v.at<first.deadline and math.abs(v.x-v.target)<=18)end
  b.arena.studentHP=50;assert(b:command('recover-gather'));local recovery=b.bossTrace.gathers[2]
  local anchor=recovery.initialPlan.anchor;local deadline=recovery.deadline
  assert(b:command('right'));D.sleep(.4);assert(b:command('stop'))
  wait(function()return recovery.replans>0 end,2)
  assert(recovery.initialPlan.anchor==anchor and recovery.latestPlan.anchor~=anchor and recovery.deadline==deadline,'Mutable snapshot or extended deadline')
  assert(b:command('gather'));assert(recovery.reason=='PLAYER_CANCELLED'and recovery.ended and not b:gatherActive())
  assert(b:command('recover-gather'));local expired=b.bossTrace.gathers[3]
  -- Leave the actual deadline untouched; damage exceeds healing within it.
  b.arena.studentHP=20
  wait(function()return expired.ended end,15);assert(expired.reason=='DEADLINE'and expired.ended>=expired.deadline)
  assert(b:command('recover-gather'));local finished=b.bossTrace.gathers[4]
  assert(b:finish('aborted','Controlled gather trace complete'));assert(finished.reason=='BATTLE_ENDED')
  assert(original==D.json.encode(models));r.modelsUnchanged=true
  r.gathers=b.bossTrace.gathers;r.scope='Native movement/arrival, immutable plan snapshots, player cancellation and battle finish; natural deadline expiration; controlled placement/injury, not formal Boss or training acceptance'
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
