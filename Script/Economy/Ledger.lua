-- Pure, versioned per-attempt budget ledger. Currency is integer supply points.
-- Persistence must reserve quote.total and commit settlement exactly once.
local L={version=1}
L.items={
 kinetic={unit=2,deploy=2},emp={unit=4,deploy=3},laser={unit=6,deploy=5},
 blade={unit=1,deploy=1},smoke={unit=6,deploy=0},flare={unit=8,deploy=0},grenade={unit=12,deploy=0},medical={unit=15,deploy=0}}
local function integer(n)return type(n)=='number' and n==n and n%1==0 and n>=0 and n<=100000000 end
function L.quote(loadout)
 if type(loadout)~='table' or #loadout==0 then return nil,'EMPTY_LOADOUT'end
 local lines,keys={},{};local total,deploy=0,0
 for _,entry in ipairs(loadout)do
  local price=type(entry)=='table' and L.items[entry.item]
  if not price or type(entry.actor)~='string' or entry.actor=='' or not integer(entry.quantity) or entry.quantity==0 then return nil,'INVALID_LOADOUT'end
  local key=entry.actor..':'..entry.item;if keys[key]then return nil,'DUPLICATE_LOADOUT'end;keys[key]=true
  local amount=entry.quantity*price.unit+price.deploy
  if not integer(total+amount)then return nil,'BUDGET_TOO_LARGE'end
  total=total+amount;deploy=deploy+price.deploy
  lines[#lines+1]={key=key,actor=entry.actor,item=entry.item,quantity=entry.quantity,unit=price.unit,deploy=price.deploy}
 end
 return {total=total,deployment=deploy,lines=lines,priceVersion=L.version}
end
function L.new(attempt,loadout,balance,reward)
 if type(attempt)~='string' or attempt=='' or not integer(balance) or not integer(reward)then return nil,'INVALID_ATTEMPT'end
 local quote,why=L.quote(loadout);if not quote then return nil,why end
 if balance<quote.total then return nil,'INSUFFICIENT_SUPPLIES'end
 local stock={};for _,line in ipairs(quote.lines)do stock[line.key]={remaining=line.quantity,used=0,unit=line.unit}end
 return {schemaVersion=1,attempt=attempt,quote=quote,balanceBefore=balance,reward=reward,stock=stock,events={},spent=quote.deployment,status='active'}
end
-- owner is the actor whose provisioned weapon was used, including stolen guns.
-- caller records an actual emission/consumption, never a keypress or hit count.
function L.consume(ledger,id,owner,item,count,performer,step)
 if type(id)~='string' or id=='' or not integer(count) or count==0 then return false,'INVALID_EVENT'end
 if type(owner)~='string' or not L.items[item] or type(performer)~='string' then return false,'INVALID_EVENT'end
 if step~=nil and (not integer(step) or step==0)then return false,'INVALID_ACTION_STEP'end
 local previous=ledger.events[id]
 if previous then
  return previous.owner==owner and previous.item==item and previous.count==count and previous.performer==performer and previous.step==step,
   previous.owner==owner and previous.item==item and previous.count==count and previous.performer==performer and previous.step==step and 'ALREADY_RECORDED' or 'EVENT_CONFLICT'
 end
 if ledger.status~='active'then return false,'CLOSED'end
 local stock=ledger.stock[owner..':'..item]
 if not stock then return false,'NOT_EQUIPPED'end
 if stock.remaining<count then return false,'OUT_OF_SUPPLIES'end
 stock.remaining=stock.remaining-count;stock.used=stock.used+count
 local cost=stock.unit*count;ledger.spent=ledger.spent+cost
 ledger.events[id]={owner=owner,item=item,count=count,performer=performer,cost=cost,step=step}
 return true,'RECORDED'
end
function L.settle(ledger,status)
 if status~='won' and status~='failed' and status~='aborted'then return nil,'INVALID_RESULT'end
 if ledger.result then if ledger.status==status then return ledger.result,'ALREADY_SETTLED'end;return nil,'RESULT_CONFLICT'end
 local income=status=='won' and ledger.reward or 0
 local refund=ledger.quote.total-ledger.spent
 assert(refund>=0,'Budget invariant broken')
 local others={}
 for _,event in pairs(ledger.events)do
  if event.performer~=event.owner then local key=event.owner..':'..event.item;others[key]=(others[key]or 0)+event.count end
 end
 local lines={}
 for _,line in ipairs(ledger.quote.lines)do
  local stock=ledger.stock[line.key]
  lines[#lines+1]={actor=line.actor,item=line.item,quantity=line.quantity,used=stock.used,remaining=stock.remaining,
   unit=line.unit,deployment=line.deploy,consumption=stock.used*line.unit,cost=line.deploy+stock.used*line.unit,
   refund=stock.remaining*line.unit,usedByOthers=others[line.key]or 0}
 end
 local result={schemaVersion=1,attempt=ledger.attempt,status=status,income=income,cost=ledger.spent,
  lines=lines,net=income-ledger.spent,reserved=ledger.quote.total,refund=refund,
  balanceAfter=ledger.balanceBefore-ledger.spent+income,priceVersion=ledger.quote.priceVersion}
 ledger.status=status;ledger.result=result;return result,'SETTLED'
end
return L
