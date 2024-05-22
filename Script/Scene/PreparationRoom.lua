-- [yue]: Script/Scene/PreparationRoom.yue
local Spine = Dora.Spine -- 1
local Class = Dora.Class -- 1
local property = Dora.property -- 1
local Vec2 = Dora.Vec2 -- 1
local Sprite = Dora.Sprite -- 1
local View = Dora.View -- 1
local Rect = Dora.Rect -- 1
local once = Dora.once -- 1
local cycle = Dora.cycle -- 1
local Ease = Dora.Ease -- 1
local sleep = Dora.sleep -- 1
local _module_0 = Dora.Platformer -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local BodyDef = Dora.BodyDef -- 1
local Body = Dora.Body -- 1
local Data = _module_0.Data -- 1
local Array = Dora.Array -- 1
local Cache = Dora.Cache -- 1
local _module_0 = nil -- 1
local Map = require("Academy.Map") -- 2
local W <const> = 3840 -- 4
local HW <const> = W / 2 -- 5
local H <const> = 1080 -- 6
local HH <const> = H / 2 -- 7
local Offset <const> = 0 -- 8
local BackZ <const> = 470 -- 9
local ZOffset <const> = BackZ / 2 -- 10
local PathOffset <const> = 50 -- 11
local MaxPath <const> = 2 -- 12
local DefaultZoom <const> = 0.7 -- 13
local GateZ <const> = 400 -- 14
local SceneName <const> = "PreparationRoom" -- 15
local layerDefs = { -- 24
	{ -- 24
		look = "lantern", -- 24
		order = 100, -- 24
		x = W * (1.0 - DefaultZoom) / 2, -- 24
		scale = DefaultZoom -- 24
	}, -- 24
	{ -- 25
		look = "front", -- 25
		order = 99 -- 25
	}, -- 25
	{ -- 26
		look = "furniture", -- 26
		order = -100, -- 26
		z = 300 -- 26
	}, -- 26
	{ -- 27
		look = "shield", -- 27
		order = -101, -- 27
		z = GateZ -- 27
	}, -- 27
	{ -- 28
		look = "gate", -- 28
		order = -102, -- 28
		z = GateZ -- 28
	}, -- 28
	{ -- 29
		look = "elevatorfloor", -- 29
		order = -110, -- 29
		z = GateZ, -- 29
		angleX = 90 -- 29
	}, -- 29
	{ -- 30
		look = "elevator", -- 30
		order = -111, -- 30
		z = GateZ + 268 -- 30
	}, -- 30
	{ -- 31
		look = "leftwall", -- 31
		order = -112, -- 31
		angleY = -90 -- 31
	}, -- 31
	{ -- 32
		look = "rightwall", -- 32
		order = -113, -- 32
		x = W, -- 32
		angleY = 90 -- 32
	}, -- 32
	{ -- 33
		look = "floor", -- 33
		order = -114, -- 33
		angleX = 90 -- 33
	}, -- 33
	{ -- 34
		look = "back", -- 34
		order = -115, -- 34
		z = BackZ -- 34
	} -- 34
} -- 23
local addLayer -- 36
addLayer = function(world, def) -- 36
	local layer -- 37
	do -- 37
		local _with_0 = Spine("preparationRoom") -- 37
		_with_0.look = def.look -- 38
		_with_0.order = def.order -- 39
		_with_0.scaleX = def.scale or 1.0 -- 40
		_with_0.scaleY = def.scale or 1.0 -- 41
		_with_0.x = def.x or 0 -- 42
		_with_0.y = def.y or 0 -- 43
		_with_0.z = def.z or 0 -- 44
		_with_0.angleX = def.angleX or 0 -- 45
		_with_0.angleY = def.angleY or 0 -- 46
		_with_0.x = def.x or 0 -- 47
		layer = _with_0 -- 37
	end -- 37
	if def.ratio then -- 48
		world:setLayerRatio(def.order, def.ratio) -- 49
	end -- 48
	if def.offset then -- 50
		world:setLayerOffset(def.order, def.offset) -- 51
	end -- 50
	world:addChild(layer) -- 52
	if def.handle then -- 53
		def.handle(layer) -- 53
	end -- 53
	return layer -- 54
