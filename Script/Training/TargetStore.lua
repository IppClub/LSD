-- Part selection has separate adopted/previous slots from combat actions.
local D=require('Dora');local Policy=require('Training.TargetPolicy')
local S={};S.__index=S
local function validate(e,id)
 if type(e)~='table' or e.schemaVersion~=1 or e.characterId~=id or type(e.revision)~='number' or e.revision%1~=0 or e.revision<1 or e.revision>1000000000 then return false end
 if not Policy.validate(e.adopted,id,'dataotie')then return false end
 return not e.previous or Policy.validate(e.previous,id,'dataotie')
end
local function future(e)
 if type(e)~='table'then return false end
 if e.schemaVersion~=1 then return true end
 for _,m in pairs({e.adopted,e.previous})do
  if type(m)=='table' and m.q and not require('Training.PartQ').compatible(m.q)then return true end
  if type(m)=='table' and (m.schemaVersion~=1 or m.purpose~='part-target' or m.partSetVersion~=1 or m.weapon~='emp' or m.enemyAsset~='dataotie' or (type(m.tree)=='table' and (m.tree.schemaVersion~=1 or (m.tree.featureSchemaVersion~=3 and m.tree.featureSchemaVersion~=4) or m.tree.actionSetVersion~=1)))then return true end
 end
 return false
end
function S.open(characterId)
 local c=require('Training.Characters')[characterId];if not c then return nil,'UNKNOWN_CHARACTER'end
 if not D.DB:existDB('lsd')then return nil,'NO_GAME_DATABASE'end
 local self=setmetatable({characterId=characterId,tableName='lsd.Game0TargetTraining'..c.tableSuffix,revision=0},S)
 if D.DB:exec('CREATE TABLE IF NOT EXISTS '..self.tableName..' (slot TEXT PRIMARY KEY NOT NULL,payload TEXT NOT NULL)')<0 then return nil,'SCHEMA_FAILED'end
 self.traceTable='lsd.Game0TargetRuns'..c.tableSuffix
 if D.DB:exec('CREATE TABLE IF NOT EXISTS '..self.traceTable..' (id TEXT PRIMARY KEY NOT NULL,payload TEXT NOT NULL)')<0 then return nil,'SCHEMA_FAILED'end
 return self
end
function S:loadTrace(policy)
 if not policy or not policy.traceId then return nil,'LEGACY_NO_TRACE'end
 local rows=D.DB:query('SELECT payload FROM '..self.traceTable..' WHERE id=?',{policy.traceId})
 if not rows or #rows~=1 or type(rows[1][1])~='string' or #rows[1][1]>2097152 then return nil,'TRACE_MISSING'end
 local trace=D.json.decode(rows[1][1],64)
 local ok,why=require('Training.TargetTrace').validate(trace,policy)
 if not ok then return nil,why end
 return trace
end
function S:load()
 local rows=D.DB:query('SELECT slot,payload FROM '..self.tableName);if not rows then return nil,'READ_FAILED'end
 self.loaded=true;self.writeBlocked=false;self.badMain=false;self.good=nil;self.revision=0
 local data={};for _,row in ipairs(rows)do data[row[1]]=row[2]end
 for _,slot in ipairs({'main','backup'})do
  local raw=data[slot]
  if raw then
   local e=type(raw)=='string' and #raw<=262144 and D.json.decode(raw,32) or nil
   if future(e)then self.writeBlocked=true end
   if validate(e,self.characterId)then self.revision=e.revision;self.good=D.json.decode(raw,32);return e,slot=='main' and 'LOADED' or 'RECOVERED_BACKUP'end
   if slot=='main'then self.badMain=true end
  end
 end
 return nil,next(data) and 'CORRUPT_TARGET_SAVE' or 'NEW_PROFILE'
end
function S:saveAsync(adopted,previous,trace)
 if not self.loaded then return false,'LOAD_REQUIRED'end
 if self.writeBlocked then return false,'INCOMPATIBLE_SAVE_READ_ONLY'end
 local e={schemaVersion=1,characterId=self.characterId,revision=self.revision+1,adopted=adopted,previous=previous}
 if not validate(e,self.characterId)then return false,'INVALID_TARGET_SAVE'end
 local raw=D.json.encode(e,false,true);if not raw or #raw>262144 then return false,'SAVE_TOO_LARGE'end
 local sql={}
 for _,policy in pairs({adopted,previous})do
  if policy.traceId then
   local existing=self:loadTrace(policy)
   if not existing then
    if policy~=adopted or not trace then return false,'TRACE_REQUIRED'end
    local ok,why=require('Training.TargetTrace').validate(trace,policy);if not ok then return false,why end
    local payload=D.json.encode(trace,false,true);if not payload or #payload>2097152 then return false,'TRACE_TOO_LARGE'end
    -- Never replace historical evidence under an existing identifier.
    local rows=D.DB:query('SELECT id FROM '..self.traceTable..' WHERE id=?',{policy.traceId})
    if not rows or #rows>0 then return false,'TRACE_CONFLICT'end
    sql[#sql+1]={'INSERT INTO '..self.traceTable..' VALUES (?,?)',{{policy.traceId,payload}}}
   end
  end
 end
 if self.badMain then sql[#sql+1]="INSERT OR REPLACE INTO "..self.tableName.." SELECT 'quarantine',payload FROM "..self.tableName.." WHERE slot='main'"end
 if self.good then sql[#sql+1]={"INSERT OR REPLACE INTO "..self.tableName.." VALUES (?,?)",{{'backup',D.json.encode(self.good,false,true)}}}end
 sql[#sql+1]={"INSERT OR REPLACE INTO "..self.tableName.." VALUES (?,?)",{{'main',raw}}}
 if not D.DB:transactionAsync(sql)then return false,'WRITE_FAILED'end
 self.revision=e.revision;self.good=D.json.decode(raw,32);self.badMain=false;return true
end
return S
