-- [yue]: Script/Scene/OperationRoom.yue
local Spine = dora.Spine -- 1
local Class = dora.Class -- 1
local property = dora.property -- 1
local Vec2 = dora.Vec2 -- 1
local Sprite = dora.Sprite -- 1
local View = dora.View -- 1
local Rect = dora.Rect -- 1
local _module_0 = dora.Platformer -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local BodyDef = dora.BodyDef -- 1
local Body = dora.Body -- 1
local Data = _module_0.Data -- 1
local Array = dora.Array -- 1
local Cache = dora.Cache -- 1
local _module_0 = nil -- 1
local Map = require("Academy.Map") -- 2
local W <const> = 3554 -- 4
local HW <const> = W / 2 -- 5
local H <const> = 1080 -- 6
local HH <const> = H / 2 -- 7
local Offset <const> = 0 -- 8
local BackZ <const> = 470 -- 9
local ZOffset <const> = BackZ / 2 - 50 -- 10
local PathOffset <const> = 50 -- 11
local MaxPath <const> = 2 -- 12
local DefaultZoom <const> = 0.5 -- 13
local SceneName <const> = "OperationRoom" -- 14
local layerDefs = { -- 23
	{ -- 23
		look = "lantern", -- 23
		order = 100, -- 23
		x = W * (1.0 - DefaultZoom) / 2, -- 23
		scale = DefaultZoom -- 23
	}, -- 23
	{ -- 24
		look = "chairLR", -- 24
		order = -100, -- 24
		z = ZOffset + 100 -- 24
	}, -- 24
	{ -- 25
		look = "chaircenter", -- 25
		order = -101, -- 25
		z = ZOffset + 100 -- 25
	}, -- 25
	{ -- 26
		look = "curtainL", -- 26
		order = -102, -- 26
		z = BackZ - 100 -- 26
	}, -- 26
	{ -- 27
		look = "curtainR", -- 27
		order = -103, -- 27
		z = BackZ - 100 -- 27
	}, -- 27
	{ -- 28
		look = "control", -- 28
		order = -104, -- 28
		z = BackZ - 50 -- 28
	}, -- 28
	{ -- 29
		look = "leftwall", -- 29
		order = -105, -- 29
		angleY = -90 -- 29
	}, -- 29
	{ -- 30
		look = "rightwall", -- 30
		order = -106, -- 30
		x = W, -- 30
		angleY = 90 -- 30
	}, -- 30
	{ -- 31
		look = "closetL", -- 31
		order = -107, -- 31
		z = BackZ -- 31
	}, -- 31
	{ -- 32
		look = "closetR", -- 32
		order = -108, -- 32
		z = BackZ -- 32
	}, -- 32
	{ -- 33
		look = "device", -- 33
		order = -109, -- 33
		z = BackZ -- 33
	}, -- 33
	{ -- 34
		look = "backcurtain", -- 34
		order = -110, -- 34
		z = BackZ + 80 -- 34
	}, -- 34
	{ -- 35
		look = "floor", -- 35
		order = -111, -- 35
		angleX = 90 -- 35
	}, -- 35
	{ -- 36
		look = "back", -- 36
		order = -112, -- 36
		z = BackZ + 150 -- 36
	} -- 36
} -- 22
local addLayer -- 38
addLayer = function(world, def) -- 38
	local layer -- 39
	do -- 39
		local _with_0 = Spine("operationRoom") -- 39
		_with_0.look = def.look -- 40
		_with_0.order = def.order -- 41
		_with_0.scaleX = def.scale or 1.0 -- 42
		_with_0.scaleY = def.scale or 1.0 -- 43
		_with_0.x = def.x or 0 -- 44
		_with_0.y = def.y or 0 -- 45
		_with_0.z = def.z or 0 -- 46
		_with_0.angleX = def.angleX or 0 -- 47
		_with_0.angleY = def.angleY or 0 -- 48
		_with_0.x = def.x or 0 -- 49
		layer = _with_0 -- 39
	end -- 39
	if def.ratio then -- 50
		world:setLayerRatio(def.order, def.ratio) -- 51
	end -- 50
	if def.offset then -- 52
		world:setLayerOffset(def.order, def.offset) -- 53
	end -- 52
	world:addChild(layer) -- 54
	if def.handle then -- 55
		def.handle(layer) -- 55
	end -- 55
	return layer -- 56
