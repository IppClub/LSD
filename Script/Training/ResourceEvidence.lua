-- Economic evidence is versioned separately from life-support gold/energy.
local E={version=1}
local function integer(n)return type(n)=='number' and n==n and n%1==0 and n>=0 and n<=100000000 end
function E.validate(e)
 if type(e)~='table' or e.schemaVersion~=1 or e.trainable~=false or type(e.attempt)~='string' or type(e.quote)~='table' or type(e.quote.lines)~='table' or type(e.events)~='table' or type(e.stock)~='table'then return false end
 if e.mode~=nil and e.mode~='mission' and e.mode~='virtual'then return false end
 local stock,spent,total={},0,0
 for _,line in ipairs(e.quote.lines)do
  if type(line.key)~='string' or stock[line.key] or not integer(line.quantity) or not integer(line.unit) or not integer(line.deploy)then return false end
  stock[line.key]={remaining=line.quantity,used=0,unit=line.unit};spent=spent+line.deploy;total=total+line.quantity*line.unit+line.deploy
 end
 if total~=e.quote.total or spent~=e.quote.deployment then return false end
 for id,event in pairs(e.events)do
  if type(id)~='string' or type(event)~='table' or type(event.owner)~='string' or type(event.item)~='string' or type(event.performer)~='string' or not integer(event.count) or event.count==0 then return false end
  local s=stock[event.owner..':'..event.item]
  if not s or s.remaining<event.count or event.cost~=s.unit*event.count then return false end
  s.remaining=s.remaining-event.count;s.used=s.used+event.count;spent=spent+event.cost
 end
 if spent~=e.spent then return false end
 return require('Training.FlowerIdentity').equal(stock,e.stock)
end
function E.observation(s)
 if type(s)~='table' or s.schemaVersion~=1 or type(s.actor)~='string' or not integer(s.spent) or not integer(s.reserved) or s.spent>s.reserved or s.budgetLeft~=s.reserved-s.spent or type(s.ammo)~='table'then return false end
 for item,n in pairs(s.ammo)do if not ({smoke=true,flare=true,kinetic=true,emp=true,laser=true,blade=true,grenade=true,medical=true})[item] or not integer(n)then return false end end
 return true
end
function E.attribute(e,steps)
 if not E.validate(e) or type(steps)~='table'then return nil,'INVALID_RESOURCE_EVIDENCE'end
 local result={schemaVersion=1,byStep={},unattributed=0,deployment=e.quote.deployment,total=e.spent}
 for id,event in pairs(e.events)do
  if event.step~=nil then
   if not integer(event.step) or event.step==0 then return nil,'INVALID_RESOURCE_STEP'end
   local step=steps[event.step];local action=step and step.action
   if not action or step.id~=event.step or action.actor~=event.performer or event.owner~=event.performer or action.weapon~=event.item or (action.name~='shoot' and action.name~='melee')then return nil,'RESOURCE_ACTION_MISMATCH'end
   local key=tostring(event.step);local entry=result.byStep[key]or{cost=0,count=0,events={}}
   entry.cost=entry.cost+event.cost;entry.count=entry.count+event.count;entry.events[#entry.events+1]=id;result.byStep[key]=entry
  else result.unattributed=result.unattributed+event.cost end
 end
 for _,entry in pairs(result.byStep)do table.sort(entry.events)end
 return result
end
return E
