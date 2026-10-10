-- [yue]: Script/Scene/LibraryRoom.yue
local _module_0 = nil -- 1
local _ENV = Dora(Dora.Platformer) -- 1
local require <const> = require -- 2
local Spine <const> = Spine -- 2
local Class <const> = Class -- 2
local property <const> = property -- 2
local Vec2 <const> = Vec2 -- 2
local Sprite <const> = Sprite -- 2
local View <const> = View -- 2
local PlatformWorld <const> = PlatformWorld -- 2
local Rect <const> = Rect -- 2
local BodyDef <const> = BodyDef -- 2
local Body <const> = Body -- 2
local Data <const> = Data -- 2
local Array <const> = Array -- 2
local math <const> = math -- 2
local Cache <const> = Cache -- 2
local Map = require("Academy.Map") -- 3
local W <const> = 3640 -- 5
local HW <const> = W / 2 -- 6
local H <const> = 1080 -- 7
local HH <const> = H / 2 -- 8
local Offset <const> = 0 -- 9
local BackZ <const> = 470 -- 10
local ZOffset <const> = BackZ / 2 -- 11
local PathOffset <const> = 50 -- 12
local MaxPath <const> = 2 -- 13
local DefaultZoom <const> = 0.68 -- 14
local SceneName <const> = "LibraryRoom" -- 15
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
		look = "leftwall", -- 26
		order = -103, -- 26
		angleY = -90 -- 26
	}, -- 26
	{ -- 27
		look = "rightwall", -- 27
		order = -104, -- 27
		x = W, -- 27
		angleY = 90 -- 27
	}, -- 27
	{ -- 28
		look = "floor", -- 28
		order = -105, -- 28
		angleX = 90 -- 28
	}, -- 28
	{ -- 29
		look = "back", -- 29
		order = -106, -- 29
		z = BackZ -- 29
	} -- 29
} -- 23
local addLayer -- 31
addLayer = function(world, def) -- 31
	local layer -- 32
	do -- 32
		local _with_0 = Spine("restRoom") -- 32
		_with_0.look = def.look -- 33
		_with_0.order = def.order -- 34
		_with_0.scaleX = def.scale or 1.0 -- 35
		_with_0.scaleY = def.scale or 1.0 -- 36
		_with_0.x = def.x or 0 -- 37
		_with_0.y = def.y or 0 -- 38
		_with_0.z = def.z or 0 -- 39
		_with_0.angleX = def.angleX or 0 -- 40
		_with_0.angleY = def.angleY or 0 -- 41
		_with_0.x = def.x or 0 -- 42
		layer = _with_0 -- 32
	end -- 32
	if def.ratio then -- 43
		world:setLayerRatio(def.order, def.ratio) -- 44
	end -- 43
	if def.offset then -- 45
		world:setLayerOffset(def.order, def.offset) -- 46
	end -- 45
	world:addChild(layer) -- 47
	if def.handle then -- 48
		def.handle(layer) -- 48
	end -- 48
	return layer -- 49
