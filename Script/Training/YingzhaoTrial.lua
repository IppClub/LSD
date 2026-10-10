-- Frozen candidate execution only: never records human labels or adopts itself.
local D=require('Dora');local M={}
function M.attach(b,model,options)
 options=options or {};local origin=options.origin or 'candidate';assert(origin=='candidate'or origin=='adopted','Invalid policy origin')
 local P=require(model and model.algorithm=='yingzhao-qlearning'and 'Training.YingzhaoQ'or 'Training.YingzhaoPolicy');assert(P.validate(model),'Invalid Boss candidate');assert(b.phase=='ready'and not b.demonstrator and (not b.yingzhaoQTraining or b.yingzhaoQTraining.actor~=model.characterId)and not (b.yingzhaoCandidates and b.yingzhaoCandidates[model.characterId]),'Candidate requires an uncontrolled ready battle')
 local a;for _,arena in ipairs(b.learners)do if arena.character.id==model.characterId then a=arena end end;assert(a,'Candidate actor absent')
 local formalFallback=options.formalBasicFallback==true
 assert(not formalFallback or b.supplies and not b.supplies.isVirtual,'Basic fallback requires formal supplies')
 local frozen=D.json.decode(D.json.encode(model),32)
 b.yingzhaoCandidates=b.yingzhaoCandidates or {};b.yingzhaoCandidates[frozen.characterId]=frozen
 b.yingzhaoDecisionsByActor=b.yingzhaoDecisionsByActor or {};b.yingzhaoDecisionsByActor[frozen.characterId]={}
 b.yingzhaoCandidate=b.yingzhaoCandidate or frozen
 b.yingzhaoCandidateDecisions=b.yingzhaoDecisionsByActor[b.yingzhaoCandidate.characterId]
 local q=frozen.algorithm=='yingzhao-qlearning'and assert(P.restore(frozen))or nil
 local function predict(state,available)if q then return q:choose(state,available,false,0)end;return P.predict(frozen,state,available)end
 a.continuousDecisions=true
 local update=a.update;local nextDecision=0;local A=require('Training.YingzhaoActions')
 a.update=function(self,...)
  self.mode='demo';self.recorder.active=false
  local formation=require('Combat.Formation');local now=D.App.runningTime
  if b.phase=='playing'and (not formation.owns(self,b,now)or formation.stationaryRecovery(self,b,now))and now>=nextDecision and not self:isAttacking()then
   nextDecision=D.App.runningTime+.25
   local observation=b.observeYingzhao(self.student);local blockedActions={}
   local action,why=predict(observation,function(label)
    local physical,part=A.decode(label,frozen.actionSetVersion);local available,detail=A.available(b,self,label,frozen.actionSetVersion)
    if not available then
     if not detail then
      if require('Combat.Displacement').blocked(self.student)then detail='DISPLACED'
      elseif not self.student.onSurface then detail='AIRBORNE'
      elseif (physical=='laser'or physical=='melee')and D.App.runningTime<self.nextShot then detail='COOLDOWN'
      elseif physical=='laser'and self.studentEnergy and self.studentEnergy<self.shotEnergyCost then detail='ENERGY_SHORTAGE'
      else detail='ACTION_UNAVAILABLE'end
     end
     blockedActions[label]=detail;return false
    end
    return true
   end)
   local accepted,reason=false,why
   if action then accepted,reason=A.request(b,self,action,origin,frozen.actionSetVersion)end
   local fallback
   if formalFallback and not action and (why=='NO_MATCH'or why=='UNSEEN_STATE'or why=='UNSEEN_ACTIONS')then
    -- Execute the existing saved basic model, never exploration or a new
    -- demonstration label. Keep its result separate from candidate success.
    local label,missing=require('Training.Model').predict(self.trialModel,self:snapshot(),function(a)return self:available(a)end)
    local started,detail=false,missing
    if label then started,detail=self:request(label,'model')end
    fallback={version=1,source='saved-basic-model',action=label,accepted=started,reason=detail}
    self.metrics.fallback=self.metrics.fallback+1
   end
   local decisions=b.yingzhaoDecisionsByActor[frozen.characterId]
   if #decisions<1500 then decisions[#decisions+1]={at=D.App.runningTime,observation=observation,blockedActions=blockedActions,action=action,accepted=accepted,reason=reason,origin=origin,fallback=fallback}else b.yingzhaoCandidateTraceTruncated=true end
   if not accepted and not (fallback and fallback.accepted)and not require('Combat.Displacement').blocked(self.student)and self.student.onSurface then
    -- Only cancel candidate locomotion; never erase a hit impulse or interrupt
    -- hit/fall/standUp playback while the policy has no legal action.
    if self.student:isDoing(self.physical.fmove)or self.student:isDoing(self.physical.bmove)then self.student:stop();self.student.velocityX=0 end
   end
  end
  return update(self,...)
 end
 return a
end
return M
