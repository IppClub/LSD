-- Records successful player demonstrations, not attempted keyboard presses.
local Extra=require("Training.CombatFeatures")
local Parts=require("Training.PartFeatures")
local Recorder = {}
Recorder.__index = Recorder
Recorder.schemaVersion = 3
function Recorder.distanceBand(distance)
 return distance<=330 and "near" or distance<=650 and "mid" or "far"
end
Recorder.features = {"distance", "facing", "enemyAction", "attackReady", "distanceBand"}
for _,name in ipairs(Extra.names)do Recorder.features[#Recorder.features+1]=name end
local categories = {
	facing = {yes = true, no = true},
	enemyAction = {idle = true, attack = true, recover = true},
	attackReady = {yes = true, no = true},
}

local function finite(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Recorder.validateFeatures(state,version)
	if type(state) ~= "table" or not finite(state.distance) or state.distance < 0 or state.distance > 100000 then
		return false, "INVALID_DISTANCE"
	end
	for name, allowed in pairs(categories) do
		if not allowed[state[name]] then return false, "INVALID_" .. name end
	end
	if state.distanceBand~=nil and state.distanceBand~=Recorder.distanceBand(state.distance) then return false,"INVALID_distanceBand" end
 local ok,why=Extra.validate(state);if not ok then return false,why end
 if version==4 then return Parts.validate(state)end
 return true
end

function Recorder.new(options)
	options = options or {}
	assert(type(options.characterId) == "string" and options.characterId ~= "", "characterId required")
	local actions = {}
	for _, action in ipairs(options.actions or {}) do
		assert(type(action) == "string" and action:match("^[%w_]+$") and #action <= 64, "Invalid action ID")
		actions[action] = true
	end
	assert(next(actions), "At least one legal action required")
	local limit = options.maxSamples or 1500
	assert(finite(limit) and limit >= 1 and limit <= 10000 and limit % 1 == 0, "Invalid sample limit")
 local version=options.featureSchemaVersion or Recorder.schemaVersion;assert(version==3 or version==4,'Invalid recorder version')
 local features={};for _,name in ipairs(Recorder.features)do features[#features+1]=name end
 if version==4 then for _,name in ipairs(Parts.names)do features[#features+1]=name end end
	return setmetatable({schemaVersion=version,features=features,characterId = options.characterId, actions = actions, maxSamples = limit,
		samples = {}, counts = {}, active = true, rejected = 0}, Recorder)
end

function Recorder:record(state, action, actionSucceeded)
	if not self.active then return false, "STOPPED" end
	if actionSucceeded ~= true then self.rejected = self.rejected + 1; return false, "ACTION_REJECTED" end
	if not self.actions[action] then return false, "UNKNOWN_ACTION" end
	local valid, message = Recorder.validateFeatures(state,self.schemaVersion)
	if not valid then return false, message end
	if #self.samples >= self.maxSamples then return false, "SAMPLE_LIMIT" end
	local keys={string.format("%.2f",state.distance),state.facing,state.enemyAction,state.attackReady,action}
 for _,name in ipairs(Extra.names)do keys[#keys+1]=Extra.value(state,name)end
 if self.schemaVersion==4 then for _,name in ipairs(Parts.names)do keys[#keys+1]=Parts.value(state,name)end end
 local key=table.concat(keys,"|")
	-- Each accepted shot is a separate demonstration, even in the same state.
	-- Continuous movement/waiting still deduplicate adjacent states.
	if action ~= "laser" and action ~= "melee" and key == self.lastKey then return false, "DUPLICATE" end
	self.samples[#self.samples + 1] = {distance = state.distance, facing = state.facing,
		enemyAction = state.enemyAction, attackReady = state.attackReady, distanceBand=Recorder.distanceBand(state.distance), action = action}
	local sample=self.samples[#self.samples];for _,name in ipairs(Extra.names)do sample[name]=Extra.value(state,name)end
 if self.schemaVersion==4 then for _,name in ipairs(Parts.names)do sample[name]=Parts.value(state,name)end end
 self.lastKey = key
	self.counts[action] = (self.counts[action] or 0) + 1
	return true
end

function Recorder:stop() self.active = false end

function Recorder:toCSV()
	if #self.samples == 0 then return nil, "NO_SAMPLES" end
 local header={};local types={}
 for _,name in ipairs(self.features)do header[#header+1]=name;types[#types+1]=name=='distance' and 'N' or 'C'end
 header[#header+1]='action';types[#types+1]='C'
 local rows={table.concat(header,','),table.concat(types,',')}
 for _,sample in ipairs(self.samples)do
  local values={}
  for _,name in ipairs(self.features)do values[#values+1]=name=='distance' and string.format('%.6f',sample.distance) or name=='distanceBand' and Recorder.distanceBand(sample.distance) or sample[name] or 'unknown'end
  values[#values+1]=sample.action;rows[#rows+1]=table.concat(values,',')
 end
	return table.concat(rows, "\n")
end

return Recorder
