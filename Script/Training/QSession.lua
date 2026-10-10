-- One learner, one unarmored opponent. Part/composite encounters require their
-- event-ledger reward adapter and are deliberately rejected by this collector.
local Q=require('Training.QModel')
local Session={};Session.__index=Session
Session.rewardPolicy='unarmored-v1'
function Session.new(arena,options)
 local o=options or {}
 if arena.partObservation or arena.damageOpponent or arena.enemyTargets or arena.extraEnemyTargets or arena.studentEffects or arena.externalCombat then return nil,'REWARD_ADAPTER_REQUIRED'end
 if type(o.random)~='function'then return nil,'EXPLICIT_RNG_REQUIRED'end
 local epsilon=o.epsilon or .2
 if type(epsilon)~='number' or epsilon~=epsilon or epsilon<0 or epsilon>1 then return nil,'INVALID_EPSILON'end
 local model=o.model or Q.new({characterId=arena.character.id})
 if getmetatable(model)~=Q or model.characterId~=arena.character.id then return nil,'INCOMPATIBLE_CHARACTER'end
 if model.updates>0 and model.rewardPolicy~=Session.rewardPolicy then return nil,'INCOMPATIBLE_REWARD_POLICY'end
 model.rewardPolicy=Session.rewardPolicy
 return setmetatable({arena=arena,model=model,random=o.random,epsilon=epsilon,steps={},closed=false},Session)
end
function Session:legal()
 local result={};for _,name in ipairs(self.model.actions)do if self.arena:available(name)then result[#result+1]=name end end
 return result
end
function Session:finish(now,done,reason)
 local p=self.pending;if not p then return true end
 local a=self.arena
 -- Rewards are actual clamped losses in this sole-attacker training fixture.
 -- Healing needs a budgeted event adapter, never a silent positive delta reset.
 if a.enemyHP>p.enemyHP or a.studentHP>p.studentHP then return false,'HEALING_REQUIRES_ADAPTER'end
 local duration=now-p.started;if duration<=0 then return false,'EMPTY_INTERVAL'end
 local components={healthDamage=p.enemyHP-a.enemyHP,damageTaken=p.studentHP-a.studentHP,
  energySpent=math.max(0,p.energy-(a.studentEnergy or 0)),seconds=duration,
  victory=done and a.enemyHP<=0 and a.studentHP>0 and 1 or 0,defeat=done and a.studentHP<=0 and 1 or 0}
 -- Initial, versioned tuning: normalized HP benefit/cost, small resource/time
 -- cost, one terminal outcome. No bonus for firing or merely playing animation.
 local reward=components.healthDamage/100-components.damageTaken/100-components.energySpent/1000-duration*.01+components.victory-components.defeat
 local transition={state=p.state,action=p.action,nextState=a:snapshot(),nextActions=self:legal(),
  duration=duration,reward=reward,components=components,rewardPolicy=Session.rewardPolicy,
  done=done,sealed=true,reason=reason,started=p.started,finished=now}
 local ok,why=self.model:update(transition);if not ok then return false,why end
 self.steps[#self.steps+1]=transition;self.pending=nil;return true
end
function Session:abort(reason)
 if self.closed then return end
 if self.pending then self.pending.truncated=true;self.pending.reason=reason or 'INTERRUPTED';self.steps[#self.steps+1]=self.pending;self.pending=nil end
 self.closed=true;self.reason=reason or 'INTERRUPTED'
 if not self.arena.closed then self.arena.student:stop();self.arena.student.velocityX=0 end
end
function Session:update(now)
 if self.closed then return end
 local a=self.arena
 local done=a.enemyHP<=0 or a.studentHP<=0 or now-a.roundStarted>=(a.roundLimit or 35)
 if done then
  local reason=a.studentHP<=0 and 'DEFEAT' or a.enemyHP<=0 and 'VICTORY' or 'TIMEOUT'
  local ok,why=self:finish(now,true,reason);if not ok then self:abort(why);a.mode='review';return end
  self.closed=true;self.reason=reason;a.mode='review';a.student:stop();a.student.velocityX=0
  -- Terminal projectiles are cancelled before another episode can begin.
  for _,bullet in ipairs(a.projectiles)do bullet:removeFromParent()end;a.projectiles={}
  a.result={controller='qlearning-training',won=reason=='VICTORY',studentHP=a.studentHP,enemyHP=a.enemyHP,seconds=now-a.roundStarted,metrics=a.metrics}
  return
 end
 -- Attacks retain their full animation and all projectiles' declared lifetime.
 -- Movement/wait intervals last at least .5 seconds, and end only at a legal
 -- decision boundary. Other controllers continue using their existing cadence.
 if self.pending then
  if now-self.pending.started<.5 or a:isAttacking() or now<(a.qProjectileUntil or 0) or #self:legal()==0 then return end
  local ok,why=self:finish(now,false,'DECISION');if not ok then self:abort(why);a.mode='review';return end
 end
 local action=self.model:choose(a:snapshot(),function(name)return a:available(name)end,true,self.epsilon,self.random)
 if not action then return end
 -- Continuing locomotion is a real accepted interval, not a restart that
 -- truncates its looping animation. Attack decisions always use request().
 local state=a:snapshot();local enemyHP,studentHP,energy=a.enemyHP,a.studentHP,a.studentEnergy or 0
 local accepted
 if not a:isAttacking() and a.student:isDoing(a.physical[action])then accepted=true
 else accepted=a:request(action,'qlearning');state=a.lastAcceptedState or state end
 if accepted then self.pending={state=state,action=action,started=now,enemyHP=enemyHP,studentHP=studentHP,energy=energy}end
end
return Session
