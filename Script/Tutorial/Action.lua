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
local ____DoraX = require("DoraX") -- 6
local React = ____DoraX.React -- 6
local toNode = ____DoraX.toNode -- 6
local Rectangle = require("UI.View.Shape.Rectangle") -- 7
local ____LightStrip = require("Script.Tutorial.LightStrip") -- 8
local LightStrip = ____LightStrip.LightStrip -- 8
local ____require_result_0 = require("Platformer") -- 5
local Unit = ____require_result_0.Unit -- 5
local UnitAction = ____require_result_0.UnitAction -- 5
local Data = ____require_result_0.Data -- 5
local BulletDef = ____require_result_0.BulletDef -- 5
local Face = ____require_result_0.Face -- 5
local Bullet = ____require_result_0.Bullet -- 5
local TargetAllow = ____require_result_0.TargetAllow -- 5
function ____exports.default() -- 10
	UnitAction:add( -- 11
		"bmove", -- 11
		{ -- 11
			priority = 1, -- 12
			reaction = 2, -- 13
			recovery = 0.2, -- 14
			available = function(owner) return owner.onSurface end, -- 15
			create = function(owner) -- 16
				local playable = owner.playable -- 17
				playable:play("bmove", true) -- 18
				return function(owner, action) -- 19
					local ____action_1 = action -- 20
					local elapsedTime = ____action_1.elapsedTime -- 20
					local recovery = ____action_1.recovery -- 20
					local move = owner.unitDef.move -- 21
					local moveSpeed = 1 -- 22
					if elapsedTime < recovery then -- 22
						moveSpeed = math.min(elapsedTime / recovery, 1) -- 24
					end -- 24
					owner.velocityX = moveSpeed * (owner.faceRight and -move or move) * 0.5 -- 26
					return not owner.onSurface -- 27
				end -- 19
			end -- 16
		} -- 16
	) -- 16
	UnitAction:add( -- 32
		"fmove", -- 32
		{ -- 32
			priority = 1, -- 33
			reaction = 2, -- 34
			recovery = 0.2, -- 35
			available = function(owner) return owner.onSurface end, -- 36
			create = function(owner) -- 37
				local playable = owner.playable -- 38
				playable:play("fmove", true) -- 39
				return function(owner, action) -- 40
					local ____action_2 = action -- 41
					local elapsedTime = ____action_2.elapsedTime -- 41
					local recovery = ____action_2.recovery -- 41
					local move = owner.unitDef.move -- 42
					local moveSpeed = 1 -- 43
					if elapsedTime < recovery then -- 43
						moveSpeed = math.min(elapsedTime / recovery, 1) -- 45
					end -- 45
					owner.velocityX = moveSpeed * (owner.faceRight and move or -move) -- 47
					return not owner.onSurface -- 48
				end -- 40
			end -- 37
		} -- 37
	) -- 37
	UnitAction:add( -- 53
		"prepare", -- 53
		{ -- 53
			priority = 1, -- 54
			reaction = 2, -- 55
			recovery = 0.2, -- 56
			available = function(owner) return owner.onSurface end, -- 57
			create = function(owner) -- 58
				local playable = owner.playable -- 59
				playable.recovery = 0.2 -- 60
				playable:play("prepare", true) -- 61
				return function() return not owner.onSurface end -- 62
			end -- 58
		} -- 58
	) -- 58
	UnitAction:add( -- 66
		"idle", -- 66
		{ -- 66
			priority = 1, -- 67
			reaction = 2, -- 68
			recovery = 0.2, -- 69
			create = function(owner) -- 70
				local playable = owner.playable -- 71
				playable.recovery = 0.2 -- 72
				playable:play("idle", true) -- 73
				local playIdleSpecial = coroutine.create(function() -- 74
					while true do -- 74
						sleep(3) -- 76
						sleep(playable:play("idle1")) -- 77
						playable:play("idle", true) -- 78
					end -- 78
				end) -- 74
				owner.data.playIdleSpecial = playIdleSpecial -- 81
				return function() -- 82
					coroutine.resume(playIdleSpecial) -- 83
					return not owner.onSurface -- 84
				end -- 82
			end -- 70
		} -- 70
	) -- 70
	UnitAction:add( -- 89
		"laser", -- 89
		{ -- 89
			priority = 3, -- 90
			reaction = 3, -- 91
			recovery = 0.2, -- 92
			queued = true, -- 93
			create = function(owner) return once(function() -- 94
				owner.playable:slot("attack"):set(function() -- 95
					local bulletDef = BulletDef() -- 96
					bulletDef.lifeTime = 10 -- 97
					bulletDef.damageRadius = 0 -- 98
					bulletDef.highSpeedFix = true -- 99
					bulletDef.gravity = Vec2.zero -- 100
					bulletDef.face = Face(function() -- 101
						return Rectangle({width = 10, height = 10, borderColor = 4294901896, fillColor = 1727987848}) -- 102
					end) -- 101
					bulletDef:setAsCircle(10) -- 109
					bulletDef:setVelocity(0, 5000) -- 110
					local bullet = Bullet(bulletDef, owner) -- 111
					local targetAllow = TargetAllow() -- 112
					targetAllow:allow("Enemy", true) -- 113
					targetAllow.terrainAllowed = true -- 114
					bullet.angle = 0 -- 115
					bullet.targetAllow = targetAllow:toValue() -- 116
					bullet:slot( -- 117
						"HitTarget", -- 117
						function(bullet, target, pos) -- 117
							local entity = target.entity -- 118
							target.data.hitFromRight = bullet.velocityX < 0 -- 119
							entity.ap = entity.ap - 100 -- 120
							bullet.hitStop = true -- 121
						end -- 117
					) -- 117
					bullet:addTo(owner.world, owner.order) -- 123
					local pistol = owner.playable:getSlot("pistol") -- 124
					if pistol then -- 124
						local worldPos = pistol:convertToWorldSpace(Vec2(300, 0)) -- 126
						local ____opt_3 = owner.parent -- 126
						local pos = ____opt_3 and ____opt_3:convertToNodeSpace(worldPos) -- 127
						if pos then -- 127
							bullet.position = pos -- 128
						end -- 128
					end -- 128
					LightStrip(bullet.position, bullet, 3431841523) -- 130
				end) -- 95
				owner.playable.recovery = 0.2 -- 132
				sleep(owner.playable:play("pistol")) -- 133
				return true -- 134
			end) end -- 94
		} -- 94
	) -- 94
	UnitAction:add( -- 138
		"kinetic", -- 138
		{ -- 138
			priority = 3, -- 139
			reaction = 3, -- 140
			recovery = 0.2, -- 141
			queued = true, -- 142
			create = function(owner) return once(function() -- 143
				owner.playable:slot("attack"):set(function() -- 144
					local ____owner_data_aimAngle_5 = owner.data.aimAngle -- 145
					if ____owner_data_aimAngle_5 == nil then -- 145
						____owner_data_aimAngle_5 = 0 -- 145
					end -- 145
					local aimAngle = ____owner_data_aimAngle_5 -- 145
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
								local ____bullet_6 = bullet -- 179
								local velocity = ____bullet_6.velocity -- 179
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
						local ____opt_7 = owner.parent -- 190
						local pos = ____opt_7 and ____opt_7:convertToNodeSpace(worldPos) -- 191
						if pos then -- 191
							bullet.position = pos -- 192
						end -- 192
						worldPos = pistol:convertToWorldSpace(Vec2.zero) -- 193
						local ____opt_9 = owner.parent -- 193
						pos = ____opt_9 and ____opt_9:convertToNodeSpace(worldPos) or Vec2.zero -- 194
						local casing = toNode(React.createElement( -- 195
							"body", -- 195
							{ -- 195
								type = "Dynamic", -- 195
								x = pos.x, -- 195
								y = pos.y, -- 195
								world = owner.world, -- 195
								group = Data.groupHide, -- 195
								linearAcceleration = Vec2(0, -9.8), -- 195
								velocityX = (math.random() + 1) * (owner.faceRight and -200 or 200), -- 195
								velocityY = (math.random() + 1) * 300, -- 195
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
							unit:start("cancel") -- 305
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