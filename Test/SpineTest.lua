-- [yue]: Test/SpineTest.yue
local Path = dora.Path -- 1
local Content = dora.Content -- 1
local Director = dora.Director -- 1
local _module_0 = dora.Platformer -- 1
local Data = _module_0.Data -- 1
local UnitAction = _module_0.UnitAction -- 1
local once = dora.once -- 1
local sleep = dora.sleep -- 1
local cycle = dora.cycle -- 1
local math = _G.math -- 1
local coroutine = _G.coroutine -- 1
local Vec2 = dora.Vec2 -- 1
local _module_1 = dora.Platformer.Decision -- 1
local Sel = _module_1.Sel -- 1
local Seq = _module_1.Seq -- 1
local Con = _module_1.Con -- 1
local AI = _module_1.AI -- 1
local Act = _module_1.Act -- 1
local Reject = _module_1.Reject -- 1
local tostring = _G.tostring -- 1
local Group = dora.Group -- 1
local Entity = dora.Entity -- 1
local Spine = dora.Spine -- 1
local pairs = _G.pairs -- 1
local Dictionary = dora.Dictionary -- 1
local Size = dora.Size -- 1
local Array = dora.Array -- 1
local table = _G.table -- 1
local Unit = _module_0.Unit -- 1
local Node = dora.Node -- 1
local Sprite = dora.Sprite -- 1
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

do -- 6
	local scriptPath = Path:getScriptPath(...) -- 6
	if scriptPath then -- 6
		scriptPath = Path:getPath(scriptPath) -- 7
		local _list_0 = { -- 9
			scriptPath, -- 9
			Path(scriptPath, "Script"), -- 10
			Path(scriptPath, "Spine"), -- 11
			Path(scriptPath, "Image"), -- 12
			Path(scriptPath, "Font") -- 13
		} -- 8
		for _index_0 = 1, #_list_0 do -- 14
			local path = _list_0[_index_0] -- 8
			Content:insertSearchPath(1, path) -- 15
		end -- 15
	else -- 16
		return -- 16
	end -- 6
end -- 6
require("Control") -- 18
local Set = require("Utils").Set -- 19
local HUDControl = require("UI.HUDControl") -- 20
local MotherBase = require("Logic.MotherBase") -- 21
MotherBase() -- 23
Director.ui3D:addChild(HUDControl()) -- 25
local Store = Data.store -- 27
UnitAction:add("fall", { -- 30
	priority = 10, -- 30
	reaction = 3, -- 31
	recovery = 0.1, -- 32
	queued = true, -- 33
	available = function() -- 34
		return true -- 34
	end, -- 34
	create = function(self) -- 35
		return once(function() -- 35
			local _with_0 = self.playable -- 35
			_with_0.speed = 1 -- 36
			sleep(_with_0:play("fall")) -- 37
			sleep(0.1) -- 38
			_with_0.recovery = 0 -- 39
			sleep(_with_0:play("standUp")) -- 40
			return _with_0 -- 35
		end) -- 40
	end -- 35
}) -- 29
UnitAction:add("evade", { -- 43
	priority = 10, -- 43
	reaction = 10, -- 44
	recovery = 0, -- 45
	queued = true, -- 46
	available = function() -- 47
		return true -- 47
	end, -- 47
	create = function(self) -- 48
		local time = 0 -- 49
		do -- 50
			local _with_0 = self.playable -- 50
			_with_0.speed = 1.0 -- 51
			time = _with_0:play("bstep") -- 52
		end -- 50
		return once(function(self) -- 53
			local dir = self.faceRight and -1 or 1 -- 54
			cycle(math.max(time, 0.4), function() -- 55
				self.velocityX = 800 * dir -- 55
			end) -- 55
			do -- 56
				local _with_0 = self.playable -- 56
				_with_0.recovery = 0.3 -- 57
				_with_0.speed = 1.0 -- 58
				_with_0:play("idle") -- 59
			end -- 56
			sleep(0.3) -- 60
			return true -- 61
		end) -- 61
	end -- 48
}) -- 42
UnitAction:add("rush", { -- 64
	priority = 10, -- 64
	reaction = 10, -- 65
	recovery = 0, -- 66
	queued = true, -- 67
	available = function() -- 68
		return true -- 68
	end, -- 68
	create = function(self) -- 69
		local time = 0 -- 70
		do -- 71
			local _with_0 = self.playable -- 71
			_with_0.speed = 1.0 -- 72
			time = _with_0:play("fstep") -- 73
		end -- 71
		return once(function(self) -- 74
			local dir = self.faceRight and 1 or -1 -- 75
			cycle(math.max(time, 0.4), function() -- 76
				self.velocityX = 800 * dir -- 76
			end) -- 76
			do -- 77
				local _with_0 = self.playable -- 77
				_with_0.recovery = 0.3 -- 78
				_with_0.speed = 1.0 -- 79
				_with_0:play("idle") -- 80
			end -- 77
			sleep(0.3) -- 81
			return true -- 82
		end) -- 82
	end -- 69
}) -- 63
local pistolEnd -- 84
pistolEnd = function(name, playable) -- 84
	if name == "pistol" then -- 84
		return playable.parent.parent:stop() -- 85
	end -- 84
