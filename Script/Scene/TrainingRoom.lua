-- [yue]: Script/Scene/TrainingRoom.yue
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
local W <const> = 3840 -- 4
local HW <const> = W / 2 -- 5
local H <const> = 1080 -- 6
local HH <const> = H / 2 -- 7
local Offset <const> = 0 -- 8
local BackZ <const> = 475 -- 9
local ZOffset <const> = BackZ / 2 -- 10
local PathOffset <const> = 50 -- 11
local MaxPath <const> = 2 -- 12
local DefaultZoom <const> = 0.65 -- 13
local SceneName <const> = "TrainingRoom" -- 14
local layerDefs = { -- 23
	{ -- 23
		look = "lantern", -- 23
		order = 100, -- 23
		x = W * (1.0 - DefaultZoom) / 2, -- 23
		scale = DefaultZoom -- 23
	}, -- 23
	{ -- 24
		look = "dummyanchor2", -- 24
		order = 99, -- 24
		x = 1761, -- 24
		z = ZOffset - 80 - 60 -- 24
	}, -- 24
	{ -- 25
		look = "dummyanchor1", -- 25
		order = 98, -- 25
		x = 1761, -- 25
		z = ZOffset - 80 - 30 -- 25
	}, -- 25
	{ -- 26
		look = "dummy", -- 26
		order = 97, -- 26
		x = 1761, -- 26
		z = ZOffset - 80, -- 26
		handle = function(self) -- 26
			return self:play("dummyglow", true) -- 26
		end -- 26
	}, -- 26
	{ -- 27
		look = "backanchor2", -- 27
		order = 96, -- 27
		z = BackZ - 300 -- 27
	}, -- 27
	{ -- 28
		look = "seat", -- 28
		order = 95, -- 28
		x = 935, -- 28
		z = ZOffset - 100, -- 28
		scale = 0.7 -- 28
	}, -- 28
	{ -- 29
		look = "horseanchor2", -- 29
		order = -100, -- 29
		x = 2382, -- 29
		z = ZOffset + 100 - 60 -- 29
	}, -- 29
	{ -- 30
		look = "horseanchor1", -- 30
		order = -101, -- 30
		x = 2382, -- 30
		z = ZOffset + 100 - 30 -- 30
	}, -- 30
	{ -- 31
		look = "horse", -- 31
		order = -102, -- 31
		x = 2382, -- 31
		z = ZOffset + 100, -- 31
		handle = function(self) -- 31
			return self:play("horseglow", true) -- 31
		end -- 31
	}, -- 31
	{ -- 32
		look = "dummyanchor2", -- 32
		order = -103, -- 32
		x = 2940, -- 32
		z = ZOffset + 150 - 60 -- 32
	}, -- 32
	{ -- 33
		look = "dummyanchor1", -- 33
		order = -104, -- 33
		x = 2940, -- 33
		z = ZOffset + 150 - 30 -- 33
	}, -- 33
	{ -- 34
		look = "dummy", -- 34
		order = -105, -- 34
		x = 2940, -- 34
		z = ZOffset + 150, -- 34
		handle = function(self) -- 34
			return self:play("dummyglow", true) -- 34
		end -- 34
	}, -- 34
	{ -- 35
		look = "text", -- 35
		order = -106, -- 35
		x = 935, -- 35
		z = ZOffset + 50, -- 35
		handle = function(self) -- 35
			return self:play("textroll", true) -- 35
		end -- 35
	}, -- 35
	{ -- 36
		look = "table", -- 36
		order = -107, -- 36
		x = 935, -- 36
		z = ZOffset + 50, -- 36
		handle = function(self) -- 36
			return self:play("maskglow", true) -- 36
		end -- 36
	}, -- 36
	{ -- 37
		look = "leftwall", -- 37
		order = -108, -- 37
		angleY = -90 -- 37
	}, -- 37
	{ -- 38
		look = "rightwall", -- 38
		order = -109, -- 38
		x = W, -- 38
		angleY = 90 -- 38
	}, -- 38
	{ -- 39
		look = "backanchor1", -- 39
		order = -110, -- 39
		z = BackZ - 100 -- 39
	}, -- 39
	{ -- 40
		look = "back", -- 40
		order = -111, -- 40
		z = BackZ -- 40
	}, -- 40
	{ -- 41
		look = "floor", -- 41
		order = -112, -- 41
		angleX = 90 -- 41
	} -- 41
} -- 22
local addLayer -- 43
addLayer = function(world, def) -- 43
	local layer -- 44
	do -- 44
		local _with_0 = Spine("trainingRoom") -- 44
		_with_0.look = def.look -- 45
		_with_0.order = def.order -- 46
		_with_0.scaleX = def.scale or 1.0 -- 47
		_with_0.scaleY = def.scale or 1.0 -- 48
		_with_0.x = def.x or 0 -- 49
		_with_0.y = def.y or 0 -- 50
		_with_0.z = def.z or 0 -- 51
		_with_0.angleX = def.angleX or 0 -- 52
		_with_0.angleY = def.angleY or 0 -- 53
		_with_0.x = def.x or 0 -- 54
		layer = _with_0 -- 44
	end -- 44
	if def.ratio then -- 55
		world:setLayerRatio(def.order, def.ratio) -- 56
	end -- 55
	if def.offset then -- 57
		world:setLayerOffset(def.order, def.offset) -- 58
	end -- 57
	world:addChild(layer) -- 59
	if def.handle then -- 60
		def.handle(layer) -- 60
	end -- 60
	return layer -- 61
