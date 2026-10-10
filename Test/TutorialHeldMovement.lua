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
local reportPath = Dora.Path(root, "Test", "tutorial-held-movement.txt")
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

        local function findMove(node)
          if node.move and node.weapon then return node.move end
          if node.children then
            local found
            node.children:each(function(child) found=findMove(child);return found~=nil end)
            return found
          end
        end
        local move=assert(findMove(Dora.Director.ui3D),'HUD movement not found')
        -- Drive the original HUD slots. These are engine inputs, not OS events.
        move:emit('Left',true);Dora.sleep(.3);move:emit('Left',false)
        local deadline=Dora.App.runningTime+60
        while enemy.hp and enemy.hp>0 do
          assert(Dora.App.runningTime<deadline,'Tutorial enemy did not die')
          Dora.emit('Skill.Began');Dora.sleep(.05);Dora.emit('Skill.Ended');Dora.sleep(.6)
        end
        Dora.sleep(9)
        local x0=player.unit.x
        move:emit('Right',true);Dora.sleep(2);move:emit('Right',false)
        local x1=player.unit.x
        assert(x1-x0>150,'Held right did not move forward: '..(x1-x0))
        Dora.sleep(.3);local stopped=player.unit.x;Dora.sleep(.5)
        assert(math.abs(player.unit.x-stopped)<2,'Released input kept moving')
        move:emit('Left',true);Dora.sleep(2);move:emit('Left',false)
        local x2=player.unit.x
        assert(x1-x2>150,'Held left did not move backward: '..(x1-x2))
        Dora.sleep(.3)
        Dora.Content:save(root..'/Test/tutorial-held-movement-result.json',Dora.json.encode({status='PASS',inputMethod='engine HUD slots',enemyDefeated=true,rightDistance=x1-x0,leftDistance=x1-x2,releaseStops=true},false,true))
        return 'PASS heldRightAndLeft=true releaseStops=true'

	end)
	local report = "LSD_TUTORIAL_INPUT_" .. (ok and result or "FAIL " .. tostring(result)) .. " runId=" .. runId .. " character=charF"
	if not ok then Dora.Content:save(root..'/Test/tutorial-held-movement-result.json',Dora.json.encode({status='FAIL',error=tostring(result)},false,true))end
	print(report)
	Dora.Content:save(reportPath, report .. "\n")
end)
