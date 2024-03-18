local App <const> = require("App")
local thread <const> = require("thread")
local Node <const> = require("Node")
local DrawNode <const> = require("DrawNode")
local Color <const> = require("Color")
local sleep <const> = require("sleep")
local once <const> = require("once")
local Observer = require("Observer")
local Entity = require("Entity")
local Vec2 = require("Vec2")
local Size = require("Size")
local Dictionary = require("Dictionary")
local Array = require("Array")
local Platformer = require("Platformer")
local Unit = Platformer.Unit
local Opacity = require("Opacity")
local Spine = require("Spine")
local loop = require("loop")
local cycle = require("cycle")
local Group = require("Group")
local StatusBar = require("UI.StatusBar")
local PlayBubbleChat = require("System.PlayBubbleChat")
local Interaction = require("UI.Interaction")

return function()
	Platformer.Data:setRelation(1, 2, "Enemy")

	local Width <const>, Height <const>, MaxPath <const> = 100, 300, 2

	Observer("Add", { "tutorial", "name", "position", "faceRight", "group" }):watch(function(entity, _tutorial, name, position, faceRight, group)
		local unitDef = Dictionary()
		unitDef.tag = name;
		unitDef.linearAcceleration = Vec2(0, -15)
		unitDef.bodyType = "Dynamic"
		unitDef.scale = 1.0
		unitDef.density = 1.0
		unitDef.friction = 1.0
		unitDef.restitution = 0.0
		unitDef.playable = "spine:" .. name
		unitDef.defaultFaceRight = true
		unitDef.size = Size(Width, Height)
		unitDef.sensity = entity.player and 0 or 0.5
		unitDef.move = 300
		unitDef.jump = 800
		unitDef.detectDistance = 800
		unitDef.attackRange = Size(800, 200)
		unitDef.hp = 1.0
		unitDef.usePreciseHit = false
		unitDef.actions = Array({
			"hit",
			"prepare",
			"idle",
			"idle1",
			"turn",
			"fmove",
			"bmove",
			"fallOff",
			"lose",
			"cancel",
		})
		local actions = unitDef.actions
		if entity.player ~= nil then
			if entity.player then
				actions:add("kinetic")
			else
				actions:add("laser")
			end
		end
		if name == "xiaotaotie" then
			unitDef.decisionTree = "AI:Monster"
			actions:add("blow")
			actions:add("dizzy")
			unitDef.attackRange = Size(400, 200)
			unitDef.detectDistance = 800
		elseif entity.decisionTree then
			unitDef.decisionTree = entity.decisionTree
		else
			unitDef.decisionTree = entity.player and "AI:PlayerControl" or "AI:NPC"
		end





		local world = Platformer.Data.store.world
		local unit = Unit(unitDef, world, entity, position + Vec2(0, Height / 2))
		local playable = unit.playable
		playable.y = -Height / 2
		playable:perform(Opacity(0.3, 0, 1))
		unit.group = group
		unit.faceRight = faceRight
		unit.order = entity.player and 0 or (entity.order) or math.random(-MaxPath, MaxPath)
		unit:start("idle")
		world:addShadowTo(unit)
		unit:addTo(world)
		if name == "xiaotaotie" then
			entity.hp = 100
			entity.maxHP = 1000
			entity.ap = 1000
			entity.maxAP = 1000
			local statusBar = StatusBar(0.1, 1, true)
			statusBar.order = unit.order
			statusBar:addTo(world)
			statusBar:schedule(function()
				statusBar.position = unit.position + Vec2(0, 200)
				local hp, ap, maxHP, maxAP = entity.hp, entity.ap, entity.maxHP, entity.maxAP
				if hp and ap and maxHP and maxAP then
					statusBar.hp = math.max(math.min(hp / maxHP, 1), 0)
					statusBar.ap = math.max(math.min(ap / maxAP, 1), 0)
				end
			end)
			unit:slot("Cleanup", function()
				statusBar:removeFromParent()
			end)
		end
		if entity.player then
			world.camera.followTarget = unit
			unit:gslot("Skill.Began", function()
				entity.keySkill = true
			end)
			unit:gslot("Skill.Ended", function()
				entity.keySkill = false
			end)
			local aimLine = DrawNode()
			aimLine:drawSegment(Vec2(100, 0), Vec2(150, 0), 2, Color(0xaaffffff))
			aimLine.tag = "aim"
			aimLine.visible = false
			aimLine:addTo(unit);
		elseif name == "ninilite" then
			unit:slot("ReachedExit", function()
				world:openRightDoor()
				Group({ "player" }):each(function(e)
					if e.player then
						e.exitAvailable = true
					end
				end)
			end)
		end
	end)
	Observer("AddOrChange", { "unit", "keySkill" }):watch(function(entity, unit, keySkill)
		local aimLine = unit:getChildByTag("aim")
		if keySkill then
			unit:schedule(loop(function()
				cycle(0.5, function(dt)
					local scaleX = unit.faceRight and 1 or -1
					aimLine.scaleX = scaleX
					aimLine.angle = -scaleX * dt * 90 + 45 * scaleX
					aimLine.visible = true
				end)
				cycle(0.5, function(dt)
					local scaleX = unit.faceRight and 1 or -1
					aimLine.scaleX = scaleX
					aimLine.angle = -scaleX * (1.0 - dt) * 90 + 45 * scaleX
				end)
				return false
			end))
		else
			aimLine.visible = false
			entity.keyShoot = true
			unit:schedule(function()
				entity.keyShoot = false
				return true
			end)
		end
	end)

	Group({ "player", "name" }):each(function(entity)
		local name = entity.name
		if name == "ninilite" then
			local unit = entity.unit
			local gun = Spine("empgun")
			if gun == nil then
				return
			end
			gun.look = "PT"
			gun.scaleX = 0.2
			gun.scaleY = 0.2
			unit.playable:setSlot("pistol", gun)
			entity.decisionTree = "AI:NiniliteIntro"
		elseif name == "charF" or name == "charM" then
			local unit = entity.unit
			local gun = Spine("kineticgun")
			if gun == nil then
				return
			end
			gun.look = "PT"
			gun.scaleX = 0.2
			gun.scaleY = 0.2
			unit.playable:setSlot("pistol", gun)
		end
	end)

	Observer("Change", { "ap" }):watch(function(e, ap)







		local entity = e
		if entity.hp and entity.hp <= 0 then
			return
		end
		local unit = entity.unit
		if not unit then return end
		if not unit:isDoing("dizzy") then
			if ap <= 0 then
				unit:start("cancel")
				if unit.data.hitFromRight ~= unit.faceRight then
					unit:start("turn")
				end
				unit:start("dizzy")
				unit:schedule(once(function()
					while entity.ap < 1000 do
						sleep(1)
						entity.ap = math.min(entity.ap + 400, entity.maxAP)
					end
					unit:start("cancel")
				end))
				if entity.firstHit then
					PlayBubbleChat("Tutorial/Dialog/finishHim.yarn")
				end
			elseif entity.oldValues.ap > ap then
				unit:start("cancel")
				if unit.data.hitFromRight ~= unit.faceRight then
					unit:start("turn")
				end
				unit:start("hit")
			end
		end
	end)

	Observer("Change", { "hp" }):watch(function(e, hp)






		local entity = e
		local unit = entity.unit
		if not unit then return end
		if unit:isDoing("dizzy") then
			entity.hp = hp - 100
		elseif not entity.firstHit then
			entity.firstHit = true
			PlayBubbleChat("Tutorial/Dialog/explain.yarn")
		end
		if entity.hp <= 0 then
			entity.ap = 0
			unit.group = Platformer.Data.groupHide
			unit:start("cancel")
			unit:start("lose")
			unit:schedule(once(function()
				sleep(3)
				PlayBubbleChat("Tutorial/Dialog/followMe.yarn")
				sleep(2)
				sleep(unit:perform(Opacity(1, 1, 0)))
				sleep(1)
				Group({ "player", "name" }):each(function(ent)
					if ent.name == "ninilite" then
						ent.leading = true
						return true
					end
				end)
				unit:removeFromParent()
			end))
		end
	end)

	Observer("AddOrChange", { "enterExit", "player", "unit", "exitAvailable" }):watch(function(e, enterExit, player, unit)
		if not player then return end
		if not Group({ "player", "leading" }):each(function(entity)
				return not entity.leading
			end) then
			return
		end
		if enterExit then
			local interaction = Interaction({
				text = "不明电梯",
				buttons = {
					{ "搭乘", "TAKING" },
				},
			})
			e.interaction = interaction
			interaction.order = (unit.world.children.last).order
			interaction.transformTarget = unit
			interaction:slot("Tapped", function()
				interaction.menu.enabled = false
				thread(function()
					local last = App.runningTime
					local PreparationRoom = require("Scene.PreparationRoom")
					PreparationRoom:loadAsync()
					local time = math.max(0, App.runningTime - last)
					if time < 0.5 then
						sleep(0.5 - time)
					end
					local ArriveLevel = require("Academy.Level.Arrive")
					ArriveLevel()
				end)
			end)
			interaction:addTo(unit.world)
			interaction:show()
		elseif e.interaction then
			(e.interaction):hide()
			e.interaction = nil
		end
	end)
end