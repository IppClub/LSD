-- Controlled real native launch during settlement, not a formal win.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/settlement-displacement-result.json'
local fixed=os.getenv('LSD_QA_EXPECT_SETTLED_RECOVERY')=='1'
local r={status='RUNNING',scope='controlled-native-settlement-hit-fall-standup',expectRecovery=fixed}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=model('ninilite'),wuyun=model('wuyun')};local before=D.json.encode(models,false,true)
  local supplies=assert(require('Economy.CombatSession').virtual('settlement-displacement',{{actor='wuyun',item='blade',quantity=1}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true});local a=b.arena
  local function wait(fn)local stop=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<stop,'Settlement displacement stalled');D.sleep(.01)end end
  wait(function()return a.student.onSurface end);assert(b:start());b.enemies[1].guard.nextAttack=math.huge
  local K=require('Combat.Displacement');local strike={source='controlled-fixture',kind='massive'}
  assert(a.student.data.combatHasFall and a.student.data.combatHasStandUp)
  assert(K.apply({unit=a.student,alive=function()return a.studentHP>0 end},1000,650,strike));assert(K.blocked(a.student))
  local edge
  if fixed then
   local other=b.wuyun;other.student.x=b.maxX-20
   edge={source='controlled-edge-fixture',kind='massive'}
   assert(K.apply({unit=other.student,alive=function()return other.studentHP>0 end},1000,650,edge))
  end
  local start=D.App.runningTime;assert(b:finish('aborted','Controlled in-flight settlement'))
  r.velocityAfterFinish=a.student.velocityX
  wait(function()return b.settled end)
  r.settleSeconds=D.App.runningTime-start;r.blockedAtSettled=K.blocked(a.student);r.phases=strike.displacements[1].reactions
  assert(r.blockedAtSettled~=fixed,'Result page recovery ownership mismatch')
  if fixed then
   assert(r.velocityAfterFinish>900,'Settlement erased actual launch velocity')
   assert(#r.phases==3 and r.phases[1].name=='hit'and r.phases[2].name=='fall'and r.phases[3].name=='standUp')
   for _,p in ipairs(r.phases)do assert(p.completed and p.completed>=p.started+p.duration-.1,'Settlement interrupted '..p.name)end
  else assert(r.velocityAfterFinish==0)end
  if edge then
   assert(not K.blocked(b.wuyun.student)and b.wuyun.student.x<=b.maxX+.01)
   r.edgeX=b.wuyun.student.x;r.maxX=b.maxX;r.edgePhases=edge.displacements[1].reactions
   assert(#r.edgePhases==3);for _,p in ipairs(r.edgePhases)do assert(p.completed and p.completed>=p.started+p.duration-.1)end
  end
  assert(before==D.json.encode(models,false,true));r.modelsUnchanged=true;r.phase=b.phase
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
