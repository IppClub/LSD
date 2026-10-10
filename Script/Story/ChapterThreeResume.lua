-- Latest chapter facts outrank historical factory checkpoints.
local Resume={}
function Resume.scene(facts)
 if facts.completed['jade-arrival']then return 'RDRoom'end
 if facts.completed['network-warning']then
  if facts.mission.unlocks['academy-defense-complete']or (facts.mission.last and facts.mission.last.mission=='c0-m07')then return 'PassageA'end
  return 'RDRoom'
 end
 if facts.completed['return-online']then return 'OperationRoom'end
end
return Resume
