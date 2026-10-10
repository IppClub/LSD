-- One non-exploring executor for evaluation and adopted production policies.
local E={}
function E.counters()return {q=0,explored=0,fallback=0,accepted=0,rejected=0,reasons={}}end
function E.step(battle,arena,policy,base,counts,resourceFallback)
 local decision,unavailable=require('Training.FlowerDecisionTrace').decision(battle,arena)
 if not decision then counts.skipped=(counts.skipped or 0)+1;arena.lastDecision=unavailable;return false,unavailable end
 local mask={};for _,label in ipairs(decision.actions)do mask[label]=true end
 local selected,why=policy:choose(decision.state,function(label)return mask[label]==true end,false,0)
 local action,part,witness
 if selected then
  counts.q=counts.q+1;action,part=require('Training.FlowerPolicy').decodeAction(selected);if action=='shoot'then action='laser'end;witness={reason=why}
 elseif why=='UNSEEN_STATE' or why=='UNSEEN_ACTIONS'then
  counts.fallback=counts.fallback+1;counts.reasons[why]=(counts.reasons[why] or 0)+1
  local state=arena:snapshot();local available=require('Training.FlowerDecisionTrace').baseActions(decision)
  if resourceFallback then
   assert(resourceFallback==1 or resourceFallback==2 or resourceFallback==3);action=require('Training.ResourceFallback').predict(base,state,available,decision.state,resourceFallback)
  else
   action=require('Training.Model').predict(base,state,function(name)return available[name]end)
   if not action and available.idle then action='idle'end
  end
  witness={reason=why,state=state,available=available}
 end
 arena.lastDecision=selected or why
 if not action then return false,why end
 arena.flowerTargetPart=part;arena.flowerTargetAim=part and decision.aims[part] or nil
 local ok,reason=arena:request(action,'model',decision);arena.flowerTargetPart=nil;arena.flowerTargetAim=nil
 counts[ok and 'accepted' or 'rejected']=counts[ok and 'accepted' or 'rejected']+1
 local trace=battle.flowerDecisionTrace
 if ok and trace and trace.decisionSourcesVersion==1 then local steps=trace.actors[arena.character.id].steps;steps[#steps].decisionSource=witness end
 return ok,reason
end
return E