end -- 43
_module_0 = Class({ -- 64
	width = property(function() -- 64
		return W -- 64
	end), -- 64
	offset = property(function() -- 65
		return Offset -- 65
	end), -- 65
	left = property(function(self) -- 66
		return Vec2(100, self.offset) -- 66
	end), -- 66
	right = property(function(self) -- 67
		return Vec2(self.width - 100, self.offset) -- 67
	end), -- 67
	addShadowTo = function(self, unit) -- 69
		local _with_0 = Sprite("Image/shadow1.png") -- 70
		_with_0.angleX = 90 -- 71
		_with_0.order = -1 -- 72
		_with_0:schedule(function() -- 73
			_with_0.y = self.offset - unit.y -- 73
		end) -- 73
		_with_0:addTo(unit) -- 74
		return _with_0 -- 70
	end, -- 69
	openLeftDoor = function(self) -- 76
		local _with_0 = self._layers.leftwall -- 76
		_with_0.opened = true -- 77
		_with_0.recovery = 0 -- 78
		_with_0:play("openLI") -- 79
		return _with_0 -- 76
	end, -- 76
	openRightDoor = function(self) -- 81
		local _with_0 = self._layers.rightwall -- 81
		_with_0.opened = true -- 82
		_with_0.recovery = 0 -- 83
		_with_0:play("openRI") -- 84
		return _with_0 -- 81
	end, -- 81
	zoom = property(function(self) -- 86
		return self._zoom -- 86
	end, function(self, value) -- 87
		self._zoom = value -- 88
		return self:updateZoom() -- 89
	end), -- 86
	updateZoom = function(self) -- 91
		local actualZoom = self._zoom * DefaultZoom -- 92
		do -- 93
			local _with_0 = self._layers.lantern -- 93
			_with_0.x = W * (1.0 - actualZoom) / 2 -- 94
			_with_0.scaleX = actualZoom -- 95
			_with_0.scaleY = actualZoom -- 96
		end -- 93
		local width, height -- 97
		do -- 97
			local _obj_0 = View.size -- 97
			width, height = _obj_0.width, _obj_0.height -- 97
		end -- 97
		local zoom = height / H / actualZoom -- 98
		if width > W * zoom then -- 99
			zoom = width / W -- 100
		end -- 99
		local _with_0 = self.camera -- 101
		_with_0.zoom = zoom -- 102
		_with_0.boundary = Rect(0, 0, W, H * actualZoom) -- 103
		return _with_0 -- 101
	end, -- 91
	__partial = function(self) -- 105
		local _with_0 = PlatformWorld() -- 106
		_with_0.camera.followRatio = Vec2(0.03, 0.03) -- 107
		_with_0.tag = "TrainingRoom" -- 108
		return _with_0 -- 106
	end, -- 105
	__init = function(self) -- 110
		for i = -MaxPath, MaxPath do -- 111
			local _with_0 = self:getLayer(i) -- 112
			_with_0.z = ZOffset - PathOffset * i -- 113
		end -- 113
		do -- 115
			local _tbl_0 = { } -- 115
			for _index_0 = 1, #layerDefs do -- 115
				local def = layerDefs[_index_0] -- 115
				_tbl_0[def.look] = addLayer(self, def) -- 115
			end -- 115
			self._layers = _tbl_0 -- 115
		end -- 115
		local LeftDoorSensor <const> = 0 -- 117
		local RightDoorSensor <const> = 1 -- 118
		local terrainDef -- 119
		do -- 119
			local _with_0 = BodyDef() -- 119
			_with_0.type = "Static" -- 120
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 121
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 122
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 123
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 124
			_with_0:attachPolygonSensor(LeftDoorSensor, Vec2(75, 175), 150, 350) -- 125
			_with_0:attachPolygonSensor(RightDoorSensor, Vec2(W - 75, 175), 150, 350) -- 126
			_with_0.position = Vec2(0, Offset) -- 127
			terrainDef = _with_0 -- 119
		end -- 119
		self._layers.leftwall.opened = false -- 129
		self._layers.rightwall.opened = false -- 130
		local DoorSpeed <const> = 1.5 -- 131
		do -- 132
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 132
			_with_0.group = Data.groupTerrain -- 133
			_with_0:slot("BodyEnter", function(body, sensorTag) -- 134
				if not body.entity then -- 135
					return -- 135
				end -- 135
				if not body.entity.player then -- 136
					return -- 136
				end -- 136
				local door, animation, route -- 137
				if LeftDoorSensor == sensorTag then -- 138
					door, animation, route = self._layers.leftwall, "openL", "left" -- 139
				elseif RightDoorSensor == sensorTag then -- 140
					door, animation, route = self._layers.rightwall, "openR", "right" -- 141
				end -- 141
				local name, enter, targets = Map.getRoute(SceneName, route) -- 142
				if name then -- 142
					do -- 143
						local _with_1 = body.entity -- 143
						if body.velocityX == 0 then -- 144
							_with_1.moveFromRight = route ~= "right" -- 144
						else -- 144
							_with_1.moveFromRight = body.velocityX < 0 -- 144
						end -- 144
						_with_1.moveRouteName = name -- 145
						_with_1.moveEnter = enter -- 146
						_with_1.moveTargets = Array(targets) -- 147
					end -- 143
					if #targets > 0 and not door.opened then -- 148
						door.opened = true -- 150
						door.recovery = 1 -- 151
						door.speed = DoorSpeed -- 152
						door:play(animation) -- 153
						return door -- 149
					end -- 148
				end -- 142
			end) -- 134
			_with_0:slot("BodyLeave", function(body, sensorTag) -- 154
				if not body.entity then -- 155
					return -- 155
				end -- 155
				if not body.entity.player then -- 156
					return -- 156
				end -- 156
				if not body.entity.moveTargets then -- 157
					return -- 157
				end -- 157
				local available = not body.entity.moveTargets.empty -- 158
				do -- 159
					local _with_1 = body.entity -- 159
					_with_1.moveFromRight = nil -- 160
					_with_1.moveRouteName = nil -- 161
					_with_1.moveEnter = nil -- 162
					_with_1.moveTargets = nil -- 163
				end -- 159
				if not available then -- 164
					return -- 164
				end -- 164
				local door, animation -- 165
				if LeftDoorSensor == sensorTag then -- 166
					door, animation = self._layers.leftwall, "closeL" -- 167
				elseif RightDoorSensor == sensorTag then -- 168
					door, animation = self._layers.rightwall, "closeR" -- 169
				end -- 169
				door.opened = false -- 171
				door.recovery = 1 -- 172
				door.speed = DoorSpeed -- 173
				door:play(animation) -- 174
				return door -- 170
			end) -- 154
			_with_0:addTo(self) -- 175
		end -- 132
		self._zoom = 1.0 -- 177
		self:gslot("AppSizeChanged", function() -- 178
			return self:updateZoom() -- 178
		end) -- 178
		return self:updateZoom() -- 179
	end, -- 110
	loadAsync = function(self) -- 181
		return Cache:loadAsync("spine:trainingRoom") -- 181
	end -- 181
}) -- 63
return _module_0 -- 181
