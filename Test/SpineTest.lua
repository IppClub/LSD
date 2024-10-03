-- [yue]: Test/SpineTest.yue
local Path = Dora.Path -- 1
local Content = Dora.Content -- 1
local Director = Dora.Director -- 1
local _module_0 = Dora.Platformer -- 1
local Data = _module_0.Data -- 1
local UnitAction = _module_0.UnitAction -- 1
local once = Dora.once -- 1
local sleep = Dora.sleep -- 1
local cycle = Dora.cycle -- 1
local math = _G.math -- 1
local coroutine = _G.coroutine -- 1
local Vec2 = Dora.Vec2 -- 1
local _module_1 = Dora.Platformer.Decision -- 1
local Sel = _module_1.Sel -- 1
local Seq = _module_1.Seq -- 1
local Con = _module_1.Con -- 1
local AI = _module_1.AI -- 1
local Act = _module_1.Act -- 1
local Reject = _module_1.Reject -- 1
local tostring = _G.tostring -- 1
local Group = Dora.Group -- 1
local Entity = Dora.Entity -- 1
local Spine = Dora.Spine -- 1
local pairs = _G.pairs -- 1
local Dictionary = Dora.Dictionary -- 1
local Size = Dora.Size -- 1
local Array = Dora.Array -- 1
local table = _G.table -- 1
local Unit = _module_0.Unit -- 1
local Node = Dora.Node -- 1
local Sprite = Dora.Sprite -- 1
local App = Dora.App -- 1
local _module_2 = Dora.ImGui -- 1
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
Director.ui3D:addChild(HUDControl()) -- 22
local Store = Data.store -- 24
UnitAction:add("fall", { -- 27
	priority = 10, -- 27
	reaction = 3, -- 28
	recovery = 0.1, -- 29
	queued = true, -- 30
	available = function() -- 31
		return true -- 31
	end, -- 31
	create = function(self) -- 32
		return once(function() -- 32
			local _with_0 = self.playable -- 32
			_with_0.speed = 1 -- 33
			sleep(_with_0:play("fall")) -- 34
			sleep(0.1) -- 35
			_with_0.recovery = 0 -- 36
			sleep(_with_0:play("standUp")) -- 37
			return _with_0 -- 32
		end) -- 37
	end -- 32
}) -- 26
UnitAction:add("evade", { -- 40
	priority = 10, -- 40
	reaction = 10, -- 41
	recovery = 0, -- 42
	queued = true, -- 43
	available = function() -- 44
		return true -- 44
	end, -- 44
	create = function(self) -- 45
		local time = 0 -- 46
		do -- 47
			local _with_0 = self.playable -- 47
			_with_0.speed = 1.0 -- 48
			time = _with_0:play("bstep") -- 49
		end -- 47
		return once(function(self) -- 50
			local dir = self.faceRight and -1 or 1 -- 51
			cycle(math.max(time, 0.4), function() -- 52
				self.velocityX = 800 * dir -- 52
			end) -- 52
			do -- 53
				local _with_0 = self.playable -- 53
				_with_0.recovery = 0.3 -- 54
				_with_0.speed = 1.0 -- 55
				_with_0:play("idle") -- 56
			end -- 53
			sleep(0.3) -- 57
			return true -- 58
		end) -- 58
	end -- 45
}) -- 39
UnitAction:add("rush", { -- 61
	priority = 10, -- 61
	reaction = 10, -- 62
	recovery = 0, -- 63
	queued = true, -- 64
	available = function() -- 65
		return true -- 65
	end, -- 65
	create = function(self) -- 66
		local time = 0 -- 67
		do -- 68
			local _with_0 = self.playable -- 68
			_with_0.speed = 1.0 -- 69
			time = _with_0:play("fstep") -- 70
		end -- 68
		return once(function(self) -- 71
			local dir = self.faceRight and 1 or -1 -- 72
			cycle(math.max(time, 0.4), function() -- 73
				self.velocityX = 800 * dir -- 73
			end) -- 73
			do -- 74
				local _with_0 = self.playable -- 74
				_with_0.recovery = 0.3 -- 75
				_with_0.speed = 1.0 -- 76
				_with_0:play("idle") -- 77
			end -- 74
			sleep(0.3) -- 78
			return true -- 79
		end) -- 79
	end -- 66
}) -- 60
local pistolEnd -- 81
pistolEnd = function(name, playable) -- 81
	if name == "pistol" then -- 81
		return playable.parent.parent:stop() -- 82
	end -- 81
