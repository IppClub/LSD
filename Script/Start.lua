local _ENV = Dora
local DB <const> = DB
local Path <const> = Path
local Content <const> = Content
local tostring <const> = tostring
local Director <const> = Director
local once <const> = once
local require <const> = require
if not DB:existDB("lsd") then
	local dbPath = Path(Content.writablePath, "lsd.db")
	DB:exec("ATTACH DATABASE '" .. tostring(dbPath) .. "' AS lsd;")
end
Director.entry:slot("Cleanup", function()
	if DB:existDB("lsd") then
		return DB:exec("DETACH DATABASE lsd")
	end
end)
return Director.entry:schedule(once(function()
	local Config = require("Data.Config")
	Config:loadAsync()
	if Config.char == nil then
		Config.char = "charM"
	end
	if Config.charName == nil then
		Config.charName = "匿名玩家"
	end
	if Config.heroine == nil then
		Config.heroine = "于灵"
	end
	local tutorialDone = Config.tutorialCompleted == 1 or Config.tutorialCompleted == true
	if not tutorialDone and (Config.skipOP == nil or Config.skipOP == 0) then
		local PlayOP = require("System.PlayOP")
		PlayOP()
		Config.skipOP = 1
	end
	if tutorialDone then
		local storyService = require("Story.Service").open()
		local facts = storyService and storyService:summary()
		if facts and facts.completed["final-betrayal"] then
			local mission, err = require("Mission.Service").open()
			if not (mission and mission:recoverAsync()) then
				require("UI.ResumeProblem")(err or "MISSION_RECOVERY_FAILED")
				return
			end
			local hub
			hub, err = require("Ending.Hub").openAsync("records")
			if not hub then
				require("UI.ResumeProblem")(err)
			end
			return
		end
		local chapterThreeScene = facts and require("Story.ChapterThreeResume").scene(facts)
		if chapterThreeScene then
			local mission, err = require("Mission.Service").open()
			if not (mission and mission:recoverAsync()) then
				require("UI.ResumeProblem")(err or "MISSION_RECOVERY_FAILED")
				return
			end
			require("Academy.Navigation").returnToRoomAsync(chapterThreeScene)
			return
		end
		local infiltrationOptions, resumeError = nil, nil
		if facts then
			infiltrationOptions, resumeError = require("Story.InfiltrationStore").resumeOptions(facts)
		end
		if resumeError then
			require("UI.ResumeProblem")(resumeError)
			return
		end
		local foxOptions = infiltrationOptions or facts and require("Story.FoxTrailResume").options(facts)
		if foxOptions then
			require("Mission.Service").open():recoverAsync()
			require("Academy.Navigation").returnToRoomAsync(foxOptions.scene, foxOptions)
			return
		end
		if facts and facts.mission.unlocks["ruins-diversion-complete"] and not facts.completed["fox-trail-return"] then
			require("Mission.Service").open():recoverAsync()
			require("Academy.Navigation").returnToRoomAsync("OuterHeaven", {
				spawn = 1800,
				valleyVisit = true
			})
			return
		end
		local ArriveLevel = require("Academy.Level.Arrive")
		return ArriveLevel()
	else
		local TutorialLevel = require("Tutorial.Level")
		return TutorialLevel()
	end
end))
