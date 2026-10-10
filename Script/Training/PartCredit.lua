-- Outcome attribution, not a policy update. Per-episode budgets prevent rewards
-- for regenerating the same HP/AP repeatedly. Assistance is separately labelled.
local Credit={};Credit.__index=Credit
local function finite(n)return type(n)=='number' and n==n and n>=0 and n<math.huge end
local function id(v)return type(v)=='string' and #v>0 end
local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
function Credit.new(config)
 assert(id(config.target) and finite(config.maxHP) and config.maxHP>0)
 local parts={};for name,ap in pairs(config.parts)do assert(id(name) and finite(ap));parts[name]={maxAP=ap,remaining=ap,breakRemaining=1}end
 assert(next(parts))
 return setmetatable({target=config.target,maxHP=config.maxHP,remainingHP=config.maxHP,parts=parts,seen={},totals={},window=6,closed=false},Credit)
end
function Credit:hit(e,actor,now)
 if self.closed then return nil,'CLOSED'end
 if type(e)~='table' or e.target~=self.target or not id(actor) or not id(e.attackId) or not id(e.hitId) or not finite(now) or (self.lastTime and now<self.lastTime)then return nil,'INVALID_EVENT'end
 local part=self.parts[e.part];if not part then return nil,'UNKNOWN_PART'end
 for _,key in ipairs({'hpBefore','hpAfter','apBefore','apAfter','healthDamage','armorDamage'})do if not finite(e[key])then return nil,'INVALID_DELTA'end end
 if e.hpBefore>self.maxHP or e.apBefore>part.maxAP or math.abs(e.hpBefore-e.hpAfter-e.healthDamage)>1e-6 or math.abs(e.apBefore-e.apAfter-e.armorDamage)>1e-6 or e.armorBroken~=(e.apBefore>0 and e.apAfter==0)then return nil,'INCONSISTENT_DELTA'end
 local seen=self.seen[e.attackId]
 if seen and seen[e.hitId]then return nil,'DUPLICATE_EVENT'end
 if not seen then seen={};self.seen[e.attackId]=seen end
 seen[e.hitId]=true;self.lastTime=now
 local hp=math.min(self.remainingHP,e.healthDamage);self.remainingHP=self.remainingHP-hp
 local armor=math.min(part.remaining,e.armorDamage);part.remaining=part.remaining-armor
 local result={schemaVersion=1,actor=actor,at=now,health=hp,armor=armor,breaks=0}
 -- Re-armoring ends the previous exposure window, even when its reward budget
 -- is exhausted. A fresh break may enable play, but cannot mint another bonus.
 if e.apBefore>0 then part.opener=nil end
 if e.armorBroken then
  result.breaks=part.breakRemaining;part.breakRemaining=0
  if result.breaks>0 then part.opener={actor=actor,at=now,attackId=e.attackId}end
 elseif e.apBefore==0 and hp>0 and part.opener and part.opener.actor~=actor and now-part.opener.at<=self.window then
  result.assist={actor=part.opener.actor,health=hp,attackId=part.opener.attackId}
 end
 local function total(who)
  if not self.totals[who]then self.totals[who]={health=0,armor=0,breaks=0,assistedHealth=0}end
  return self.totals[who]
 end
 local direct=total(actor);direct.health=direct.health+hp;direct.armor=direct.armor+armor;direct.breaks=direct.breaks+result.breaks
 if result.assist then local assisted=total(result.assist.actor);assisted.assistedHealth=assisted.assistedHealth+result.assist.health end
 return result
end
function Credit:snapshot()return {schemaVersion=1,target=self.target,assistWindow=self.window,actors=copy(self.totals)}end
function Credit:close()self.closed=true;self.seen={}end
return Credit