end -- 81
UnitAction:add("pistol", { -- 85
	priority = 3, -- 85
	reaction = 3, -- 86
	recovery = 0.2, -- 87
	queued = true, -- 88
	available = function() -- 89
		return true -- 89
	end, -- 89
	create = function(self) -- 90
		do -- 91
			local _with_0 = self.playable -- 91
			_with_0.speed = 1 -- 92
			_with_0:play("pistol") -- 93
			_with_0:slot("AnimationEnd", pistolEnd) -- 94
		end -- 91
		return function() -- 95
			return false -- 95
		end -- 95
	end, -- 90
	stop = function(self) -- 96
		return self.playable:slot("AnimationEnd"):remove(pistolEnd) -- 97
	end -- 96
}) -- 84
local testEnd -- 99
testEnd = function(name, playable) -- 99
	if name == Store.testAction then -- 99
		return playable.parent.parent:stop() -- 100
	end -- 99
end -- 99
UnitAction:add("test", { -- 103
	priority = 3, -- 103
	reaction = 3, -- 104
	recovery = 0.1, -- 105
	queued = true, -- 106
	available = function() -- 107
		return true -- 107
	end, -- 107
	create = function(self) -- 108
		do -- 109
			local _with_0 = self.playable -- 109
			_with_0.speed = 1 -- 110
			_with_0:play(Store.testAction) -- 111
			_with_0:slot("AnimationEnd", testEnd) -- 112
		end -- 109
		return function() -- 113
			return false -- 113
		end -- 113
	end, -- 108
	stop = function(self) -- 114
		return self.playable:slot("AnimationEnd"):remove(testEnd) -- 115
	end -- 114
}) -- 102
UnitAction:add("idle", { -- 118
	priority = 1, -- 118
	reaction = 2.0, -- 119
	recovery = 0.2, -- 120
	available = function(self) -- 121
		return self.onSurface -- 121
	end, -- 121
	create = function(self) -- 122
		local _with_0 = self.playable -- 122
		_with_0.speed = 1.0 -- 123
		if Store.battle then -- 124
			do -- 125
				local _exp_0 = _with_0.lastCompleted -- 125
				if "melee" == _exp_0 or "pistol" == _exp_0 or "bow" == _exp_0 or "gun1" == _exp_0 or "gun2" == _exp_0 or "gun3" == _exp_0 or "throw" == _exp_0 or "parry" == _exp_0 or "defense" == _exp_0 or "comp" == _exp_0 or "comm" == _exp_0 then -- 126
					_with_0.recovery = 0.0 -- 127
				end -- 127
			end -- 127
			_with_0:play("prepare", true) -- 128
			return function(self) -- 129
				return not self.onSurface -- 129
			end -- 129
		else -- 131
			_with_0:play("idle", true) -- 131
			local playIdleSpecial = coroutine.create(function() -- 132
				while true do -- 132
					sleep(3) -- 133
					sleep(_with_0:play("idle1")) -- 134
					_with_0:play("idle", true) -- 135
				end -- 135
			end) -- 132
			self.data.playIdleSpecial = playIdleSpecial -- 136
			return function(self) -- 137
				coroutine.resume(playIdleSpecial) -- 138
				return not self.onSurface -- 139
			end -- 139
		end -- 124
		return _with_0 -- 122
	end -- 122
}) -- 117
UnitAction:add("fmove", { -- 142
	priority = 1, -- 142
	reaction = 2.0, -- 143
	recovery = 0.2, -- 144
	available = function(self) -- 145
		return self.onSurface -- 145
	end, -- 145
	create = function(self) -- 146
		do -- 147
			local _with_0 = self.playable -- 147
			_with_0.speed = 1 -- 148
			local duration = _with_0:play("fmove", true) -- 149
			if duration == 0 then -- 150
				_with_0:play("move", true) -- 151
			end -- 150
		end -- 147
		return function(self, action) -- 152
			local elapsedTime, recovery = action.elapsedTime, action.recovery -- 153
			local move = self.unitDef.move -- 154
			local moveSpeed -- 155
			if elapsedTime < recovery then -- 155
				moveSpeed = math.min(elapsedTime / recovery, 1.0) -- 156
			else -- 158
				moveSpeed = 1.0 -- 158
			end -- 155
			self.velocityX = moveSpeed * (self.faceRight and move or -move) -- 159
			return not self.onSurface -- 160
		end -- 160
	end -- 146
}) -- 141
UnitAction:add("keepIdle", { -- 163
	priority = 100, -- 163
	reaction = 2.0, -- 164
	recovery = 0.2, -- 165
	available = function() -- 166
		return true -- 166
	end, -- 166
	create = function(self) -- 167
		do -- 168
			local _with_0 = self.playable -- 168
			_with_0.speed = 1 -- 169
			_with_0:play("idle", true) -- 170
		end -- 168
		return function() -- 171
			return false -- 171
		end -- 171
	end -- 167
}) -- 162
UnitAction:add("idle1", { -- 174
	priority = 1, -- 174
	reaction = 2.0, -- 175
	recovery = 0.2, -- 176
	available = function() -- 177
		return true -- 177
	end, -- 177
	queued = true, -- 178
	create = function(self) -- 179
		return once(function() -- 179
			local _with_0 = self.playable -- 180
			_with_0.speed = 1 -- 181
			sleep(_with_0:play("idle1", false)) -- 182
			return _with_0 -- 180
		end) -- 182
	end -- 179
}) -- 173
UnitAction:add("keepMove", { -- 185
	priority = 100, -- 185
	reaction = 2.0, -- 186
	recovery = 0.2, -- 187
	available = function() -- 188
		return true -- 188
	end, -- 188
	create = function(self) -- 189
		do -- 190
			local _with_0 = self.playable -- 190
			_with_0.speed = 1 -- 191
			_with_0:play("fmove", true) -- 192
		end -- 190
		return function() -- 193
			return false -- 193
		end -- 193
	end -- 189
}) -- 184
UnitAction:add("bmove", { -- 196
	priority = 1, -- 196
	reaction = 2.0, -- 197
	recovery = 0.2, -- 198
	available = function(self) -- 199
		return self.onSurface -- 199
	end, -- 199
	create = function(self) -- 200
		do -- 201
			local _with_0 = self.playable -- 201
			_with_0.speed = 1 -- 202
			_with_0:play("bmove", true) -- 203
		end -- 201
		return function(self, action) -- 204
			local elapsedTime, recovery = action.elapsedTime, action.recovery -- 205
			local move = self.unitDef.move -- 206
			local moveSpeed -- 207
			if elapsedTime < recovery then -- 207
				moveSpeed = math.min(elapsedTime / recovery, 1.0) -- 208
			else -- 210
				moveSpeed = 1.0 -- 210
			end -- 207
			self.velocityX = moveSpeed * (self.faceRight and -move or move) * 0.5 -- 211
			return not self.onSurface -- 212
		end -- 212
	end -- 200
}) -- 195
UnitAction:add("jump", { -- 215
	priority = 3, -- 215
	reaction = 2.0, -- 216
	recovery = 0.1, -- 217
	queued = true, -- 218
	available = function(self) -- 219
		return self.onSurface -- 219
	end, -- 219
	create = function(self) -- 220
		local velocityX = self.velocityX -- 221
		local jump = self.unitDef.jump -- 222
		self.velocity = Vec2(velocityX, jump) -- 223
		return once(function(self, _action) -- 224
			local _with_0 = self.playable -- 225
			_with_0.speed = 1 -- 226
			sleep(_with_0:play("jump", false)) -- 227
			return _with_0 -- 225
		end) -- 227
	end -- 220
}) -- 214
UnitAction:add("fallOff", { -- 230
	priority = 2, -- 230
	reaction = -1, -- 231
	recovery = 0.3, -- 232
	available = function(self) -- 233
		return not self.onSurface -- 233
	end, -- 233
	create = function(self) -- 234
		if self.playable.current ~= "jumping" then -- 235
			local _with_0 = self.playable -- 236
			_with_0.speed = 1 -- 237
			_with_0:play("jumping", true) -- 238
		end -- 235
		return once(function(self, _action) -- 239
			while true do -- 240
				if self.onSurface then -- 241
					do -- 242
						local _with_0 = self.playable -- 242
						_with_0.speed = 1 -- 243
						sleep(_with_0:play("landing", false)) -- 244
					end -- 242
					coroutine.yield(true) -- 245
				else -- 247
					coroutine.yield(false) -- 247
				end -- 241
			end -- 247
		end) -- 247
	end -- 234
}) -- 229
Store["AI:NPC"] = Sel({ -- 250
	Seq({ -- 251
		Con("not facing nearest unit", function(self) -- 251
			local _list_0 = AI:getDetectedUnits() -- 252
			for _index_0 = 1, #_list_0 do -- 252
				local unit = _list_0[_index_0] -- 252
				if unit.entity.player then -- 253
					return (self.x > unit.x) == self.faceRight -- 254
				end -- 253
			end -- 254
			local unit = AI:getNearestUnit("Any") -- 255
			if unit then -- 255
				return (self.x > unit.x) == self.faceRight -- 256
			else -- 258
				return false -- 258
			end -- 255
		end), -- 251
		Act("turn") -- 259
	}), -- 250
	Act("idle") -- 261
}) -- 249
Store["AI:PlayerControl"] = Sel({ -- 265
	Seq({ -- 266
		Sel({ -- 267
			Seq({ -- 268
				Con("fmove key down", function(self) -- 268
					return not (self.entity.keyLeft and self.entity.keyRight) and ((self.entity.keyLeft and self.faceRight) or (self.entity.keyRight and not self.faceRight)) -- 273
				end), -- 268
				Act("turn") -- 274
			}), -- 267
			Seq({ -- 277
				Con("bmove key down", function(self) -- 277
					return not (self.entity.keyLeft or self.entity.keyRight) and not (self.entity.keyBLeft and self.entity.keyBRight) and ((self.entity.keyBLeft and not self.faceRight) or (self.entity.keyBRight and self.faceRight)) -- 283
				end), -- 277
				Act("turn") -- 284
			}) -- 276
		}), -- 266
		Reject() -- 287
	}), -- 265
	Seq({ -- 290
		Con("pistol", function(self) -- 290
			return self.entity.keyShoot -- 290
		end), -- 290
		Act("pistol") -- 291
	}), -- 289
	Seq({ -- 294
		Con("evade", function(self) -- 294
			return self.entity.keyEvade -- 294
		end), -- 294
		Act("evade") -- 295
	}), -- 293
	Seq({ -- 298
		Con("rush", function(self) -- 298
			return self.entity.keyRush -- 298
		end), -- 298
		Act("rush") -- 299
	}), -- 297
	Seq({ -- 302
		Con("fall", function(self) -- 302
			return self.entity.keyFall -- 302
		end), -- 302
		Act("fall") -- 303
	}), -- 301
	Sel({ -- 306
		Seq({ -- 307
			Con("is falling", function(self) -- 307
				return not self.onSurface -- 307
			end), -- 307
			Act("fallOff") -- 308
		}), -- 306
		Seq({ -- 311
			Con("jump key down", function(self) -- 311
				return self.entity.keyUp -- 311
			end), -- 311
			Act("jump") -- 312
		}) -- 310
	}), -- 305
	Seq({ -- 316
		Con("fmove key down", function(self) -- 316
			return self.entity.keyLeft or self.entity.keyRight -- 316
		end), -- 316
		Act("fmove") -- 317
	}), -- 315
	Seq({ -- 320
		Con("bmove key down", function(self) -- 320
			return self.entity.keyBLeft or self.entity.keyBRight -- 320
		end), -- 320
		Act("bmove") -- 321
	}), -- 319
	Act("idle") -- 323
}) -- 264
Store.battle = false -- 326
local unit = nil -- 328
local playable = nil -- 329
local targetAnims = Set({ -- 332
	"bmove", -- 332
	"bow", -- 333
	"bstep", -- 334
	"comm", -- 335
	"comp", -- 336
	"defence", -- 337
	"fall", -- 338
	"fmove", -- 339
	"fstep", -- 340
	"gun1", -- 341
	"gun2", -- 342
	"gun3", -- 343
	"hit", -- 344
	"idle", -- 345
	"idle1", -- 346
	"jump", -- 347
	"jumping", -- 348
	"landing", -- 349
	"lose", -- 350
	"melee", -- 351
	"parry", -- 352
	"pistol", -- 353
	"prepare", -- 354
	"standUp", -- 355
	"throw" -- 356
}) -- 331
local testAnims = { -- 360
	"bow", -- 360
	"gun1", -- 361
	"gun2", -- 362
	"gun3", -- 363
	"hit", -- 364
	"lose", -- 365
	"melee", -- 366
	"parry", -- 367
	"throw", -- 368
	"comm", -- 369
	"comp", -- 370
	"defence" -- 371
} -- 359
local missingAnims = { } -- 374
local extraAnims = { } -- 375
local availableAnims = { } -- 377
local defaultFaceRight = true -- 378
local getAllFiles -- 380
getAllFiles = function(path, exts) -- 380
	local filters = Set(exts) -- 381
	local _accum_0 = { } -- 382
	local _len_0 = 1 -- 382
	local _list_0 = Content:getAllFiles(path) -- 382
	for _index_0 = 1, #_list_0 do -- 382
		local file = _list_0[_index_0] -- 382
		if not filters[Path:getExt(file)] then -- 383
			goto _continue_0 -- 383
		end -- 383
		_accum_0[_len_0] = file -- 384
		_len_0 = _len_0 + 1 -- 384
		::_continue_0:: -- 383
	end -- 384
	return _accum_0 -- 384
