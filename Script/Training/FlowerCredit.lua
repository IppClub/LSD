-- Encounter-scoped net contribution. Raw hit deltas remain available separately.
local PartCredit=require('Training.PartCredit')
local Credit={};Credit.__index=Credit
function Credit.new()
 return setmetatable({targets={},ledgers={},summonRemaining=300,sequence=0,closed=false},Credit)
end
function Credit:hit(event,config,now)
 assert(not self.closed and event.relation=='hostile')
 self.sequence=self.sequence+1
 local result
 if event.targetStage=='bud' then
  -- Bud HP is restored every tick and changes the future flower's strength.
  -- It is not permanent HP loss and cannot earn ordinary damage rewards.
  result={actor=event.source,at=now,health=0,armor=0,breaks=0,excluded='bud-transient'}
 else
  local ledger=self.ledgers[event.target]
  if not ledger then
   assert(config and config.target==event.target)
   self.targets[event.target]=config;ledger=PartCredit.new(config);self.ledgers[event.target]=ledger
  end
  result=assert(ledger:hit(event,event.source,now))
  if self.targets[event.target].summoned then
   result.health=math.min(result.health,self.summonRemaining)
   self.summonRemaining=self.summonRemaining-result.health
  end
 end
 result.schemaVersion=2;result.sequence=self.sequence
 return result
end
function Credit:close()
 if self.closed then return end;self.closed=true
 for _,ledger in pairs(self.ledgers)do ledger:close()end
end
return Credit
