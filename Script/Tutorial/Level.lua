-- [yue]: Script/Tutorial/Level.yue
local Director = dora.Director -- 1
local Cache = dora.Cache -- 1
local _module_0 = dora.Platformer -- 1
local Data = _module_0.Data -- 1
local Entity = dora.Entity -- 1
local Vec2 = dora.Vec2 -- 1
local once = dora.once -- 1
local sleep = dora.sleep -- 1
local emit = dora.emit -- 1
local Group = dora.Group -- 1
local threadLoop = dora.threadLoop -- 1
local Spine = dora.Spine -- 1
local thread = dora.thread -- 1
local Observer = dora.Observer -- 1
local _module_0 = nil -- 1
local TutorialSystem = require("Tutorial.System") -- 3
local TutorialAI = require("Tutorial.AI") -- 4
local TutorialAction = require("Tutorial.Action").default -- 5
local LoopTowerA = require("Scene.LoopTowerA") -- 6
local Config = require("Data.Config") -- 7
local _anon_func_0 = function(_with_0, Spine) -- 59
	local _with_1 = Spine("kineticgun") -- 56
	_with_1.look = "PT" -- 57
	_with_1.scaleX = 0.2 -- 58
	_with_1.scaleY = 0.2 -- 59
	return _with_1 -- 56
end -- 56
_module_0 = function() -- 9
	LoopTowerA:loadAsync() -- 10
	local world = LoopTowerA() -- 11
	do -- 12
		local _with_0 = Director.entry -- 12
		_with_0:removeAllChildren() -- 13
		Cache:removeUnused("Texture") -- 14
		_with_0:addChild(world) -- 15
	end -- 12
	Data:setRelation(1, 2, "Enemy") -- 16
	Entity:clear() -- 18
	Data.store:clear() -- 19
	Data.store.world = world -- 20
	TutorialAction() -- 21
	TutorialAI() -- 22
	TutorialSystem() -- 23
	local chars = { -- 26
		{ -- 26
			'ninilite', -- 26
			500, -- 26
			-2, -- 26
			true -- 26
		}, -- 26
		{ -- 27
			Config.char, -- 27
			800, -- 27
			0, -- 27
			false -- 27
		} -- 27
	} -- 25
	for _index_0 = 1, #chars do -- 28
		local _des_0 = chars[_index_0] -- 28
		local name, x, order, faceRight = _des_0[1], _des_0[2], _des_0[3], _des_0[4] -- 28
		Entity({ -- 30
			name = name, -- 30
			faceRight = faceRight, -- 31
			order = order, -- 32
			player = name == "charF" or name == "charM", -- 33
			group = 1, -- 34
			position = Vec2(x, world.offset), -- 35
			tutorial = true -- 36
		}) -- 29
	end -- 36
	local HUDControl = require("UI.HUDControl") -- 38
	Director.ui3D:addChild((function() -- 40
		local _with_0 = HUDControl() -- 40
		_with_0:schedule(once(function() -- 41
			sleep(0.1) -- 42
			emit("MessageBox.Add", { -- 43
				title = "系统", -- 43
				special = false, -- 43
				text = "已上线/79.03.27.09.24；" -- 43
			}) -- 43
			sleep(0.9) -- 44
			return emit("MessageBox.Add", { -- 45
				title = "系统", -- 45
				special = false, -- 45
				text = "代理日志更新，代理第1天；" -- 45
			}) -- 45
		end)) -- 41
		return _with_0 -- 40
	end)()) -- 40
	Group({ -- 47
		"player", -- 47
		"name" -- 47
	}):each(function(self) -- 47
		local _exp_0 = self.name -- 48
		if "ninilite" == _exp_0 then -- 48
			self.decisionTree = "AI:NiniliteIntro" -- 49
		end -- 49
	end) -- 47
	threadLoop(function() -- 51
		local group = Group({ -- 52
			"player", -- 52
			"name", -- 52
			"unit" -- 52
		}) -- 52
		if group.count > 0 then -- 53
			group:each(function(self) -- 54
				local _exp_0 = self.name -- 54
				if "charF" == _exp_0 or "charM" == _exp_0 then -- 54
					do -- 55
						local _with_0 = self.unit.playable -- 55
						_with_0:setSlot("pistol", _anon_func_0(_with_0, Spine)) -- 56
					end -- 55
					return true -- 60
				end -- 60
			end) -- 54
			return true -- 61
		end -- 53
	end) -- 51
	return thread(function() -- 63
		sleep(2) -- 64
		local Story = require("UI.Story") -- 65
		local _with_0 = Story("Tutorial/Dialog/firstMeet.yarn") -- 66
		_with_0:addTo(Director.ui3D) -- 67
		_with_0:showAsync() -- 68
		_with_0:slot("Ended", function() -- 69
			return thread(function() -- 69
				Group({ -- 70
					"player" -- 70
				}):each(function(self) -- 70
					if self.name == "ninilite" then -- 71
						self.unit.playable.speed = 1.0 -- 72
						self.unit.decisionTree = "AI:NiniliteFight" -- 73
						self.unit:start("cancel") -- 74
						return true -- 75
					end -- 71
					return false -- 76
				end) -- 70
				Cache:loadAsync("spine:xiaotaotie") -- 77
				Entity({ -- 79
					name = "xiaotaotie", -- 79
					position = Vec2(1200, 168), -- 80
					group = 2, -- 81
					order = -1, -- 82
					faceRight = false, -- 83
					tutorial = true, -- 84
					monster = true -- 85
				}) -- 78
				sleep(1) -- 86
				emit("HUD.DisplayMove", true) -- 87
				local PlayBubbleChat = require("System.PlayBubbleChat") -- 88
				PlayBubbleChat("Tutorial/Dialog/evade.yarn") -- 89
				local moved = false -- 90
				do -- 91
					local _with_1 = Observer("Add", { -- 91
						"keyLeft", -- 91
						"player" -- 91
					}) -- 91
					_with_1:watch(function(_entity, keyLeft) -- 92
						if keyLeft then -- 92
							return thread(function() -- 92
								if not moved and Group({ -- 93
									"monster" -- 93
								}).count > 0 then -- 93
									moved = true -- 94
									PlayBubbleChat("Tutorial/Dialog/evadeLeft.yarn") -- 95
									sleep(1) -- 96
									PlayBubbleChat("Tutorial/Dialog/weapon.yarn") -- 97
									emit("Tutorial.Weapon") -- 98
								end -- 93
								return true -- 99
							end) -- 99
						end -- 92
					end) -- 92
				end -- 91
				local _with_1 = Observer("AddOrChange", { -- 100
					"keyRight", -- 100
					"player" -- 100
				}) -- 100
				_with_1:watch(function(_entity, keyRight) -- 101
					if keyRight then -- 101
						return thread(function() -- 101
							if not moved and Group({ -- 102
								"monster" -- 102
							}).count > 0 then -- 102
								moved = true -- 103
								PlayBubbleChat("Tutorial/Dialog/evadeRight.yarn") -- 104
								sleep(1) -- 105
								PlayBubbleChat("Tutorial/Dialog/weapon.yarn") -- 106
								emit("Tutorial.Weapon") -- 107
							end -- 102
							return true -- 108
						end) -- 108
					end -- 101
				end) -- 101
				return _with_1 -- 100
			end) -- 108
		end) -- 69
		return _with_0 -- 66
	end) -- 108
end -- 9
return _module_0 -- 108
