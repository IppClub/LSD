-- [yue]: Test/BattleTest.yue
local Path = dora.Path -- 1
local Content = dora.Content -- 1
local _module_0 = dora.Platformer -- 1
local Data = _module_0.Data -- 1
local _module_1 = dora.Platformer.Decision -- 1
local Seq = _module_1.Seq -- 1
local Con = _module_1.Con -- 1
local AI = _module_1.AI -- 1
local Sel = _module_1.Sel -- 1
local Unit = _module_0.Unit -- 1
local math = _G.math -- 1
local Act = _module_1.Act -- 1
local Accept = _module_1.Accept -- 1
local Reject = _module_1.Reject -- 1
local BulletDef = _module_0.BulletDef -- 1
local Vec2 = dora.Vec2 -- 1
local pairs = _G.pairs -- 1
local Spine = dora.Spine -- 1
local table = _G.table -- 1
local tostring = _G.tostring -- 1
local Director = dora.Director -- 1
local Entity = dora.Entity -- 1
local Node = dora.Node -- 1
local App = dora.App -- 1
local _module_2 = dora.ImGui -- 1
local SetNextWindowPos = _module_2.SetNextWindowPos -- 1
local SetNextWindowSize = _module_2.SetNextWindowSize -- 1
local Begin = _module_2.Begin -- 1
local Combo = _module_2.Combo -- 1
local Checkbox = _module_2.Checkbox -- 1
local ipairs = _G.ipairs -- 1
local Button = _module_2.Button -- 1
local SameLine = _module_2.SameLine -- 1
local Text = _module_2.Text -- 1
do -- 7
	local scriptPath = Path:getScriptPath(...) -- 7
	if scriptPath then -- 7
		scriptPath = Path:getPath(scriptPath) -- 8
		local _list_0 = { -- 10
			scriptPath, -- 10
			Path(scriptPath, "Script"), -- 11
			Path(scriptPath, "Spine"), -- 12
			Path(scriptPath, "Image"), -- 13
			Path(scriptPath, "Font") -- 14
		} -- 9
		for _index_0 = 1, #_list_0 do -- 15
			local path = _list_0[_index_0] -- 9
			Content:insertSearchPath(1, path) -- 16
		end -- 16
	else -- 17
		return -- 17
	end -- 7
end -- 7
require("Control") -- 19
local Set = require("Utils").Set -- 20
require("Logic.MotherBase") -- 22
require("Logic.BattleLogic") -- 23
require("Unit.HeroUnit") -- 24
require("Unit.EnemyUnit") -- 25
local Store = Data.store -- 28
do -- 30
	local _with_0 = Data.store -- 30
	_with_0.PlayerGroup = 1 -- 31
	_with_0.EnemyGroup = 2 -- 32
	_with_0.CurrentScene = 1 -- 34
	_with_0.PlayerLayer = 1 -- 36
	_with_0.EnemyLayer = 2 -- 37
	_with_0.TerrainLayer = 0 -- 38
	Data:setShouldContact(_with_0.PlayerGroup, _with_0.EnemyGroup, false) -- 40
	Data:setRelation(_with_0.PlayerGroup, _with_0.EnemyGroup, "Enemy") -- 41
	_with_0.unit = nil -- 42
