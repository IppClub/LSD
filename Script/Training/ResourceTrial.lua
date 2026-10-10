-- Explicit evaluation attachment only. Does not adopt, explore, or update Q.
local M={}
function M.attach(battle,models,baseModels)
 assert(battle.phase=='ready' and battle.supplies,'Resource trial requires a prepared budgeted battle')
 local prepared={}
 for _,arena in ipairs(battle.learners)do
  local actor=arena.character.id;local executor,why=require('Training.ResourceQ').restore(models[actor],actor);assert(executor,why)
  prepared[actor]={executor=executor,base=assert(baseModels[actor]),decisions=require('Training.FlowerQExecutor').counters(),model=models[actor]}
 end
 for _,arena in ipairs(battle.learners)do arena.resourceCandidate=prepared[arena.character.id]end
 return prepared
end
return M
