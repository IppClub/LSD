-- Engine-level replay through real story buttons and skill events.
-- This supplements manual UI play; it is not a human-input/platform test.
local Dora = require("Dora")
local Platformer = Dora.Platformer
local root = Dora.Path:getPath(Dora.Path:getScriptPath(...))
for _, path in ipairs({root, Dora.Path(root, "Script"), Dora.Path(root, "Spine"), Dora.Path(root, "Image"), Dora.Path(root, "Font")}) do
	Dora.Content:insertSearchPath(1, path)
end
assert(not Dora.DB:existDB("lsd"), "Another LSD session is already using the schema")
local runId = tostring(os.time())
local reportPath = Dora.Path(root, "Test", "tutorial-input-result.txt")
local database = Dora.Path(Dora.Content.writablePath, "lsd-game0-tutorial-regression-qa-" .. runId .. ".db")
assert(not Dora.Content:exist(database), "Fresh tutorial QA database already exists")
assert(Dora.DB:exec("ATTACH DATABASE '" .. database:gsub("'", "''") .. "' AS lsd"))
-- Config owns the schema. Seed only this disposable test profile; replay the
-- tutorial itself rather than spending every regression run in the opening PV.
require("Data.Config")
assert(Dora.DB:exec("INSERT INTO lsd.Config (name, value_num, value_str) VALUES ('skipOP', 1, NULL), ('char', NULL, 'charF'), ('charName', NULL, 'StarRiver')"))
Dora.Content:save(reportPath, "LSD_TUTORIAL_INPUT_RUNNING runId=" .. runId .. "\n")
print("LSD_TUTORIAL_QA_DATABASE=" .. database)
require("Start")
Dora.thread(function()
	local ok, result = pcall(function()
		local group = Dora.Group({"player", "unit"})
		local player, enemy
		local deadline = Dora.App.runningTime + 70
		while Dora.App.runningTime < deadline do
			local children = Dora.Director.ui3D.children
			local story
			if children then children:each(function(node)
				if node._runner and node.visible then
					story = node
				end
			end) end
			-- Story completion removes its node; dispatch outside Array traversal.
			if story then
				if story._options and story.answerList.children.count > 0 then
					story.answerList.children.first:emit("Tapped")
				else Dora.emit("Story.Advance") end
			end
			group:each(function(e) if e.player then player = e; return true end end)
			Dora.Group({"monster", "unit"}):each(function(e) enemy = e; return true end)
			if player and enemy then break end
			Dora.sleep(0.5)
		end
		assert(player and enemy, "Tutorial entities not ready")
		Dora.emit("Skill.Began");Dora.sleep(.05);Dora.emit("Skill.Ended",true)
		local cancelDeadline=Dora.App.runningTime+.3
		while Dora.App.runningTime<cancelDeadline do assert(not player.unit:isDoing("kinetic"),"Cancelled tutorial aim fired");Dora.sleep()end
		assert(not player.unit:getChildByTag("aim").visible,"Cancelled preview remained visible")
		local before = enemy.hp
		-- Same release event as HUD/J key, with a short ordinary tap duration.
		Dora.emit("Skill.Began")
		Dora.sleep(0.05)
		Dora.emit("Skill.Ended")
		local started = false
		local actionDeadline = Dora.App.runningTime + 0.5
		while Dora.App.runningTime < actionDeadline do
			if player.unit:isDoing("kinetic") then started = true; break end
			Dora.sleep()
		end
		assert(started, "Short tap did not submit kinetic action")
		Dora.sleep(2)
		assert(enemy.hp < before, "Projectile did not reach the enemy")
		return "PASS cancelDidNotFire=true shortTapStarted=true hpBefore=" .. before .. " hpAfter=" .. enemy.hp
	end)
	local report = "LSD_TUTORIAL_INPUT_" .. (ok and result or "FAIL " .. tostring(result)) .. " runId=" .. runId .. " character=charF"
	print(report)
	Dora.Content:save(reportPath, report .. "\n")
end)