end -- 30
local PlayerGroup, EnemyGroup, CurrentScene, PlayerLayer, EnemyLayer, unit = Store.PlayerGroup, Store.EnemyGroup, Store.CurrentScene, Store.PlayerLayer, Store.EnemyLayer, Store.unit -- 43
Store.battle = false -- 53
local playable = nil -- 54
require("Action.Battle") -- 56
local _fightDecision = Seq({ -- 62
	Con("see enemy", function() -- 62
		return (AI:getNearestUnit("Enemy") ~= nil) -- 62
	end), -- 62
	Sel({ -- 64
		Seq({ -- 65
			Con("need evade", function(self) -- 65
				if not self.onSurface then -- 66
					return false -- 66
				end -- 66
				local evadeLeftEnemy = false -- 67
				local evadeRightEnemy = false -- 68
				local sensor = self:getSensorByTag(Unit.DetectSensorTag) -- 69
				sensor.sensedBodies:each(function(body) -- 70
					if Data:isEnemy(self, body) then -- 71
						local distance = math.abs(self.x - body.x) -- 72
						if distance < 350 then -- 73
							evadeRightEnemy = false -- 74
							evadeLeftEnemy = false -- 75
							return true -- 76
						elseif distance < 600 then -- 77
							if body.x > self.x then -- 78
								evadeRightEnemy = true -- 78
							end -- 78
							if body.x <= self.x then -- 79
								evadeLeftEnemy = true -- 79
							end -- 79
						end -- 73
					end -- 71
				end) -- 70
				local needEvade = not (evadeLeftEnemy == evadeRightEnemy) -- 80
				if needEvade then -- 81
					self.entity.evadeRight = evadeRightEnemy -- 81
				end -- 81
				return needEvade -- 82
			end), -- 65
			Sel({ -- 84
				Seq({ -- 85
					Con("face enemy", function(self) -- 85
						return self.entity.evadeRight == self.faceRight -- 85
					end), -- 85
					Act("roll") -- 86
				}), -- 84
				Act("turn"), -- 88
				Act("roll") -- 89
			}) -- 83
		}), -- 64
		Seq({ -- 93
			Con("not facing nearest enemy", function(self) -- 93
				local enemy = AI:getNearestUnit("Enemy") -- 94
				return (self.x > enemy.x) == self.faceRight -- 95
			end), -- 93
			Act("turn") -- 96
		}), -- 92
		Seq({ -- 99
			Con("enemy in attack range", function() -- 99
				local enemy = AI:getNearestUnit("Enemy") -- 100
				local attackUnits = AI:getUnitsInAttackRange() -- 101
				return attackUnits and attackUnits:contains(enemy) or false -- 102
			end), -- 99
			Act("butt") -- 103
		}), -- 98
		Act("fmove") -- 105
	}) -- 63
}) -- 61
Store["AI:NPC"] = Act("idle") -- 109
Store["AI:XIAOTAOTIE"] = Sel({ -- 112
	Seq({ -- 113
		Con("is dead", function(self) -- 113
			return self.entity.hp <= 0 -- 113
		end), -- 113
		Accept() -- 114
	}), -- 112
	Seq({ -- 117
		Con("see enemy", function() -- 117
			return (AI:getNearestUnit("Enemy") ~= nil) -- 117
		end), -- 117
		Sel({ -- 119
			Seq({ -- 120
				Con("need evade", function(self) -- 120
					if not self.onSurface then -- 121
						return false -- 121
					end -- 121
					local evadeLeftEnemy = false -- 122
					local evadeRightEnemy = false -- 123
					local sensor = self:getSensorByTag(Unit.DetectSensorTag) -- 124
					sensor.sensedBodies:each(function(body) -- 125
						if Data:isEnemy(self, body) then -- 126
							local distance = math.abs(self.x - body.x) -- 127
							if distance < 350 then -- 128
								evadeRightEnemy = false -- 129
								evadeLeftEnemy = false -- 130
								return true -- 131
							elseif distance < 600 then -- 132
								if body.x > self.x then -- 133
									evadeRightEnemy = true -- 133
								end -- 133
								if body.x <= self.x then -- 134
									evadeLeftEnemy = true -- 134
								end -- 134
							end -- 128
						end -- 126
					end) -- 125
					local needEvade = not (evadeLeftEnemy == evadeRightEnemy) -- 135
					if needEvade then -- 136
						self.entity.evadeRight = evadeRightEnemy -- 136
					end -- 136
					return needEvade -- 137
				end), -- 120
				Sel({ -- 139
					Seq({ -- 140
						Con("face enemy", function(self) -- 140
							return self.entity.evadeRight == self.faceRight -- 140
						end), -- 140
						Act("roll") -- 141
					}), -- 139
					Act("turn"), -- 143
					Act("roll") -- 144
				}) -- 138
			}), -- 119
			Seq({ -- 148
				Con("not facing nearest enemy", function(self) -- 148
					local enemy = AI:getNearestUnit("Enemy") -- 149
					return (self.x > enemy.x) == self.faceRight -- 150
				end), -- 148
				Act("turn") -- 151
			}), -- 147
			Seq({ -- 154
				Con("enemy in attack range", function() -- 154
					local enemy = AI:getNearestUnit("Enemy") -- 155
					local attackUnits = AI:getUnitsInAttackRange() -- 156
					return attackUnits and attackUnits:contains(enemy) or false -- 157
				end), -- 154
				Act("butt") -- 158
			}), -- 153
			Act("fmove") -- 160
		}) -- 118
	}), -- 116
	Seq({ -- 164
		Con("need stop", function(self) -- 164
			return not self:isDoing("idle") -- 164
		end), -- 164
		Act("cancel"), -- 165
		Act("idle") -- 166
	}) -- 163
}) -- 111
Store["AI:DATAOTIE"] = Sel({ -- 171
	Seq({ -- 172
		Con("is dead", function(self) -- 172
			return self.entity.hp <= 0 -- 172
		end), -- 172
		Accept() -- 173
	}), -- 171
	Seq({ -- 176
		Con("see enemy", function() -- 176
			return (AI:getNearestUnit("Enemy") ~= nil) -- 176
		end), -- 176
		Sel({ -- 178
			Seq({ -- 179
				Con("need evade", function(self) -- 179
					if not self.onSurface then -- 180
						return false -- 180
					end -- 180
					local evadeLeftEnemy = false -- 181
					local evadeRightEnemy = false -- 182
					local sensor = self:getSensorByTag(Unit.DetectSensorTag) -- 183
					sensor.sensedBodies:each(function(body) -- 184
						if Data:isEnemy(self, body) then -- 185
							local distance = math.abs(self.x - body.x) -- 186
							if distance < 350 then -- 187
								evadeRightEnemy = false -- 188
								evadeLeftEnemy = false -- 189
								return true -- 190
							elseif distance < 600 then -- 191
								if body.x > self.x then -- 192
									evadeRightEnemy = true -- 192
								end -- 192
								if body.x <= self.x then -- 193
									evadeLeftEnemy = true -- 193
								end -- 193
							end -- 187
						end -- 185
					end) -- 184
					local needEvade = not (evadeLeftEnemy == evadeRightEnemy) -- 194
					if needEvade then -- 195
						self.entity.evadeRight = evadeRightEnemy -- 195
					end -- 195
					return needEvade -- 196
				end), -- 179
				Sel({ -- 198
					Seq({ -- 199
						Con("face enemy", function(self) -- 199
							return self.entity.evadeRight == self.faceRight -- 199
						end), -- 199
						Act("dtdRush1") -- 200
					}), -- 198
					Act("turn"), -- 202
					Act("dtdRush1") -- 203
				}) -- 197
			}), -- 178
			Seq({ -- 207
				Con("not facing nearest enemy", function(self) -- 207
					local enemy = AI:getNearestUnit("Enemy") -- 208
					return (self.x > enemy.x) == self.faceRight -- 209
				end), -- 207
				Act("turn") -- 210
			}), -- 206
			Seq({ -- 213
				Con("enemy in attack range", function() -- 213
					local enemy = AI:getNearestUnit("Enemy") -- 214
					local attackUnits = AI:getUnitsInAttackRange() -- 215
					return attackUnits and attackUnits:contains(enemy) or false -- 216
				end), -- 213
				Act("trample") -- 217
			}), -- 212
			Act("fmove") -- 219
		}) -- 177
	}), -- 175
	Seq({ -- 223
		Con("need stop", function(self) -- 223
			return not self:isDoing("idle") -- 223
		end), -- 223
		Act("cancel"), -- 224
		Act("idle") -- 225
	}) -- 222
}) -- 170
Store["AI:PlayerControl"] = Sel({ -- 230
	Seq({ -- 231
		Sel({ -- 232
			Seq({ -- 233
				Con("fmove key down", function(self) -- 233
					return not (self.entity.keyLeft and self.entity.keyRight) and ((self.entity.keyLeft and self.faceRight) or (self.entity.keyRight and not self.faceRight)) -- 238
				end), -- 233
				Act("turn") -- 239
			}), -- 232
			Seq({ -- 242
				Con("bmove key down", function(self) -- 242
					return not (self.entity.keyLeft or self.entity.keyRight) and not (self.entity.keyBLeft and self.entity.keyBRight) and ((self.entity.keyBLeft and not self.faceRight) or (self.entity.keyBRight and self.faceRight)) -- 248
				end), -- 242
				Act("turn") -- 249
			}) -- 241
		}), -- 231
		Reject() -- 252
	}), -- 230
	Seq({ -- 255
		Con("test", function(self) -- 255
			return self.entity.keyTest -- 255
		end), -- 255
		Act("test") -- 256
	}), -- 254
	Seq({ -- 259
		Con("melee", function(self) -- 259
			return self.entity.keyMelee -- 259
		end), -- 259
		Act("melee") -- 260
	}), -- 258
	Seq({ -- 263
		Con("pistol", function(self) -- 263
			return self.entity.keyShoot -- 263
		end), -- 263
		Act("pistol") -- 264
	}), -- 262
	Seq({ -- 267
		Con("evade", function(self) -- 267
			return self.entity.keyEvade -- 267
		end), -- 267
		Act("evade") -- 268
	}), -- 266
	Seq({ -- 271
		Con("rush", function(self) -- 271
			return self.entity.keyRush -- 271
		end), -- 271
		Act("rush") -- 272
	}), -- 270
	Seq({ -- 275
		Con("fall", function(self) -- 275
			return self.entity.keyFall -- 275
		end), -- 275
		Act("fall") -- 276
	}), -- 274
	Sel({ -- 279
		Seq({ -- 280
			Con("is falling", function(self) -- 280
				return not self.onSurface -- 280
			end), -- 280
			Act("fallOff") -- 281
		}), -- 279
		Seq({ -- 284
			Con("jump key down", function(self) -- 284
				return self.entity.keyUp -- 284
			end), -- 284
			Act("jump") -- 285
		}) -- 283
	}), -- 278
	Seq({ -- 289
		Con("fmove key down", function(self) -- 289
			return self.entity.keyLeft or self.entity.keyRight -- 289
		end), -- 289
		Act("fmove") -- 290
	}), -- 288
	Seq({ -- 293
		Con("bmove key down", function(self) -- 293
			return self.entity.keyBLeft or self.entity.keyBRight -- 293
		end), -- 293
		Act("bmove") -- 294
	}), -- 292
	Act("idle") -- 296
}) -- 229
do -- 301
	local _with_0 = BulletDef() -- 301
	_with_0.tag = "" -- 302
	_with_0.endEffect = "" -- 303
	_with_0.lifeTime = 2 -- 304
	_with_0.damageRadius = 0 -- 305
	_with_0.highSpeedFix = false -- 306
	_with_0.gravity = Vec2.zero -- 307
	_with_0:setAsCircle(10) -- 310
	_with_0:setVelocity(0, 1800) -- 311
	Store["Bullet_1"] = _with_0 -- 301
