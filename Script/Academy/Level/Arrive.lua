-- [yue]: Script/Academy/Level/Arrive.yue
local Director = dora.Director -- 1
local Cache = dora.Cache -- 1
local Entity = dora.Entity -- 1
local _module_0 = dora.Platformer -- 1
local Data = _module_0.Data -- 1
local Vec2 = dora.Vec2 -- 1
local threadLoop = dora.threadLoop -- 1
local Group = dora.Group -- 1
local thread = dora.thread -- 1
local sleep = dora.sleep -- 1
local Opacity = dora.Opacity -- 1
local emit = dora.emit -- 1
local _module_0 = nil -- 1
local AcademyAction = require("Academy.Action") -- 3
local AcademyAI = require("Academy.AI") -- 4
local AcademySystem = require("Academy.System") -- 5
local PreparationRoom = require("Scene.PreparationRoom") -- 6
local Config = require("Data.Config") -- 7
_module_0 = function() -- 9
	PreparationRoom:loadAsync() -- 10
	local world = PreparationRoom() -- 11
	do -- 12
		local _with_0 = Director.entry -- 12
		_with_0:removeAllChildren() -- 13
		Cache:removeUnused("Texture") -- 14
		_with_0:addChild(world) -- 15
	end -- 12
	Director.ui3D:removeAllChildren() -- 16
	Entity:clear() -- 18
	Data.store:clear() -- 19
	Data.store.world = world -- 20
	AcademyAction() -- 21
	AcademyAI() -- 22
	AcademySystem() -- 23
	world:turnOnLights() -- 25
	Entity({ -- 28
		player = true, -- 28
		name = Config.char, -- 29
		faceRight = false, -- 30
		position = Vec2(world.width / 2, world.offset), -- 31
		busy = true, -- 32
		base = true -- 33
	}) -- 27
	Entity({ -- 36
		player = false, -- 36
		name = "ninilite", -- 37
		faceRight = false, -- 38
		position = Vec2(world.width / 2 + 180, world.offset), -- 39
		busy = true, -- 40
		base = true -- 41
	}) -- 35
	threadLoop(function() -- 43
		local group = Group({ -- 44
			"player", -- 44
			"name", -- 44
			"unit" -- 44
		}) -- 44
		if group.count > 0 then -- 45
			group:each(function(self) -- 46
				if (function() -- 47
					local _val_0 = self.name -- 47
					return "charF" == _val_0 or "charM" == _val_0 -- 47
				end)() then -- 47
					world.camera.position = self.unit.position -- 48
					return world:makeUnitEnter(self.unit, 1, 0) -- 49
				else -- 51
					return world:makeUnitEnter(self.unit, 0, -1) -- 51
				end -- 47
			end) -- 46
			return true -- 52
		end -- 45
	end) -- 43
	return thread(function() -- 54
		local HUDControl = require("UI.HUDControl") -- 55
		local _with_0 = HUDControl() -- 56
		_with_0:addTo(Director.ui3D) -- 57
		_with_0.visible = false -- 58
		sleep(6) -- 59
		_with_0.visible = true -- 60
		_with_0:perform(Opacity(1, 0, 1)) -- 61
		emit("HUD.DisplayMove", true) -- 62
		return _with_0 -- 56
	end) -- 62
end -- 9
return _module_0 -- 62