end -- 84
UnitAction:add("pistol", { -- 88
	priority = 3, -- 88
	reaction = 3, -- 89
	recovery = 0.2, -- 90
	queued = true, -- 91
	available = function() -- 92
		return true -- 92
	end, -- 92
	create = function(self) -- 93
		do -- 94
			local _with_0 = self.playable -- 94
			_with_0.speed = 1 -- 95
			_with_0:play("pistol") -- 96
			_with_0:slot("AnimationEnd", pistolEnd) -- 97
		end -- 94
		return function() -- 98
			return false -- 98
		end -- 98
	end, -- 93
	stop = function(self) -- 99
		return self.playable:slot("AnimationEnd"):remove(pistolEnd) -- 100
	end -- 99
}) -- 87
local testEnd -- 102
testEnd = function(name, playable) -- 102
	if name == Store.testAction then -- 102
		return playable.parent.parent:stop() -- 103
	end -- 102
end -- 102
UnitAction:add("test", { -- 106
	priority = 3, -- 106
	reaction = 3, -- 107
	recovery = 0.1, -- 108
	queued = true, -- 109
	available = function() -- 110
		return true -- 110
	end, -- 110
	create = function(self) -- 111
		do -- 112
			local _with_0 = self.playable -- 112
			_with_0.speed = 1 -- 113
			_with_0:play(Store.testAction) -- 114
			_with_0:slot("AnimationEnd", testEnd) -- 115
		end -- 112
		return function() -- 116
			return false -- 116
		end -- 116
	end, -- 111
	stop = function(self) -- 117
		return self.playable:slot("AnimationEnd"):remove(testEnd) -- 118
	end -- 117
}) -- 105
UnitAction:add("idle", { -- 121
	priority = 1, -- 121
	reaction = 2.0, -- 122
	recovery = 0.2, -- 123
	available = function(self) -- 124
		return self.onSurface -- 124
	end, -- 124
	create = function(self) -- 125
		local _with_0 = self.playable -- 125
		_with_0.speed = 1.0 -- 126
		if Store.battle then -- 127
			do -- 128
				local _exp_0 = _with_0.lastCompleted -- 128
				if "melee" == _exp_0 or "pistol" == _exp_0 or "bow" == _exp_0 or "gun1" == _exp_0 or "gun2" == _exp_0 or "gun3" == _exp_0 or "throw" == _exp_0 or "parry" == _exp_0 or "defense" == _exp_0 or "comp" == _exp_0 or "comm" == _exp_0 then -- 129
					_with_0.recovery = 0.0 -- 130
				end -- 130
			end -- 130
			_with_0:play("prepare", true) -- 131
			return function(self) -- 132
				return not self.onSurface -- 132
			end -- 132
		else -- 134
			_with_0:play("idle", true) -- 134
			local playIdleSpecial = coroutine.create(function() -- 135
				while true do -- 135
					sleep(3) -- 136
					sleep(_with_0:play("idle1")) -- 137
					_with_0:play("idle", true) -- 138
				end -- 138
			end) -- 135
			self.data.playIdleSpecial = playIdleSpecial -- 139
			return function(self) -- 140
				coroutine.resume(playIdleSpecial) -- 141
				return not self.onSurface -- 142
			end -- 142
		end -- 127
		return _with_0 -- 125
	end -- 125
}) -- 120
UnitAction:add("fmove", { -- 145
	priority = 1, -- 145
	reaction = 2.0, -- 146
	recovery = 0.2, -- 147
	available = function(self) -- 148
		return self.onSurface -- 148
	end, -- 148
	create = function(self) -- 149
		do -- 150
			local _with_0 = self.playable -- 150
			_with_0.speed = 1 -- 151
			local duration = _with_0:play("fmove", true) -- 152
			if duration == 0 then -- 153
				_with_0:play("move", true) -- 154
			end -- 153
		end -- 150
		return function(self, action) -- 155
			local elapsedTime, recovery = action.elapsedTime, action.recovery -- 156
			local move = self.unitDef.move -- 157
			local moveSpeed -- 158
			if elapsedTime < recovery then -- 158
				moveSpeed = math.min(elapsedTime / recovery, 1.0) -- 159
			else -- 161
				moveSpeed = 1.0 -- 161
			end -- 158
			self.velocityX = moveSpeed * (self.faceRight and move or -move) -- 162
			return not self.onSurface -- 163
		end -- 163
	end -- 149
}) -- 144
UnitAction:add("keepIdle", { -- 166
	priority = 100, -- 166
	reaction = 2.0, -- 167
	recovery = 0.2, -- 168
	available = function() -- 169
		return true -- 169
	end, -- 169
	create = function(self) -- 170
		do -- 171
			local _with_0 = self.playable -- 171
			_with_0.speed = 1 -- 172
			_with_0:play("idle", true) -- 173
		end -- 171
		return function() -- 174
			return false -- 174
		end -- 174
	end -- 170
}) -- 165
UnitAction:add("idle1", { -- 177
	priority = 1, -- 177
	reaction = 2.0, -- 178
	recovery = 0.2, -- 179
	available = function() -- 180
		return true -- 180
	end, -- 180
	queued = true, -- 181
	create = function(self) -- 182
		return once(function() -- 182
			local _with_0 = self.playable -- 183
			_with_0.speed = 1 -- 184
			sleep(_with_0:play("idle1", false)) -- 185
			return _with_0 -- 183
		end) -- 185
	end -- 182
}) -- 176
UnitAction:add("keepMove", { -- 188
	priority = 100, -- 188
	reaction = 2.0, -- 189
	recovery = 0.2, -- 190
	available = function() -- 191
		return true -- 191
	end, -- 191
	create = function(self) -- 192
		do -- 193
			local _with_0 = self.playable -- 193
			_with_0.speed = 1 -- 194
			_with_0:play("fmove", true) -- 195
		end -- 193
		return function() -- 196
			return false -- 196
		end -- 196
	end -- 192
}) -- 187
UnitAction:add("bmove", { -- 199
	priority = 1, -- 199
	reaction = 2.0, -- 200
	recovery = 0.2, -- 201
	available = function(self) -- 202
		return self.onSurface -- 202
	end, -- 202
	create = function(self) -- 203
		do -- 204
			local _with_0 = self.playable -- 204
			_with_0.speed = 1 -- 205
			_with_0:play("bmove", true) -- 206
		end -- 204
		return function(self, action) -- 207
			local elapsedTime, recovery = action.elapsedTime, action.recovery -- 208
			local move = self.unitDef.move -- 209
			local moveSpeed -- 210
			if elapsedTime < recovery then -- 210
				moveSpeed = math.min(elapsedTime / recovery, 1.0) -- 211
			else -- 213
				moveSpeed = 1.0 -- 213
			end -- 210
			self.velocityX = moveSpeed * (self.faceRight and -move or move) * 0.5 -- 214
			return not self.onSurface -- 215
		end -- 215
	end -- 203
}) -- 198
UnitAction:add("jump", { -- 218
	priority = 3, -- 218
	reaction = 2.0, -- 219
	recovery = 0.1, -- 220
	queued = true, -- 221
	available = function(self) -- 222
		return self.onSurface -- 222
	end, -- 222
	create = function(self) -- 223
		local velocityX = self.velocityX -- 224
		local jump = self.unitDef.jump -- 225
		self.velocity = Vec2(velocityX, jump) -- 226
		return once(function(self, _action) -- 227
			local _with_0 = self.playable -- 228
			_with_0.speed = 1 -- 229
			sleep(_with_0:play("jump", false)) -- 230
			return _with_0 -- 228
		end) -- 230
	end -- 223
}) -- 217
UnitAction:add("fallOff", { -- 233
	priority = 2, -- 233
	reaction = -1, -- 234
	recovery = 0.3, -- 235
	available = function(self) -- 236
		return not self.onSurface -- 236
	end, -- 236
	create = function(self) -- 237
		if self.playable.current ~= "jumping" then -- 238
			do -- 239
				local _with_0 = self.playable -- 239
				_with_0.speed = 1 -- 240
				_with_0:play("jumping", true) -- 241
			end -- 239
		end -- 238
		return once(function(self, _action) -- 242
			while true do -- 243
				if self.onSurface then -- 244
					do -- 245
						local _with_0 = self.playable -- 245
						_with_0.speed = 1 -- 246
						sleep(_with_0:play("landing", false)) -- 247
					end -- 245
					coroutine.yield(true) -- 248
				else -- 250
					coroutine.yield(false) -- 250
				end -- 244
			end -- 250
		end) -- 250
	end -- 237
}) -- 232
Store["AI:NPC"] = Sel({ -- 253
	Seq({ -- 254
		Con("not facing nearest unit", function(self) -- 254
			local _list_0 = AI:getDetectedUnits() -- 255
			for _index_0 = 1, #_list_0 do -- 255
				local unit = _list_0[_index_0] -- 255
				if unit.entity.player then -- 256
					return (self.x > unit.x) == self.faceRight -- 257
				end -- 256
			end -- 257
			do -- 258
				local unit = AI:getNearestUnit("Any") -- 258
				if unit then -- 258
					return (self.x > unit.x) == self.faceRight -- 259
				else -- 261
					return false -- 261
				end -- 258
			end -- 258
		end), -- 254
		Act("turn") -- 262
	}), -- 253
	Act("idle") -- 264
}) -- 252
Store["AI:PlayerControl"] = Sel({ -- 268
	Seq({ -- 269
		Sel({ -- 270
			Seq({ -- 271
				Con("fmove key down", function(self) -- 271
					return not (self.entity.keyLeft and self.entity.keyRight) and ((self.entity.keyLeft and self.faceRight) or (self.entity.keyRight and not self.faceRight)) -- 276
				end), -- 271
				Act("turn") -- 277
			}), -- 270
			Seq({ -- 280
				Con("bmove key down", function(self) -- 280
					return not (self.entity.keyLeft or self.entity.keyRight) and not (self.entity.keyBLeft and self.entity.keyBRight) and ((self.entity.keyBLeft and not self.faceRight) or (self.entity.keyBRight and self.faceRight)) -- 286
				end), -- 280
				Act("turn") -- 287
			}) -- 279
		}), -- 269
		Reject() -- 290
	}), -- 268
	Seq({ -- 293
		Con("pistol", function(self) -- 293
			return self.entity.keyShoot -- 293
		end), -- 293
		Act("pistol") -- 294
	}), -- 292
	Seq({ -- 297
		Con("evade", function(self) -- 297
			return self.entity.keyEvade -- 297
		end), -- 297
		Act("evade") -- 298
	}), -- 296
	Seq({ -- 301
		Con("rush", function(self) -- 301
			return self.entity.keyRush -- 301
		end), -- 301
		Act("rush") -- 302
	}), -- 300
	Seq({ -- 305
		Con("fall", function(self) -- 305
			return self.entity.keyFall -- 305
		end), -- 305
		Act("fall") -- 306
	}), -- 304
	Sel({ -- 309
		Seq({ -- 310
			Con("is falling", function(self) -- 310
				return not self.onSurface -- 310
			end), -- 310
			Act("fallOff") -- 311
		}), -- 309
		Seq({ -- 314
			Con("jump key down", function(self) -- 314
				return self.entity.keyUp -- 314
			end), -- 314
			Act("jump") -- 315
		}) -- 313
	}), -- 308
	Seq({ -- 319
		Con("fmove key down", function(self) -- 319
			return self.entity.keyLeft or self.entity.keyRight -- 319
		end), -- 319
		Act("fmove") -- 320
	}), -- 318
	Seq({ -- 323
		Con("bmove key down", function(self) -- 323
			return self.entity.keyBLeft or self.entity.keyBRight -- 323
		end), -- 323
		Act("bmove") -- 324
	}), -- 322
	Act("idle") -- 326
}) -- 267
Store.battle = false -- 329
local unit = nil -- 331
local playable = nil -- 332
local targetAnims = Set({ -- 335
	"bmove", -- 335
	"bow", -- 336
	"bstep", -- 337
	"comm", -- 338
	"comp", -- 339
	"defence", -- 340
	"fall", -- 341
	"fmove", -- 342
	"fstep", -- 343
	"gun1", -- 344
	"gun2", -- 345
	"gun3", -- 346
	"hit", -- 347
	"idle", -- 348
	"idle1", -- 349
	"jump", -- 350
	"jumping", -- 351
	"landing", -- 352
	"lose", -- 353
	"melee", -- 354
	"parry", -- 355
	"pistol", -- 356
	"prepare", -- 357
	"standUp", -- 358
	"throw" -- 359
}) -- 334
local testAnims = { -- 363
	"bow", -- 363
	"gun1", -- 364
	"gun2", -- 365
	"gun3", -- 366
	"hit", -- 367
	"lose", -- 368
	"melee", -- 369
	"parry", -- 370
	"throw", -- 371
	"comm", -- 372
	"comp", -- 373
	"defence" -- 374
} -- 362
local missingAnims = { } -- 377
local extraAnims = { } -- 378
local availableAnims = { } -- 380
local defaultFaceRight = true -- 381
local getAllFiles -- 383
getAllFiles = function(path, exts) -- 383
	local filters = Set(exts) -- 384
	local _accum_0 = { } -- 385
	local _len_0 = 1 -- 385
	local _list_0 = Content:getAllFiles(path) -- 385
	for _index_0 = 1, #_list_0 do -- 385
		local file = _list_0[_index_0] -- 385
		if not filters[Path:getExt(file)] then -- 386
			goto _continue_0 -- 386
		end -- 386
		_accum_0[_len_0] = file -- 387
		_len_0 = _len_0 + 1 -- 387
		::_continue_0:: -- 386
	end -- 387
	return _accum_0 -- 387