end -- 380
local fileSet = Set((function() -- 386
	local _accum_0 = { } -- 386
	local _len_0 = 1 -- 386
	local _list_0 = getAllFiles("Spine", { -- 386
		"skel", -- 386
		"json" -- 386
	}) -- 386
	for _index_0 = 1, #_list_0 do -- 386
		local file = _list_0[_index_0] -- 386
		_accum_0[_len_0] = Path:getName(file) -- 387
		_len_0 = _len_0 + 1 -- 387
	end -- 387
	return _accum_0 -- 387
end)()) -- 386
local includes = { -- 389
	"char", -- 389
	"charF", -- 390
	"charM", -- 391
	"ayan", -- 392
	"liyena", -- 393
	"moling", -- 394
	"moyu", -- 395
	"villywan", -- 396
	"sunborn", -- 397
	"yuzijiang", -- 398
	"ninilite", -- 399
	"wuyun", -- 400
	"dataotie", -- 401
	"xiaotaotie", -- 402
	"dahuayao", -- 403
	"xiaohuayao", -- 404
	"dashanxiao", -- 405
	"xiaoshanxiao", -- 406
	"dayingzhao", -- 407
	"zhongyingzhao", -- 408
	"xiaoyingzhao", -- 409
	"dahuli", -- 410
	"xiaohuli" -- 411
} -- 388
local files -- 413
do -- 413
	local _accum_0 = { } -- 413
	local _len_0 = 1 -- 413
	for _index_0 = 1, #includes do -- 413
		local k = includes[_index_0] -- 413
		if fileSet[k] then -- 413
			_accum_0[_len_0] = k -- 413
			_len_0 = _len_0 + 1 -- 413
		end -- 413
	end -- 413
	files = _accum_0 -- 413
