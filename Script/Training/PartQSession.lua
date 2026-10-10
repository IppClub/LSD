-- Isolated stationary-target training; does not adopt or train the action stage.
local D=require('Dora');local Q=require('Training.PartQ');local F=require('Training.PartFeatures')
local S={}
function S.runAsync(practice,options)
 local o=options or {};local a=practice.arena
 if not practice.managesPartCleanup or a.enemyAsset~='dataotie' or practice.mentorHP~=0 or practice.rescueHP~=0 then return nil,'UNSUPPORTED_PART_SCENARIO'end
 if type(o.random)~='function'then return nil,'EXPLICIT_RNG_REQUIRED'end
 local model,problem
 if o.initialModel then model,problem=Q.restore(o.initialModel,a.character.id);if not model then return nil,problem end else model=Q.new(a.character.id)end
 local initialUpdates=model.updates;local report={schemaVersion=1,rewardPolicy=Q.rewardPolicy,rounds={},epsilon=.35,seed=o.seed,initialModel=o.initialModel}
 local function alive()return practice.phase=='playing' and not a.closed and not practice.cancelQ end
 local function waitUntil(check)
  local limit=D.App.runningTime+6
  while not check()do if not alive()then error('INTERRUPTED')end;if D.App.runningTime>limit then error('ACTION_TIMEOUT')end;D.sleep(.02)end
  if not alive()then error('INTERRUPTED')end
 end
 local ok,why=xpcall(function()
  for _,distance in ipairs({420,620,780})do
   if not alive()then error('INTERRUPTED')end
   a:beginDemo(distance);D.sleep(.1)
   waitUntil(function()return a.student.onSurface and a.enemy.onSurface end)
   local round={distance=distance,steps={}};report.rounds[#report.rounds+1]=round
   practice.message='自主部位练习 · 第'..#report.rounds..'/3场；原成果保持不变。'
   for i=1,12 do
    waitUntil(function()return a:available('laser') and not a:isAttacking() and #practice.partCombat.shots==0 end)
    a.student.faceRight=a.enemy.x>=a.student.x
    local state=a.targetSnapshot()
    local function available(label)return state['part_'..label]~='blocked'end
    local action,reason=model:choose(state,available,true,report.epsilon,o.random);assert(action,reason)
    assert(a.selectPart(F.parts[action]))
    local started=D.App.runningTime;local energy=a.studentEnergy or 0
    local accepted,err=a:request('laser','part-qlearning');assert(accepted,err)
    local step=practice.partCombat.journal.steps[#practice.partCombat.journal.steps]
    round.pending={state=state,action=action,started=started,combatStep=step}
    waitUntil(function()return not a:isAttacking() and #practice.partCombat.shots==0 and a:available('laser')end)
    assert(step.sealed and not step.truncated,'UNSEALED_ATTACK')
    local finished=D.App.runningTime
    local c={armor=0,breaks=0,energy=math.max(0,energy-(a.studentEnergy or 0)),seconds=finished-started}
    for _,hit in ipairs(step.hits)do
     assert(hit.credit and hit.credit.actor==a.character.id,'MISSING_LEARNER_CREDIT')
     c.armor=c.armor+hit.credit.armor;c.breaks=c.breaks+hit.credit.breaks
    end
    local nextState=a.targetSnapshot();local legal={}
    for _,label in ipairs(model.actions)do if nextState['part_'..label]~='blocked'then legal[#legal+1]=label end end
    local done=i==12 or #legal==0
    local transition={state=state,action=action,nextState=nextState,nextActions=legal,duration=c.seconds,
     reward=c.armor/100+c.breaks*.1-c.energy/1000-c.seconds*.01,components=c,done=done,sealed=true,started=started,finished=finished,combatStep=step,
     reason=i==12 and 'SHOT_BUDGET' or #legal==0 and 'NO_REACHABLE_PART' or 'DECISION'}
    local updated,problem=model:update(transition);assert(updated,problem)
    round.steps[#round.steps+1]=transition;round.pending=nil
    if done then round.reason=transition.reason;break end
   end
  end
 end,debug.traceback)
 if not ok then
  local round=report.rounds[#report.rounds];if round and round.pending then round.pending.truncated=true;round.pending.reason='INTERRUPTED'end
  report.status='CANCELLED';report.error=why;report.updates=model.updates-initialUpdates
  return nil,why,report
 end
 report.status='COMPLETE';report.model=model:snapshot();report.updates=model.updates-initialUpdates
 return report
end
return S
