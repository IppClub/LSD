-- [yue]: Script/Start.yue
local DB = dora.DB -- 1
local Path = dora.Path -- 1
local Content = dora.Content -- 1
local tostring = _G.tostring -- 1
local Director = dora.Director -- 1
local once = dora.once -- 1
if not DB:exist("Config", "lsd") then -- 3
	local dbPath = Path(Content.writablePath, "lsd.db") -- 4
	DB:exec("ATTACH DATABASE '" .. tostring(dbPath) .. "' AS lsd;") -- 5
end -- 3
Director.entry:slot("Cleanup", function() -- 6
	return DB:exec("DETACH DATABASE lsd") -- 6
end) -- 6
return Director.entry:schedule(once(function() -- 8
	local Config = require("Data.Config") -- 9
	Config:loadAsync() -- 10
	Config.skipOP = 0 -- 11
	Config.char = "charM" -- 12
	Config.charName = "瑾" -- 13
	Config.heroine = "于灵" -- 14
	if Config.skipOP == nil or Config.skipOP == 0 then -- 16
		Config.skipOP = 1 -- 17
		local PlayOP = require("System.PlayOP") -- 18
		PlayOP() -- 19
	end -- 16
	local TutorialLevel = require("Tutorial.Level") -- 21
	return TutorialLevel() -- 22
end)) -- 22