end -- 38
_module_0 = Class({ -- 59
	width = property(function() -- 59
		return W -- 59
	end), -- 59
	offset = property(function() -- 60
		return Offset -- 60
	end), -- 60
	left = property(function(self) -- 61
		return Vec2(100, self.offset) -- 61
	end), -- 61
	right = property(function(self) -- 62
		return Vec2(self.width - 100, self.offset) -- 62
	end), -- 62
	addShadowTo = function(self, unit) -- 64
		local _with_0 = Sprite("Image/shadow1.png") -- 65
		_with_0.angleX = 90 -- 66
		_with_0.order = -1 -- 67
		_with_0:schedule(function() -- 68
			_with_0.y = self.offset - unit.y -- 68
		end) -- 68
		_with_0:addTo(unit) -- 69
		return _with_0 -- 65
	end, -- 64
	openLeftDoor = function(self) -- 71
		local _with_0 = self._layers.leftwall -- 71
		_with_0.opened = true -- 72
		_with_0.recovery = 0 -- 73
		_with_0:play("openLI") -- 74
		return _with_0 -- 71
	end, -- 71
	openRightDoor = function(self) -- 76
		local _with_0 = self._layers.rightwall -- 76
		_with_0.opened = true -- 77
		_with_0.recovery = 0 -- 78
		_with_0:play("openRI") -- 79
		return _with_0 -- 76
	end, -- 76
	zoom = property(function(self) -- 81
		return self._zoom -- 81
	end, function(self, value) -- 82
		self._zoom = value -- 83
		return self:updateZoom() -- 84
	end), -- 81
	updateZoom = function(self) -- 86
		local actualZoom = self._zoom * DefaultZoom -- 87
		do -- 88
			local _with_0 = self._layers.lantern -- 88
			_with_0.x = W * (1.0 - actualZoom) / 2 -- 89
			_with_0.scaleX = actualZoom -- 90
			_with_0.scaleY = actualZoom -- 91
		end -- 88
		local width, height -- 92
		do -- 92
			local _obj_0 = View.size -- 92
			width, height = _obj_0.width, _obj_0.height -- 92
		end -- 92
		local zoom = height / H / actualZoom -- 93
		if width > W * zoom then -- 94
			zoom = width / W -- 95
		end -- 94
		local _with_0 = self.camera -- 96
		_with_0.zoom = zoom -- 97
		_with_0.boundary = Rect(0, 0, W, H * actualZoom) -- 98
		return _with_0 -- 96
	end, -- 86
	__partial = function(_) -- 100
		local _with_0 = PlatformWorld() -- 101
		_with_0.camera.followRatio = Vec2(0.03, 0.03) -- 102
		_with_0.tag = "OperationRoom" -- 103
		return _with_0 -- 101
	end, -- 100
	__init = function(self) -- 105
		for i = -MaxPath, MaxPath do -- 106
			do -- 107
				local _with_0 = self:getLayer(i) -- 107
				_with_0.z = ZOffset - PathOffset * i -- 108
			end -- 107
		end -- 108
		do -- 110
			local _tbl_0 = { } -- 110
			for _index_0 = 1, #layerDefs do -- 110
				local def = layerDefs[_index_0] -- 110
				_tbl_0[def.look] = addLayer(self, def) -- 110
			end -- 110
			self._layers = _tbl_0 -- 110
		end -- 110
		local LeftDoorSensor <const> = 0 -- 112
		local RightDoorSensor <const> = 1 -- 113
		local terrainDef -- 114
		do -- 114
			local _with_0 = BodyDef() -- 114
			_with_0.type = "Static" -- 115
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 116
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 117
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 118
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 119
			_with_0:attachPolygonSensor(LeftDoorSensor, Vec2(75, 175), 150, 350) -- 120
			_with_0:attachPolygonSensor(RightDoorSensor, Vec2(W - 75, 175), 150, 350) -- 121
			_with_0.position = Vec2(0, Offset) -- 122
			terrainDef = _with_0 -- 114
		end -- 114
		self._layers.leftwall.opened = false -- 124
		self._layers.rightwall.opened = false -- 125
		local DoorSpeed <const> = 1.5 -- 126
		do -- 127
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 127
			_with_0.group = Data.groupTerrain -- 128
			_with_0:slot("BodyEnter", function(body, sensorTag) -- 129
				if not body.entity then -- 130
					return -- 130
				end -- 130
				if not body.entity.player then -- 131
					return -- 131
				end -- 131
				local door, animation, route -- 132
				if LeftDoorSensor == sensorTag then -- 133
					door, animation, route = self._layers.leftwall, "openL", "left" -- 134
				elseif RightDoorSensor == sensorTag then -- 135
					door, animation, route = self._layers.rightwall, "openR", "right" -- 136
				end -- 136
				do -- 137
					local name, enter, targets = Map.getRoute(SceneName, route) -- 137
					if name then -- 137
						do -- 138
							local _with_1 = body.entity -- 138
							if body.velocityX == 0 then -- 139
								_with_1.moveFromRight = route ~= "right" -- 139
							else -- 139
								_with_1.moveFromRight = body.velocityX < 0 -- 139
							end -- 139
							_with_1.moveRouteName = name -- 140
							_with_1.moveEnter = enter -- 141
							_with_1.moveTargets = Array(targets) -- 142
						end -- 138
						if #targets > 0 and not door.opened then -- 143
							door.opened = true -- 145
							door.recovery = 1 -- 146
							door.speed = DoorSpeed -- 147
							door:play(animation) -- 148
							return door -- 144
						end -- 143
					end -- 137
				end -- 137
			end) -- 129
			_with_0:slot("BodyLeave", function(body, sensorTag) -- 149
				if not body.entity then -- 150
					return -- 150
				end -- 150
				if not body.entity.player then -- 151
					return -- 151
				end -- 151
				if not body.entity.moveTargets then -- 152
					return -- 152
				end -- 152
				local available = not body.entity.moveTargets.empty -- 153
				do -- 154
					local _with_1 = body.entity -- 154
					_with_1.moveFromRight = nil -- 155
					_with_1.moveRouteName = nil -- 156
					_with_1.moveEnter = nil -- 157
					_with_1.moveTargets = nil -- 158
				end -- 154
				if not available then -- 159
					return -- 159
				end -- 159
				local door, animation -- 160
				if LeftDoorSensor == sensorTag then -- 161
					door, animation = self._layers.leftwall, "closeL" -- 162
				elseif RightDoorSensor == sensorTag then -- 163
					door, animation = self._layers.rightwall, "closeR" -- 164
				end -- 164
				door.opened = false -- 166
				door.recovery = 1 -- 167
				door.speed = DoorSpeed -- 168
				door:play(animation) -- 169
				return door -- 165
			end) -- 149
			_with_0:addTo(self) -- 170
		end -- 127
		self._zoom = 1.0 -- 172
		self:gslot("AppSizeChanged", function() -- 173
			return self:updateZoom() -- 173
		end) -- 173
		return self:updateZoom() -- 174
	end, -- 105
	loadAsync = function(_) -- 176
		return Cache:loadAsync("spine:operationRoom") -- 176
	end -- 176
}) -- 58
return _module_0 -- 176
