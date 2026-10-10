-- Namespaced, transactional training saves in the already-attached game DB.
-- Main and backup envelopes are both validated before any model is used.
local D = require("Dora")
local Model = require("Training.Model")
local Store = {}
Store.__index = Store
local Characters=require("Training.Characters")
local function validate(envelope,character)
	if type(envelope)~="table" or envelope.schemaVersion~=1 or type(envelope.revision)~="number" or envelope.revision%1~=0 or envelope.revision<0 or envelope.revision>1000000000 then return false,"INCOMPATIBLE_SAVE" end
	if envelope.characterId and envelope.characterId~=character.id then return false,"INCOMPATIBLE_CHARACTER" end
	if not envelope.adopted then return false,"MISSING_MODEL" end
	local ok, err = Model.validate(envelope.adopted,character.id,character.legal)
	if not ok then return false,err end
	if envelope.previous then return Model.validate(envelope.previous,character.id,character.legal) end
	return true
end

function Store.open(schema,characterId)
	schema = schema or "lsd"
 local character=Characters[characterId or "ninilite"]; if not character then return nil,"UNKNOWN_CHARACTER" end
	assert(schema:match("^[%a_][%w_]*$"),"Invalid training schema")
	if not D.DB:existDB(schema) then return nil,"NO_GAME_DATABASE" end
	local self = setmetatable({tableName=schema..".Game0Training"..character.tableSuffix, traceTable=schema..".Game0TrainingRuns"..character.tableSuffix, character=character, revision=0},Store)
	if D.DB:exec("CREATE TABLE IF NOT EXISTS "..self.tableName.." (slot TEXT PRIMARY KEY NOT NULL, payload TEXT NOT NULL)") < 0 then return nil,"SCHEMA_FAILED" end
	if D.DB:exec("CREATE TABLE IF NOT EXISTS "..self.traceTable.." (id TEXT PRIMARY KEY NOT NULL, payload TEXT NOT NULL)")<0 then return nil,"SCHEMA_FAILED"end
	return self
end

function Store:load()
	local rows = D.DB:query("SELECT slot,payload FROM "..self.tableName)
	if not rows then return nil,"READ_FAILED" end
	self.loaded = true; self.writeBlocked = false; self.badMain = false
	local slots = {}
	for _, row in ipairs(rows) do slots[row[1]]=row[2] end
	local found = false
	for _, slot in ipairs({"main","backup"}) do
		local payload = slots[slot]
		if payload then
			found = true
			local envelope = type(payload)=="string" and #payload<=262144 and D.json.decode(payload,32) or nil
			if type(envelope)=="table" then
    if envelope.schemaVersion~=1 then self.writeBlocked=true end
    for _,model in pairs({adopted=envelope.adopted,previous=envelope.previous}) do
     if type(model)=="table" and (model.schemaVersion~=1 or not Model.featureVersions[model.featureSchemaVersion] or model.actionSetVersion~=1) then self.writeBlocked=true end
     if type(model)=='table' and model.algorithm~=nil and model.algorithm~='c45' then
      if model.algorithm~='qlearning' or not require('Training.QModel').compatible(model)then self.writeBlocked=true end
     end
    end
   end
			local ok = validate(envelope,self.character)
			if ok then
				self.revision = envelope.revision
				self.goodEnvelope = envelope
				return envelope,slot=="backup" and "RECOVERED_BACKUP" or "LOADED"
			end
			if slot=="main" then self.badMain = true end
		end
	end
	self.revision = 0; self.goodEnvelope = nil
	return nil,found and "CORRUPT_TRAINING_SAVE" or "NEW_PROFILE"
end

function Store:loadTrace(model)
 if type(model)~='table' or model.trainingRunId==nil then return nil,'NOT_RECORDED'end
 local T=require('Training.QTrace')
 if not T.validId(model.trainingRunId)then return nil,'INVALID_TRACE_ID'end
 local rows=D.DB:query('SELECT payload FROM '..self.traceTable..' WHERE id=?',{model.trainingRunId})
 if not rows then return nil,'READ_FAILED'end
 if not rows[1]then return nil,'TRACE_MISSING'end
 local payload=rows[1][1]
 if type(payload)~='string' or #payload>T.maxBytes then return nil,'INVALID_TRACE_PAYLOAD'end
 local trace=D.json.decode(payload,32);local ok,why=T.validate(trace,model);if not ok then return nil,why end
 return trace
end
function Store:saveAsync(adopted, previous, trace)
	if not self.loaded then return false,"LOAD_REQUIRED" end
	if self.writeBlocked then return false,"INCOMPATIBLE_SAVE_READ_ONLY" end
	local envelope = {schemaVersion=1,revision=self.revision+1,characterId=self.character.id,adopted=adopted,previous=previous}
	local ok, err = validate(envelope,self.character)
	if not ok then return false,err end
	local payload, encodeError = D.json.encode(envelope,false,true)
	if not payload or #payload>262144 then return false,encodeError or "SAVE_TOO_LARGE" end
 local sqls = {}
 local newTrace
 for _,model in pairs({adopted=adopted,previous=previous})do
  if model.trainingRunId then
   local recorded,why=self:loadTrace(model)
   if not recorded then
    if why~='TRACE_MISSING' then return false,why end
    if not trace or trace.id~=model.trainingRunId then return false,'TRACE_REQUIRED'end
    local T=require('Training.QTrace');local valid,err=T.validate(trace,model);if not valid then return false,err end
    local data=D.json.encode(trace,false,true);if not data or #data>T.maxBytes then return false,'TRACE_TOO_LARGE'end
    if not newTrace then sqls[#sqls+1]={"INSERT INTO "..self.traceTable.." (id,payload) VALUES (?,?)",{{trace.id,data}}};newTrace=trace.id end
   end
  end
 end
	if self.badMain then
		sqls[#sqls+1] = "INSERT OR REPLACE INTO "..self.tableName.." (slot,payload) SELECT 'quarantine',payload FROM "..self.tableName.." WHERE slot='main'"
	end
	-- Keep the last validated state, not a potentially corrupt primary row.
	if self.goodEnvelope then
		local backup = assert(D.json.encode(self.goodEnvelope,false,true))
		sqls[#sqls+1] = {"INSERT OR REPLACE INTO "..self.tableName.." (slot,payload) VALUES (?,?)",{{"backup",backup}}}
	end
	sqls[#sqls+1] = {"INSERT OR REPLACE INTO "..self.tableName.." (slot,payload) VALUES (?,?)",{{"main",payload}}}
	if not D.DB:transactionAsync(sqls) then return false,"WRITE_FAILED" end
	self.revision = envelope.revision; self.goodEnvelope = envelope
	self.badMain = false
	return true
end

return Store
