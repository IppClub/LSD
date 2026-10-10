local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-q-learning-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local source=D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/economy-online-resource-source/source.json'),32)
  local Q=require('Training.ResourceQ');local equal=require('Training.FlowerIdentity').equal
  local models,why=Q.learn(source.trace,source.episode,source.trace.status);assert(models,why)
  assert(equal(models,assert(Q.learn(source.trace,source.episode,source.trace.status))))
  local probe=Q.new('ninilite');probe.explorationPolicy='coverage-v1'
  local state=source.trace.actors.ninilite.steps[1].state;local k=assert(Q.key(state));probe.values[k]={shoot=-1}
  local initial=probe:snapshot();local seen={}
  local allowed=function(a)return a=='idle'or a=='fmove'or a=='shoot'end
  for i=1,3 do local a,why=probe:choose(state,allowed,true,1,function()return 0 end);assert(why=='EXPLORE'and not seen[a]);seen[a]=true;if i<3 then assert(a~='shoot')end end
  assert(seen.idle and seen.fmove and seen.shoot and equal(initial,probe:snapshot()))
  assert(probe:choose(state,function(a)return a=='shoot'end,true,1,function()return 0 end)=='shoot')
  assert(probe:choose(state,allowed,false,0)=='shoot','Evaluation must not explore unknown actions')
  r.coverageExploration=true
  r.actors={}
  for _,actor in ipairs({'ninilite','wuyun'})do
   local q,why=Q.restore(models[actor],actor);assert(q,why)
   local original=source.trace.actors[actor].steps[1];local mask={};for _,action in ipairs(original.actions)do mask[action]=true end
   local action=assert(q:choose(original.state,function(a)return mask[a]end,false,0));assert(mask[action])
   local rejected,why=q:choose(original.state,function()return true end,false,.1);assert(not rejected and why=='EXPLORATION_REQUIRES_TRAINING')
   local before=Q.key(original.state);local altered=D.json.decode(D.json.encode(original.state,false,true),32);altered.resources.ammo.emp=0
   assert(Q.key(altered)~=before,'Ammo omitted from Q state')
   local broken=D.json.decode(D.json.encode(models[actor],false,true),32);broken.rewardPolicy='flower-contribution-v1';assert(not Q.restore(broken,actor))
   r.actors[actor]={updates=q.updates,states=q.states,firstAction=action}
  end
  -- Contract fixtures only: these altered copies are not saved as practice sources.
  local tagged=D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/resource-virtual-isolation-final/source.json'),32)
  tagged.episode.versions.trainingGoal='resource-clear-v1';tagged.episode.versions.outcome=1
  tagged.episode.resources.mode='virtual'
  tagged.episode.outcome={version=1,enemiesRemaining=0,partyAlive=true,niniliteHit=false,wuyunHit=false,confusionCleared=false,injury=false}
  local upgraded,why=Q.learn(tagged.trace,tagged.episode,tagged.trace.status);assert(upgraded,why)
  for actor,model in pairs(upgraded)do assert(model.trainingGoal=='resource-clear-v1' and Q.restore(model,actor))end
  local mixed,why=Q.learn(tagged.trace,tagged.episode,tagged.trace.status,models);assert(not mixed and why=='TRAINING_GOAL_MISMATCH')
  mixed,why=Q.learn(source.trace,source.episode,source.trace.status,upgraded);assert(not mixed and why=='TRAINING_GOAL_MISMATCH')
  assert(Q.learn(tagged.trace,tagged.episode,tagged.trace.status,upgraded))
  tagged.episode.versions.trainingGoal='unknown';assert(not Q.learn(tagged.trace,tagged.episode,tagged.trace.status))
  r.goalIsolation=true
  r.candidate=root..'/Test/resource-q-candidate.json';assert(D.Content:save(r.candidate,D.json.encode({schemaVersion=1,sourceEpisode=source.episode.episode,models=models,adopted=false},false,true)))
  source.trace.actors.ninilite.steps[1].components.health=99999;assert(not Q.learn(source.trace,source.episode,source.trace.status))
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
