-- Last explicitly confirmed deployment choice; an old save has no inferred history.
local D=require('Dora');local Store={};Store.__index=Store
local variants={defence=true,cargo=true,mobility=true}
function Store.open()
 if not D.DB:existDB('lsd')then return nil,'NO_GAME_DATABASE'end
 if D.DB:exec("CREATE TABLE IF NOT EXISTS lsd.Game0AuxiliarySelection(id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL,variant TEXT NOT NULL CHECK(variant IN ('defence','cargo','mobility')),destination TEXT NOT NULL)")<0 then return nil,'SCHEMA_FAILED'end
 return setmetatable({},Store)
end
function Store:load()
 local rows=D.DB:query('SELECT schemaVersion,variant,destination FROM lsd.Game0AuxiliarySelection WHERE id=1')
 if not rows then return nil,'READ_FAILED'end
 if not rows[1]then return {recorded=false}end
 local r=rows[1]
 if r[1]~=1 or not variants[r[2]]or type(r[3])~='string'then return nil,'INCOMPATIBLE_AUXILIARY_SAVE'end
 return {recorded=true,variant=r[2],destination=r[3]}
end
function Store:saveAsync(variant,destination)
 if not variants[variant]then return false,'INVALID_VARIANT'end
 if destination~='AbandonedCity'and destination~='Factory'and destination~='final-preparation'then return false,'INVALID_DESTINATION'end
 local current,why=self:load();if not current then return false,why end
 if self.busy then return false,'BUSY'end;self.busy=true
 local ok=D.DB:transactionAsync({{'INSERT OR REPLACE INTO lsd.Game0AuxiliarySelection VALUES(1,1,?,?)',{{variant,destination}}}})
 self.busy=false;if not ok then return false,'WRITE_FAILED'end
 return true
end
return Store
