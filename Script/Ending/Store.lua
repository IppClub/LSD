-- Presentation milestones are independent of narrative and mission rewards.
local D=require('Dora');local Store={};Store.__index=Store
function Store.open()
 if not D.DB:existDB('lsd')then return nil,'NO_GAME_DATABASE'end
 if D.DB:exec("CREATE TABLE IF NOT EXISTS lsd.Game0EndingViews(kind TEXT PRIMARY KEY CHECK(kind IN ('ending','credits')),schemaVersion INTEGER NOT NULL,contentVersion INTEGER NOT NULL,watchedAt INTEGER NOT NULL)")<0 then return nil,'SCHEMA_FAILED'end
 return setmetatable({},Store)
end
function Store:load()
 local rows=D.DB:query('SELECT kind,schemaVersion,contentVersion,watchedAt FROM lsd.Game0EndingViews');if not rows then return nil,'READ_FAILED'end
 local result={ending=false,credits=false}
 for _,r in ipairs(rows)do
  if (r[1]~='ending'and r[1]~='credits')or r[2]~=1 or r[3]~=1 or type(r[4])~='number'or r[4]<0 then return nil,'INCOMPATIBLE_ENDING_SAVE'end
  result[r[1]]=true
 end
 return result
end
function Store:markAsync(kind)
 if kind~='ending'and kind~='credits'then return false,'INVALID_VIEW'end
 if self.busy then return false,'BUSY'end
 local current,why=self:load();if not current then return false,why end
 local records,why=require('Ending.Records').read();if not records then return false,why end
 if kind=='credits'and not current.ending then return false,'ENDING_VIEW_REQUIRED'end
 if current[kind]then return true end
 self.busy=true
 local ok=D.DB:transactionAsync({{'INSERT OR IGNORE INTO lsd.Game0EndingViews VALUES(?,1,1,?)',{{kind,os.time()}}}})
 self.busy=false;if not ok then return false,'WRITE_FAILED'end
 return true
end
return Store
