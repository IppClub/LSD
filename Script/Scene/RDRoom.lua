-- [yue]: Script/Scene/RDRoom.yue
local Spine = Dora.Spine -- 1
local Class = Dora.Class -- 1
local property = Dora.property -- 1
local Vec2 = Dora.Vec2 -- 1
local Sprite = Dora.Sprite -- 1
local View = Dora.View -- 1
local Rect = Dora.Rect -- 1
local _module_0 = Dora.Platformer -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local BodyDef = Dora.BodyDef -- 1
local Body = Dora.Body -- 1
local Data = _module_0.Data -- 1
local Array = Dora.Array -- 1
local Cache = Dora.Cache -- 1
local _module_0 = nil -- 1
local Map = require("Academy.Map") -- 2
local W <const> = 5690 -- 4
local HW <const> = W / 2 -- 5
local H <const> = 1080 -- 6
local HH <const> = H / 2 -- 7
local Offset <const> = 0 -- 8
local BackZ <const> = 470 -- 9
local ZOffset <const> = BackZ / 2 -- 10
local PathOffset <const> = 50 -- 11
local MaxPath <const> = 2 -- 12
local DefaultZoom <const> = 0.7 -- 13
local SceneName <const> = "RDRoom" -- 14
local layerDefs = { -- 23
	{ -- 23
		look = "lantern", -- 23
		order = 100, -- 23
		x = W * (1.0 - DefaultZoom) / 2, -- 23
		scale = DefaultZoom -- 23
	}, -- 23
	{ -- 24
		look = "front", -- 24
		order = 99 -- 24
	}, -- 24
	{ -- 25
		look = "dragonhead", -- 25
		order = 98, -- 25
		z = 100, -- 25
		x = W * (1.0 - DefaultZoom) / 2, -- 25
		scale = DefaultZoom, -- 25
		y = 50 -- 25
	}, -- 25
	{ -- 26
		look = "backlight", -- 26
		order = 97, -- 26
		z = 150, -- 26
		x = W * (1.0 - DefaultZoom) / 2, -- 26
		scale = DefaultZoom, -- 26
		y = 78 -- 26
	}, -- 26
	{ -- 27
		look = "device1", -- 27
		order = -100, -- 27
		z = ZOffset + 40 -- 27
	}, -- 27
	{ -- 28
		look = "device2", -- 28
		order = -101, -- 28
		z = ZOffset + 40 * 2 -- 28
	}, -- 28
	{ -- 29
		look = "console1", -- 29
		order = -102, -- 29
		z = ZOffset + 40 * 3 -- 29
	}, -- 29
	{ -- 30
		look = "console2", -- 30
		order = -103, -- 30
		z = ZOffset + 40 * 4 -- 30
	}, -- 30
	{ -- 31
		look = "console3", -- 31
		order = -104, -- 31
		z = ZOffset + 40 * 5 -- 31
	}, -- 31
	{ -- 32
		look = "printer", -- 32
		order = -105, -- 32
		z = ZOffset + 50 -- 32
	}, -- 32
	{ -- 33
		look = "sigil", -- 33
		order = -106, -- 33
		z = ZOffset + 120 -- 33
	}, -- 33
	{ -- 34
		look = "dragonbody", -- 34
		order = -107, -- 34
		z = ZOffset + 150, -- 34
		x = 600 -- 34
	}, -- 34
	{ -- 35
		look = "leftwall", -- 35
		order = -108, -- 35
		angleY = -90 -- 35
	}, -- 35
	{ -- 36
		look = "rightwall", -- 36
		order = -109, -- 36
		x = W, -- 36
		z = -100, -- 36
		angleY = 90 -- 36
	}, -- 36
	{ -- 37
		look = "floor", -- 37
		order = -110, -- 37
		angleX = 90 -- 37
	}, -- 37
	{ -- 38
		look = "back", -- 38
		order = -111, -- 38
		z = BackZ -- 38
	} -- 38
} -- 22
local addLayer -- 40
addLayer = function(world, def) -- 40
	local layer -- 41
	do -- 41
		local _with_0 = Spine("RDRoom") -- 41
		_with_0.look = def.look -- 42
		_with_0.order = def.order -- 43
		_with_0.scaleX = def.scale or 1.0 -- 44
		_with_0.scaleY = def.scale or 1.0 -- 45
		_with_0.x = def.x or 0 -- 46
		_with_0.y = def.y or 0 -- 47
		_with_0.z = def.z or 0 -- 48
		_with_0.angleX = def.angleX or 0 -- 49
		_with_0.angleY = def.angleY or 0 -- 50
		_with_0.x = def.x or 0 -- 51
		layer = _with_0 -- 41
	end -- 41
	if def.ratio then -- 52
		world:setLayerRatio(def.order, def.ratio) -- 53
	end -- 52
	if def.offset then -- 54
		world:setLayerOffset(def.order, def.offset) -- 55
	end -- 54
	world:addChild(layer) -- 56
	if def.handle then -- 57
		def.handle(layer) -- 57
	end -- 57
	return layer -- 58
