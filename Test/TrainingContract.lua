-- Pure data tests; engine BuildDecisionTreeAsync is verified separately.
local root = (... and ... ~= "") and ... or "."
package.path = root .. "/Script/?.lua;" .. package.path
local Recorder = require("Training.Recorder")
local Model = require("Training.Model")
local checks = 0
local function check(value, message)
	assert(value, message); checks = checks + 1
end
local function state(distance, threat)
	return {distance = distance, facing = "yes", enemyAction = threat or "idle", attackReady = "yes"}
end
local r = Recorder.new({characterId = "ninilite", actions = {"laser", "bmove", "idle"}, maxSamples = 4})
check(not r:toCSV(), "Empty demonstrations must not reach C4.5")
check(not r:record(state(100), "laser", false), "Rejected action not a label")
check(#r.samples == 0 and r.rejected == 1, "Rejected action counter")
check(not r:record(state(100), "injected", true), "Unknown action rejected")
check(not r:record(state(0/0), "laser", true), "NaN rejected")
check(r:record(state(100), "laser", true), "Successful action recorded")
check(r:record(state(100), "laser", true), "Separate successful shots retain frequency")
check(r:record(state(300), "bmove", true), "Different behavior recorded")
check(not r:record(state(300), "bmove", true), "Continuous identical movement remains bounded")
check(r:record(state(500), "idle", true), "Explicit wait can be learned")
check(not r:record(state(700), "idle", true), "Sample limit enforced")
local csv = assert(r:toCSV())
check(csv:find("N,C,C,C,C", 1, true), "Real engine column type row")
local rules = assert(Model.compileNodes({
	{depth = 0, name = "distance", op = "<=", value = "200"},
	{depth = 1, name = "", op = "return", value = "laser"},
	{depth = 0, name = "distance", op = ">", value = "200"},
	{depth = 1, name = "enemyAction", op = "==", value = "attack"},
	{depth = 2, name = "", op = "return", value = "bmove"},
	{depth = 1, name = "enemyAction", op = "==", value = "idle"},
	{depth = 2, name = "", op = "return", value = "idle"},
}, r.actions))
local model = {schemaVersion = 1, featureSchemaVersion = 1, actionSetVersion = 1, characterId = "ninilite", actions = {"laser","bmove","idle"}, sampleCount=3, trainingAccuracy=1, rules = rules}
check(Model.predict(model, state(100)) == "laser", "Near target prediction")
check(Model.predict(model, state(500, "attack")) == "bmove", "Nested categorical branch")
check(Model.predict(model, state(500)) == "idle", "Sibling branch resets previous condition")
local action, why = Model.predict(model, state(100), function() return false end)
check(action == nil and why == "ACTION_UNAVAILABLE", "Illegal actions use explicit fallback")
check(not Model.compileNodes({{depth = 0, op = "return", value = "os_execute"}}, r.actions), "Tree action whitelist")
check(not Model.compileNodes({{depth = 2, name = "distance", op = ">", value = "5"}}, r.actions), "Malformed depth rejected")
model.featureSchemaVersion = 99
check(not Model.predict(model, state(100)), "Incompatible feature version")
model.featureSchemaVersion = 1
check(not Model.validate(model,"charF"),"Wrong character cannot reuse a tree")
model.rules[1].action = "os_execute"
check(not Model.predict(model,state(100)),"Unknown persisted leaf rejected")
model.rules[1].action = "laser"
model.rules[1].conditions[1].value = 0/0
check(not Model.predict(model,state(100)),"Malformed persisted numeric condition rejected")
model.rules[1].conditions[1].value = 200
local validRules = model.rules
model.rules = "broken"
check(not Model.predict(model,state(100)),"Wrong rules type returns an error instead of throwing")
model.rules = validRules
model.actions[5] = "idle"
check(not Model.validate(model),"Sparse action array rejected")
model.actions[5] = nil
r:stop()
check(not r:record(state(100), "laser", true), "Stopped session cannot record")

local bandModel={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId="ninilite",actions={"bmove","laser","fmove"},sampleCount=18,trainingAccuracy=1,rules={
 {conditions={{name="distanceBand",op="==",value="near"}},action="bmove"},
 {conditions={{name="distanceBand",op="==",value="mid"}},action="laser"},
 {conditions={{name="distanceBand",op="==",value="far"}},action="fmove"}}}
check(Model.predict(bandModel,state(220))=="bmove" and Model.predict(bandModel,state(420))=="laser" and Model.predict(bandModel,state(680))=="fmove","Derived range bands")
bandModel.featureSchemaVersion=1
check(not Model.validate(bandModel),"Version 1 cannot claim version 2 features")
print("LSD_TRAINING_CONTRACT_PASS "..checks)
