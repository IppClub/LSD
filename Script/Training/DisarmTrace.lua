-- Versioned observation trace only. Collection never trains/adopts a model or
-- treats repeated input polling, a queued cast, or a rejected shot as a demo.
local D=require('Dora')
local T={}
function T.attach(b,formal)
 local trace={schemaVersion=2,kind=formal and 'disarm-mission'or'disarm-practice',clock='runningTime',trainable=false,
  demonstrator=b.demonstrator and b.demonstrator.character.id or nil,trainingBlock='DEMONSTRATION_PROVENANCE_AND_REWARD_REVIEW_REQUIRED',actions={},weaponEvents={},rejected={},consumption={},limit=2000,truncated=false}
 local function append(list,item)
  if #list>=trace.limit then trace.truncated=true;return end
  list[#list+1]=item
 end
 local function actor(unit)
  if unit==b.mentor then return 'mentor' end
  for _,a in ipairs(b.learners)do if a.student==unit then return a.character.id end end
  return 'unknown'
 end
 local function snapshot(u)
  local target=b:target(u);local guard=target and target.guard
  return {at=D.App.runningTime,actor=actor(u),x=u.x,y=u.y,lane=u.order,
   weapon=u.data.weaponDisarmed and 'disarmed' or 'equipped',
   enemyDistance=target and math.abs(target.enemy.x-u.x) or nil,
   enemySkill=guard and guard.busy and guard.strike.skill or 'idle',
   enemyArmed=guard and guard.lease and guard.lease.active or false,
   enemyCanFire=guard and require('Enemy.StolenFirearm').canFire(guard) or false,
   resources=b.supplies and b.supplies:observation(actor(u)) or nil,
   displaced=require('Combat.Displacement').blocked(u),phase=b.phase}
 end
 b.disarmSnapshot=snapshot
 local vitals=require('Training.DisarmVitals').attach(b,trace)
 local execution=require('Training.DisarmExecution').attach(b,trace,snapshot)
 local closed=false
 if b.supplies then
  local emit=b.supplies.emit
  b.supplies.emit=function(session,owner,item,count,performer,step)
   local before=session:observation(owner)
   local ok,id=emit(session,owner,item,count,performer,step)
   if ok and not closed then append(trace.consumption,{event=id,at=D.App.runningTime,owner=owner,item=item,count=count,performer=performer,step=step,before=before,after=session:observation(owner)})end
   return ok,id
  end
 end
 for _,u in ipairs({b.mentor,b.arena.student,b.wuyun.student})do
  u:slot('Combat.WeaponState',function(event)
   if closed then return end
   local item={actor=actor(u),at=event.at,state=event.state,weapon=event.weapon,reason=event.reason,started=event.started,expires=event.expires}
   append(trace.weaponEvents,item)
  end)
 end
 local function record(u,action,source,before,ok,why,continued)
  if closed or before.phase~='playing' then return end
  if continued then return end
  local item={actor=actor(u),action=action,source=source,before=before,after=snapshot(u),accepted=ok==true,reason=why}
  if ok and why~='QUEUED_AFTER_ATTACK' then append(trace.actions,item)
  elseif not ok then
   item.reason=before.weapon=='disarmed' and (action=='shoot' or action=='laser') and 'WEAPON_DISARMED' or why or 'ACTION_UNAVAILABLE'
   local last=trace.rejected[#trace.rejected]
   if last and last.actor==item.actor and last.action==action and last.reason==item.reason and item.after.at-last.after.at<.25 then return end
   append(trace.rejected,item)
  end
 end
 for _,a in ipairs(b.learners)do
  local request=a.request
  a.request=function(self,action,source,...)
   local before=snapshot(self.student);local ok,why=request(self,action,source,...)
   record(self.student,action,source or 'unknown',before,ok,why);return ok,why
  end
 end
 local command=b.command
 b.command=function(self,name,...)
  if self.demonstrator and ({left=true,right=true,stop=true,shoot=true,melee=true})[name]then return command(self,name,...)end
  local u=self.mentor
  if name=='fire' then u=self.arena.student elseif name=='wind' then u=self.wuyun.student end
  local physical=name=='shoot' and 'groundMentorShot' or (name=='left' or name=='right') and 'groundMentorMove'
  local continued=(physical and u:isDoing(physical)) or (name=='stop' and not u:isDoing('groundMentorMove'))
  if continued and not (name=='shoot' and u.data.weaponDisarmed) then return command(self,name,...)end
  if name=='shoot' and u.data.weaponDisarmed then continued=false end
  local before=snapshot(u);local ok,why=command(self,name,...)
  record(u,name,self.commandOrigin or 'command',before,ok,why,continued);return ok,why
 end
 local start=b.start
 b.start=function(self,...)local ok=start(self,...);if ok then trace.startedAt=self.started end;return ok end
 local finish=b.finish
 b.finish=function(self,status,reason,...)
  local ok=finish(self,status,reason,...)
  if ok and self.report then
   -- Weapon-return events can arrive while the encounter settles. The report
   -- owns only scalar trace data, never actors or native nodes.
   trace.status=status;trace.finishedAt=D.App.runningTime;self.report.disarmTrace=trace
   if self.supplies then D.thread(function()
    while not self.settled and not closed do D.sleep(.02)end
    if closed then return end
    execution.finish();vitals.finish()
    trace.resources=self.supplies:evidence()
    if self.supplies.isVirtual then trace.virtualResult=assert(self.supplies:closeVirtual(status))end
    trace.resourcesFinalizedAt=D.App.runningTime
    trace.resourceReview,trace.resourceReviewError=require('Training.DisarmResourceReview').rebuild(trace)
    trace.executionReview,trace.executionReviewError=require('Training.DisarmCredit').rebuild(trace)
    if formal then trace.encounter={enemyHP=self.enemies[1].enemyHP,defeated=self.enemies[1].guard.dead==true,asset='zhongyingzhao',rules=require('Training.DisarmRules').version};trace.sourceSaveState=trace.resourceReview and trace.executionReview and 'mission-ready'or'rejected';return end
    if trace.resourceReview then
     trace.sourceSaveState='saving'
     local saved,why,id=require('Training.DisarmStore').saveAsync(trace)
     trace.sourceSaveState=saved and 'saved' or 'failed';trace.sourceId=id;trace.sourceSaveError=why
    else trace.sourceSaveState='rejected' end
   end)end
  end
  return ok
 end
 b.world:slot('Cleanup',function()closed=true;trace.closedAt=D.App.runningTime end)
 b.disarmTrace=trace
 return trace
end
return T
