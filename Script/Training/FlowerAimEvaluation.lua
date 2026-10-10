-- Per-projectile aim outcomes; no hit backfills an unknown intention.
local A={}
function A.build(episode)
 if not episode.versions or episode.versions.aim~=1 then return nil end
 local actors={}
 for _,name in ipairs({'mentor','ninilite','wuyun'})do actors[name]={emitted=0,unresolved=0,unknownIntent=0,redirected=0,aimed=0,correct=0,wrongPart=0,otherEnemy=0,friendly=0,missOrBlocked=0}end
 for _,step in ipairs(episode.steps)do
  local action=step.action;local n=action.emitted or 0
  if action.name=='shoot' and n>0 then
   local counts=actors[action.actor];counts.emitted=counts.emitted+n
   if not step.sealed then counts.unresolved=counts.unresolved+n
   elseif action.redirected then counts.redirected=counts.redirected+n
   elseif not action.aimSource or action.intendedPart=='unknown' then counts.unknownIntent=counts.unknownIntent+n
   else
    counts.aimed=counts.aimed+n
    local contacts={}
    for _,hit in ipairs(step.hits)do if not contacts[hit.attackId]then
     contacts[hit.attackId]=hit.relation=='friendly' and 'friendly' or hit.target~='factory-flower' and 'otherEnemy' or hit.part==action.intendedPart and 'correct' or 'wrongPart'
    end end
    local resolved=0
    for _,kind in pairs(contacts)do counts[kind]=counts[kind]+1;resolved=resolved+1 end
    counts.missOrBlocked=counts.missOrBlocked+math.max(0,n-resolved)
   end
  end
 end
 return {schemaVersion=1,denominator='completed-explicit-intent-nonredirected-projectiles',actors=actors}
end
function A.text(aim,actor)
 if not aim then return '本记录未采集部位瞄准评价。'end
 local a=aim.actors[actor]
 return string.format('部位命中 %d/%d · 错部位%d · 其他目标%d · 落空或遮挡%d（未知意图%d、改向%d、未完成%d另计）',a.correct,a.aimed,a.wrongPart,a.otherEnemy+a.friendly,a.missOrBlocked,a.unknownIntent,a.redirected,a.unresolved)
end
return A
