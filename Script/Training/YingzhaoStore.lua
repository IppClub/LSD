-- Independent virtual observation archive; never writes wallet or adoption.
local D=require('Dora');local S={maxBytes=4*1024*1024};local busy=false
local function open()return D.DB:existDB('lsd')and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0YingzhaoObservations(id INTEGER PRIMARY KEY AUTOINCREMENT,episode TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0 end
local function decode(payload)
 if type(payload)~='string'or #payload>S.maxBytes then return nil,'SOURCE_TOO_LARGE'end
 local ok,e,valid,why=pcall(function()local e=D.json.decode(payload,32);local valid,why=require('Enemy.BigYingzhaoEvidence').validateVirtual(e);return e,valid,why end)
 if not ok then return nil,'INVALID_SOURCE'end
 if not valid then return nil,why end;return e
end
function S.listAsync(actor)
 if actor~=nil and actor~='ninilite'and actor~='wuyun'then return nil,'INVALID_CHARACTER'end
 if not open()then return nil,'READ_FAILED'end
 if actor then
  -- The history panel keeps its global page; learning gets the selected actor's
  -- latest sources, so another learner cannot evict their demonstrations.
  local ids,cursor={},nil
  while #ids<32 do
   local rows
   if cursor then rows=D.DB:query('SELECT id,payload FROM lsd.Game0YingzhaoObservations WHERE id<? ORDER BY id DESC LIMIT 32',{cursor})
   else rows=D.DB:query('SELECT id,payload FROM lsd.Game0YingzhaoObservations ORDER BY id DESC LIMIT 32')end
   if not rows then return nil,'READ_FAILED'end
   for _,row in ipairs(rows)do
    local source,why=decode(row[2]);if not source then return nil,why end
    if source.demonstrator==actor then ids[#ids+1]=row[1];if #ids==32 then break end end
   end
   if #rows<32 or #ids==32 then break end
   cursor=rows[#rows][1];D.sleep(0)
  end
  return ids
 end
 local rows=D.DB:query('SELECT id FROM lsd.Game0YingzhaoObservations ORDER BY id DESC LIMIT 20');if not rows then return nil,'READ_FAILED'end
 local ids={};for _,row in ipairs(rows)do ids[#ids+1]=row[1]end;return ids
end
function S.loadAsync(id)
 if type(id)~='number'or id<1 or id%1~=0 then return nil,'INVALID_SOURCE_ID'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoObservations WHERE id=?',{id})
 if not rows then return nil,'READ_FAILED'end;if not rows[1]then return nil,'NOT_RECORDED'end
 return decode(rows[1][1])
end
function S.saveAsync(e)
 if busy then return false,'BUSY'end;busy=true
 local ok,accepted,why,id=pcall(function()
  local payload=D.json.encode(e,false,true);local source,reason=decode(payload);if not source then return false,reason end
  if not open()then return false,'WRITE_FAILED'end
  local rows=D.DB:query('SELECT id,payload FROM lsd.Game0YingzhaoObservations WHERE episode=?',{source.episode})
  if not rows then return false,'READ_FAILED'end
  if rows[1]then
   local old=decode(rows[1][2]);if not old or not require('Training.FlowerIdentity').equal(old,source)then return false,'SOURCE_CONFLICT'end
   return true,'ALREADY_RECORDED',rows[1][1]
  end
  if not D.DB:transactionAsync({{'INSERT INTO lsd.Game0YingzhaoObservations(episode,payload) VALUES(?,?)',{{source.episode,payload}}}})then return false,'WRITE_FAILED'end
  rows=D.DB:query('SELECT id FROM lsd.Game0YingzhaoObservations WHERE episode=?',{source.episode})
  if not rows or not rows[1]then return false,'READ_FAILED'end
  return true,nil,rows[1][1]
 end)
 busy=false;if not ok then return false,'INVALID_SOURCE'end;return accepted,why,id
end
return S
