-- Durable 2-13 consumable and reconnaissance; stage boundaries remain Story nodes.
local D=require('Dora');local S={};S.__index=S
function S.open()
 local story,err=require('Story.Service').open();if not story then return nil,err end
 local facts=story:summary();if not facts or not facts.completed['valley-friends'] then return nil,'FOX_ROUTE_LOCKED' end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0FoxMeta (id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL)')<0 then return nil,'SCHEMA_FAILED' end
 if D.DB:exec('INSERT OR IGNORE INTO lsd.Game0FoxMeta VALUES (1,1)')<0 then return nil,'SCHEMA_FAILED' end
 local rows=D.DB:query('SELECT schemaVersion FROM lsd.Game0FoxMeta WHERE id=1')
 if not rows or not rows[1] or rows[1][1]~=1 then return nil,'INCOMPATIBLE_FOX_SAVE' end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0FoxTrail (id INTEGER PRIMARY KEY CHECK(id=1),departed INTEGER NOT NULL CHECK(departed IN (0,1)),foodUsed INTEGER NOT NULL CHECK(foodUsed IN (0,1)),stamina INTEGER NOT NULL CHECK(stamina BETWEEN 0 AND 100),scanned INTEGER NOT NULL CHECK(scanned IN (0,1)),locationX REAL NOT NULL)')<0 then return nil,'SCHEMA_FAILED' end
 if D.DB:exec('INSERT OR IGNORE INTO lsd.Game0FoxTrail VALUES (1,0,0,60,0,0)')<0 then return nil,'SCHEMA_FAILED' end
 return setmetatable({},S)
end
function S:load()
 local rows=D.DB:query('SELECT departed,foodUsed,stamina,scanned,locationX FROM lsd.Game0FoxTrail WHERE id=1');if not rows or not rows[1] then return nil,'READ_FAILED' end
 local r=rows[1];return {departed=r[1]==1,foodUsed=r[2],stamina=r[3],scanned=r[4]==1,locationX=r[5]}
end
function S:foodCount()
 local story=assert(require('Story.Service').open());local facts=story:summary();local n=facts.completed['ayan-refreshment'] and 1 or 0
 local rows=D.DB:query("SELECT COALESCE(SUM(amount),0) FROM lsd.Game0ValleyRewards WHERE item IN ('valley-fish','valley-grain','valley-eggs')")
 if not rows or not rows[1] then return nil,'READ_FAILED' end
 local state=assert(self:load());return n+rows[1][1]-state.foodUsed
end
function S:writeAsync(kind,x)
 local current,err=S.open();if not current then return false,err end
 if self.busy then return false,'BUSY' end
 local state,why=current:load();if not state then return false,why end
 local sql
 if kind=='depart' then sql='UPDATE lsd.Game0FoxTrail SET departed=1 WHERE id=1'
 elseif kind=='food' then
  if not state.departed or not assert(require('Story.Service').open()):summary().completed['valley-departure'] then return false,'TRAIL_REQUIRED' end
  if state.foodUsed==1 then return true,'ALREADY_USED' end
  local n=current:foodCount();if not n or n<=0 then return false,'EMPTY' end
  sql='UPDATE lsd.Game0FoxTrail SET foodUsed=1,stamina=100 WHERE id=1 AND foodUsed=0'
 elseif kind=='scan' then
  if type(x)~='number' or math.abs(x-4100)>=180 then return false,'OUT_OF_RANGE' end
  if state.scanned then return true,'ALREADY_SCANNED' end
  if not assert(require('Story.Service').open()):summary().completed['fox-trail-rest'] then return false,'TRAIL_REQUIRED' end
  sql='UPDATE lsd.Game0FoxTrail SET scanned=1,locationX='..tostring(x)..' WHERE id=1 AND scanned=0'
 else return false,'INVALID_OPERATION' end
 self.busy=true;local ok=D.DB:transactionAsync({sql});self.busy=false;return ok,ok and nil or 'SAVE_FAILED'
end
return S
