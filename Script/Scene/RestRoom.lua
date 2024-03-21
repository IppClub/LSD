-- [yue]: Script/Scene/RestRoom.yue
local Spine = dora.Spine -- 1
local Class = dora.Class -- 1
local property = dora.property -- 1
local Vec2 = dora.Vec2 -- 1
local Sprite = dora.Sprite -- 1
local View = dora.View -- 1
local _module_0 = dora.Platformer -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local Rect = dora.Rect -- 1
local BodyDef = dora.BodyDef -- 1
local Body = dora.Body -- 1
local Data = _module_0.Data -- 1
local Array = dora.Array -- 1
local math = _G.math -- 1
local Cache = dora.Cache -- 1
local _module_0 = nil -- 1
local Map = require("Academy.Map") -- 2
local W <const> = 3640 -- 4
local HW <const> = W / 2 -- 5
local H <const> = 1080 -- 6
local HH <const> = H / 2 -- 7
local Offset <const> = 0 -- 8
local BackZ <const> = 470 -- 9
local ZOffset <const> = BackZ / 2 -- 10
local PathOffset <const> = 50 -- 11
local MaxPath <const> = 2 -- 12
local DefaultZoom <const> = 0.68 -- 13
local SceneName <const> = "RestRoom" -- 14
local layerDefs = { -- 23
	{ -- 23
		look = "lantern", -- 23
		order = 100, -- 23
		x = W * (1.0 - DefaultZoom) / 2, -- 23
		scale = DefaultZoom -- 23
	}, -- 23
	{ -- 24
		look = "disco", -- 24
		order = 99, -- 24
		z = 100, -- 24
		x = W * (1.0 - DefaultZoom) / 2, -- 24
		scale = DefaultZoom, -- 24
		y = 50 -- 24
	}, -- 24
	{ -- 25
		look = "front", -- 25
		order = 98 -- 25
	}, -- 25
	{ -- 26
		look = "vending", -- 26
		order = -100, -- 26
		z = BackZ - 150 -- 26
	}, -- 26
	{ -- 27
		look = "board", -- 27
		order = -101, -- 27
		z = BackZ - 50 -- 27
	}, -- 27
	{ -- 28
		look = "closet", -- 28
		order = -102, -- 28
		z = BackZ -- 28
	}, -- 28
	{ -- 29
		look = "leftwall", -- 29
		order = -103, -- 29
		angleY = -90 -- 29
	}, -- 29
	{ -- 30
		look = "rightwall", -- 30
		order = -104, -- 30
		x = W, -- 30
		angleY = 90 -- 30
	}, -- 30
	{ -- 31
		look = "floor", -- 31
		order = -105, -- 31
		angleX = 90 -- 31
	}, -- 31
	{ -- 32
		look = "back", -- 32
		order = -106, -- 32
		z = BackZ -- 32
	} -- 32
} -- 22
local addLayer -- 34
addLayer = function(world, def) -- 34
	local layer -- 35
	do -- 35
		local _with_0 = Spine("restRoom") -- 35
		_with_0.look = def.look -- 36
		_with_0.order = def.order -- 37
		_with_0.scaleX = def.scale or 1.0 -- 38
		_with_0.scaleY = def.scale or 1.0 -- 39
		_with_0.x = def.x or 0 -- 40
		_with_0.y = def.y or 0 -- 41
		_with_0.z = def.z or 0 -- 42
		_with_0.angleX = def.angleX or 0 -- 43
		_with_0.angleY = def.angleY or 0 -- 44
		_with_0.x = def.x or 0 -- 45
		layer = _with_0 -- 35
	end -- 35
	if def.ratio then -- 46
		world:setLayerRatio(def.order, def.ratio) -- 47
	end -- 46
	if def.offset then -- 48
		world:setLayerOffset(def.order, def.offset) -- 49
	end -- 48
	world:addChild(layer) -- 50
	if def.handle then -- 51
		def.handle(layer) -- 51
	end -- 51
	return layer -- 52
