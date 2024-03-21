-- [yue]: Script/Scene/Passage.yue
local Spine = dora.Spine -- 1
local Class = dora.Class -- 1
local property = dora.property -- 1
local Vec2 = dora.Vec2 -- 1
local Sprite = dora.Sprite -- 1
local View = dora.View -- 1
local Rect = dora.Rect -- 1
local _module_0 = dora.Platformer -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local ClipNode = dora.ClipNode -- 1
local BodyDef = dora.BodyDef -- 1
local Body = dora.Body -- 1
local Data = _module_0.Data -- 1
local Array = dora.Array -- 1
local Cache = dora.Cache -- 1
local _module_0 = nil -- 1
local Rectangle = require("UI.View.Shape.Rectangle") -- 2
local Map = require("Academy.Map") -- 3
local H <const> = 940 -- 5
local HH <const> = H / 2 -- 6
local Offset <const> = 0 -- 7
local BackZ <const> = 470 -- 8
local ZOffset <const> = BackZ / 2 -- 9
local PathOffset <const> = 80 -- 10
local MaxPath <const> = 2 -- 11
local DefaultZoom <const> = 0.7 -- 12
local passageDefs = { -- 21
	{ -- 21
		w = 790, -- 21
		items = { -- 23
			{ -- 23
				look = "spotlight1", -- 23
				order = 100, -- 23
				z = ZOffset -- 23
			}, -- 23
			{ -- 24
				look = "leftwall", -- 24
				order = -110, -- 24
				angleY = -90 -- 24
			}, -- 24
			{ -- 25
				look = "rightwall", -- 25
				order = -111, -- 25
				x = 790, -- 25
				angleY = 90 -- 25
			}, -- 25
			{ -- 26
				look = "floor1", -- 26
				order = -112, -- 26
				angleX = 90 -- 26
			}, -- 26
			{ -- 27
				look = "back1", -- 27
				order = -113, -- 27
				z = BackZ -- 27
			} -- 27
		}, -- 22
		elevator = { -- 29
			frame = { -- 29
				look = "elevator", -- 29
				order = -100, -- 29
				x = 790 / 2, -- 29
				z = BackZ -- 29
			}, -- 29
			door = { -- 30
				look = "elevatordoor", -- 30
				order = -101, -- 30
				x = 790 / 2, -- 30
				z = BackZ -- 30
			}, -- 30
			floor = { -- 31
				look = "elevatorfloor", -- 31
				order = -102, -- 31
				x = 790 / 2, -- 31
				z = BackZ, -- 31
				angleX = 90 -- 31
			}, -- 31
			back = { -- 32
				look = "elevatorback", -- 32
				order = -103, -- 32
				x = 790 / 2, -- 32
				z = BackZ + 134 -- 32
			} -- 32
		} -- 28
	}, -- 21
	{ -- 33
		w = 1570, -- 33
		items = { -- 35
			{ -- 35
				look = "spotlight2", -- 35
				order = 100, -- 35
				z = ZOffset -- 35
			}, -- 35
			{ -- 36
				look = "leftwall", -- 36
				order = -110, -- 36
				angleY = -90 -- 36
			}, -- 36
			{ -- 37
				look = "rightwall", -- 37
				order = -111, -- 37
				x = 1570, -- 37
				angleY = 90 -- 37
			}, -- 37
			{ -- 38
				look = "floor2", -- 38
				order = -112, -- 38
				angleX = 90 -- 38
			}, -- 38
			{ -- 39
				look = "back2", -- 39
				order = -113, -- 39
				z = BackZ -- 39
			} -- 39
		}, -- 34
		elevator = { -- 41
			frame = { -- 41
				look = "elevator", -- 41
				order = -100, -- 41
				x = 1570 / 2, -- 41
				z = BackZ -- 41
			}, -- 41
			door = { -- 42
				look = "elevatordoor", -- 42
				order = -101, -- 42
				x = 1570 / 2, -- 42
				z = BackZ -- 42
			}, -- 42
			floor = { -- 43
				look = "elevatorfloor", -- 43
				order = -102, -- 43
				x = 1570 / 2, -- 43
				z = BackZ, -- 43
				angleX = 90 -- 43
			}, -- 43
			back = { -- 44
				look = "elevatorback", -- 44
				order = -103, -- 44
				x = 1570 / 2, -- 44
				z = BackZ + 134 -- 44
			} -- 44
		} -- 40
	}, -- 33
	{ -- 45
		w = 2344, -- 45
		items = { -- 47
			{ -- 47
				look = "spotlight3", -- 47
				order = 100, -- 47
				z = ZOffset -- 47
			}, -- 47
			{ -- 48
				look = "leftwall", -- 48
				order = -110, -- 48
				angleY = -90 -- 48
			}, -- 48
			{ -- 49
				look = "rightwall", -- 49
				order = -111, -- 49
				x = 2344, -- 49
				angleY = 90 -- 49
			}, -- 49
			{ -- 50
				look = "floor3", -- 50
				order = -112, -- 50
				angleX = 90 -- 50
			}, -- 50
			{ -- 51
				look = "back3", -- 51
				order = -113, -- 51
				z = BackZ -- 51
			} -- 51
		}, -- 46
		elevator = { -- 53
			frame = { -- 53
				look = "elevator", -- 53
				order = -100, -- 53
				x = 1558, -- 53
				z = BackZ -- 53
			}, -- 53
			door = { -- 54
				look = "elevatordoor", -- 54
				order = -101, -- 54
				x = 1558, -- 54
				z = BackZ -- 54
			}, -- 54
			floor = { -- 55
				look = "elevatorfloor", -- 55
				order = -102, -- 55
				x = 1558, -- 55
				z = BackZ, -- 55
				angleX = 90 -- 55
			}, -- 55
			back = { -- 56
				look = "elevatorback", -- 56
				order = -103, -- 56
				x = 1558, -- 56
				z = BackZ + 134 -- 56
			} -- 56
		} -- 52
	} -- 45
} -- 20
local createLayer -- 58
createLayer = function(def) -- 58
	local _with_0 = Spine("passage") -- 59
	_with_0.look = def.look -- 60
	_with_0.order = def.order -- 61
	_with_0.scaleX = def.scale or 1.0 -- 62
	_with_0.scaleY = def.scale or 1.0 -- 63
	_with_0.x = def.x or 0 -- 64
	_with_0.y = def.y or 0 -- 65
	_with_0.z = def.z or 0 -- 66
	_with_0.angleX = def.angleX or 0 -- 67
	_with_0.angleY = def.angleY or 0 -- 68
	_with_0.x = def.x or 0 -- 69
	return _with_0 -- 59