end -- 36
_module_0 = Class({ -- 57
	width = property(function() -- 57
		return W -- 57
	end), -- 57
	offset = property(function() -- 58
		return Offset -- 58
	end), -- 58
	left = property(function(self) -- 59
		return Vec2(100, self.offset) -- 59
	end), -- 59
	right = property(function(self) -- 60
		return Vec2(self.width - 100, self.offset) -- 60
	end), -- 60
	center = property(function(self) -- 61
		return Vec2(self.width / 2, self.offset) -- 61
	end), -- 61
	addShadowTo = function(self, unit) -- 63
		local _with_0 = Sprite("Image/shadow1.png") -- 64
		_with_0.angleX = 90 -- 65
		_with_0.order = -1 -- 66
		_with_0:schedule(function() -- 67
			_with_0.y = self.offset - unit.y -- 67
		end) -- 67
		_with_0:addTo(unit) -- 68
		return _with_0 -- 64
	end, -- 63
	openLeftDoor = function(self) -- 70
		local _with_0 = self._layers.leftwall -- 70
		_with_0.opened = true -- 71
		_with_0.recovery = 0 -- 72
		_with_0:play("openLI") -- 73
		return _with_0 -- 70
	end, -- 70
	openRightDoor = function(self) -- 75
		local _with_0 = self._layers.rightwall -- 75
		_with_0.opened = true -- 76
		_with_0.recovery = 0 -- 77
		_with_0:play("openRI") -- 78
		return _with_0 -- 75
	end, -- 75
	zoom = property(function(self) -- 80
		return self._zoom -- 80
	end, function(self, value) -- 81
		self._zoom = value -- 82
		return self:updateZoom() -- 83
	end), -- 80
	updateZoom = function(self) -- 85
		local actualZoom = self._zoom * DefaultZoom -- 86
		do -- 87
			local _with_0 = self._layers.lantern -- 87
			_with_0.x = W * (1.0 - actualZoom) / 2 -- 88
			_with_0.scaleX = actualZoom -- 89
			_with_0.scaleY = actualZoom -- 90
		end -- 87
		local width, height -- 91
		do -- 91
			local _obj_0 = View.size -- 91
			width, height = _obj_0.width, _obj_0.height -- 91
		end -- 91
		local zoom = height / H / actualZoom -- 92
		if width > W * zoom then -- 93
			zoom = width / W -- 94
		end -- 93
		local _with_0 = self.camera -- 95
		_with_0.zoom = zoom -- 96
		_with_0.boundary = Rect(0, 0, W, H * actualZoom) -- 97
		return _with_0 -- 95
	end, -- 85
	openGate = function(self) -- 99
		self._layers.gate.speed = self._speed -- 100
		self._layers.gate:play("gateOpen") -- 101
		self._layers.shield.speed = self._speed -- 102
		return self._layers.shield:play("gateOpen") -- 103
	end, -- 99
	closeGate = function(self) -- 105
		self._layers.gate.speed = self._speed -- 106
		self._layers.gate:play("gateClose") -- 107
		self._layers.shield.speed = self._speed -- 108
		return self._layers.shield:play("gateClose") -- 109
	end, -- 105
	turnOnLights = function(self) -- 111
		self.zoom = 1.0 -- 112
		self:schedule(once(function() -- 113
			cycle(3.5 / self._speed, function(dt) -- 114
				self.zoom = 1.4 - (0.8 * Ease:func(Ease.OutQuad, dt)) -- 115
			end) -- 114
			return self:schedule(once(function() -- 116
				return cycle(4.5 / self._speed, function(dt) -- 117
					self.zoom = 0.6 + (0.4 * Ease:func(Ease.InOutBack, dt)) -- 118
				end) -- 118
			end)) -- 118
		end)) -- 113
		return self._layers.back:schedule(once(function() -- 119
			self._layers.back:play("backOn") -- 120
			self._layers.lantern.speed = self._speed -- 121
			self._layers.lantern:play("lanternOn") -- 122
			self._layers.shield.speed = self._speed -- 123
			self._layers.shield:play("gateOn") -- 124
			self._layers.furniture.speed = self._speed -- 125
			self._layers.furniture:play("gateOn") -- 126
			do -- 127
				local _with_0 = self._layers.gate -- 127
				_with_0.speed = self._speed -- 128
				sleep(_with_0:play("gateOn")) -- 129
			end -- 127
			return self:openGate() -- 130
		end)) -- 130
	end, -- 111
	makeUnitEnter = function(self, unit, delay, order) -- 132
		if delay == nil then -- 132
			delay = 0 -- 132
		end -- 132
		if order == nil then -- 132
			order = 0 -- 132
		end -- 132
		unit:start("cancel") -- 133
		unit:start("keepIdle") -- 134
		unit.order = -110 -- 135
		local startZ = GateZ + 100 -- 136
		unit.z = startZ -- 137
		return unit:schedule(once(function() -- 138
			sleep(3.5 + delay) -- 139
			unit:start("keepMove") -- 140
			cycle(1 / 2, function(dt) -- 141
				unit.z = startZ - dt * 100 -- 142
			end) -- 141
			unit.order = order -- 143
			local layer = self:getLayer(order) -- 144
			startZ = GateZ - layer.z -- 145
			unit.z = startZ -- 146
			cycle(1.65 / 2, function(dt) -- 147
				unit.z = startZ - dt * startZ -- 148
			end) -- 147
			unit:start("cancel") -- 149
			unit:start("idle1") -- 150
			return sleep(3) -- 151
		end)) -- 151
	end, -- 132
	__partial = function(_) -- 153
		local _with_0 = PlatformWorld() -- 154
		_with_0.camera.followRatio = Vec2(0.03, 0.03) -- 155
		_with_0.tag = "PreparationRoom" -- 156
		return _with_0 -- 154
	end, -- 153
	__init = function(self) -- 158
		for i = -MaxPath, MaxPath do -- 159
			local _with_0 = self:getLayer(i) -- 160
			_with_0.z = ZOffset - PathOffset * i -- 161
		end -- 161
		do -- 163
			local _tbl_0 = { } -- 163
			for _index_0 = 1, #layerDefs do -- 163
				local def = layerDefs[_index_0] -- 163
				_tbl_0[def.look] = addLayer(self, def) -- 163
			end -- 163
			self._layers = _tbl_0 -- 163
		end -- 163
		local LeftDoorSensor <const> = 0 -- 165
		local RightDoorSensor <const> = 1 -- 166
		local terrainDef -- 167
		do -- 167
			local _with_0 = BodyDef() -- 167
			_with_0.type = "Static" -- 168
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 169
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 170
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 171
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 172
			_with_0:attachPolygonSensor(LeftDoorSensor, Vec2(75, 175), 150, 350) -- 173
			_with_0:attachPolygonSensor(RightDoorSensor, Vec2(W - 75, 175), 150, 350) -- 174
			_with_0.position = Vec2(0, Offset) -- 175
			terrainDef = _with_0 -- 167
		end -- 167
		self._layers.leftwall.opened = false -- 177
		self._layers.rightwall.opened = false -- 178
		local DoorSpeed <const> = 1.5 -- 179
		do -- 180
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 180
			_with_0.group = Data.groupTerrain -- 181
			_with_0:slot("BodyEnter", function(body, sensorTag) -- 182
				if not body.entity then -- 183
					return -- 183
				end -- 183
				if not body.entity.player then -- 184
					return -- 184
				end -- 184
				local door, animation, route -- 185
				if LeftDoorSensor == sensorTag then -- 186
					door, animation, route = self._layers.leftwall, "openL", "left" -- 187
				elseif RightDoorSensor == sensorTag then -- 188
					door, animation, route = self._layers.rightwall, "openR", "right" -- 189
				end -- 189
				local name, enter, targets = Map.getRoute(SceneName, route) -- 190
				if name then -- 190
					do -- 191
						local _with_1 = body.entity -- 191
						if body.velocityX == 0 then -- 192
							_with_1.moveFromRight = route ~= "right" -- 192
						else -- 192
							_with_1.moveFromRight = body.velocityX < 0 -- 192
						end -- 192
						_with_1.moveRouteName = name -- 193
						_with_1.moveEnter = enter -- 194
						_with_1.moveTargets = Array(targets) -- 195
					end -- 191
					if #targets > 0 and not door.opened then -- 196
						door.opened = true -- 198
						door.recovery = 1 -- 199
						door.speed = DoorSpeed -- 200
						door:play(animation) -- 201
						return door -- 197
					end -- 196
				end -- 190
			end) -- 182
			_with_0:slot("BodyLeave", function(body, sensorTag) -- 202
				if not body.entity then -- 203
					return -- 203
				end -- 203
				if not body.entity.player then -- 204
					return -- 204
				end -- 204
				if not body.entity.moveTargets then -- 205
					return -- 205
				end -- 205
				local available = not body.entity.moveTargets.empty -- 206
				do -- 207
					local _with_1 = body.entity -- 207
					_with_1.moveFromRight = nil -- 208
					_with_1.moveRouteName = nil -- 209
					_with_1.moveEnter = nil -- 210
					_with_1.moveTargets = nil -- 211
				end -- 207
				if not available then -- 212
					return -- 212
				end -- 212
				local door, animation -- 213
				if LeftDoorSensor == sensorTag then -- 214
					door, animation = self._layers.leftwall, "closeL" -- 215
				elseif RightDoorSensor == sensorTag then -- 216
					door, animation = self._layers.rightwall, "closeR" -- 217
				end -- 217
				door.opened = false -- 219
				door.recovery = 1 -- 220
				door.speed = DoorSpeed -- 221
				door:play(animation) -- 222
				return door -- 218
			end) -- 202
			_with_0:addTo(self) -- 223
		end -- 180
		self._speed = 1.0 -- 225
		self._zoom = 1.0 -- 226
		self:gslot("AppSizeChanged", function() -- 227
			return self:updateZoom() -- 227
		end) -- 227
		return self:updateZoom() -- 228
	end, -- 158
	loadAsync = function(_) -- 230
		return Cache:loadAsync("spine:preparationRoom") -- 230
	end -- 230
}) -- 56
return _module_0 -- 230
