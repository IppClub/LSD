-- Consumables granted by the actual Lin conversation, durable across attempts.
local D=require('Dora')
local Supplies={};local busy={}
local function resolve(recipient)
 if recipient=='mentor' then return require('Data.Config').char=='charF' and 'charF' or 'charM' end
 return recipient
end
function Supplies.count(recipient,item)
 local service,err=require('Story.Service').open();if not service then return nil,err end
 recipient=resolve(recipient)
 local rows=D.DB:query('SELECT COALESCE(SUM(amount),0) FROM lsd.Game0StorySupplies WHERE recipient=? AND item=?',{recipient,item})
 return rows and rows[1] and rows[1][1] or nil
end
function Supplies.consumeAsync(recipient,item)
 recipient=resolve(recipient)
 if recipient~='charM' and recipient~='charF' and recipient~='ninilite' and recipient~='wuyun' then return false,'INVALID_RECIPIENT' end
 if item~='first-aid-water' and item~='medicated-plaster' then return false,'INVALID_ITEM' end
 local key=recipient..'/'..item;if busy[key] then return false,'BUSY' end
 local service,err=require('Story.Service').open();if not service then return false,err end
 busy[key]=true
 local rows=D.DB:query('SELECT source FROM lsd.Game0StorySupplies WHERE recipient=? AND item=? AND amount>0 ORDER BY source LIMIT 1',{recipient,item})
 if not rows or not rows[1] then busy[key]=nil;return false,rows and 'EMPTY' or 'READ_FAILED' end
 local ok=D.DB:transactionAsync({{'UPDATE lsd.Game0StorySupplies SET amount=amount-1 WHERE source=? AND recipient=? AND item=? AND amount>0',{{rows[1][1],recipient,item}}}})
 busy[key]=nil;return ok,ok and nil or 'SAVE_FAILED'
end
return Supplies
