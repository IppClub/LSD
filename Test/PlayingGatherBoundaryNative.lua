-- Controlled live combat boundary regression, not natural victory or training.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/playing-gather-boundary-result.json'
local fixed=os.getenv('LSD_QA_EXPECT_PLAYING_BOUNDARY')=='1'
local r={status='RUNNING',expectBounded=fixed,scope='controlled-playing-recovery-gather-hit-fall-standup-left-right',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function wait(fn,t)local stop=D.App.runningTime+(t or 15);while not fn()do assert(D.App.runningTime<stop,'Live gather boundary fixture stalled');D.sleep(.01)end end
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  for _,side in ipairs({-1,1})do
   local models={ninilite=model('ninilite'),wuyun=model('wuyun')};local original=D.json.encode(models,false,true)
   local supplies=assert(require('Economy.CombatSession').virtual('playing-gather-boundary',{{actor='ninilite',item='emp',quantity=1},{actor='wuyun',item='blade',quantity=1}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true})
   require('Ground.BattleSupport').attach(b,require('Ground.LifeSupport').new(90,'defence'))
   wait(function()return b.arena.student.onSurface and b.wuyun.student.onSurface and b.mentor.onSurface end)
   -- Fixture positions and injury create a real arrived recovery order.
   local edge=side<0 and b.minX or b.maxX
   b.arena.student.x=edge-side*20;b.wuyun.student.x=edge-side*120;b.mentor.x=edge-side*220
   b.arena.studentHP=50
   assert(b:start());b.enemies[1].guard.nextAttack=math.huge
   assert(b:command('recover-gather'))
   wait(function()return b.arena.regroupComplete and b.wuyun.regroupComplete and b:gatherActive()end)
   local K=require('Combat.Displacement');local strike={source='controlled-playing-edge',kind='massive'}
   assert(K.apply({unit=b.arena.student,alive=function()return b.arena.studentHP>0 end},side*1000,650,strike))
   local case={side=side,minX=b.minX,maxX=b.maxX,initialX=b.arena.student.x,initialVelocityX=b.arena.student.velocityX,samples={},outsideFrames=0}
   r.cases[#r.cases+1]=case;save()
   while K.blocked(b.arena.student)do
    local u=b.arena.student;local outside=u.x<b.minX-.01 or u.x>b.maxX+.01
    if outside then case.outsideFrames=case.outsideFrames+1 end
    case.samples[#case.samples+1]={at=D.App.runningTime,x=u.x,velocityX=u.velocityX,clip=u.playable.current,regroupComplete=b.arena.regroupComplete,gatherMode=b.gatherMode,gatherActive=b:gatherActive()}
    D.sleep(.02)
   end
   case.phases=strike.displacements[1].reactions
   assert(math.abs(case.initialVelocityX)>900,'Boundary fix erased the launch before movement')
   assert(#case.phases==3 and case.phases[1].name=='hit'and case.phases[2].name=='fall'and case.phases[3].name=='standUp')
   for _,phase in ipairs(case.phases)do assert(phase.completed and phase.completed>=phase.started+phase.duration-.1,'Boundary cut authored '..phase.name)end
   assert((case.outsideFrames==0)==fixed,'Live recovery boundary expectation mismatch')
   assert(b.phase=='playing'and b:gatherActive(),'Fixture did not remain in live recovery')
   assert(original==D.json.encode(models,false,true));case.modelsUnchanged=true;save()
   b:finish('aborted','Controlled live boundary complete');wait(function()return b.settled end)
   D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();D.sleep(.1)
  end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