end -- 383
local fileSet = Set((function() -- 389
	local _accum_0 = { } -- 389
	local _len_0 = 1 -- 389
	local _list_0 = getAllFiles("Spine", { -- 389
		"skel", -- 389
		"json" -- 389
	}) -- 389
	for _index_0 = 1, #_list_0 do -- 389
		local file = _list_0[_index_0] -- 389
		_accum_0[_len_0] = Path:getName(file) -- 390
		_len_0 = _len_0 + 1 -- 390
	end -- 390
	return _accum_0 -- 390
end)()) -- 389
local includes = { -- 392
	"char", -- 392
	"charF", -- 393
	"charM", -- 394
	"ayan", -- 395
	"liyena", -- 396
	"moling", -- 397
	"moyu", -- 398
	"villywan", -- 399
	"sunborn", -- 400
	"yuzijiang", -- 401
	"ninilite", -- 402
	"wuyun", -- 403
	"dataotie", -- 404
	"xiaotaotie", -- 405
	"dahuayao", -- 406
	"xiaohuayao", -- 407
	"dashanxiao", -- 408
	"xiaoshanxiao", -- 409
	"dayingzhao", -- 410
	"zhongyingzhao", -- 411
	"xiaoyingzhao", -- 412
	"dahuli", -- 413
	"xiaohuli" -- 414
} -- 391
local files -- 416
do -- 416
	local _accum_0 = { } -- 416
	local _len_0 = 1 -- 416
	for _index_0 = 1, #includes do -- 416
		local k = includes[_index_0] -- 416
		if fileSet[k] then -- 416
			_accum_0[_len_0] = k -- 416
			_len_0 = _len_0 + 1 -- 416
		end -- 416
	end -- 416
	files = _accum_0 -- 416
