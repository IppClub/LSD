-- Episode-scoped evidence for imitation and reinforcement learning. Observation
-- snapshots never contain later outcomes. No reward weights or training updates
-- are applied here; consumers must explicitly select a versioned policy.
local Journal={};Journal.__index=Journal
local function copy(t)
 if type(t)~='table' then return t end
 local out={};for k,v in pairs(t)do out[k]=copy(v)end;return out
end
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
function Journal.new(episode,versions,limit)
 assert(type(episode)=='string' and episode~='' and type(versions)=='table')
 limit=limit or 1500;assert(finite(limit) and limit>=1 and limit%1==0)
 return setmetatable({schemaVersion=1,episode=episode,versions=copy(versions),limit=limit,steps={},attacks={},events={},closed=false},Journal)
end
function Journal:movementEvent(event)
 if self.closed or not require('Combat.Spatial').eventValid(event) then return false end
 self.movement=self.movement or {}
 if #self.movement>=4096 then self.movementTruncated=true;return true end
 self.movement[#self.movement+1]=copy(event);return true
end
function Journal:begin(observation,action,now,accepted)
 if self.closed then return nil,'CLOSED' end
 if accepted~=true then return nil,'ACTION_REJECTED' end
 if #self.steps>=self.limit then return nil,'LIMIT' end
 if type(observation)~='table' or type(action)~='table' or type(action.name)~='string' or not finite(now) then return nil,'INVALID_DECISION' end
 local step={id=#self.steps+1,observation=copy(observation),action=copy(action),started=now,hits={},pending=0,totals={armorDamage=0,healthDamage=0,armorBreaks=0}}
 self.steps[#self.steps+1]=step;return step.id
end
function Journal:attach(stepId,attackId)
 local step=self.steps[stepId]
 if self.closed or not step or step.sealed or type(attackId)~='string' or attackId=='' or self.attacks[attackId]~=nil then return false end
 self.attacks[attackId]={step=stepId,open=true};step.pending=step.pending+1;return true
end
function Journal:hit(event)
 if self.closed or type(event)~='table' then return false,'CLOSED_OR_INVALID' end
 local attack=self.attacks[event.attackId]
 if not attack or not attack.open then return false,'INACTIVE_ATTACK' end
 if type(event.hitId)~='string' or event.hitId=='' or type(event.target)~='string' then return false,'INVALID_HIT' end
 -- Contact ids are scoped to an attack and target, not globally by a delimiter.
 local byAttack=self.events[event.attackId] or {};self.events[event.attackId]=byAttack
 local byTarget=byAttack[event.target] or {};byAttack[event.target]=byTarget
 if byTarget[event.hitId] then return false,'DUPLICATE_HIT' end
 if not finite(event.healthDamage) or event.healthDamage<0 or not finite(event.armorDamage) or event.armorDamage<0 then return false,'INVALID_DELTA' end
 local step=self.steps[attack.step]
 byTarget[event.hitId]=true;step.hits[#step.hits+1]=copy(event)
 if event.relation=='friendly' then
  step.totals.friendlyHealthDamage=(step.totals.friendlyHealthDamage or 0)+event.healthDamage
  step.totals.friendlyHits=(step.totals.friendlyHits or 0)+1
  return true
 end
 step.totals.healthDamage=step.totals.healthDamage+event.healthDamage
 step.totals.armorDamage=step.totals.armorDamage+event.armorDamage
 if event.armorBroken then step.totals.armorBreaks=step.totals.armorBreaks+1 end
 return true
end
-- End of the decision interval is separate from the lifetime of its bullets.
function Journal:finish(stepId,nextObservation,now,done,reason)
 local step=self.steps[stepId]
 if self.closed or not step or step.finished or not finite(now) or now<step.started or type(nextObservation)~='table' then return false end
 step.nextObservation=copy(nextObservation);step.finished=now;step.duration=now-step.started
 step.done=done==true;step.reason=reason;step.sealed=step.pending==0;return true
end
function Journal:expire(attackId)
 local a=self.attacks[attackId];if self.closed or not a or not a.open then return false end
 a.open=false;local step=self.steps[a.step];step.pending=step.pending-1
 if step.finished and step.pending==0 then step.sealed=true end
 return true
end
function Journal:transition(stepId)
 local s=self.steps[stepId]
 if not s or not s.sealed then return nil,'PENDING_OUTCOMES' end
 return copy(s)
end
function Journal:close(reason)
 if self.closed then return end
 self.closed=true
 for _,s in ipairs(self.steps)do
  -- Interrupted intervals are not fabricated into terminal wins or misses.
  if not s.sealed then s.truncated=true;s.reason=reason or 'INTERRUPTED' end
 end
 self.attacks={};self.events={}
end
function Journal:snapshot()
 assert(self.closed,'Close episode before persistence')
 return copy({schemaVersion=self.schemaVersion,episode=self.episode,versions=self.versions,steps=self.steps,movement=self.movement,movementTruncated=self.movementTruncated,closed=true})
end
return Journal