end -- 58
local addLayer -- 71
addLayer = function(world, def) -- 71
	local layer = createLayer(def) -- 72
	if def.ratio then -- 73
		world:setLayerRatio(def.order, def.ratio) -- 74
	end -- 73
	if def.offset then -- 75
		world:setLayerOffset(def.order, def.offset) -- 76
	end -- 75
	world:addChild(layer) -- 77
	if def.handle then -- 78
		def.handle(layer) -- 78
	end -- 78
	return layer -- 79
end -- 71
local _anon_func_0 = function(ClipNode, back, createLayer, floor, mask) -- 163
	local _with_0 = ClipNode(mask) -- 160
	_with_0:addChild(createLayer(back)) -- 161
	_with_0:addChild(createLayer(floor)) -- 162
	_with_0.order = back.order -- 163
	return _with_0 -- 160
end -- 160
_module_0 = Class({ -- 82
	width = property(function(self) -- 82
		return self._width -- 82
	end), -- 82
	offset = property(function() -- 83
		return Offset -- 83
	end), -- 83
	left = property(function(self) -- 84
		return Vec2(100, self.offset) -- 84
	end), -- 84
	right = property(function(self) -- 85
		return Vec2(self.width - 100, self.offset) -- 85
	end), -- 85
	center = property(function(self) -- 86
		local elevator = self._layers.elevatorDoor -- 87
		if elevator then -- 87
			return Vec2(elevator.x, self.offset) -- 88
		else -- 90
			return nil -- 90
		end -- 87
	end), -- 86
	addShadowTo = function(self, unit) -- 92
		local _with_0 = Sprite("Image/shadow1.png") -- 93
		_with_0.angleX = 90 -- 94
		_with_0.order = -1 -- 95
		_with_0:schedule(function() -- 96
			_with_0.y = self.offset - unit.y -- 96
		end) -- 96
		_with_0:addTo(unit) -- 97
		return _with_0 -- 93
	end, -- 92
	openLeftDoor = function(self) -- 99
		local _with_0 = self._layers.leftwall -- 99
		_with_0.opened = true -- 100
		_with_0.recovery = 0 -- 101
		_with_0:play("openLI") -- 102
		return _with_0 -- 99
	end, -- 99
	openRightDoor = function(self) -- 104
		local _with_0 = self._layers.rightwall -- 104
		_with_0.opened = true -- 105
		_with_0.recovery = 0 -- 106
		_with_0:play("openRI") -- 107
		return _with_0 -- 104
	end, -- 104
	openCenterDoor = function(self) -- 109
		local _with_0 = self._layers.elevatorDoor -- 109
		_with_0.opened = true -- 110
		_with_0.recovery = 0 -- 111
		_with_0:play("openElevatorI") -- 112
		return _with_0 -- 109
	end, -- 109
	zoom = property(function(self) -- 114
		return self._zoom -- 114
	end, function(self, value) -- 115
		self._zoom = value -- 116
		return self:updateZoom() -- 117
	end), -- 114
	updateZoom = function(self) -- 119
		local actualZoom = self._zoom * DefaultZoom -- 120
		local width, height -- 121
		do -- 121
			local _obj_0 = View.size -- 121
			width, height = _obj_0.width, _obj_0.height -- 121
		end -- 121
		local zoom = height / H / actualZoom -- 122
		if width > self._width * zoom then -- 123
			zoom = width / self._width -- 124
		end -- 123
		local _with_0 = self.camera -- 125
		_with_0.zoom = zoom -- 126
		_with_0.boundary = Rect(0, 0, self._width, H * actualZoom) -- 127
		return _with_0 -- 125
	end, -- 119
	__partial = function() -- 129
		local _with_0 = PlatformWorld() -- 130
		_with_0.camera.followRatio = Vec2(0.03, 0.03) -- 131
		return _with_0 -- 130
	end, -- 129
	__init = function(self, name, index, withElevator) -- 133
		if index == nil then -- 133
			index = 3 -- 133
		end -- 133
		if withElevator == nil then -- 133
			withElevator = true -- 133
		end -- 133
		self._name = name -- 134
		local passageDef = passageDefs[index] -- 136
		local W <const> = passageDef.w -- 137
		local HW <const> = W / 2 -- 138
		self._width = W -- 139
		for i = -MaxPath, MaxPath do -- 141
			local _with_0 = self:getLayer(i) -- 142
			_with_0.z = ZOffset - PathOffset * i -- 143
		end -- 143
		do -- 145
			local _tbl_0 = { } -- 145
			local _list_0 = passageDef.items -- 145
			for _index_0 = 1, #_list_0 do -- 145
				local def = _list_0[_index_0] -- 145
				_tbl_0[def.look] = addLayer(self, def) -- 145
			end -- 145
			self._layers = _tbl_0 -- 145
		end -- 145
		if withElevator then -- 147
			local frame, door, floor, back -- 148
			do -- 148
				local _obj_0 = passageDef.elevator -- 148
				frame, door, floor, back = _obj_0.frame, _obj_0.door, _obj_0.floor, _obj_0.back -- 148
			end -- 148
			addLayer(self, frame) -- 149
			do -- 150
				local _with_0 = addLayer(self, door) -- 150
				_with_0.opened = false -- 151
				self._layers.elevatorDoor = _with_0 -- 150
			end -- 150
			local mask -- 152
			do -- 152
				local _with_0 = Rectangle({ -- 153
					x = frame.x, -- 153
					y = 375 / 2, -- 154
					width = 270, -- 155
					height = 375, -- 156
					fillColor = 0xffffffff -- 157
				}) -- 152
				_with_0.z = frame.z -- 159
				mask = _with_0 -- 152
			end -- 152
			self:addChild(_anon_func_0(ClipNode, back, createLayer, floor, mask)) -- 160
		end -- 147
		local LeftDoorSensor <const> = 0 -- 165
		local RightDoorSensor <const> = 1 -- 166
		local ElevatorSensor <const> = 2 -- 167
		local terrainDef -- 168
		do -- 168
			local _with_0 = BodyDef() -- 168
			_with_0.type = "Static" -- 169
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 170
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 171
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 172
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 173
			_with_0:attachPolygonSensor(LeftDoorSensor, Vec2(75, 175), 150, 350) -- 174
			_with_0:attachPolygonSensor(RightDoorSensor, Vec2(W - 75, 175), 150, 350) -- 175
			if withElevator then -- 176
				_with_0:attachPolygonSensor(ElevatorSensor, Vec2(passageDef.elevator.frame.x, 175), 270, 350) -- 177
			end -- 176
			_with_0.position = Vec2(0, Offset) -- 178
			terrainDef = _with_0 -- 168
		end -- 168
		self._layers.leftwall.opened = false -- 180
		self._layers.rightwall.opened = false -- 181
		local DoorSpeed <const> = 1.5 -- 182
		self:addChild((function() -- 183
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 183
			_with_0.group = Data.groupTerrain -- 184
			_with_0:slot("BodyEnter", function(body, sensorTag) -- 185
				if not body.entity then -- 186
					return -- 186
				end -- 186
				if not body.entity.player then -- 187
					return -- 187
				end -- 187
				local door, animation, route -- 188
				if LeftDoorSensor == sensorTag then -- 189
					door, animation, route = self._layers.leftwall, "openL", "left" -- 190
				elseif RightDoorSensor == sensorTag then -- 191
					door, animation, route = self._layers.rightwall, "openR", "right" -- 192
				elseif ElevatorSensor == sensorTag then -- 193
					door, animation, route = self._layers.elevatorDoor, "openElevator", "center" -- 194
				end -- 194
				local enter, targets -- 195
				name, enter, targets = Map.getRoute(self._name, route) -- 195
				if name then -- 195
					do -- 196
						local _with_1 = body.entity -- 196
						if body.velocityX == 0 then -- 197
							_with_1.moveFromRight = route ~= "right" -- 197
						else -- 197
							_with_1.moveFromRight = body.velocityX < 0 -- 197
						end -- 197
						_with_1.moveRouteName = name -- 198
						_with_1.moveEnter = enter -- 199
						_with_1.moveTargets = Array(targets) -- 200
					end -- 196
					if #targets > 0 and not door.opened then -- 201
						door.opened = true -- 203
						door.recovery = 1 -- 204
						door.speed = DoorSpeed -- 205
						door:play(animation) -- 206
						return door -- 202
					end -- 201
				end -- 195
			end) -- 185
			_with_0:slot("BodyLeave", function(body, sensorTag) -- 207
				if not body.entity then -- 208
					return -- 208
				end -- 208
				if not body.entity.player then -- 209
					return -- 209
				end -- 209
				if not body.entity.moveTargets then -- 210
					return -- 210
				end -- 210
				local available = not body.entity.moveTargets.empty -- 211
				do -- 212
					local _with_1 = body.entity -- 212
					_with_1.moveFromRight = nil -- 213
					_with_1.moveRouteName = nil -- 214
					_with_1.moveEnter = nil -- 215
					_with_1.moveTargets = nil -- 216
				end -- 212
				if not available then -- 217
					return -- 217
				end -- 217
				local door, animation -- 218
				if LeftDoorSensor == sensorTag then -- 219
					door, animation = self._layers.leftwall, "closeL" -- 220
				elseif RightDoorSensor == sensorTag then -- 221
					door, animation = self._layers.rightwall, "closeR" -- 222
				elseif ElevatorSensor == sensorTag then -- 223
					door, animation = self._layers.elevatorDoor, "closeElevator" -- 224
				end -- 224
				door.opened = false -- 226
				door.recovery = 1 -- 227
				door.speed = DoorSpeed -- 228
				door:play(animation) -- 229
				return door -- 225
			end) -- 207
			return _with_0 -- 183
		end)()) -- 183
		self._zoom = 1.0 -- 230
		self:gslot("AppSizeChanged", function() -- 231
			return self:updateZoom() -- 231
		end) -- 231
		return self:updateZoom() -- 232
	end, -- 133
	loadAsync = function() -- 234
		return Cache:loadAsync("spine:passage") -- 234
	end -- 234
}) -- 81
return _module_0 -- 234
