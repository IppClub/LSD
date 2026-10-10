-- Shared candidate/deployed executor: observations, availability and fallback
-- are identical. Mentor input remains owned by the encounter/player.
local C={}
function C.step(battle,arena,policy)
 if arena.resourceCandidate then local saved=arena.resourceCandidate;return require('Training.FlowerQExecutor').step(battle,arena,saved.executor,saved.base,saved.decisions)end
 if policy.algorithm=='flower-qlearning'then local saved=assert(arena.flowerDeployment);return require('Training.FlowerQExecutor').step(battle,arena,saved.executor,saved.base,saved.decisions)end
 local P=require(policy.algorithm=='flower-resource-c45' and 'Training.ResourcePolicy' or 'Training.FlowerPolicy')
 local selectedAim
 local action,why=P.predict(policy,require('Training.FlowerFeatures').capture(battle,arena.student,battle.partCombat.known),function(label)
  local name,part=P.decodeAction(label)
  if not arena:available(name=='shoot' and 'laser' or name)then return false end
  if not part then return true end
  selectedAim=battle.partCombat:aim(arena.student,part,true,battle.roots[3].enemy.x>=arena.student.x)
  return selectedAim~=nil
 end)
 arena.lastDecision=action or why
 if action then
  local name,part=P.decodeAction(action);arena.flowerTargetPart=part;arena.flowerTargetAim=part and selectedAim or nil
  local ok,reason=arena:request(name=='shoot' and 'laser' or name,'model')
  arena.flowerTargetPart=nil;arena.flowerTargetAim=nil;return ok,reason
 end
 if why=='ACTION_UNAVAILABLE'then arena.metrics.unavailable=arena.metrics.unavailable+1 else arena.metrics.fallback=arena.metrics.fallback+1 end
 if arena:available('idle')then return arena:request('idle','baseline')end
 return false,why
end
function C.attach(battle,models)
 local store=require('Training.FlowerAdoptionStore');battle.flowerDeployments={};battle.flowerDeploymentContext={}
 local q,qWhy=require('Training.FlowerQAdoptionStore').loadAsync(models)
 if q or qWhy~='NOT_ADOPTED'then
  for _,arena in ipairs(battle.learners)do local actor=arena.character.id
   if q then
    local policy=q.models[actor]
    arena.flowerDeployment={id=q.id,qAdoptionId=q.id,candidate=q.bundle.candidate,policy=policy,executor=assert(require('Training.FlowerQ').restore(policy,actor)),base=q.bundle.models[actor],decisions=require('Training.FlowerQExecutor').counters()}
    local matches=battle.support.variant=='defence' and battle.support.gold==45
    battle.flowerDeployments[actor]={id=q.id,qAdoptionId=q.id,status='adopted',supportMatchesEvaluation=matches}
    battle.flowerDeploymentContext[actor]={qAdoptionId=q.id,candidate=q.bundle.candidate,evaluatedSupportVariant='defence',evaluatedSupportGold=45,initialSupportVariant=battle.support.variant,initialSupportGold=battle.support.gold,supportMatchesEvaluation=matches,initialHP={mentor=battle.mentorHP,ninilite=battle.arena.studentHP,wuyun=battle.wuyun.studentHP}}
   else battle.flowerDeployments[actor]={status=qWhy}end
  end
  return
 end
 local team,teamWhy=require('Training.FlowerTeamAdoptionStore').load(models)
 battle.flowerTeamAdoption=team and team.id or nil
 for _,arena in ipairs(battle.learners)do
  local actor=arena.character.id;local saved,why
  if team then saved={id=team.id,bundle={source=team.bundle.sources[actor],fieldTrials={team.bundle.trials[7]}}}
  elseif teamWhy=='NOT_ADOPTED'then saved,why=store.load(actor,models)
  else why=teamWhy end
  if saved then
   arena.flowerDeployment={id=saved.id,teamAdoptionId=team and team.id or nil,policy=saved.bundle.source.policy}
   local setup=(saved.bundle.fieldTrials or saved.bundle.trials)[1].setup
   local context={teamAdoptionId=team and team.id or nil,adoptionId=saved.id,evaluatedSupportVariant=setup.supportVariant,evaluatedSupportGold=setup.supportGold,
    initialSupportVariant=battle.support.variant,initialSupportGold=battle.support.gold,initialHP={mentor=battle.mentorHP,ninilite=battle.arena.studentHP,wuyun=battle.wuyun.studentHP}}
   context.supportMatchesEvaluation=context.initialSupportVariant==context.evaluatedSupportVariant and context.initialSupportGold==context.evaluatedSupportGold
   battle.flowerDeploymentContext[actor]=context
   battle.flowerDeployments[actor]={id=saved.id,teamAdoptionId=team and team.id or nil,status='adopted',supportMatchesEvaluation=context.supportMatchesEvaluation}
  else battle.flowerDeployments[actor]={status=why}end
 end
end
function C.identity(arena)
 if arena.resourceCandidate then local p=arena.resourceCandidate.model;return {resourceCandidate=true,domain='flower',characterId=p.characterId,algorithm=p.algorithm,count=p.updates,updates=p.updates,featureSchemaVersion=p.featureSchemaVersion,actionSetVersion=p.actionSetVersion,partSetVersion=p.partSetVersion}end
 local saved=arena.flowerDeployment;if not saved then return nil end
 local p=saved.policy
 if saved.qAdoptionId then return {qAdoptionId=saved.qAdoptionId,candidate=saved.candidate,domain='flower',characterId=p.characterId,algorithm=p.algorithm,count=p.updates,updates=p.updates,featureSchemaVersion=p.featureSchemaVersion,actionSetVersion=p.actionSetVersion,partSetVersion=p.partSetVersion}end
 return {teamAdoptionId=saved.teamAdoptionId,adoptionId=saved.id,domain='flower',characterId=p.characterId,algorithm=p.algorithm,count=p.sampleCount,featureSchemaVersion=p.featureSchemaVersion,actionSetVersion=p.actionSetVersion,partSetVersion=p.partSetVersion}
end
function C.text(battle)
 if not battle.flowerDeployments then return ''end
 local text={}
 for _,item in ipairs({{'ninilite','妮妮莉特'},{'wuyun','乌云'}})do
  local state=battle.flowerDeployments[item[1]]
  if state and state.id then text[#text+1]=item[2]..(state.qAdoptionId and '：花妖自主策略 #' or state.teamAdoptionId and '：联合花妖专项 #' or '：花妖专项 #')..state.id..(state.supportMatchesEvaluation and '' or '（本场补给与评价不同）')
  elseif state and state.status=='ENCOUNTER_CHANGED'then text[#text+1]=item[2]..'：战斗规则已更新，请重新评价专项策略'
  elseif state and state.status~='NOT_ADOPTED'then text[#text+1]=item[2]..'：专项配置不可用，使用基础模型（请回训练室检查）'end
 end
 return table.concat(text,' · ')
end
return C