end -- 413
local defaultFaceLeft = Set({ -- 416
	"liyena", -- 416
	"dataotie", -- 417
	"dahuayao", -- 418
	"xiaohuayao", -- 419
	"dashanxiao", -- 420
	"xiaoshanxiao", -- 421
	"dayingzhao", -- 422
	"zhongyingzhao", -- 423
	"xiaoyingzhao", -- 424
	"dahuli", -- 425
	"xiaohuli" -- 426
}) -- 415
local looks = { -- 429
	xiaohuayao = "white", -- 429
	dashanxiao = "glasses" -- 430
} -- 428
local scenes = { -- 433
	"LoopTowerA", -- 433
	"Station", -- 434
	"Factory", -- 435
	"FrozenCity", -- 436
	"AbandonedCity", -- 437
	"OuterHeaven", -- 438
	"TrainA", -- 439
	"TrainB", -- 440
	"VRTraining", -- 441
	"PreparationRoom", -- 442
	"PassageA", -- 443
	"PassageB", -- 444
	"PassageC", -- 445
	"PassageD", -- 446
	"TrainingRoom", -- 447
	"OperationRoom", -- 448
	"RestRoom", -- 449
	"RDRoom" -- 450
} -- 432
local currentScene = 3 -- 452
local createScene -- 454
createScene = function() -- 454
	local world = Store.world -- 455
	if world then -- 456
		world:removeFromParent() -- 456
	end -- 456
	world = (require("Scene." .. tostring(scenes[currentScene])))() -- 457
	Store.world = world -- 458
	return Director.entry:addChild(world) -- 459