end -- 34
_module_0 = Class({ -- 55
	width = property(function() -- 55
		return W -- 55
	end), -- 55
	offset = property(function() -- 56
		return Offset -- 56
	end), -- 56
	left = property(function(self) -- 57
		return Vec2(100, self.offset) -- 57
	end), -- 57
	right = property(function(self) -- 58
		return Vec2(self.width - 100, self.offset) -- 58
	end), -- 58
	addShadowTo = function(self, unit) -- 60
		local _with_0 = Sprite("Image/shadow1.png") -- 61
		_with_0.angleX = 90 -- 62
		_with_0.order = -1 -- 63
		_with_0:schedule(function() -- 64
			_with_0.y = self.offset - unit.y -- 64
		end) -- 64
		_with_0:addTo(unit) -- 65
		return _with_0 -- 61
	end, -- 60
	openLeftDoor = function(self) -- 67
		local _with_0 = self._layers.leftwall -- 67
		_with_0.opened = true -- 68
		_with_0.recovery = 0 -- 69
		_with_0:play("openLI") -- 70
		return _with_0 -- 67
	end, -- 67
	openRightDoor = function(self) -- 72
		local _with_0 = self._layers.rightwall -- 72
		_with_0.opened = true -- 73
		_with_0.recovery = 0 -- 74
		_with_0:play("openRI") -- 75
		return _with_0 -- 72
	end, -- 72
	zoom = property(function(self) -- 77
		return self._zoom -- 77
	end, function(self, value) -- 78
		self._zoom = value -- 79
		return self:updateZoom() -- 80
	end), -- 77
	updateZoom = function(self) -- 82
		local actualZoom = self._zoom * DefaultZoom -- 83
		local width, height -- 84
		do -- 84
			local _obj_0 = View.size -- 84
			width, height = _obj_0.width, _obj_0.height -- 84
		end -- 84
		local zoom = height / H / actualZoom -- 85
		if width > W * zoom then -- 86
			zoom = width / W -- 87
		end -- 86
		self.camera.zoom = zoom -- 88
	end, -- 82
	__partial = function(self) -- 90
		local _with_0 = PlatformWorld() -- 91
		do -- 92
			local _with_1 = _with_0.camera -- 92
			_with_1.boundary = Rect(0, 0, W, H * DefaultZoom) -- 93
			_with_1.followRatio = Vec2(0.03, 0.03) -- 94
		end -- 92
		_with_0.tag = "RestRoom" -- 95
		return _with_0 -- 91
	end, -- 90
	__init = function(self) -- 97
		for i = -MaxPath, MaxPath do -- 98
			local _with_0 = self:getLayer(i) -- 99
			_with_0.z = ZOffset - PathOffset * i -- 100
		end -- 100
		do -- 102
			local _tbl_0 = { } -- 102
			for _index_0 = 1, #layerDefs do -- 102
				local def = layerDefs[_index_0] -- 102
				_tbl_0[def.look] = addLayer(self, def) -- 102
			end -- 102
			self._layers = _tbl_0 -- 102
		end -- 102
		local LeftDoorSensor <const> = 0 -- 104
		local RightDoorSensor <const> = 1 -- 105
		local terrainDef -- 106
		do -- 106
			local _with_0 = BodyDef() -- 106
			_with_0.type = "Static" -- 107
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 108
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 109
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 110
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 111
			_with_0:attachPolygonSensor(LeftDoorSensor, Vec2(75, 175), 150, 350) -- 112
			_with_0:attachPolygonSensor(RightDoorSensor, Vec2(W - 75, 175), 150, 350) -- 113
			_with_0.position = Vec2(0, Offset) -- 114
			terrainDef = _with_0 -- 106
		end -- 106
		self._layers.leftwall.opened = false -- 116
		self._layers.rightwall.opened = false -- 117
		local DoorSpeed <const> = 1.5 -- 118
		do -- 119
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 119
			_with_0.group = Data.groupTerrain -- 120
			_with_0:slot("BodyEnter", function(body, sensorTag) -- 121
				if not body.entity then -- 122
					return -- 122
				end -- 122
				if not body.entity.player then -- 123
					return -- 123
				end -- 123
				local door, animation, route -- 124
				if LeftDoorSensor == sensorTag then -- 125
					door, animation, route = self._layers.leftwall, "openL", "left" -- 126
				elseif RightDoorSensor == sensorTag then -- 127
					door, animation, route = self._layers.rightwall, "openR", "right" -- 128
				end -- 128
				local name, enter, targets = Map.getRoute(SceneName, route) -- 129
				if name then -- 129
					do -- 130
						local _with_1 = body.entity -- 130
						if body.velocityX == 0 then -- 131
							_with_1.moveFromRight = route ~= "right" -- 131
						else -- 131
							_with_1.moveFromRight = body.velocityX < 0 -- 131
						end -- 131
						_with_1.moveRouteName = name -- 132
						_with_1.moveEnter = enter -- 133
						_with_1.moveTargets = Array(targets) -- 134
					end -- 130
					if #targets > 0 and not door.opened then -- 135
						door.opened = true -- 137
						door.recovery = 1 -- 138
						door.speed = DoorSpeed -- 139
						door:play(animation) -- 140
						return door -- 136
					end -- 135
				end -- 129
			end) -- 121
			_with_0:slot("BodyLeave", function(body, sensorTag) -- 141
				if not body.entity then -- 142
					return -- 142
				end -- 142
				if not body.entity.player then -- 143
					return -- 143
				end -- 143
				if not body.entity.moveTargets then -- 144
					return -- 144
				end -- 144
				local available = not body.entity.moveTargets.empty -- 145
				do -- 146
					local _with_1 = body.entity -- 146
					_with_1.moveFromRight = nil -- 147
					_with_1.moveRouteName = nil -- 148
					_with_1.moveEnter = nil -- 149
					_with_1.moveTargets = nil -- 150
				end -- 146
				if not available then -- 151
					return -- 151
				end -- 151
				local door, animation -- 152
				if LeftDoorSensor == sensorTag then -- 153
					door, animation = self._layers.leftwall, "closeL" -- 154
				elseif RightDoorSensor == sensorTag then -- 155
					door, animation = self._layers.rightwall, "closeR" -- 156
				end -- 156
				door.opened = false -- 158
				door.recovery = 1 -- 159
				door.speed = DoorSpeed -- 160
				door:play(animation) -- 161
				return door -- 157
			end) -- 141
			_with_0:addTo(self) -- 162
		end -- 119
		self._zoom = 1.0 -- 164
		self:gslot("AppSizeChanged", function() -- 165
			return self:updateZoom() -- 165
		end) -- 165
		self:updateZoom() -- 166
		return self:schedule(function() -- 167
			local x = self.camera.position.x -- 168
			local distance -- 169
			if x < 800 then -- 169
				distance = 800 - x -- 170
			elseif x > 2300 then -- 171
				distance = x - 2300 -- 172
			else -- 174
				distance = 0 -- 174
			end -- 169
			self.zoom = 0.61 + 0.39 * math.min(1.0, distance / 800) -- 175
		end) -- 175
	end, -- 97
	loadAsync = function(self) -- 177
		return Cache:loadAsync("spine:restRoom") -- 177
	end -- 177
}) -- 54
return _module_0 -- 177