end -- 416
local defaultFaceLeft = Set({ -- 419
	"liyena", -- 419
	"dataotie", -- 420
	"dahuayao", -- 421
	"xiaohuayao", -- 422
	"dashanxiao", -- 423
	"xiaoshanxiao", -- 424
	"dayingzhao", -- 425
	"zhongyingzhao", -- 426
	"xiaoyingzhao", -- 427
	"dahuli", -- 428
	"xiaohuli" -- 429
}) -- 418
local looks = { -- 432
	xiaohuayao = "white", -- 432
	dashanxiao = "glasses" -- 433
} -- 431
local scenes = { -- 436
	"LoopTowerA", -- 436
	"Station", -- 437
	"Factory", -- 438
	"FrozenCity", -- 439
	"AbandonedCity", -- 440
	"OuterHeaven", -- 441
	"TrainA", -- 442
	"TrainB", -- 443
	"VRTraining", -- 444
	"PreparationRoom", -- 445
	"PassageA", -- 446
	"PassageB", -- 447
	"PassageC", -- 448
	"PassageD", -- 449
	"TrainingRoom", -- 450
	"OperationRoom", -- 451
	"RestRoom", -- 452
	"RDRoom" -- 453
} -- 435
local currentScene = 3 -- 455
local createScene -- 457
createScene = function() -- 457
	local world = Store.world -- 458
	if world then -- 459
		world:removeFromParent() -- 459
	end -- 459
	world = (require("Scene." .. tostring(scenes[currentScene])))() -- 460
	Store.world = world -- 461
	return Director.entry:addChild(world) -- 462