end -- 454
local _anon_func_0 = function(Node, Size, _with_1, grabSize, parent) -- 555
	do -- 547
		local _with_0 = Node() -- 547
		_with_0.size = Size(grabSize, grabSize) -- 548
		_with_0:addTo(parent) -- 555
		return _with_0 -- 547
	end -- 555
end -- 547
local _anon_func_1 = function(Spine, _with_0, scaleY) -- 567
	do -- 564
		local _with_1 = Spine("coldweapon") -- 564
		_with_1.look = "grenade" -- 565
		_with_1.scaleX = 0.04 -- 566
		_with_1.scaleY = 0.04 * scaleY -- 567
		return _with_1 -- 564
	end -- 567
end -- 564
local _anon_func_2 = function(Spine, _with_0, scaleY) -- 571
	do -- 568
		local _with_1 = Spine("coldweapon") -- 568
		_with_1.look = "comm" -- 569
		_with_1.scaleX = 0.06 -- 570
		_with_1.scaleY = 0.06 * scaleY -- 571
		return _with_1 -- 568
	end -- 571
end -- 568
local _anon_func_3 = function(Spine, _with_0, scaleY) -- 575
	do -- 572
		local _with_1 = Spine("coldweapon") -- 572
		_with_1.look = "comp" -- 573
		_with_1.scaleX = 0.1 -- 574
		_with_1.scaleY = 0.1 * scaleY -- 575
		return _with_1 -- 572
	end -- 575