end -- 301
local targetAnims = Set({ -- 318
	"bmove", -- 318
	"bow", -- 319
	"bstep", -- 320
	"comm", -- 321
	"comp", -- 322
	"defence", -- 323
	"fall", -- 324
	"fmove", -- 325
	"fstep", -- 326
	"gun1", -- 327
	"gun2", -- 328
	"gun3", -- 329
	"hit", -- 330
	"idle", -- 331
	"idle1", -- 332
	"jump", -- 333
	"jumping", -- 334
	"landing", -- 335
	"lose", -- 336
	"melee", -- 337
	"parry", -- 338
	"pistol", -- 339
	"prepare", -- 340
	"standUp", -- 341
	"throw" -- 342
}) -- 317
local testAnims = { -- 346
	"bow", -- 346
	"gun1", -- 347
	"gun2", -- 348
	"gun3", -- 349
	"hit", -- 350
	"lose", -- 351
	"melee", -- 352
	"parry", -- 353
	"throw", -- 354
	"comm", -- 355
	"comp", -- 356
	"defence" -- 357
} -- 345
local missingAnims = { } -- 360
local extraAnims = { } -- 361
local availableAnims = { } -- 363
local defaultFaceRight = true -- 364
local getAllFiles -- 366
getAllFiles = function(path, exts) -- 366
	local filters = Set(exts) -- 367
	local _accum_0 = { } -- 368
	local _len_0 = 1 -- 368
	local _list_0 = Content:getAllFiles(path) -- 368
	for _index_0 = 1, #_list_0 do -- 368
		local file = _list_0[_index_0] -- 368
		if not filters[Path:getExt(file)] then -- 369
			goto _continue_0 -- 369
		end -- 369
		_accum_0[_len_0] = file -- 370
		_len_0 = _len_0 + 1 -- 370
		::_continue_0:: -- 369
	end -- 370
	return _accum_0 -- 370
