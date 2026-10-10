-- Engine test: scripted player requests, real UnitAction acceptance/projectiles,
-- native C4.5 and held-out arena trial. Not a manual-input acceptance result.
local D = require("Dora")
local root = D.Path:getPath(D.Path:getScriptPath(...))
for _, path in ipairs({root, D.Path(root,"Script"), D.Path(root,"Spine"), D.Path(root,"Image"), D.Path(root,"Font")}) do
	D.Content:insertSearchPath(1,path)
end
local path = D.Path(root,"Test","training-arena-result.txt")
D.Content:save(path,"LSD_TRAINING_ARENA_RUNNING\n")
local database = D.Path(D.Content.writablePath,"lsd-game0-training-qa-"..os.time()..".db")
assert(not D.Content:exist(database),"QA database collision")
assert(not D.DB:existDB("lsd"),"Another game owns the schema")
assert(D.DB:exec("ATTACH DATABASE '"..database:gsub("'","''").."' AS lsd"))
D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
D.thread(function()
	local ok, result = xpcall(function()
		local Progress = require("Training.Progress")
		assert(Progress.load())
		local arena = require("Training.Arena").createAsync({scene="VRTraining"})
		local function demonstrate()
			D.sleep(1)
			assert(arena.student.onSurface,"Student not grounded")
			for _, distance in ipairs({320,380,440,500}) do
				arena.enemy.x = arena.student.x + distance
				assert(arena:request("laser","demo"),"Real shooting request rejected")
				local count = #arena.recorder.samples
				assert(not arena:request("laser","demo"),"Cooldown accepted a second shot")
				assert(#arena.recorder.samples == count,"Rejected shot became a label")
				D.sleep(1.1)
			end
			assert(arena.metrics.hits >= 3,"Real projectiles failed to hit")
			for _, distance in ipairs({650,740,820}) do
				arena.enemy.x = arena.student.x + distance
				assert(arena:request("fmove","demo"),"Real movement rejected")
				D.sleep(0.15)
				arena.student:stop()
			end
			assert(arena.recorder.counts.laser == 4 and arena.recorder.counts.fmove == 3,"Action distribution")
		end
		assert(not arena:finishDemoAsync(),"Empty demonstration built a candidate")
		arena:beginDemo()
		demonstrate()
		local model, err = arena:finishDemoAsync()
		assert(model,err)
		assert(arena:beginTrial(530),"Held-out trial did not start")
		local deadline = D.App.runningTime + 38
		while arena.mode == "trial" and D.App.runningTime < deadline do D.sleep(0.1) end
		assert(arena.result and arena.result.won,"Learned model did not win held-out real battle")
		assert(arena.result.metrics.modelActions >= 5,"Model did not drive accepted attacks")
		assert(arena.result.metrics.fallback == 0,"Fallback drove the result")
		local evaluation = assert(arena:evaluateAsync())
		assert(#evaluation.candidate == 3,"Fixed trial matrix incomplete")
		for _, round in ipairs(evaluation.candidate) do assert(round.won,"Evaluation trial failed") end
		assert(arena:adopt(),"Candidate adoption failed")
		assert(Progress.saveAsync(arena.adopted,arena.previous),"First adoption not saved")
		local adopted = arena.adopted
		arena:beginDemo()
		arena:discard()
		assert(arena.adopted == adopted,"Discard erased adopted model")
		arena:beginDemo()
		demonstrate()
		local second = assert(arena:finishDemoAsync())
		assert(not arena:adopt(),"Unevaluated candidate was adopted")
		local comparison = assert(arena:evaluateAsync())
		assert(#comparison.candidate == 3 and #comparison.previous == 3,"Version comparison matrix incomplete")
		assert(arena:adopt() and arena.adopted == second and arena.previous == adopted,"Version history lost")
		assert(Progress.saveAsync(arena.adopted,arena.previous),"Second adoption not saved")
		assert(arena:rollback() and arena.adopted == adopted,"Rollback failed")
		assert(Progress.saveAsync(arena.adopted,arena.previous),"Rollback not saved")
		D.Content:save(D.Path(root,"Test","training-resume-fixture.txt"),database)
		return "PASS scene=VRTraining samples=" .. model.sampleCount .. " trials=" .. #evaluation.candidate .. " comparisonTrials=6 rollback=true" .. " realHits=" .. evaluation.candidate[1].metrics.hits .. " modelActions=" .. evaluation.candidate[1].metrics.modelActions .. " fallback=" .. evaluation.candidate[1].metrics.fallback
	end, debug.traceback)
	local report = "LSD_TRAINING_ARENA_" .. (ok and result or "FAIL " .. tostring(result))
	print(report); D.Content:save(path,report.."\n")
end)