end -- 572
local _anon_func_4 = function(Spine, _with_0, scaleY) -- 579
	do -- 576
		local _with_1 = Spine("coldweapon") -- 576
		_with_1.look = "shield" -- 577
		_with_1.scaleX = 0.2 -- 578
		_with_1.scaleY = 0.2 * scaleY -- 579
		return _with_1 -- 576
	end -- 579
end -- 576
local _anon_func_5 = function(Spine, _with_0, scaleY) -- 583
	do -- 580
		local _with_1 = Spine("coldweapon") -- 580
		_with_1.look = "sword" -- 581
		_with_1.scaleX = 0.2 -- 582
		_with_1.scaleY = 0.2 * scaleY -- 583
		return _with_1 -- 580
	end -- 583
end -- 580
local _anon_func_6 = function(Spine, _with_0, scaleY) -- 587
	do -- 584
		local _with_1 = Spine("coldweapon") -- 584
		_with_1.look = "bow" -- 585
		_with_1.scaleX = 0.2 -- 586
		_with_1.scaleY = 0.2 * scaleY -- 587
		return _with_1 -- 584
	end -- 587
end -- 584
local _anon_func_7 = function(Spine, _with_0, scaleY) -- 591
	do -- 588
		local _with_1 = Spine("kineticgun") -- 588
		_with_1.look = "PT" -- 589
		_with_1.scaleX = 0.2 -- 590
		_with_1.scaleY = 0.2 * scaleY -- 591
		return _with_1 -- 588
	end -- 591
end -- 588
local _anon_func_8 = function(Spine, _with_0, scaleY) -- 595
	do -- 592
		local _with_1 = Spine("kineticgun") -- 592
		_with_1.look = "AR" -- 593
		_with_1.scaleX = 0.2 -- 594
		_with_1.scaleY = 0.2 * scaleY -- 595
		return _with_1 -- 592
	end -- 595
