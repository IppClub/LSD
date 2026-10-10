-- Exercises the real native C4.5 service; this is not a gameplay acceptance test.
local Dora = require("Dora")
local root = Dora.Path:getPath(Dora.Path:getScriptPath(...))
Dora.Content:insertSearchPath(1, Dora.Path(root, "Script"))
local Recorder = require("Training.Recorder")
local Model = require("Training.Model")
Dora.thread(function()
	local ok, result = pcall(function()
		local recorder = Recorder.new({characterId = "ninilite", actions = {"laser", "bmove", "idle"}})
		for distance = 50, 600, 25 do
			assert(recorder:record({distance = distance, facing = "yes", enemyAction = "idle", attackReady = "yes"},
				distance <= 200 and "laser" or "bmove", true))
		end
		local model, err = Model.buildAsync(recorder)
		assert(model, err)
		assert(Model.predict(model, {distance = 80, facing = "yes", enemyAction = "idle", attackReady = "yes"}) == "laser", "Near held-out input")
		assert(Model.predict(model, {distance = 470, facing = "yes", enemyAction = "idle", attackReady = "yes"}) == "bmove", "Far held-out input")
		assert(model.sampleCount == 23, "Sample count")
		return "PASS samples=" .. model.sampleCount .. " rules=" .. #model.rules .. " trainingAccuracy=" .. model.trainingAccuracy
	end)
	local report = "LSD_TRAINING_ENGINE_" .. (ok and result or "FAIL " .. tostring(result))
	print(report)
	Dora.Content:save(Dora.Path(root, "Test", "training-engine-result.txt"), report .. "\n")
end)
