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
local reportPath = Dora.Path(root, "Test", "tutorial-diagnostic.txt")
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
        Dora.emit("HUD.DisplayMove",true);Dora.emit("Tutorial.Weapon")
        local trace={status='AWAITING_NATIVE_INPUT',events={},samples={}}
        local node=Dora.Node();node:addTo(Dora.Director.ui3D)
        for _,name in ipairs({'Skill.Began','Skill.Ended','AppEvent'})do node:gslot(name,function(value)
          trace.events[#trace.events+1]={event=name,value=value,time=Dora.App.runningTime}
        end)end
        for i=1,90 do
          trace.samples[#trace.samples+1]={time=Dora.App.runningTime,x=player.unit.x,faceRight=player.unit.faceRight,skill=player.keySkill,kinetic=player.unit:isDoing('kinetic'),hp=enemy.hp,ap=enemy.ap,speed=player.unit.playable.speed}
          Dora.Content:save(root..'/Test/tutorial-native-trace.json',Dora.json.encode(trace,false,true))
          Dora.sleep(1)
        end
        return 'PASS diagnostic observation completed'

	end)
	local report = "LSD_TUTORIAL_INPUT_" .. (ok and result or "FAIL " .. tostring(result)) .. " runId=" .. runId .. " character=charF"
	print(report)
	Dora.Content:save(reportPath, report .. "\n")
 Dora.Content:save(root.."/Test/tutorial-native-diagnostic-result.json",Dora.json.encode({status=ok and "PASS" or "FAIL",report=report},false,true))
end)