end -- 457
local createUnit -- 475
createUnit = function() -- 475
	if unit then -- 476
		unit:removeFromParent() -- 476
	end -- 476
	Group({ -- 477
		"player" -- 477
	}):each(function(self) -- 477
		local _obj_0 = self.unit -- 477
		if _obj_0 ~= nil then -- 477
			return _obj_0:removeFromParent() -- 477
		end -- 477
		return nil -- 477
	end) -- 477
	Entity({ -- 480
		player = true, -- 480
		name = playable -- 481
	}) -- 479
	local entity = Group({ -- 483
		"player" -- 483
	}):find(function() -- 483
		return true -- 483
	end) -- 483
	local anims = Set(Spine:getAnimations(playable)) -- 485
	do -- 487
		local _accum_0 = { } -- 487
		local _len_0 = 1 -- 487
		for anim in pairs(targetAnims) do -- 487
			if not anims[anim] then -- 488
				_accum_0[_len_0] = anim -- 489
			else -- 490
				goto _continue_0 -- 490
			end -- 488
			_len_0 = _len_0 + 1 -- 490
			::_continue_0:: -- 488
		end -- 490
		missingAnims = _accum_0 -- 487
	end -- 490
	do -- 492
		local _accum_0 = { } -- 492
		local _len_0 = 1 -- 492
		for anim in pairs(anims) do -- 492
			if not targetAnims[anim] then -- 493
				_accum_0[_len_0] = anim -- 494
			else -- 495
				goto _continue_1 -- 495
			end -- 493
			_len_0 = _len_0 + 1 -- 495
			::_continue_1:: -- 493
		end -- 495
		extraAnims = _accum_0 -- 492
	end -- 495
	defaultFaceRight = not defaultFaceLeft[playable] -- 497
	local getUnitDef -- 499
	getUnitDef = function() -- 499
		local _with_0 = Dictionary() -- 499
		_with_0.linearAcceleration = Vec2(0, -15) -- 500
		_with_0.bodyType = "Dynamic" -- 501
		_with_0.scale = 1.0 -- 502
		_with_0.density = 1.0 -- 503
		_with_0.friction = 1.0 -- 504
		_with_0.restitution = 0.0 -- 505
		_with_0.playable = "spine:" .. tostring(playable) -- 506
		_with_0.defaultFaceRight = defaultFaceRight -- 507
		_with_0.size = Size(100, 300) -- 508
		_with_0.sensity = 0 -- 509
		_with_0.move = 300 -- 510
		_with_0.jump = 1200 -- 511
		_with_0.detectDistance = 300 -- 512
		_with_0.hp = 5.0 -- 513
		_with_0.tag = "player" -- 514
		_with_0.decisionTree = "AI:PlayerControl" -- 515
		_with_0.usePreciseHit = false -- 516
		do -- 517
			local _with_1 = Array({ -- 518
				"idle", -- 518
				"turn", -- 519
				"fallOff", -- 520
				"test", -- 521
				"cancel", -- 522
				"keepIdle", -- 523
				"keepMove", -- 524
				"idle1" -- 525
			}) -- 517
			if anims["fstep"] then -- 527
				_with_1:add("rush") -- 527
			end -- 527
			if anims["bstep"] then -- 528
				_with_1:add("evade") -- 528
			end -- 528
			if anims["jump"] then -- 529
				_with_1:add("jump") -- 529
			end -- 529
			if anims["pistol"] then -- 530
				_with_1:add("pistol") -- 530
			end -- 530
			if anims["fall"] and anims["standUp"] then -- 531
				_with_1:add("fall") -- 531
			end -- 531
			if anims["fmove"] or anims["move"] then -- 532
				_with_1:add("fmove") -- 532
			end -- 532
			if anims["bmove"] then -- 533
				_with_1:add("bmove") -- 533
			end -- 533
			_with_0.actions = _with_1 -- 517
		end -- 517
		return _with_0 -- 499
	end -- 499
	do -- 535
		local _accum_0 = { } -- 535
		local _len_0 = 1 -- 535
		for _index_0 = 1, #testAnims do -- 535
			local anim = testAnims[_index_0] -- 535
			if anims[anim] then -- 536
				_accum_0[_len_0] = anim -- 537
			else -- 538
				goto _continue_2 -- 538
			end -- 536
			_len_0 = _len_0 + 1 -- 538
			::_continue_2:: -- 536
		end -- 538
		availableAnims = _accum_0 -- 535
	end -- 538
	for _index_0 = 1, #extraAnims do -- 540
		local a = extraAnims[_index_0] -- 540
		table.insert(availableAnims, a) -- 541
	end -- 541
	local world = Store.world -- 543
	local grabSize <const> = 800 -- 544
	do -- 545
		local _with_0 = Unit(getUnitDef(), world, entity, Vec2(100, world.offset + 150)) -- 545
		_with_0.group = 1 -- 546
		do -- 547
			local _with_1 = _with_0.playable -- 547
			_with_1.look = looks[playable] or "" -- 548
			local parent = _with_1.parent -- 549
			_with_1:moveToParent((function() -- 550
				local _with_2 = Node() -- 550
				_with_2.size = Size(grabSize, grabSize) -- 551
				_with_2:addTo(parent) -- 558
				return _with_2 -- 550
			end)()) -- 550
			_with_1.position = Vec2(grabSize / 2, grabSize / 2 - 150) -- 559
		end -- 547
		unit = _with_0 -- 545
	end -- 545
	if unit.playable.hitTestEnabled then -- 561
		entity.hitTest = true -- 562
	end -- 561
	local scaleY = defaultFaceRight and 1.0 or -1.0 -- 564
	do -- 566
		local _with_0 = unit.playable -- 566
		_with_0:setSlot("item", (function() -- 567
			local _with_1 = Spine("coldweapon") -- 567
			_with_1.look = "grenade" -- 568
			_with_1.scaleX = 0.04 -- 569
			_with_1.scaleY = 0.04 * scaleY -- 570
			return _with_1 -- 567
		end)()) -- 567
		_with_0:setSlot("comm", (function() -- 571
			local _with_1 = Spine("coldweapon") -- 571
			_with_1.look = "comm" -- 572
			_with_1.scaleX = 0.06 -- 573
			_with_1.scaleY = 0.06 * scaleY -- 574
			return _with_1 -- 571
		end)()) -- 571
		_with_0:setSlot("comp", (function() -- 575
			local _with_1 = Spine("coldweapon") -- 575
			_with_1.look = "comp" -- 576
			_with_1.scaleX = 0.1 -- 577
			_with_1.scaleY = 0.1 * scaleY -- 578
			return _with_1 -- 575
		end)()) -- 575
		_with_0:setSlot("shield", (function() -- 579
			local _with_1 = Spine("coldweapon") -- 579
			_with_1.look = "shield" -- 580
			_with_1.scaleX = 0.2 -- 581
			_with_1.scaleY = 0.2 * scaleY -- 582
			return _with_1 -- 579
		end)()) -- 579
		_with_0:setSlot("melee", (function() -- 583
			local _with_1 = Spine("coldweapon") -- 583
			_with_1.look = "sword" -- 584
			_with_1.scaleX = 0.2 -- 585
			_with_1.scaleY = 0.2 * scaleY -- 586
			return _with_1 -- 583
		end)()) -- 583
		_with_0:setSlot("bow", (function() -- 587
			local _with_1 = Spine("coldweapon") -- 587
			_with_1.look = "bow" -- 588
			_with_1.scaleX = 0.2 -- 589
			_with_1.scaleY = 0.2 * scaleY -- 590
			return _with_1 -- 587
		end)()) -- 587
		_with_0:setSlot("pistol", (function() -- 591
			local _with_1 = Spine("kineticgun") -- 591
			_with_1.look = "PT" -- 592
			_with_1.scaleX = 0.2 -- 593
			_with_1.scaleY = 0.2 * scaleY -- 594
			return _with_1 -- 591
		end)()) -- 591
		_with_0:setSlot("gun", (function() -- 595
			local _with_1 = Spine("kineticgun") -- 595
			_with_1.look = "AR" -- 596
			_with_1.scaleX = 0.2 -- 597
			_with_1.scaleY = 0.2 * scaleY -- 598
			return _with_1 -- 595
		end)()) -- 595
	end -- 566
	local shadow -- 600
	do -- 600
		local _with_0 = Sprite("Image/shadow.png") -- 600
		_with_0.order = -1 -- 601
		_with_0:schedule(function() -- 602
			local start = unit.position -- 603
			local stop = start + Vec2(0, -1000) -- 604
			if world:raycast(start, stop, false, function(body, point) -- 605
				if body.group == Data.groupTerrain then -- 606
					stop = point -- 607
					return true -- 608
				end -- 606
				return false -- 609
			end) then -- 605
				_with_0.y = stop.y - unit.y -- 610
			end -- 605
		end) -- 602
		_with_0:addTo(unit) -- 611
		shadow = _with_0 -- 600
	end -- 600
	world:addChild(unit) -- 612
	do -- 613
		local _with_0 = world.camera -- 613
		_with_0.position = unit.position -- 614
		_with_0.followTarget = unit -- 615
	end -- 613
	if scenes[currentScene] == "PreparationRoom" then -- 617
		world:turnOnLights() -- 618
		return world:makeUnitEnter(unit) -- 619
	else -- 621
		if not Group({ -- 621
			"name", -- 621
			"player" -- 621
		}):find(function(self) -- 621
			return self.name == "liyena" and not self.player -- 621
		end) then -- 621
			Entity({ -- 623
				player = false, -- 623
				name = "liyena", -- 624
				faceRight = true, -- 625
				position = Vec2(300, world.offset), -- 626
				order = -1, -- 627
				base = true -- 628
			}) -- 622
			Entity({ -- 630
				player = false, -- 630
				name = "moling", -- 631
				faceRight = true, -- 632
				position = Vec2(300, world.offset), -- 633
				order = -2, -- 634
				base = true -- 635
			}) -- 629
			Entity({ -- 637
				player = false, -- 637
				name = "villywan", -- 638
				faceRight = true, -- 639
				position = Vec2(300, world.offset), -- 640
				order = 1, -- 641
				base = true -- 642
			}) -- 636
			return Entity({ -- 644
				player = false, -- 644
				name = "ayan", -- 645
				faceRight = true, -- 646
				position = Vec2(300, world.offset), -- 647
				order = 2, -- 648
				base = true -- 649
			}) -- 649
		end -- 621
	end -- 617
