-- Per-actor chronological HP ledger. Only continuous support ticks coalesce;
-- discrete attacks and poison ticks retain individual source/attack identities.
local V={};V.__index=V
local function finite(n)return type(n)=='number' and n==n and n>=0 and n<math.huge end
local actors={mentor=true,ninilite=true,wuyun=true}
function V.new()return setmetatable({schemaVersion=1,actors={},closed=false},V)end
function V:checkpoint(actor)
 self.boundaries=self.boundaries or {};self.boundaries[actor]=true
end
function V:record(actor,before,after,context,now)
 assert(not self.closed and actors[actor] and finite(before) and finite(after) and finite(now))
 if before==after then return end
 assert(type(context)=='table' and type(context.kind)=='string' and type(context.source)=='string')
 local state=self.actors[actor]
 if not state then state={initialHP=before,finalHP=before,damage=0,healing=0,events={}};self.actors[actor]=state end
 assert(math.abs(before-state.finalHP)<1e-5,'Unrecorded HP change')
 local last=state.events[#state.events];assert(not last or now>=last.finished)
 local support=context.kind=='support-heal' or context.kind=='support-hazard'
 if support and not (self.boundaries and self.boundaries[actor]) and last and last.kind==context.kind and last.source==context.source and now-last.finished<.1 then
  last.hpAfter=after;last.finished=now;last.samples=last.samples+1
 else
  last={kind=context.kind,source=context.source,attackId=context.attackId,started=now,finished=now,hpBefore=before,hpAfter=after,samples=1}
  state.events[#state.events+1]=last
 end
 if after<before then state.damage=state.damage+before-after else state.healing=state.healing+after-before end
 if self.boundaries then self.boundaries[actor]=nil end
 state.finalHP=after
end
function V:snapshot()
 self.closed=true
 return {schemaVersion=1,actors=self.actors}
end
function V.validate(v)
 if type(v)~='table' or v.schemaVersion~=1 or type(v.actors)~='table' then return false end
 for actor,s in pairs(v.actors)do
  if not actors[actor] or type(s)~='table' or not finite(s.initialHP) or not finite(s.finalHP) or not finite(s.damage) or not finite(s.healing) or type(s.events)~='table' or #s.events>20000 then return false end
  local hp,damage,healing,time=s.initialHP,0,0,0
  for _,e in ipairs(s.events)do
   if type(e)~='table' or type(e.kind)~='string' or type(e.source)~='string' or e.source=='' or (e.attackId~=nil and type(e.attackId)~='string') or not finite(e.started) or not finite(e.finished) or e.started<time or e.finished<e.started or not finite(e.hpBefore) or not finite(e.hpAfter) or math.abs(e.hpBefore-hp)>1e-5 or not finite(e.samples) or e.samples<1 or e.samples%1~=0 then return false end
   local support=e.kind=='support-heal' or e.kind=='support-hazard'
   if (e.samples>1 and not support) or (e.hpAfter>e.hpBefore and e.kind~='support-heal') or (e.hpAfter<e.hpBefore and e.kind=='support-heal') then return false end
   if e.hpAfter<e.hpBefore then damage=damage+e.hpBefore-e.hpAfter else healing=healing+e.hpAfter-e.hpBefore end
   hp=e.hpAfter;time=e.finished
  end
  if math.abs(hp-s.finalHP)>1e-5 or math.abs(damage-s.damage)>1e-5 or math.abs(healing-s.healing)>1e-5 then return false end
 end
 return true
end
return V
