local D=require('Dora');local R=require('Story.ValleyRules');local S={};S.__index=S
function S.open()
 local story,err=require('Story.Service').open();if not story then return nil,err end
 local facts=story:summary();if not facts or not facts.completed['valley-awakening'] then return nil,'VALLEY_LOCKED' end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0ValleyMeta (id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL)')<0 then return nil,'SCHEMA_FAILED' end
 if D.DB:exec('INSERT OR IGNORE INTO lsd.Game0ValleyMeta VALUES (1,1)')<0 then return nil,'SCHEMA_FAILED' end
 local meta=D.DB:query('SELECT schemaVersion FROM lsd.Game0ValleyMeta WHERE id=1')
 if not meta or not meta[1] or meta[1][1]~=1 then return nil,'INCOMPATIBLE_VALLEY_SAVE' end
 for _,sql in ipairs({'CREATE TABLE IF NOT EXISTS lsd.Game0ValleyActivities (id TEXT PRIMARY KEY,state TEXT NOT NULL,completed INTEGER NOT NULL CHECK(completed IN (0,1)))','CREATE TABLE IF NOT EXISTS lsd.Game0ValleyRewards (id TEXT PRIMARY KEY,item TEXT NOT NULL,amount INTEGER NOT NULL CHECK(amount>0))'}) do if D.DB:exec(sql)<0 then return nil,'SCHEMA_FAILED' end end
 return setmetatable({},S)
end
function S:load(id)
 if not R.specs[id] then return nil,'UNKNOWN_ACTIVITY' end
 local rows=D.DB:query('SELECT state FROM lsd.Game0ValleyActivities WHERE id=?',{id});if not rows then return nil,'READ_FAILED' end
 local state=rows[1] and D.json.decode(rows[1][1],16) or R.initial(id)
 if not R.validate(id,state) then return nil,'INVALID_SAVED_ACTIVITY' end
 return state
end
function S:summary()
 local result={states={},complete={},rewards={}}
 for _,id in ipairs(R.ids) do local s,err=self:load(id);if not s then return nil,err end;result.states[id]=s;result.complete[id]=R.complete(id,s) end
 local rows=D.DB:query('SELECT id,item,amount FROM lsd.Game0ValleyRewards');if not rows then return nil,'READ_FAILED' end
 for _,row in ipairs(rows) do result.rewards[row[1]]={item=row[2],amount=row[3]} end
 return result
end
function S:saveAsync(id,state)
 local current,err=S.open();if not current then return false,err end
 if self.busy then return false,'BUSY' end
 local old,readError=current:load(id);if not old then return false,readError end
 if not R.monotonic(id,old,state) then return false,'INVALID_ACTIVITY_PROGRESS' end
 self.busy=true;local complete=R.complete(id,state);local spec=R.specs[id]
 local ops={{'INSERT OR REPLACE INTO lsd.Game0ValleyActivities VALUES (?,?,?)',{{id,D.json.encode(state,false,true),complete and 1 or 0}}}}
 if complete then ops[#ops+1]={'INSERT OR IGNORE INTO lsd.Game0ValleyRewards VALUES (?,?,?)',{{id,spec.item,spec.amount}}} end
 local ok=D.DB:transactionAsync(ops);self.busy=false;return ok,ok and nil or 'SAVE_FAILED'
end
return S