end -- 475
local currentFile = 1 -- 651
createScene() -- 653
if #files > 0 then -- 654
	for i = 1, #files do -- 655
		if files[i] == "charF" then -- 656
			playable = files[i] -- 657
			currentFile = math.tointeger(i) -- 658
			break -- 659
		end -- 656
	end -- 659
	if not playable then -- 660
		currentFile = 1 -- 661
		playable = files[1] -- 662
	end -- 660
	createUnit() -- 663
end -- 654
local battle = false -- 665
return Director.entry:addChild((function() -- 666
	local _with_0 = Node() -- 666
	_with_0:schedule(function() -- 667
		local width, height -- 668
		do -- 668
			local _obj_0 = App.visualSize -- 668
			width, height = _obj_0.width, _obj_0.height -- 668
		end -- 668
		SetNextWindowPos(Vec2(width - 300, 10), "FirstUseEver") -- 669
		SetNextWindowSize(Vec2(290, 325), "FirstUseEver") -- 670
		return Begin("Spine", { -- 671
			"NoResize", -- 671
			"NoSavedSettings" -- 671
		}, function() -- 671
			local changed -- 672
			changed, currentScene = Combo("Scene", currentScene, scenes) -- 672
			if changed then -- 673
				createScene() -- 674
				createUnit() -- 675
			end -- 673
			changed, currentFile = Combo("Spine", currentFile, files) -- 676
			if changed then -- 677
				playable = files[currentFile] -- 678
				createUnit() -- 679
			end -- 677
			changed, defaultFaceRight = Checkbox("默认朝向右", defaultFaceRight) -- 680
			if changed then -- 681
				createUnit() -- 681
			end -- 681
			changed, battle = Checkbox("战斗状态", battle) -- 682
			if changed then -- 683
				Store.battle = battle -- 684
				if unit.onSurface then -- 685
					unit:start("cancel") -- 686
					unit:start("idle") -- 687
				end -- 685
			end -- 683
			for i, anim in ipairs(availableAnims) do -- 688
				if Button(anim) then -- 689
					if not unit.currentAction or unit.currentAction.name ~= "test_" then -- 690
						if not unit:isDoing("test") then -- 691
							Store.testAction = anim -- 692
							unit:start("test") -- 693
						end -- 691
					end -- 690
				end -- 689
				if i % 3 ~= 0 and i ~= #availableAnims then -- 694
					SameLine() -- 694
				end -- 694
			end -- 694
			if #missingAnims > 0 then -- 695
				Text("缺失动作或名称错误：") -- 696
				Text(table.concat(missingAnims, "\n")) -- 697
			end -- 695
			if #extraAnims > 0 then -- 698
				Text("多余动作：") -- 699
				return Text(table.concat(extraAnims, "\n")) -- 700
			end -- 698
		end) -- 700
	end) -- 667
	return _with_0 -- 666
end)()) -- 700