end -- 31
_module_0 = Class({ -- 52
	sceneWidth = property(function() -- 52
		return W -- 52
	end), -- 52
	offset = property(function() -- 53
		return Offset -- 53
	end), -- 53
	left = property(function(self) -- 54
		return Vec2(100, self.offset) -- 54
	end), -- 54
	right = property(function(self) -- 55
		return Vec2(self.sceneWidth - 100, self.offset) -- 55
	end), -- 55
	addShadowTo = function(self, unit) -- 57
		local _with_0 = Sprite("Image/shadow1.png") -- 58
		_with_0.angleX = 90 -- 59
		_with_0.order = -1 -- 60
		_with_0:schedule(function() -- 61
			_with_0.y = self.offset - unit.y -- 61
		end) -- 61
		_with_0:addTo(unit) -- 62
		return _with_0 -- 58
	end, -- 57
	openLeftDoor = function(self) -- 64
		local _with_0 = self._layers.leftwall -- 64
		_with_0.opened = true -- 65
		_with_0.recovery = 0 -- 66
		_with_0:play("openLI") -- 67
		return _with_0 -- 64
	end, -- 64
	openRightDoor = function(self) -- 69
		local _with_0 = self._layers.rightwall -- 69
		_with_0.opened = true -- 70
		_with_0.recovery = 0 -- 71
		_with_0:play("openRI") -- 72
		return _with_0 -- 69
	end, -- 69
	zoom = property(function(self) -- 74
		return self._zoom -- 74
	end, function(self, value) -- 75
		self._zoom = value -- 76
		return self:updateZoom() -- 77
	end), -- 74
	updateZoom = function(self) -- 79
		local actualZoom = self._zoom * DefaultZoom -- 80
		local width, height -- 81
		do -- 81
			local _obj_0 = View.size -- 81
			width, height = _obj_0.width, _obj_0.height -- 81
		end -- 81
		local zoom = height / H / actualZoom -- 82
		if width > W * zoom then -- 83
			zoom = width / W -- 84
		end -- 83
		self.camera.zoom = zoom -- 85
	end, -- 79
	__partial = function(_self) -- 87
		local _with_0 = PlatformWorld() -- 88
		do -- 89
			local _with_1 = _with_0.camera -- 89
			_with_1.boundary = Rect(0, 0, W, H * DefaultZoom) -- 90
			_with_1.followRatio = Vec2(0.03, 0.03) -- 91
		end -- 89
		_with_0.tag = "LibraryRoom" -- 92
		return _with_0 -- 88
	end, -- 87
	__init = function(self) -- 94
		for i = -MaxPath, MaxPath do -- 95
			local _with_0 = self:getLayer(i) -- 96
			_with_0.z = ZOffset - PathOffset * i -- 97
		end -- 95
		do -- 99
			local _tbl_0 = { } -- 99
			for _index_0 = 1, #layerDefs do -- 99
				local def = layerDefs[_index_0] -- 99
				_tbl_0[def.look] = addLayer(self, def) -- 99
			end -- 99
			self._layers = _tbl_0 -- 99
		end -- 99
		local _list_0 = { -- 101
			900, -- 101
			2690 -- 101
		} -- 101
		for _index_0 = 1, #_list_0 do -- 101
			local x = _list_0[_index_0] -- 101
			local _with_0 = Sprite("Image/library-bookcases.png") -- 102
			_with_0.position = Vec2(x, 405) -- 103
			_with_0.z = BackZ - 70 -- 104
			_with_0.order = -100 -- 105
			_with_0.scaleX = 0.8 -- 106
			_with_0.scaleY = 0.8 -- 106
			_with_0:addTo(self) -- 107
		end -- 101
		local LeftDoorSensor <const> = 0 -- 109
		local RightDoorSensor <const> = 1 -- 110
		local terrainDef -- 111
		do -- 111
			local _with_0 = BodyDef() -- 111
			_with_0.type = "Static" -- 112
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 113
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 114
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 115
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 116
			_with_0:attachPolygonSensor(LeftDoorSensor, Vec2(75, 175), 150, 350) -- 117
			_with_0:attachPolygonSensor(RightDoorSensor, Vec2(W - 75, 175), 150, 350) -- 118
			_with_0.position = Vec2(0, Offset) -- 119
			terrainDef = _with_0 -- 111
		end -- 111
		self._layers.leftwall.opened = false -- 121
		self._layers.rightwall.opened = false -- 122
		local DoorSpeed <const> = 1.5 -- 123
		do -- 124
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 124
			_with_0.group = Data.groupTerrain -- 125
			_with_0:slot("BodyEnter", function(body, sensorTag) -- 126
				if not body.entity then -- 127
					return -- 127
				end -- 127
				if not body.entity.player then -- 128
					return -- 128
				end -- 128
				local door, animation, route -- 129
				if LeftDoorSensor == sensorTag then -- 130
					door, animation, route = self._layers.leftwall, "openL", "left" -- 131
				elseif RightDoorSensor == sensorTag then -- 132
					door, animation, route = self._layers.rightwall, "openR", "right" -- 133
				end -- 129
				local name, enter, targets = Map.getRoute(SceneName, route) -- 134
				if name then -- 134
					do -- 135
						local _with_1 = body.entity -- 135
						if body.velocityX == 0 then -- 136
							_with_1.moveFromRight = route ~= "right" -- 136
						else -- 136
							_with_1.moveFromRight = body.velocityX < 0 -- 136
						end -- 136
						_with_1.moveRouteName = name -- 137
						_with_1.moveEnter = enter -- 138
						_with_1.moveTargets = Array(targets) -- 139
					end -- 135
					if #targets > 0 and not door.opened then -- 140
						door.opened = true -- 142
						door.recovery = 1 -- 143
						door.speed = DoorSpeed -- 144
						door:play(animation) -- 145
						return door -- 141
					end -- 140
				end -- 134
			end) -- 126
			_with_0:slot("BodyLeave", function(body, sensorTag) -- 146
				if not body.entity then -- 147
					return -- 147
				end -- 147
				if not body.entity.player then -- 148
					return -- 148
				end -- 148
				if not body.entity.moveTargets then -- 149
					return -- 149
				end -- 149
				local available = not body.entity.moveTargets.empty -- 150
				do -- 151
					local _with_1 = body.entity -- 151
					_with_1.moveFromRight = nil -- 152
					_with_1.moveRouteName = nil -- 153
					_with_1.moveEnter = nil -- 154
					_with_1.moveTargets = nil -- 155
				end -- 151
				if not available then -- 156
					return -- 156
				end -- 156
				local door, animation -- 157
				if LeftDoorSensor == sensorTag then -- 158
					door, animation = self._layers.leftwall, "closeL" -- 159
				elseif RightDoorSensor == sensorTag then -- 160
					door, animation = self._layers.rightwall, "closeR" -- 161
				end -- 157
				door.opened = false -- 163
				door.recovery = 1 -- 164
				door.speed = DoorSpeed -- 165
				door:play(animation) -- 166
				return door -- 162
			end) -- 146
			_with_0:addTo(self) -- 167
		end -- 124
		self._zoom = 1.0 -- 169
		self:gslot("AppChange", function(settingName) -- 170
			if settingName == "Size" then -- 170
				return self:updateZoom() -- 170
			end -- 170
		end) -- 170
		self:updateZoom() -- 171
		return self:schedule(function() -- 172
			local x = self.camera.position.x -- 173
			local distance -- 174
			if x < 800 then -- 174
				distance = 800 - x -- 175
			elseif x > 2300 then -- 176
				distance = x - 2300 -- 177
			else -- 179
				distance = 0 -- 179
			end -- 174
			self.zoom = 0.61 + 0.39 * math.min(1.0, distance / 800) -- 180
		end) -- 172
	end, -- 94
	loadAsync = function(_self) -- 182
		return Cache:loadAsync({ -- 182
			"spine:restRoom", -- 182
			"Image/library-bookcases.png" -- 182
		}) -- 182
	end -- 182
}) -- 51
return _module_0 -- 1