end -- 592
local createUnit -- 472
createUnit = function() -- 472
	if unit then -- 473
		unit:removeFromParent() -- 473
	end -- 473
	Group({ -- 474
		"player" -- 474
	}):each(function(self) -- 474
		local _obj_0 = self.unit -- 474
		if _obj_0 ~= nil then -- 474
			return _obj_0:removeFromParent() -- 474
		end -- 474
		return nil -- 474
	end) -- 474
	Entity({ -- 477
		player = true, -- 477
		name = playable -- 478
	}) -- 476
	local entity = Group({ -- 480
		"player" -- 480
	}):find(function() -- 480
		return true -- 480
	end) -- 480
	local anims = Set(Spine:getAnimations(playable)) -- 482
	do -- 484
		local _accum_0 = { } -- 484
		local _len_0 = 1 -- 484
		for anim in pairs(targetAnims) do -- 484
			if not anims[anim] then -- 485
				_accum_0[_len_0] = anim -- 486
			else -- 487
				goto _continue_0 -- 487
			end -- 485
			_len_0 = _len_0 + 1 -- 487
			::_continue_0:: -- 485
		end -- 487
		missingAnims = _accum_0 -- 484
	end -- 487
	do -- 489
		local _accum_0 = { } -- 489
		local _len_0 = 1 -- 489
		for anim in pairs(anims) do -- 489
			if not targetAnims[anim] then -- 490
				_accum_0[_len_0] = anim -- 491
			else -- 492
				goto _continue_1 -- 492
			end -- 490
			_len_0 = _len_0 + 1 -- 492
			::_continue_1:: -- 490
		end -- 492
		extraAnims = _accum_0 -- 489
	end -- 492
	defaultFaceRight = not defaultFaceLeft[playable] -- 494
	local getUnitDef -- 496
	getUnitDef = function() -- 496
		local _with_0 = Dictionary() -- 496
		_with_0.linearAcceleration = Vec2(0, -15) -- 497
		_with_0.bodyType = "Dynamic" -- 498
		_with_0.scale = 1.0 -- 499
		_with_0.density = 1.0 -- 500
		_with_0.friction = 1.0 -- 501
		_with_0.restitution = 0.0 -- 502
		_with_0.playable = "spine:" .. tostring(playable) -- 503
		_with_0.defaultFaceRight = defaultFaceRight -- 504
		_with_0.size = Size(100, 300) -- 505
		_with_0.sensity = 0 -- 506
		_with_0.move = 300 -- 507
		_with_0.jump = 1200 -- 508
		_with_0.detectDistance = 300 -- 509
		_with_0.hp = 5.0 -- 510
		_with_0.tag = "player" -- 511
		_with_0.decisionTree = "AI:PlayerControl" -- 512
		_with_0.usePreciseHit = false -- 513
		local _with_1 = Array({ -- 515
			"idle", -- 515
			"turn", -- 516
			"fallOff", -- 517
			"test", -- 518
			"cancel", -- 519
			"keepIdle", -- 520
			"keepMove", -- 521
			"idle1" -- 522
		}) -- 514
		if anims["fstep"] then -- 524
			_with_1:add("rush") -- 524
		end -- 524
		if anims["bstep"] then -- 525
			_with_1:add("evade") -- 525
		end -- 525
		if anims["jump"] then -- 526
			_with_1:add("jump") -- 526
		end -- 526
		if anims["pistol"] then -- 527
			_with_1:add("pistol") -- 527
		end -- 527
		if anims["fall"] and anims["standUp"] then -- 528
			_with_1:add("fall") -- 528
		end -- 528
		if anims["fmove"] or anims["move"] then -- 529
			_with_1:add("fmove") -- 529
		end -- 529
		if anims["bmove"] then -- 530
			_with_1:add("bmove") -- 530
		end -- 530
		_with_0.actions = _with_1 -- 514
		return _with_0 -- 496
	end -- 496
	do -- 532
		local _accum_0 = { } -- 532
		local _len_0 = 1 -- 532
		for _index_0 = 1, #testAnims do -- 532
			local anim = testAnims[_index_0] -- 532
			if anims[anim] then -- 533
				_accum_0[_len_0] = anim -- 534
			else -- 535
				goto _continue_2 -- 535
			end -- 533
			_len_0 = _len_0 + 1 -- 535
			::_continue_2:: -- 533
		end -- 535
		availableAnims = _accum_0 -- 532
	end -- 535
	for _index_0 = 1, #extraAnims do -- 537
		local a = extraAnims[_index_0] -- 537
		table.insert(availableAnims, a) -- 538
	end -- 538
	local world = Store.world -- 540
	local grabSize <const> = 800 -- 541
	do -- 542
		local _with_0 = Unit(getUnitDef(), world, entity, Vec2(100, world.offset + 150)) -- 542
		_with_0.group = 1 -- 543
		local _with_1 = _with_0.playable -- 544
		_with_1.look = looks[playable] or "" -- 545
		local parent = _with_1.parent -- 546
		_with_1:moveToParent(_anon_func_0(Node, Size, _with_1, grabSize, parent)) -- 547
		_with_1.position = Vec2(grabSize / 2, grabSize / 2 - 150) -- 556
		unit = _with_0 -- 542
	end -- 542
	if unit.playable.hitTestEnabled then -- 558
		entity.hitTest = true -- 559
	end -- 558
	local scaleY = defaultFaceRight and 1.0 or -1.0 -- 561
	do -- 563
		local _with_0 = unit.playable -- 563
		_with_0:setSlot("item", _anon_func_1(Spine, _with_0, scaleY)) -- 564
		_with_0:setSlot("comm", _anon_func_2(Spine, _with_0, scaleY)) -- 568
		_with_0:setSlot("comp", _anon_func_3(Spine, _with_0, scaleY)) -- 572
		_with_0:setSlot("shield", _anon_func_4(Spine, _with_0, scaleY)) -- 576
		_with_0:setSlot("melee", _anon_func_5(Spine, _with_0, scaleY)) -- 580
		_with_0:setSlot("bow", _anon_func_6(Spine, _with_0, scaleY)) -- 584
		_with_0:setSlot("pistol", _anon_func_7(Spine, _with_0, scaleY)) -- 588
		_with_0:setSlot("gun", _anon_func_8(Spine, _with_0, scaleY)) -- 592
	end -- 563
	local shadow -- 597
	do -- 597
		local _with_0 = Sprite("Image/shadow.png") -- 597
		_with_0.order = -1 -- 598
		_with_0:schedule(function() -- 599
			local start = unit.position -- 600
			local stop = start + Vec2(0, -1000) -- 601
			if world:raycast(start, stop, false, function(body, point) -- 602
				if body.group == Data.groupTerrain then -- 603
					stop = point -- 604
					return true -- 605
				end -- 603
				return false -- 606
			end) then -- 602
				_with_0.y = stop.y - unit.y -- 607
			end -- 602
		end) -- 599
		_with_0:addTo(unit) -- 608
		shadow = _with_0 -- 597
	end -- 597
	world:addChild(unit) -- 609
	local _with_0 = world.camera -- 610
	_with_0.position = unit.position -- 611
	_with_0.followTarget = unit -- 612
	return _with_0 -- 610
