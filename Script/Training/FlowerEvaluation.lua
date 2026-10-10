-- Deterministic encounter facts for review/comparison, not a learned policy or
-- scalar reward. Missing outcome coverage is never presented as zero damage.
local E={}
function E.build(episode)
 if type(episode)~='table' or not episode.versions or episode.versions.credit~=2 or episode.versions.vitals~=1 then return nil,'INSUFFICIENT_COVERAGE'end
 local ok,why=require('Training.CombatStore').validate(episode);if not ok then return nil,why end
 local result={schemaVersion=1,actors={},incompleteActions=0,scope='encounter-facts'}
 for _,actor in ipairs({'mentor','ninilite','wuyun'})do
  result.actors[actor]={health=0,armor=0,breaks=0,assistedHealth=0,damageTaken=0,healing=0,friendlyDamage=0,friendlyContacts=0,shots=0,actions=0,completedActions=0,incompleteActions=0,completedActionSeconds=0,budDamage=0}
 end
 for _,step in ipairs(episode.steps)do
  local actor=result.actors[step.action.actor];actor.actions=actor.actions+1;actor.shots=actor.shots+(step.action.emitted or 0)
  if step.sealed then actor.completedActions=actor.completedActions+1;actor.completedActionSeconds=actor.completedActionSeconds+step.finished-step.started
  else actor.incompleteActions=actor.incompleteActions+1;result.incompleteActions=result.incompleteActions+1 end
  for _,hit in ipairs(step.hits)do
   if hit.relation=='friendly' then actor.friendlyDamage=actor.friendlyDamage+hit.healthDamage;actor.friendlyContacts=actor.friendlyContacts+1
   else
    local credit=hit.credit;actor.health=actor.health+credit.health;actor.armor=actor.armor+credit.armor;actor.breaks=actor.breaks+credit.breaks
    if hit.targetStage=='bud' then actor.budDamage=actor.budDamage+hit.healthDamage end
    if credit.assist then local opener=result.actors[credit.assist.actor];opener.assistedHealth=opener.assistedHealth+credit.assist.health end
   end
  end
 end
 for actor,state in pairs(episode.vitals.actors)do result.actors[actor].damageTaken=state.damage;result.actors[actor].healing=state.healing end
 result.aim=require('Training.FlowerAimEvaluation').build(episode)
 return result
end
function E.text(result)
 if not result then return '本场未取得完整评价记录。'end
 local rows={}
 for _,item in ipairs({{'ninilite','妮妮莉特'},{'wuyun','乌云'},{'mentor','导师'}})do
  local a=result.actors[item[1]]
  rows[#rows+1]=string.format('%s  输出 %.0f · 削甲 %.0f · 协作 %.0f · 承伤 %.0f · 误伤 %.0f',item[2],a.health,a.armor,a.assistedHealth,a.damageTaken,a.friendlyDamage)
 end
 if result.aim then rows[#rows+1]='妮妮莉特 '..require('Training.FlowerAimEvaluation').text(result.aim,'ninilite');rows[#rows+1]='乌云 '..require('Training.FlowerAimEvaluation').text(result.aim,'wuyun')end
 rows[#rows+1]='输出与削甲按有效贡献统计；协作指破甲后队友造成的伤害。'
 return table.concat(rows,'\n')
end
return E