end -- 366
local files = Set((function() -- 372
	local _accum_0 = { } -- 372
	local _len_0 = 1 -- 372
	local _list_0 = getAllFiles("Spine", { -- 372
		"skel", -- 372
		"json" -- 372
	}) -- 372
	for _index_0 = 1, #_list_0 do -- 372
		local file = _list_0[_index_0] -- 372
		_accum_0[_len_0] = Path:getName(file) -- 373
		_len_0 = _len_0 + 1 -- 373
	end -- 373
	return _accum_0 -- 373
end)()) -- 372
local includes = Set({ -- 375
	"char", -- 375
	"charF", -- 376
	"charM", -- 377
	"ayan", -- 378
	"liyena", -- 379
	"moling", -- 380
	"moyu", -- 381
	"villywan", -- 382
	"sunborn", -- 383
	"yuzijiang", -- 384
	"dataotie", -- 385
	"xiaotaotie" -- 386
}) -- 374
do -- 388
	local _accum_0 = { } -- 388
	local _len_0 = 1 -- 388
	for k in pairs(files) do -- 388
		if includes[k] then -- 388
			_accum_0[_len_0] = k -- 388
			_len_0 = _len_0 + 1 -- 388
		end -- 388
	end -- 388
	files = _accum_0 -- 388
