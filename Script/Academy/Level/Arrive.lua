-- [yue]: Script/Academy/Level/Arrive.yue
local _module_0 = nil -- 1
local _ENV = Dora(Dora.Platformer) -- 1
local require <const> = require -- 2
local Director <const> = Director -- 2
local Cache <const> = Cache -- 2
local Entity <const> = Entity -- 2
local Data <const> = Data -- 2
local Vec2 <const> = Vec2 -- 2
local threadLoop <const> = threadLoop -- 2
local Group <const> = Group -- 2
local thread <const> = thread -- 2
local sleep <const> = sleep -- 2
local Opacity <const> = Opacity -- 2
local emit <const> = emit -- 2
local AcademyAction = require("Academy.Action") -- 4
local AcademyAI = require("Academy.AI") -- 5
local AcademySystem = require("Academy.System") -- 6
local PreparationRoom = require("Scene.PreparationRoom") -- 7
local Config = require("Data.Config") -- 8
local _anon_func_0 = function(self) -- 48
	local _val_0 = self.name -- 48
	return "charF" == _val_0 or "charM" == _val_0 -- 48
end -- 48
_module_0 = function() -- 10
	PreparationRoom:loadAsync() -- 11
	local world = PreparationRoom() -- 12
	do -- 13
		local _with_0 = Director.entry -- 13
		_with_0:removeAllChildren() -- 14
		Cache:removeUnused("Texture") -- 15
		_with_0:addChild(world) -- 16
	end -- 13
	Director.ui3D:removeAllChildren() -- 17
	Entity:clear() -- 19
	Data.store:clear() -- 20
	Data.store.world = world -- 21
	AcademyAction() -- 22
	AcademyAI() -- 23
	AcademySystem() -- 24
	world:turnOnLights() -- 26
	Entity({ -- 29
		player = true, -- 29
		name = Config.char, -- 30
		faceRight = false, -- 31
		position = Vec2(world.sceneWidth / 2, world.offset), -- 32
		busy = true, -- 33
		base = true -- 34
	}) -- 28
	Entity({ -- 37
		player = false, -- 37
		name = "ninilite", -- 38
		faceRight = false, -- 39
		position = Vec2(world.sceneWidth / 2 + 180, world.offset), -- 40
		busy = true, -- 41
		base = true -- 42
	}) -- 36
	threadLoop(function() -- 44
		local group = Group({ -- 45
			"player", -- 45
			"name", -- 45
			"unit" -- 45
		}) -- 45
		if group.count > 0 then -- 46
			group:each(function(self) -- 47
				if _anon_func_0(self) then -- 48
					world.camera.position = self.unit.position -- 49
					return world:makeUnitEnter(self.unit, 1, 0) -- 50
				else -- 52
					return world:makeUnitEnter(self.unit, 0, -1) -- 52
				end -- 48
			end) -- 47
			return true -- 53
		end -- 46
	end) -- 44
	return thread(function() -- 55
		sleep(10) -- 56
		if not (world == Data.store.world and world.parent) then -- 57
			return -- 57
		end -- 57
		local HUDControl = require("UI.HUDControl") -- 58
		local _with_0 = HUDControl() -- 59
		_with_0:addTo(Director.ui3D) -- 60
		_with_0.visible = false -- 61
		_with_0.topControl.visible = false -- 62
		_with_0.message.visible = false -- 63
		sleep(1) -- 64
		if not (world == Data.store.world and world.parent) then -- 65
			_with_0:removeFromParent() -- 66
			return -- 67
		end -- 65
		_with_0.visible = true -- 68
		_with_0:perform(Opacity(1, 0, 1)) -- 69
		emit("HUD.DisplayMove", true) -- 70
		Group({ -- 71
			"busy" -- 71
		}):each(function(self) -- 71
			self.busy = nil -- 71
		end) -- 71
		require("Academy.Navigation").attach(world) -- 72
		return _with_0 -- 59
	end) -- 55
end -- 10
return _module_0 -- 1