end -- 472
local currentFile = 1 -- 614
createScene() -- 616
if #files > 0 then -- 617
	for i = 1, #files do -- 618
		if files[i] == "charF" then -- 619
			playable = files[i] -- 620
			currentFile = math.floor(i) -- 621
			break -- 622
		end -- 619
	end -- 622
	if not playable then -- 623
		currentFile = 1 -- 624
		playable = files[1] -- 625
	end -- 623
	createUnit() -- 626
end -- 617
local battle = false -- 628
return Director.entry:addChild((function() -- 629
	local _with_0 = Node() -- 629
	_with_0:schedule(function() -- 630
		local width, height -- 631
		do -- 631
			local _obj_0 = App.visualSize -- 631
			width, height = _obj_0.width, _obj_0.height -- 631
		end -- 631
		SetNextWindowPos(Vec2(width - 300, 10), "FirstUseEver") -- 632
		SetNextWindowSize(Vec2(290, 325), "FirstUseEver") -- 633
		return Begin("Spine", { -- 634
			"NoResize", -- 634
			"NoSavedSettings" -- 634
		}, function() -- 634
			local changed -- 635
			changed, currentScene = Combo("Scene", currentScene, scenes) -- 635
			if changed then -- 636
				createScene() -- 637
				createUnit() -- 638
			end -- 636
			changed, currentFile = Combo("Spine", currentFile, files) -- 639
			if changed then -- 640
				playable = files[currentFile] -- 641
				createUnit() -- 642
			end -- 640
			changed, defaultFaceRight = Checkbox("默认朝向右", defaultFaceRight) -- 643
			if changed then -- 644
				createUnit() -- 644
			end -- 644
			changed, battle = Checkbox("战斗状态", battle) -- 645
			if changed then -- 646
				Store.battle = battle -- 647
				if unit.onSurface then -- 648
					unit:start("cancel") -- 649
					unit:start("idle") -- 650
				end -- 648
			end -- 646
			for i, anim in ipairs(availableAnims) do -- 651
				if Button(anim) then -- 652
					if not unit.currentAction or unit.currentAction.name ~= "test_" then -- 653
						if not unit:isDoing("test") then -- 654
							Store.testAction = anim -- 655
							unit:start("test") -- 656
						end -- 654
					end -- 653
				end -- 652
				if i % 3 ~= 0 and i ~= #availableAnims then -- 657
					SameLine() -- 657
				end -- 657
			end -- 657
			if #missingAnims > 0 then -- 658
				Text("缺失动作或名称错误：") -- 659
				Text(table.concat(missingAnims, "\n")) -- 660
			end -- 658
			if #extraAnims > 0 then -- 661
				Text("多余动作：") -- 662
				return Text(table.concat(extraAnims, "\n")) -- 663
			end -- 661
		end) -- 663
	end) -- 630
	return _with_0 -- 629
end)()) -- 663
