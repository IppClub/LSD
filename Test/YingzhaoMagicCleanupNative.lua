-- Controlled native lifetime fixture; no formal victory or training adoption.
local entry,qaResultName=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(entry))
local out=root..'/Test/'..(qaResultName or 'yingzhao-magic-cleanup-result.json')
local r={status='RUNNING',cases={},controlledFixture=true,naturalVictory=false,osInput=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32)
  assert(prior.status=='PASS'and prior.warningChecks and prior.episodeSaved and prior.database)
  local db=D.Path(D.Content.writablePath,'magic-cleanup-'..os.time()..'.db');r.database=db;r.parentEvidence=parent
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn,t)local endAt=D.App.runningTime+(t or 8);while not fn()do assert(D.App.runningTime<endAt,'Cleanup fixture timeout');D.sleep(.01)end end
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local shutdownSkill=os.getenv('LSD_QA_MAGIC_SHUTDOWN_SKILL')
  assert(not shutdownSkill or shutdownSkill=='fire'or shutdownSkill=='wind')
  for _,skill in ipairs(shutdownSkill and {shutdownSkill}or {'fire','wind'})do
   for _,mode in ipairs(shutdownSkill and {'process-shutdown'}or {'before-release','after-release','caster-removed-first'})do
    local supplies=assert(require('Economy.CombatSession').virtual('magic-cleanup:'..D.App.runningTime,{{actor='ninilite',item='emp',quantity=4},{actor='wuyun',item='emp',quantity=4}}))
    local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},supplies,{virtual=true})
    -- Isolate native skill lifetime from combat difficulty.
    local guard=b.enemies[1].guard;local update=guard.update
    guard.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
    assert(b:start());b.arena.mode='review';b.wuyun.mode='review'
    local a=b.magic.roles[skill];wait(function()return a.student.onSurface and not a:isAttacking()end)
    local row={skill=skill,mode=mode,stopped=0};r.cases[#r.cases+1]=row
    local stopped=b.magic.onStopped
    b.magic.onStopped=function(name,log)if stopped then stopped(name,log)end;assert(name==skill);row.stopped=row.stopped+1 end
    assert(b.magic:request(skill,{faceRight=true,source='qa-cleanup',noQueue=true}))
    local log=assert(b.magic.activeLogs[skill]);assert(log.status=='casting'and not log.endedAt)
    if mode=='process-shutdown'then
     r.shutdownRequestedDuringCast=true
     b.world:slot('Cleanup',function()
      local good,why=xpcall(function()
       assert(b.magic.closed and row.stopped==1 and log.status=='cancelled'and log.reason=='CLEANUP')
       assert(not log.completedAt and not log.releaseAt)
       local step=b.bossTrace.steps[log.step];assert(step.afterUnavailable=='WORLD_CLEANUP'and not step.after)
       row.cleanupClosed=true;row.cancelledAt=log.cancelledAt;r.nativeShutdownCleanupObserved=true
      end,debug.traceback)
      r.status=good and'PASS'or'FAIL';r.error=not good and why or nil;save()
     end)
     r.status='RUNNING';save();D.App:shutdown();return
    end
    if mode=='after-release'then wait(function()return log.releaseAt end);assert(not log.endedAt)
    else D.sleep(.01);assert(not log.releaseAt,'Cleanup fixture missed windup')end
    row.startedAt=log.startedAt;row.releaseAt=log.releaseAt;row.step=log.step
    if mode=='caster-removed-first'then a.student:removeFromParent();assert(not a.student.playable)end
    b.world:removeFromParent();D.sleep(.15)
    assert(b.magic.closed and not next(b.magic.activeLogs),'Magic retained active logs after world cleanup')
    assert(log.status=='cancelled'and log.reason=='CLEANUP'and log.cancelledAt and not log.completedAt,'Cleanup cast was treated as completion')
    assert(row.stopped==1,'Cleanup did not close observer exactly once')
    local step=assert(b.bossTrace.steps[log.step])
    assert(step.ended==log.endedAt and not step.after and step.afterUnavailable=='WORLD_CLEANUP','Cleanup fabricated a post-destruction observation')
    assert(not next(b.magic.arrows)and not next(b.magic.pending)and not next(b.magic.pendingContext)and not b.magic.gust)
    local accepted,why=b.magic:request(skill,{source='qa-late-cleanup',noQueue=true});assert(not accepted and why=='CLOSED')
    assert(not b.magic:busy(skill));b.magic:update();b.magic:finish(skill,log,'completed')
    assert(row.stopped==1 and log.status=='cancelled'and not log.completedAt,'Late completion reopened cancelled cast')
    row.cancelledAt=log.cancelledAt;row.cleanupClosed=true;row.afterUnavailable=step.afterUnavailable;save()
   end
  end
 end,debug.traceback)
 if ok and r.shutdownRequestedDuringCast then return end
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