end -- 388
local defaultFaceLeft = Set({ -- 391
	"liyena", -- 391
	"dataotie" -- 392
}) -- 390
local scenes = { -- 395
	"Station", -- 395
	"Factory", -- 396
	"FrozenCity", -- 397
	"AbandonedCity", -- 398
	"OuterHeaven", -- 399
	"TrainA", -- 400
	"TrainB", -- 401
	"VRTraining", -- 402
	"PreparationRoom", -- 403
	"PassageA", -- 404
	"PassageB", -- 405
	"PassageC", -- 406
	"PassageD", -- 407
	"TrainingRoom", -- 408
	"OperationRoom", -- 409
	"RestRoom", -- 410
	"RDRoom" -- 411
} -- 394
playable = "charF" -- 416
local anims = Set(Spine:getAnimations(playable)) -- 418
do -- 420
	local _accum_0 = { } -- 420
	local _len_0 = 1 -- 420
	for anim in pairs(targetAnims) do -- 420
		if not anims[anim] then -- 421
			_accum_0[_len_0] = anim -- 422
		else -- 423
			goto _continue_0 -- 423
		end -- 421
		_len_0 = _len_0 + 1 -- 423
		::_continue_0:: -- 421
	end -- 423
	missingAnims = _accum_0 -- 420
end -- 423
do -- 425
	local _accum_0 = { } -- 425
	local _len_0 = 1 -- 425
	for anim in pairs(anims) do -- 425
		if not targetAnims[anim] then -- 426
			_accum_0[_len_0] = anim -- 427
		else -- 428
			goto _continue_1 -- 428
		end -- 426
		_len_0 = _len_0 + 1 -- 428
		::_continue_1:: -- 426
	end -- 428
	extraAnims = _accum_0 -- 425
end -- 428
defaultFaceRight = not defaultFaceLeft[playable] -- 430
do -- 433
	local _accum_0 = { } -- 433
	local _len_0 = 1 -- 433
	for _index_0 = 1, #testAnims do -- 433
		local anim = testAnims[_index_0] -- 433
		if anims[anim] then -- 434
			_accum_0[_len_0] = anim -- 435
		else -- 436
			goto _continue_2 -- 436
		end -- 434
		_len_0 = _len_0 + 1 -- 436
		::_continue_2:: -- 434
	end -- 436
	availableAnims = _accum_0 -- 433
