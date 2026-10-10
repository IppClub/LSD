local _module_0 = nil
local _ENV = Dora(Dora.Platformer)
local require <const> = require
local Director <const> = Director
local Cache <const> = Cache
local Data <const> = Data
local Entity <const> = Entity
local Vec2 <const> = Vec2
local Group <const> = Group
local App <const> = App
local once <const> = once
local sleep <const> = sleep
local emit <const> = emit
local threadLoop <const> = threadLoop
local Spine <const> = Spine
local setmetatable <const> = setmetatable
local thread <const> = thread
local Observer <const> = Observer
local TutorialSystem = require("Tutorial.System")
local TutorialAI = require("Tutorial.AI")
local TutorialAction = require("Tutorial.Action").default
local LoopTowerA = require("Scene.LoopTowerA")
local Config = require("Data.Config")
local _anon_func_0 = function(_with_0)
	local _with_1 = Spine("kineticgun")
	_with_1.look = "PT"
	_with_1.scaleX = 0.2
	_with_1.scaleY = 0.2
	return _with_1
end
_module_0 = function()
	LoopTowerA:loadAsync()
	local world = LoopTowerA();
	(require("System.Music")).play(world, "Music/军事学园.mp3")
	do
		local _with_0 = Director.entry
		_with_0:removeAllChildren()
		Cache:removeUnused("Texture")
		_with_0:addChild(world)
	end
	Data:setRelation(1, 2, "Enemy")
	Entity:clear()
	Data.store:clear()
	Data.store.world = world
	TutorialAction()
	TutorialAI()
	TutorialSystem()
	local chars = {
		{
			'ninilite',
			500,
			-2,
			true
		},
		{
			Config.char,
			800,
			0,
			false
		}
	}
	for _index_0 = 1, #chars do
		local _des_0 = chars[_index_0]
		local name, x, order, faceRight = _des_0[1], _des_0[2], _des_0[3], _des_0[4]
		Entity({
			name = name,
			faceRight = faceRight,
			order = order,
			player = name == "charF" or name == "charM",
			group = 1,
			position = Vec2(x, world.offset),
			tutorial = true
		})
	end
	local HUDControl = require("UI.HUDControl")
	local hud = HUDControl()
	Director.ui3D:addChild((function()
		(require("UI.AimHint")).attach(hud, function()
			local player = Group({
				"player",
				"unit"
			}):find(function(e)
				return e.player and e.unit.world == world
			end)
			if not player then
				return false, false, false
			end
			local held = player.keySkill == true
			local _, precision = (require("Tutorial.AimSweep")).angle(App.runningTime - (player.unit.data.aimStartedAt or App.runningTime))
			return held, held and precision, true
		end)
		hud:schedule(once(function()
			sleep(0.1)
			emit("MessageBox.Add", {
				title = "系统",
				special = false,
				text = "已上线/79.03.27.09.24；"
			})
			sleep(0.9)
			return emit("MessageBox.Add", {
				title = "系统",
				special = false,
				text = "代理日志更新，代理第1天；"
			})
		end))
		return hud
	end)())
	Group({
		"player",
		"name"
	}):each(function(self)
		local _exp_0 = self.name
		if "ninilite" == _exp_0 then
			self.decisionTree = "AI:NiniliteIntro"
		end
	end)
	local equipped = setmetatable({ }, { __mode = "k" })
	threadLoop(function()
		local group = Group({
			"player",
			"name",
			"unit"
		})
		if group.count > 0 then
			group:each(function(self)
				local _exp_0 = self.name
				if "charF" == _exp_0 or "charM" == _exp_0 then
					if not equipped[self.unit] then
						equipped[self.unit] = true
						do
							local _with_0 = self.unit.playable
							_with_0:setSlot("pistol", _anon_func_0(_with_0))
						end
					end
					return true
				end
			end)
			return true
		end
	end)
	return thread(function()
		sleep(2)
		local Story = require("UI.Story")
		local _with_0 = Story("Tutorial/Dialog/firstMeet.yarn")
		_with_0:addTo(Director.ui3D)
		_with_0:showAsync()
		_with_0:slot("Ended", function()
			return thread(function()
				Group({
					"player"
				}):each(function(self)
					if self.name == "ninilite" then
						self.unit.playable.speed = 1.0
						self.unit.decisionTree = "AI:NiniliteFight"
						self.unit:start("cancel")
						return true
					end
					return false
				end)
				Cache:loadAsync("spine:xiaotaotie")
				Entity({
					name = "xiaotaotie",
					position = Vec2(1200, 168),
					group = 2,
					order = -1,
					faceRight = false,
					tutorial = true,
					monster = true
				})
				sleep(1)
				emit("HUD.DisplayMove", true)
				local PlayBubbleChat = require("System.PlayBubbleChat")
				PlayBubbleChat("Tutorial/Dialog/evade.yarn")
				local moved = false
				do
					local _with_1 = Observer("AddOrChange", {
						"keyLeft",
						"player"
					})
					_with_1:watch(function(_entity, keyLeft)
						if keyLeft then
							return thread(function()
								if not moved and Group({
									"monster"
								}).count > 0 then
									moved = true
									PlayBubbleChat("Tutorial/Dialog/evadeLeft.yarn")
									sleep(1)
									PlayBubbleChat("Tutorial/Dialog/weapon.yarn")
									emit("Tutorial.Weapon")
								end
								return true
							end)
						end
					end)
				end
				local _with_1 = Observer("AddOrChange", {
					"keyRight",
					"player"
				})
				_with_1:watch(function(_entity, keyRight)
					if keyRight then
						return thread(function()
							if not moved and Group({
								"monster"
							}).count > 0 then
								moved = true
								PlayBubbleChat("Tutorial/Dialog/evadeRight.yarn")
								sleep(1)
								PlayBubbleChat("Tutorial/Dialog/weapon.yarn")
								emit("Tutorial.Weapon")
							end
							return true
						end)
					end
				end)
				return _with_1
			end)
		end)
		return _with_0
	end)
end
return _module_0
