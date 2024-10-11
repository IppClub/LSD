-- [yue]: Script/Tutorial/Level.yue
local Audio = Dora.Audio -- 1
local Director = Dora.Director -- 1
local Cache = Dora.Cache -- 1
local _module_0 = Dora.Platformer -- 1
local Data = _module_0.Data -- 1
local Entity = Dora.Entity -- 1
local Vec2 = Dora.Vec2 -- 1
local once = Dora.once -- 1
local sleep = Dora.sleep -- 1
local emit = Dora.emit -- 1
local Group = Dora.Group -- 1
local threadLoop = Dora.threadLoop -- 1
local Spine = Dora.Spine -- 1
local thread = Dora.thread -- 1
local Observer = Dora.Observer -- 1
local _module_0 = nil -- 1
local TutorialSystem = require("Tutorial.System") -- 3
local TutorialAI = require("Tutorial.AI") -- 4
local TutorialAction = require("Tutorial.Action").default -- 5
local LoopTowerA = require("Scene.LoopTowerA") -- 6
local Config = require("Data.Config") -- 7
local _anon_func_0 = function(Spine, _with_0) -- 59
	local _with_1 = Spine("kineticgun") -- 57
	_with_1.look = "PT" -- 58
	_with_1.scaleX = 0.2 -- 59
	_with_1.scaleY = 0.2 -- 59
	return _with_1 -- 57
end -- 57
_module_0 = function() -- 9
	Audio:playStream("Music/军事学园.mp3", true, 1) -- 10
	LoopTowerA:loadAsync() -- 11
	local world = LoopTowerA() -- 12
	do -- 13
		local _with_0 = Director.entry -- 13
		_with_0:removeAllChildren() -- 14
		Cache:removeUnused("Texture") -- 15
		_with_0:addChild(world) -- 16
	end -- 13
	Data:setRelation(1, 2, "Enemy") -- 17
	Entity:clear() -- 19
	Data.store:clear() -- 20
	Data.store.world = world -- 21
	TutorialAction() -- 22
	TutorialAI() -- 23
	TutorialSystem() -- 24
	local chars = { -- 27
		{ -- 27
			'ninilite', -- 27
			500, -- 27
			-2, -- 27
			true -- 27
		}, -- 27
		{ -- 28
			Config.char, -- 28
			800, -- 28
			0, -- 28
			false -- 28
		} -- 28
	} -- 26
	for _index_0 = 1, #chars do -- 29
		local _des_0 = chars[_index_0] -- 29
		local name, x, order, faceRight = _des_0[1], _des_0[2], _des_0[3], _des_0[4] -- 29
		Entity({ -- 31
			name = name, -- 31
			faceRight = faceRight, -- 32
			order = order, -- 33
			player = name == "charF" or name == "charM", -- 34
			group = 1, -- 35
			position = Vec2(x, world.offset), -- 36
			tutorial = true -- 37
		}) -- 30
	end -- 37
	local HUDControl = require("UI.HUDControl") -- 39
	Director.ui3D:addChild((function() -- 41
		local _with_0 = HUDControl() -- 41
		_with_0:schedule(once(function() -- 42
			sleep(0.1) -- 43
			emit("MessageBox.Add", { -- 44
				title = "系统", -- 44
				special = false, -- 44
				text = "已上线/79.03.27.09.24；" -- 44
			}) -- 44
			sleep(0.9) -- 45
			return emit("MessageBox.Add", { -- 46
				title = "系统", -- 46
				special = false, -- 46
				text = "代理日志更新，代理第1天；" -- 46
			}) -- 46
		end)) -- 42
		return _with_0 -- 41
	end)()) -- 41
	Group({ -- 48
		"player", -- 48
		"name" -- 48
	}):each(function(self) -- 48
		local _exp_0 = self.name -- 49
		if "ninilite" == _exp_0 then -- 49
			self.decisionTree = "AI:NiniliteIntro" -- 50
		end -- 50
	end) -- 48
	threadLoop(function() -- 52
		local group = Group({ -- 53
			"player", -- 53
			"name", -- 53
			"unit" -- 53
		}) -- 53
		if group.count > 0 then -- 54
			group:each(function(self) -- 55
				local _exp_0 = self.name -- 55
				if "charF" == _exp_0 or "charM" == _exp_0 then -- 55
					do -- 56
						local _with_0 = self.unit.playable -- 56
						_with_0:setSlot("pistol", _anon_func_0(Spine, _with_0)) -- 57
					end -- 56
					return true -- 60
				end -- 60
			end) -- 55
			return true -- 61
		end -- 54
	end) -- 52
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