end -- 436
for _index_0 = 1, #extraAnims do -- 438
	local a = extraAnims[_index_0] -- 438
	table.insert(availableAnims, a) -- 439
end -- 439
local createScene -- 446
createScene = function() -- 446
	local world = Store.world -- 448
	if world then -- 449
		world:removeFromParent() -- 449
	end -- 449
	world = (require("Scene." .. tostring(scenes[CurrentScene])))() -- 450
	Store.world = world -- 451
	return Director.entry:addChild(world) -- 452
end -- 446
local createUnit -- 457
createUnit = function() -- 457
	local world = Store.world -- 459
	Entity({ -- 462
		hero = playable, -- 462
		group = PlayerGroup, -- 464
		layer = PlayerLayer, -- 465
		position = Vec2(world.width / 2, world.offset + 150), -- 466
		faceRight = true, -- 467
		player = true -- 468
	}) -- 461
	Entity({ -- 491
		player = false, -- 491
		enemy = "xiaotaotie", -- 492
		faceRight = true, -- 493
		position = Vec2(world.width / 2 - 300, world.offset), -- 494
		group = EnemyGroup, -- 495
		layer = EnemyLayer, -- 496
		hp = 3.0 -- 497
	}) -- 490
	Entity({ -- 501
		player = false, -- 501
		enemy = "xiaotaotie", -- 502
		faceRight = false, -- 503
		position = Vec2(world.width / 2 + 550, world.offset), -- 504
		group = EnemyGroup, -- 505
		layer = EnemyLayer, -- 506
		hp = 3.0 -- 507
	}) -- 500
	Entity({ -- 510
		player = false, -- 510
		enemy = "dataotie", -- 511
		faceRight = false, -- 512
		position = Vec2(world.width / 2 + 1050, world.offset), -- 513
		group = EnemyGroup, -- 514
		layer = EnemyLayer, -- 515
		hp = 5.0 -- 516
	}) -- 509
	world.showDebug = false -- 518
end -- 457
createScene() -- 525
if #files > 0 then -- 526
	createUnit() -- 527
end -- 526
return Director.entry:addChild((function() -- 533
	local _with_0 = Node() -- 533
	_with_0:schedule(function() -- 534
		local width, height -- 535
		do -- 535
			local _obj_0 = App.visualSize -- 535
			width, height = _obj_0.width, _obj_0.height -- 535
		end -- 535
		SetNextWindowPos(Vec2(width - 300, 10), "FirstUseEver") -- 536
		SetNextWindowSize(Vec2(290, 325), "FirstUseEver") -- 537
		return Begin("Spine", { -- 538
			"NoResize", -- 538
			"NoSavedSettings" -- 538
		}, function() -- 538
			local changed -- 539
			changed, CurrentScene = Combo("Scene", CurrentScene, scenes) -- 539
			if changed then -- 540
				createScene() -- 541
				createUnit() -- 542
			end -- 540
			changed, defaultFaceRight = Checkbox("默认朝向右", defaultFaceRight) -- 547
			if changed then -- 548
				createUnit() -- 548
			end -- 548
			local world = Store.world -- 555
			local result -- 556
			changed, result = Checkbox("Debug", world.showDebug) -- 556
			if changed then -- 557
				world.showDebug = result -- 557
			end -- 557
			for i, anim in ipairs(availableAnims) do -- 558
				if Button(anim) then -- 559
					if not unit.currentAction or unit.currentAction.name ~= "test_" then -- 560
						Store.testAction = anim -- 561
					end -- 560
				end -- 559
				if i % 3 ~= 0 and i ~= #availableAnims then -- 563
					SameLine() -- 563
				end -- 563
			end -- 563
			if #missingAnims > 0 then -- 564
				Text("缺失动作或名称错误：") -- 565
				Text(table.concat(missingAnims, "\n")) -- 566
			end -- 564
			if #extraAnims > 0 then -- 567
				Text("多余动作：") -- 568
				return Text(table.concat(extraAnims, "\n")) -- 569
			end -- 567
		end) -- 569
	end) -- 534
	return _with_0 -- 533
end)()) -- 569
