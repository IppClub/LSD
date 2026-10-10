-- Controlled actual native actions: queue precedence, not learning or victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/gather-pending-skills-result.json'
local fixed=os.getenv('LSD_QA_EXPECT_GATHER_QUEUE_CLEAR')=='1'
local r={status='RUNNING',scope='controlled-queue-precedence-and-animation',expectCleared=fixed}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=model('ninilite'),wuyun=model('wuyun')};local before=D.json.encode(models,false,true)
  local supplies=assert(require('Economy.CombatSession').virtual('gather-skill-queue',{{actor='ninilite',item='emp',quantity=6},{actor='wuyun',item='emp',quantity=6},{actor='wuyun',item='blade',quantity=6}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true})
  require('Ground.BattleSupport').attach(b,require('Ground.LifeSupport').new(90,'defence'))
  local function wait(fn,t)local stop=D.App.runningTime+(t or 15);while not fn()do assert(D.App.runningTime<stop,'Queue fixture stalled');D.sleep(.01)end end
  wait(function()return b.arena.student.onSurface and b.wuyun.student.onSurface end)
  assert(b:start());b.enemies[1].guard.nextAttack=math.huge
  local function one(name,a,order)
   wait(function()return b.magic:available(name)and a:available('laser')end)
   assert(a:request('laser','scripted'));local attack=assert(a.student:isDoing(a.physical.laser));local old=#b.magic.logs
   local accepted,why=b.magic:request(name);assert(accepted and why=='QUEUED_AFTER_ATTACK'and b.magic.pending[name])
   assert(b:command(order));assert(a.student:isDoing(a.physical.laser),'Gather interrupted an authored shot')
   assert((b.magic.pending[name]==nil)==fixed,'Gather queue state mismatch')
   wait(function()return not a.student:isDoing(a.physical.laser)end)
   D.sleep(.2)
   if fixed then assert(#b.magic.logs==old,'Old queued skill started after gather')
   else wait(function()return #b.magic.logs>old end);wait(function()return not b.magic:busy(name)end)end
   return {order=order,oldQueuedSkillStarted=#b.magic.logs>old,shotPreserved=attack}
  end
  r.fire=one('fire',b.arena,'gather');r.wind=one('wind',b.wuyun,'recover-gather')
  wait(function()return b.magic:available('fire')end);assert(b.magic:request('fire'),'New explicit skill was blocked by gather')
  local log=b.magic.logs[#b.magic.logs];assert(log.skill=='fire');assert(b:command('recover-gather'))
  assert(b.magic:busy('fire'),'New gather interrupted a running skill')
  wait(function()return log.completedAt end);assert(log.releaseAt and log.completedAt>=log.startedAt+.9)
  r.newExplicitSkillCompleted=true;r.runningSkillPreserved=true;r.clearedPending=b.gatherClearedPending or 0
  if fixed then assert(r.clearedPending==2)end
  assert(before==D.json.encode(models,false,true));r.modelsUnchanged=true
  b:finish('aborted','Controlled queue precedence');wait(function()return b.settled end)
  r.phase=b.phase;r.skillCount=#b.magic.logs
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
