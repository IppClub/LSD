-- Declarative C4.5 rules. No generated Lua or arbitrary expressions are run.
local Extra=require("Training.CombatFeatures")
local Parts=require("Training.PartFeatures")
local Recorder = require("Training.Recorder")
local Model = {schemaVersion = 1, actionSetVersion = 1, featureVersions={[1]=true,[2]=true,[3]=true,[4]=true}}
local allowedFeatures = {distance = true, facing = true, enemyAction = true, attackReady = true, distanceBand=true}
local allowedOps = {["<="] = true, [">"] = true, ["=="] = true}
local categories = {distanceBand={near=true,mid=true,far=true},facing = {yes=true,no=true}, enemyAction = {idle=true,attack=true,recover=true}, attackReady = {yes=true,no=true}}
for name,values in pairs(Extra.categories)do allowedFeatures[name]=true;categories[name]=values end
for name,values in pairs(Parts.categories)do allowedFeatures[name]=true;categories[name]=values end
local function finite(value) return type(value)=="number" and value==value and math.abs(value)~=math.huge end
local function array(value, limit, empty)
	if type(value) ~= "table" or #value > limit or (not empty and #value == 0) then return false end
	local count = 0
	for key in pairs(value) do
		if type(key) ~= "number" or key%1~=0 or key<1 or key>#value then return false end
		count = count + 1
	end
	return count == #value
end

function Model.validate(model, characterId, legalActions)
	if type(model)=='table' and model.algorithm=='qlearning' then return require('Training.QModel').validate(model,characterId,legalActions)end
	if type(model)=='table' and model.algorithm~=nil and model.algorithm~='c45' then return false,'INCOMPATIBLE_MODEL'end
	if type(model)~="table" or model.schemaVersion~=Model.schemaVersion or not Model.featureVersions[model.featureSchemaVersion] or model.actionSetVersion~=Model.actionSetVersion then return false,"INCOMPATIBLE_MODEL" end
	if type(model.characterId)~="string" or model.characterId=="" or (characterId and model.characterId~=characterId) then return false,"INCOMPATIBLE_CHARACTER" end
	if not finite(model.sampleCount) or model.sampleCount%1~=0 or model.sampleCount<1 or model.sampleCount>10000 or not finite(model.trainingAccuracy) or model.trainingAccuracy<0 or model.trainingAccuracy>1 then return false,"INVALID_SUMMARY" end
	if not array(model.actions,64,false) or not array(model.rules,512,false) then return false,"INVALID_RULES" end
	local actions = {}
	for _, action in ipairs(model.actions) do
		if type(action)~="string" or not action:match("^[%w_]+$") or #action>64 or actions[action] or (legalActions and not legalActions[action]) then return false,"UNKNOWN_ACTION" end
		actions[action] = true
	end
	for _, rule in ipairs(model.rules) do
		if type(rule)~="table" or not actions[rule.action] or not array(rule.conditions,12,true) then return false,"INVALID_RULE" end
		for _, condition in ipairs(rule.conditions) do
			if type(condition)~="table" or not allowedFeatures[condition.name] or not allowedOps[condition.op] then return false,"INVALID_CONDITION" end
			if Parts.categories[condition.name] and model.featureSchemaVersion<4 then return false,"INCOMPATIBLE_FEATURE" end
			if Extra.categories[condition.name] and model.featureSchemaVersion<3 then return false,"INCOMPATIBLE_FEATURE" end
   if condition.name=="distanceBand" and model.featureSchemaVersion==1 then return false,"INCOMPATIBLE_FEATURE" end
			if condition.name=="distance" then
				if not finite(condition.value) or condition.value<0 or condition.value>100000 then return false,"INVALID_NUMBER" end
			elseif condition.op~="==" or not categories[condition.name][condition.value] then return false,"INVALID_CATEGORY" end
		end
	end
	return true
end

function Model.compileNodes(nodes, actions)
	local path, rules = {}, {}
	for _, node in ipairs(nodes) do
		local depth = node.depth
		if type(depth) ~= "number" or depth < 0 or depth > 12 or depth % 1 ~= 0 then return nil, "INVALID_DEPTH" end
		if node.op == "return" then
			if not actions[node.value] then return nil, "UNKNOWN_ACTION" end
			local conditions = {}
			for i = 1, depth do
				if not path[i] then return nil, "MISSING_PARENT" end
				local p = path[i]
				conditions[i] = {name = p.name, op = p.op, value = p.value}
			end
			rules[#rules + 1] = {conditions = conditions, action = node.value}
			if #rules > 512 then return nil, "MODEL_TOO_LARGE" end
		else
			if not allowedFeatures[node.name] or not allowedOps[node.op] then return nil, "INVALID_CONDITION" end
			local value = node.value
			if node.name == "distance" then
				value = tonumber(value)
				if not value or value ~= value or math.abs(value) == math.huge then return nil, "INVALID_NUMBER" end
			elseif node.op ~= "==" then return nil, "INVALID_CATEGORY_OPERATOR" end
			for i = 1, depth do if not path[i] then return nil, "MISSING_PARENT" end end
			for i = #path, depth + 1, -1 do path[i] = nil end
			path[depth + 1] = {name = node.name, op = node.op, value = value}
		end
	end
	if #rules == 0 then return nil, "EMPTY_MODEL" end
	return rules
end

function Model.buildAsync(recorder)
	local csv, err = recorder:toCSV()
	if not csv then return nil, err end
	local nodes = {}
	local accuracy, buildError = require("Dora").ML.BuildDecisionTreeAsync(csv, 5, function(depth, name, op, value)
		nodes[#nodes + 1] = {depth = depth, name = name, op = op, value = value}
	end)
	if not accuracy then return nil, buildError or "BUILD_FAILED" end
	local rules, parseError = Model.compileNodes(nodes, recorder.actions)
	if not rules then return nil, parseError end
	local actions = {}
	for action in pairs(recorder.actions) do actions[#actions + 1] = action end
	table.sort(actions)
	return {schemaVersion = Model.schemaVersion, featureSchemaVersion = recorder.schemaVersion,
		actionSetVersion = Model.actionSetVersion,
		characterId = recorder.characterId, actions = actions, rules = rules,
		sampleCount = #recorder.samples, trainingAccuracy = accuracy}
end

function Model.predict(model, state, isAvailable)
	if type(model)=='table' and model.algorithm=='qlearning' then return require('Training.QModel').predict(model,state,isAvailable)end
	local validModel, modelError = Model.validate(model)
	if not validModel then return nil, modelError end
	local valid, err = Recorder.validateFeatures(state,model.featureSchemaVersion)
	if not valid then return nil, err end
	for _, rule in ipairs(model.rules) do
		local matched = true
		for _, condition in ipairs(rule.conditions) do
			local value = condition.name=="distanceBand" and Recorder.distanceBand(state.distance) or (Parts.categories[condition.name] and Parts.value(state,condition.name) or Extra.categories[condition.name] and Extra.value(state,condition.name) or state[condition.name])
			if condition.op == "==" then matched = value == condition.value
			elseif condition.op == "<=" then matched = type(value) == "number" and value <= condition.value
			elseif condition.op == ">" then matched = type(value) == "number" and value > condition.value
			else return nil, "INVALID_CONDITION" end
			if not matched then break end
		end
		if matched then
			if isAvailable and not isAvailable(rule.action) then return nil, "ACTION_UNAVAILABLE" end
			return rule.action, "MODEL"
		end
	end
	return nil, "NO_MATCH"
end

return Model
