-- [tsx]: Action.tsx
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 1
local cycle = ____Dora.cycle -- 1
local Ease = ____Dora.Ease -- 1
local Node = ____Dora.Node -- 1
local once = ____Dora.once -- 1
local Opacity = ____Dora.Opacity -- 1
local sleep = ____Dora.sleep -- 1
local Spine = ____Dora.Spine -- 1
local tolua = ____Dora.tolua -- 1
local Vec2 = ____Dora.Vec2 -- 1
local ____Platformer = require("Platformer") -- 2
local Unit = ____Platformer.Unit -- 2
local UnitAction = ____Platformer.UnitAction -- 2
local Data = ____Platformer.Data -- 2
local BulletDef = ____Platformer.BulletDef -- 2
local Face = ____Platformer.Face -- 2
local Bullet = ____Platformer.Bullet -- 2
local TargetAllow = ____Platformer.TargetAllow -- 2
local ____DoraX = require("DoraX") -- 3
local React = ____DoraX.React -- 3
local toNode = ____DoraX.toNode -- 3
local Rectangle = require("UI.View.Shape.Rectangle") -- 4
local ____LightStrip = require("Tutorial.LightStrip") -- 5
local LightStrip = ____LightStrip.LightStrip -- 5
function ____exports.default() -- 7
	UnitAction:add( -- 8
		"bmove", -- 8
		{ -- 8
			priority = 1, -- 9
			reaction = 2, -- 10
			recovery = 0.2, -- 11
			available = function(owner) return owner.onSurface end, -- 12
			create = function(owner) -- 13
				local playable = owner.playable -- 14
				playable:play("bmove", true) -- 15
				return function(owner, action) -- 16
					local ____action_0 = action -- 17
					local elapsedTime = ____action_0.elapsedTime -- 17
					local recovery = ____action_0.recovery -- 17
					local move = owner.unitDef.move -- 18
					local moveSpeed = 1 -- 19
					if elapsedTime < recovery then -- 19
						moveSpeed = math.min(elapsedTime / recovery, 1) -- 21
					end -- 21
					owner.velocityX = moveSpeed * (owner.faceRight and -move or move) * 0.5 -- 23
					return not owner.onSurface -- 24
				end -- 16
			end -- 13
		} -- 13
	) -- 13
	UnitAction:add( -- 29
		"fmove", -- 29
		{ -- 29
			priority = 1, -- 30
			reaction = 2, -- 31
			recovery = 0.2, -- 32
			available = function(owner) return owner.onSurface end, -- 33
			create = function(owner) -- 34
				local playable = owner.playable -- 35
				playable:play("fmove", true) -- 36
				return function(owner, action) -- 37
					local ____action_1 = action -- 38
					local elapsedTime = ____action_1.elapsedTime -- 38
					local recovery = ____action_1.recovery -- 38
					local move = owner.unitDef.move -- 39
					local moveSpeed = 1 -- 40
					if elapsedTime < recovery then -- 40
						moveSpeed = math.min(elapsedTime / recovery, 1) -- 42
					end -- 42
					owner.velocityX = moveSpeed * (owner.faceRight and move or -move) -- 44
					return not owner.onSurface -- 45
				end -- 37
			end -- 34
		} -- 34
	) -- 34
	UnitAction:add( -- 50
		"prepare", -- 50
		{ -- 50
			priority = 1, -- 51
			reaction = 2, -- 52
			recovery = 0.2, -- 53
			available = function(owner) return owner.onSurface end, -- 54
			create = function(owner) -- 55
				local playable = owner.playable -- 56
				repeat -- 56
					local ____switch13 = playable.lastCompleted -- 56
					local ____cond13 = ____switch13 == "pistol" or ____switch13 == "hit" -- 56
					if ____cond13 then -- 56
						playable.recovery = 0 -- 60
						break -- 61
					end -- 61
				until true -- 61
				playable:play("prepare", true) -- 63
				return function() return not owner.onSurface end -- 64
			end -- 55
		} -- 55
	) -- 55
	UnitAction:add( -- 68
		"idle", -- 68
		{ -- 68
			priority = 1, -- 69
			reaction = 2, -- 70
			recovery = 0.2, -- 71
			create = function(owner) -- 72
				local playable = owner.playable -- 73
				playable:play("idle", true) -- 74
				local playIdleSpecial = coroutine.create(function() -- 75
					while true do -- 75
						sleep(3) -- 77
						sleep(playable:play("idle1")) -- 78
						playable:play("idle", true) -- 79
					end -- 79
				end) -- 75
				owner.data.playIdleSpecial = playIdleSpecial -- 82
				return function() -- 83
					coroutine.resume(playIdleSpecial) -- 84
					return not owner.onSurface -- 85
				end -- 83
			end -- 72
		} -- 72
	) -- 72
	UnitAction:add( -- 90
		"laser", -- 90
		{ -- 90
			priority = 3, -- 91
			reaction = 3, -- 92
			recovery = 0.2, -- 93
			queued = true, -- 94
			create = function(owner) return once(function() -- 95
				owner.playable:slot("attack"):set(function() -- 96
					local bulletDef = BulletDef() -- 97
					bulletDef.lifeTime = 10 -- 98
					bulletDef.damageRadius = 0 -- 99
					bulletDef.highSpeedFix = true -- 100
					bulletDef.gravity = Vec2.zero -- 101
					bulletDef.face = Face(function() -- 102
						return Rectangle({width = 10, height = 10, borderColor = 4294901896, fillColor = 1727987848}) -- 103
					end) -- 102
					bulletDef:setAsCircle(10) -- 110
					bulletDef:setVelocity(0, 5000) -- 111
					local bullet = Bullet(bulletDef, owner) -- 112
					local targetAllow = TargetAllow() -- 113
					targetAllow:allow("Enemy", true) -- 114
					targetAllow.terrainAllowed = true -- 115
					bullet.angle = 0 -- 116
					bullet.targetAllow = targetAllow:toValue() -- 117
					bullet:slot( -- 118
						"HitTarget", -- 118
						function(bullet, target, pos) -- 118
							local entity = target.entity -- 119
							target.data.hitFromRight = bullet.velocityX < 0 -- 120
							entity.ap = entity.ap - 100 -- 121
							bullet.hitStop = true -- 122
						end -- 118
					) -- 118
					bullet:addTo(owner.world, owner.order) -- 124
					local pistol = owner.playable:getSlot("pistol") -- 125
					if pistol then -- 125
						local worldPos = pistol:convertToWorldSpace(Vec2(300, 0)) -- 127
						local ____opt_2 = owner.parent -- 127
						local pos = ____opt_2 and ____opt_2:convertToNodeSpace(worldPos) -- 128
						if pos then -- 128
							bullet.position = pos -- 129
						end -- 129
					end -- 129
					LightStrip(bullet.position, bullet, 3431841523) -- 131
				end) -- 96
				sleep(owner.playable:play("pistol")) -- 133
				return true -- 134
			end) end -- 95
		} -- 95
	) -- 95
	UnitAction:add( -- 138
		"kinetic", -- 138
		{ -- 138
			priority = 3, -- 139
			reaction = 3, -- 140
			recovery = 0.2, -- 141
			queued = true, -- 142
			create = function(owner) return once(function() -- 143
				owner.playable:slot("attack"):set(function() -- 144
					local ____owner_data_aimAngle_4 = owner.data.aimAngle -- 145
					if ____owner_data_aimAngle_4 == nil then -- 145
						____owner_data_aimAngle_4 = 0 -- 145
					end -- 145
					local aimAngle = ____owner_data_aimAngle_4 -- 145
					local bulletDef = BulletDef() -- 146
					bulletDef.lifeTime = 10 -- 147
					bulletDef.damageRadius = 0 -- 148
					bulletDef.highSpeedFix = true -- 149
					bulletDef.gravity = Vec2.zero -- 150
					bulletDef.face = Face(function() -- 151
						local spine = Spine("Spine/kineticgun") -- 152
						if spine then -- 152
							local node = Node() -- 154
							node:addChild(spine) -- 155
							spine.angle = owner.faceRight and aimAngle or 180 - aimAngle -- 156
							spine.scaleX = 0.5 -- 157
							spine.scaleY = 0.5 -- 158
							spine.look = "PTbullet" -- 159
							return node -- 160
						end -- 160
						return Node() -- 162
					end) -- 151
					bulletDef:setAsCircle(10) -- 164
					bulletDef:setVelocity(-aimAngle, 5000) -- 165
					local bullet = Bullet(bulletDef, owner) -- 166
					local targetAllow = TargetAllow() -- 167
					targetAllow:allow("Enemy", true) -- 168
					targetAllow.terrainAllowed = true -- 169
					bullet.targetAllow = targetAllow:toValue() -- 170
					bullet:slot( -- 171
						"HitTarget", -- 171
						function(bullet, target, pos, normal) -- 171
							local entity = target.entity -- 172
							target.data.hitFromRight = bullet.velocityX < 0 -- 173
							entity.hp = entity.hp - 1 -- 174
							if target:isDoing("dizzy") then -- 174
								bullet.hitStop = true -- 176
							else -- 176
								bullet.hitStop = false -- 178
								local ____bullet_5 = bullet -- 179
								local velocity = ____bullet_5.velocity -- 179
								local proj = velocity:dot(normal) -- 180
								local reflection = velocity:sub(normal:mul(2 * proj)) -- 181
								bullet:emit("StopStrip") -- 182
								bullet.velocity = reflection -- 183
								LightStrip( -- 184
									bullet.position:sub(Vec2(5, 5)), -- 184
									bullet, -- 184
									1728053247 -- 184
								) -- 184
							end -- 184
						end -- 171
					) -- 171
					bullet:addTo(owner.world, owner.order) -- 187
					local pistol = owner.playable:getSlot("pistol") -- 188
					if pistol then -- 188
						local worldPos = pistol:convertToWorldSpace(Vec2(300, 0)) -- 190
						local ____opt_6 = owner.parent -- 190
						local pos = ____opt_6 and ____opt_6:convertToNodeSpace(worldPos) -- 191
						if pos then -- 191
							bullet.position = pos -- 192
						end -- 192
						worldPos = pistol:convertToWorldSpace(Vec2.zero) -- 193
						local ____opt_8 = owner.parent -- 193
						pos = ____opt_8 and ____opt_8:convertToNodeSpace(worldPos) or Vec2.zero -- 194
						local casing = toNode(React.createElement( -- 195
							"body", -- 195
							{ -- 195
								type = "Dynamic", -- 195
								x = pos.x, -- 195
								y = pos.y, -- 195
								world = owner.world, -- 195
								group = Data.groupHide, -- 195
								linearAcceleration = Vec2(0, -9.8), -- 195
								velocityX = math.random() * (owner.faceRight and -200 or 200), -- 195
								velocityY = math.random() * 300, -- 195
								angle = math.random() * aimAngle -- 195
							}, -- 195
							React.createElement("rect-fixture", { -- 195
								width = 20, -- 195
								height = 10, -- 195
								density = 26, -- 195
								friction = 0.4, -- 195
								restitution = 0.4 -- 195
							}), -- 195
							React.createElement("spine", {file = "Spine/kineticgun", look = "PTcasing", scaleX = 0.5, scaleY = 0.5}) -- 195
						)) -- 195
						if casing then -- 195
							casing:schedule(once(function() -- 209
								sleep(10) -- 210
								sleep(casing:perform(Opacity(0.5, 1, 0))) -- 211
								casing:removeFromParent() -- 212
							end)) -- 209
							casing:addTo(owner.world, owner.order) -- 214
						end -- 214
					end -- 214
					LightStrip(bullet.position, bullet, 3439329279) -- 217
					local playable = tolua.cast(owner.playable, "Spine") -- 218
					if playable then -- 218
						playable:schedule(once(function() -- 220
							sleep(0.2) -- 221
							cycle( -- 222
								0.2, -- 222
								function(time) -- 222
									local angle = -(1 - Ease:func(Ease.OutSine, time)) * aimAngle -- 223
									owner.data.aimAngle = angle -- 224
									playable:setBoneRotation("aim", angle) -- 225
								end -- 222
							) -- 222
						end)) -- 220
					end -- 220
				end) -- 144
				local aim = owner:getChildByTag("aim") -- 230
				local playable = tolua.cast(owner.playable, "Spine") -- 231
				if aim and playable then -- 231
					local angle = aim.angle -- 233
					playable:schedule(once(function() -- 234
						local fix = owner.faceRight and 1 or -1 -- 235
						cycle( -- 236
							0.2, -- 236
							function(time) -- 236
								local aimAngle = -Ease:func(Ease.OutSine, time) * fix * angle -- 237
								owner.data.aimAngle = -aimAngle -- 238
								playable:setBoneRotation("aim", aimAngle) -- 239
							end -- 236
						) -- 236
					end)) -- 234
				end -- 234
				sleep(owner.playable:play("pistol")) -- 243
				return true -- 244
			end) end, -- 143
			stop = function(owner) -- 246
				local aimAngle = owner.data.aimAngle -- 247
				if aimAngle then -- 247
					local playable = tolua.cast(owner.playable, "Spine") -- 249
					if playable then -- 249
						playable:schedule(once(function() -- 251
							cycle( -- 252
								0.2, -- 252
								function(time) -- 252
									playable:setBoneRotation( -- 253
										"aim", -- 253
										-(1 - Ease:func(Ease.OutSine, time)) * aimAngle -- 253
									) -- 253
								end -- 252
							) -- 252
						end)) -- 251
					end -- 251
				end -- 251
			end -- 246
		} -- 246
	) -- 246
	UnitAction:add( -- 261
		"hit", -- 261
		{ -- 261
			priority = 99, -- 262
			reaction = 3, -- 263
			recovery = 0.2, -- 264
			create = function(owner) return once(function() -- 265
				sleep(owner.playable:play("hit")) -- 266
				return true -- 267
			end) end -- 265
		} -- 265
	) -- 265
	UnitAction:add( -- 271
		"dizzy", -- 271
		{ -- 271
			priority = 99, -- 272
			reaction = 3, -- 273
			recovery = 0.2, -- 274
			create = function(owner) -- 275
				owner.playable:play("dizzy", true) -- 276
				return function() return false end -- 277
			end -- 275
		} -- 275
	) -- 275
	UnitAction:add( -- 281
		"lose", -- 281
		{ -- 281
			priority = 99, -- 282
			reaction = 3, -- 283
			recovery = 0.2, -- 284
			create = function(owner) return once(function() -- 285
				local time = owner.playable:play("lose") -- 286
				sleep(time - 0.05) -- 287
				owner.playable.speed = 0 -- 288
				return true -- 289
			end) end -- 285
		} -- 285
	) -- 285
	UnitAction:add( -- 293
		"blow", -- 293
		{ -- 293
			reaction = 3, -- 294
			recovery = 0.2, -- 295
			priority = 3, -- 296
			queued = true, -- 297
			create = function(owner) -- 298
				owner.playable:slot("attack"):set(function() -- 299
					local senser = owner:getSensorByTag(Unit.AttackSensorTag) -- 300
					senser.sensedBodies:each(function(item) -- 301
						local unit = tolua.cast(item, "Platformer::Unit") -- 302
						if unit and Data:isEnemy(unit.group, owner.group) and unit.x >= owner.x == owner.faceRight then -- 302
							unit:applyLinearImpulse( -- 304
								Vec2(unit.x < owner.x and -500 or 500, 0), -- 304
								Vec2.zero -- 304
							) -- 304
							unit:start("cancal") -- 305
							if unit.x < owner.x and not unit.faceRight then -- 305
								unit:start("turn") -- 307
							end -- 307
							unit:start("hit") -- 309
						end -- 309
						return false -- 311
					end) -- 301
				end) -- 299
				return once(function() -- 314
					sleep(owner.playable:play("blow")) -- 315
					return true -- 316
				end) -- 314
			end -- 298
		} -- 298
	) -- 298
	UnitAction:add( -- 321
		"fallOff", -- 321
		{ -- 321
			priority = 2, -- 322
			reaction = -1, -- 323
			recovery = 0.3, -- 324
			queued = true, -- 325
			available = function(owner) return not owner.onSurface end, -- 326
			create = function(owner) -- 327
				local playable = owner.playable -- 328
				if playable.current ~= "jumping" then -- 328
					playable:play("jumping", true) -- 330
				end -- 330
				return once(function() -- 332
					while true do -- 332
						if owner.onSurface then -- 332
							sleep(playable:play("landing", false)) -- 335
							coroutine.yield(true) -- 336
						else -- 336
							coroutine.yield(false) -- 338
						end -- 338
					end -- 338
				end) -- 332
			end -- 327
		} -- 327
	) -- 327
end -- 327
return ____exports -- 327