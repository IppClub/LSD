-- Rebuild only the resource history. This does not certify demonstration labels,
-- assign rewards, or authorize C4.5/Q training from accepted command requests.
local E=require('Training.ResourceEvidence');local L=require('Economy.Ledger')
local equal=require('Training.FlowerIdentity').equal
local M={}
local function array(t)
 if type(t)~='table' or #t>2000 then return false end
 local n=0;for k in pairs(t)do if type(k)~='number' or k%1~=0 or k<1 or k>#t then return false end;n=n+1 end
 return n==#t
end
local function observation(ledger,actor)
 local ammo={};for _,line in ipairs(ledger.quote.lines)do if line.actor==actor then ammo[line.item]=ledger.stock[line.key].remaining end end
 return {schemaVersion=1,actor=actor,ammo=ammo,spent=ledger.spent,reserved=ledger.quote.total,budgetLeft=ledger.quote.total-ledger.spent}
end
function M.rebuild(trace)
 if type(trace)~='table' or trace.schemaVersion~=2 or (trace.kind~='disarm-practice'and trace.kind~='disarm-mission') or trace.trainable~=false or trace.truncated~=false or not array(trace.consumption)then return nil,'INCOMPLETE_DISARM_TRACE'end
 local resource=trace.resources
 if not E.validate(resource) or resource.mode~=(trace.kind=='disarm-mission'and 'mission'or'virtual')then return nil,'INVALID_RESOURCE_EVIDENCE'end
 if trace.status~='won' and trace.status~='failed' and trace.status~='aborted'then return nil,'UNFINISHED_TRACE'end
 if type(trace.resourcesFinalizedAt)~='number' or trace.resourcesFinalizedAt~=trace.resourcesFinalizedAt then return nil,'UNFINISHED_TRACE'end
 local loadout={};for _,line in ipairs(resource.quote.lines)do loadout[#loadout+1]={actor=line.actor,item=line.item,quantity=line.quantity}end
 local ledger=L.new(resource.attempt,loadout,resource.quote.total,0)
 if not ledger or not equal(ledger.quote,resource.quote)then return nil,'PRICE_OR_LOADOUT_MISMATCH'end
 local seen={};local at=-math.huge;local review={schemaVersion=1,trainable=false,scope='resource-accounting-only',byOwner={},ownCost=0,stolenCost=0,events=0}
 for _,row in ipairs(trace.consumption)do
  if type(row)~='table' or type(row.event)~='string' or seen[row.event]then return nil,'DUPLICATE_OR_INVALID_EVENT'end
  local event=resource.events[row.event]
  if not event or event.owner~=row.owner or event.performer~=row.performer or event.item~=row.item or event.count~=row.count then return nil,'RESOURCE_EVENT_MISMATCH'end
  if type(row.at)~='number' or row.at~=row.at or row.at<at or row.at>trace.resourcesFinalizedAt then return nil,'RESOURCE_TIME_MISMATCH'end
  if not equal(row.before,observation(ledger,row.owner))then return nil,'RESOURCE_BEFORE_MISMATCH'end
  local ok=L.consume(ledger,row.event,row.owner,row.item,row.count,row.performer,event.step)
  if not ok or not equal(row.after,observation(ledger,row.owner))then return nil,'RESOURCE_AFTER_MISMATCH'end
  seen[row.event]=true;at=row.at;review.events=review.events+1
  local owner=review.byOwner[row.owner]or{ownCost=0,stolenCost=0};review.byOwner[row.owner]=owner
  local kind
  if row.performer==row.owner then kind='ownCost'
  elseif row.performer:match('^enemy:%d+$')then kind='stolenCost'
  else return nil,'UNKNOWN_CONSUMER'end
  owner[kind]=owner[kind]+event.cost;review[kind]=review[kind]+event.cost
 end
 if not equal(ledger.events,resource.events)or not equal(ledger.stock,resource.stock)or ledger.spent~=resource.spent then return nil,'INCOMPLETE_RESOURCE_HISTORY'end
 local result=L.settle(ledger,trace.status)
 if trace.kind=='disarm-practice'and not equal(result,trace.virtualResult)then return nil,'SETTLEMENT_MISMATCH'end
 review.deployment=ledger.quote.deployment;review.total=ledger.spent
 return review
end
return M