end -- 40
_module_0 = Class({ -- 61
	width = property(function() -- 61
		return W -- 61
	end), -- 61
	offset = property(function() -- 62
		return Offset -- 62
	end), -- 62
	left = property(function(self) -- 63
		return Vec2(100, self.offset) -- 63
	end), -- 63
	right = property(function(self) -- 64
		return Vec2(self.width - 100, self.offset) -- 64
	end), -- 64
	addShadowTo = function(self, unit) -- 66
		local _with_0 = Sprite("Image/shadow1.png") -- 67
		_with_0.angleX = 90 -- 68
		_with_0.order = -1 -- 69
		_with_0:schedule(function() -- 70
			_with_0.y = self.offset - unit.y -- 70
		end) -- 70
		_with_0:addTo(unit) -- 71
		return _with_0 -- 67
	end, -- 66
	openLeftDoor = function(self) -- 73
		local _with_0 = self._layers.leftwall -- 73
		_with_0.opened = true -- 74
		_with_0.recovery = 0 -- 75
		_with_0:play("openLI") -- 76
		return _with_0 -- 73
	end, -- 73
	openRightDoor = function(self) -- 78
		local _with_0 = self._layers.rightwall -- 78
		_with_0.opened = true -- 79
		_with_0.recovery = 0 -- 80
		_with_0:play("openRI") -- 81
		return _with_0 -- 78
	end, -- 78
	zoom = property(function(self) -- 83
		return self._zoom -- 83
	end, function(self, value) -- 84
		self._zoom = value -- 85
		return self:updateZoom() -- 86
	end), -- 83
	updateZoom = function(self) -- 88
		local actualZoom = self._zoom * DefaultZoom -- 89
		do -- 90
			local _with_0 = self._layers.lantern -- 90
			_with_0.x = W * (1.0 - actualZoom) / 2 -- 91
			_with_0.scaleX = actualZoom -- 92
			_with_0.scaleY = actualZoom -- 93
		end -- 90
		local width, height -- 94
		do -- 94
			local _obj_0 = View.size -- 94
			width, height = _obj_0.width, _obj_0.height -- 94
		end -- 94
		local zoom = height / H / actualZoom -- 95
		if width > W * zoom then -- 96
			zoom = width / W -- 97
		end -- 96
		local _with_0 = self.camera -- 98
		_with_0.zoom = zoom -- 99
		_with_0.boundary = Rect(0, 0, W, H * actualZoom) -- 100
		return _with_0 -- 98
	end, -- 88
	__partial = function(_) -- 102
		local _with_0 = PlatformWorld() -- 103
		_with_0.camera.followRatio = Vec2(0.03, 0.03) -- 104
		_with_0.tag = "RDRoom" -- 105
		return _with_0 -- 103
	end, -- 102
	__init = function(self) -- 107
		for i = -MaxPath, MaxPath do -- 108
			local _with_0 = self:getLayer(i) -- 109
			_with_0.z = ZOffset - PathOffset * i -- 110
		end -- 110
		do -- 112
			local _tbl_0 = { } -- 112
			for _index_0 = 1, #layerDefs do -- 112
				local def = layerDefs[_index_0] -- 112
				_tbl_0[def.look] = addLayer(self, def) -- 112
			end -- 112
			self._layers = _tbl_0 -- 112
		end -- 112
		local LeftDoorSensor <const> = 0 -- 114
		local RightDoorSensor <const> = 1 -- 115
		local terrainDef -- 116
		do -- 116
			local _with_0 = BodyDef() -- 116
			_with_0.type = "Static" -- 117
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 118
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 119
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 120
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 121
			_with_0:attachPolygonSensor(LeftDoorSensor, Vec2(75, 175), 150, 350) -- 122
			_with_0:attachPolygonSensor(RightDoorSensor, Vec2(W - 75, 175), 150, 350) -- 123
			_with_0.position = Vec2(0, Offset) -- 124
			terrainDef = _with_0 -- 116
		end -- 116
		self._layers.leftwall.opened = false -- 126
		self._layers.rightwall.opened = false -- 127
		local DoorSpeed <const> = 1.5 -- 128
		do -- 129
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 129
			_with_0.group = Data.groupTerrain -- 130
			_with_0:slot("BodyEnter", function(body, sensorTag) -- 131
				if not body.entity then -- 132
					return -- 132
				end -- 132
				if not body.entity.player then -- 133
					return -- 133
				end -- 133
				local door, animation, route -- 134
				if LeftDoorSensor == sensorTag then -- 135
					door, animation, route = self._layers.leftwall, "openL", "left" -- 136
				elseif RightDoorSensor == sensorTag then -- 137
					door, animation, route = self._layers.rightwall, "openR", "right" -- 138
				end -- 138
				local name, enter, targets = Map.getRoute(SceneName, route) -- 139
				if name then -- 139
					do -- 140
						local _with_1 = body.entity -- 140
						if body.velocityX == 0 then -- 141
							_with_1.moveFromRight = route ~= "right" -- 141
						else -- 141
							_with_1.moveFromRight = body.velocityX < 0 -- 141
						end -- 141
						_with_1.moveRouteName = name -- 142
						_with_1.moveEnter = enter -- 143
						_with_1.moveTargets = Array(targets) -- 144
					end -- 140
					if #targets > 0 and not door.opened then -- 145
						door.opened = true -- 147
						door.recovery = 1 -- 148
						door.speed = DoorSpeed -- 149
						door:play(animation) -- 150
						return door -- 146
					end -- 145
				end -- 139
			end) -- 131
			_with_0:slot("BodyLeave", function(body, sensorTag) -- 151
				if not body.entity then -- 152
					return -- 152
				end -- 152
				if not body.entity.player then -- 153
					return -- 153
				end -- 153
				if not body.entity.moveTargets then -- 154
					return -- 154
				end -- 154
				local available = not body.entity.moveTargets.empty -- 155
				do -- 156
					local _with_1 = body.entity -- 156
					_with_1.moveFromRight = nil -- 157
					_with_1.moveRouteName = nil -- 158
					_with_1.moveEnter = nil -- 159
					_with_1.moveTargets = nil -- 160
				end -- 156
				if not available then -- 161
					return -- 161
				end -- 161
				local door, animation -- 162
				if LeftDoorSensor == sensorTag then -- 163
					door, animation = self._layers.leftwall, "closeL" -- 164
				elseif RightDoorSensor == sensorTag then -- 165
					door, animation = self._layers.rightwall, "closeR" -- 166
				end -- 166
				door.opened = false -- 168
				door.recovery = 1 -- 169
				door.speed = DoorSpeed -- 170
				door:play(animation) -- 171
				return door -- 167
			end) -- 151
			_with_0:addTo(self) -- 172
		end -- 129
		self._zoom = 1.0 -- 174
		self:gslot("AppSizeChanged", function() -- 175
			return self:updateZoom() -- 175
		end) -- 175
		return self:updateZoom() -- 176
	end, -- 107
	loadAsync = function(_) -- 178
		return Cache:loadAsync("spine:RDRoom") -- 178
	end -- 178
}) -- 60
return _module_0 -- 178
