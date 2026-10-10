-- [yue]: Script/Scene/Station.yue
local _module_0 = nil -- 1
local _ENV = Dora(Dora.Platformer) -- 1
local Vec2 <const> = Vec2 -- 2
local require <const> = require -- 2
local Spine <const> = Spine -- 2
local Class <const> = Class -- 2
local property <const> = property -- 2
local Sprite <const> = Sprite -- 2
local View <const> = View -- 2
local math <const> = math -- 2
local PlatformWorld <const> = PlatformWorld -- 2
local Rect <const> = Rect -- 2
local BodyDef <const> = BodyDef -- 2
local Body <const> = Body -- 2
local Data <const> = Data -- 2
local Array <const> = Array -- 2
local Cache <const> = Cache -- 2
local W <const> = 11520 -- 4
local HW <const> = W / 2 -- 5
local H <const> = 1080 -- 6
local HH <const> = H / 2 -- 7
local Offset <const> = 100 -- 8
local PathOffset <const> = Vec2(50, -25) -- 9
local MaxPath <const> = 2 -- 10
local DefaultZoom <const> = 1.0 -- 11
local AcademyExitSensor <const> = 1001 -- 12
local Map = require("Academy.Map") -- 13
local layerDefs = { -- 22
	{ -- 22
		look = "frontUp", -- 22
		order = 100, -- 22
		ratio = Vec2(-0.2, 0) -- 22
	}, -- 22
	{ -- 23
		look = "frontDown", -- 23
		order = 99, -- 23
		ratio = Vec2(-0.2, 0) -- 23
	}, -- 23
	{ -- 24
		look = "floor", -- 24
		order = -100 -- 24
	}, -- 24
	{ -- 25
		look = "car", -- 25
		order = -101, -- 25
		ratio = Vec2(0.2, 0) -- 25
	}, -- 25
	{ -- 26
		look = "light", -- 26
		order = -102, -- 26
		ratio = Vec2(0.4, 0) -- 26
	}, -- 26
	{ -- 27
		look = "back1", -- 27
		order = -103, -- 27
		ratio = Vec2(0.4, 0) -- 27
	}, -- 27
	{ -- 28
		look = "back2", -- 28
		order = -104, -- 28
		ratio = Vec2(0.6, 0) -- 28
	} -- 28
} -- 21
local addLayer -- 30
addLayer = function(world, def) -- 30
	local layer -- 31
	do -- 31
		local _with_0 = Spine("station") -- 31
		_with_0.look = def.look -- 32
		_with_0.order = def.order -- 33
		layer = _with_0 -- 31
	end -- 31
	if def.ratio then -- 34
		world:setLayerRatio(def.order, def.ratio) -- 35
	end -- 34
	if def.offset then -- 36
		world:setLayerOffset(def.order, def.offset) -- 37
	end -- 36
	world:addChild(layer) -- 38
	if def.handle then -- 39
		def.handle(layer) -- 39
	end -- 39
	return layer -- 40
end -- 30
_module_0 = Class({ -- 43
	sceneWidth = property(function() -- 43
		return W -- 43
	end), -- 43
	offset = property(function() -- 44
		return Offset -- 44
	end), -- 44
	right = property(function() -- 45
		return Vec2(W - 220, Offset) -- 45
	end), -- 45
	openRightDoor = function(self) -- 47
		return true -- 47
	end, -- 47
	addShadowTo = function(self, unit) -- 49
		local _with_0 = Sprite("Image/shadow.png") -- 50
		_with_0.order = -1 -- 51
		_with_0:schedule(function() -- 52
			_with_0.y = self.offset - unit.y -- 52
		end) -- 52
		_with_0:addTo(unit) -- 53
		return _with_0 -- 50
	end, -- 49
	zoom = property(function(self) -- 55
		return self._zoom -- 55
	end, function(self, value) -- 56
		self._zoom = value -- 57
		return self:updateZoom() -- 58
	end), -- 55
	updateZoom = function(self) -- 60
		local scale = View.scale -- 61
		local width, height -- 62
		do -- 62
			local _obj_0 = View.size * Vec2(scale, scale) -- 62
			width, height = _obj_0.width, _obj_0.height -- 62
		end -- 62
		local zoom = self._zoom / DefaultZoom -- 63
		zoom = math.max(width / W / zoom, height / H / zoom) -- 64
		local realWidth = math.min(W / zoom, W) -- 65
		local realHeight = math.min(H / zoom, H) -- 66
		zoom = math.max(W / realWidth, H / realHeight) -- 67
		self.camera.zoom = zoom / scale -- 68
	end, -- 60
	__partial = function(_self) -- 70
		local _with_0 = PlatformWorld() -- 71
		do -- 72
			local _with_1 = _with_0.camera -- 72
			_with_1.boundary = Rect(0, 0, W, H) -- 73
			_with_1.followRatio = Vec2(0.03, 0.03) -- 74
		end -- 72
		_with_0.tag = "Station" -- 75
		return _with_0 -- 71
	end, -- 70
	__init = function(self) -- 77
		for i = -MaxPath, MaxPath do -- 78
			self:setLayerOffset(i, PathOffset * i) -- 79
		end -- 78
		for _index_0 = 1, #layerDefs do -- 81
			local def = layerDefs[_index_0] -- 81
			addLayer(self, def) -- 82
		end -- 81
		local terrainDef -- 84
		do -- 84
			local _with_0 = BodyDef() -- 84
			_with_0.type = "Static" -- 85
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 86
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 87
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 88
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 89
			_with_0:attachPolygonSensor(AcademyExitSensor, Vec2(W - 90, 175), 180, 350) -- 90
			_with_0.position = Vec2(0, Offset) -- 91
			terrainDef = _with_0 -- 84
		end -- 84
		do -- 93
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 93
			_with_0.group = Data.groupTerrain -- 94
			_with_0:addTo(self) -- 95
			_with_0:slot("BodyEnter", function(body, sensorTag) -- 96
				if not (sensorTag == AcademyExitSensor and body.entity and body.entity.player) then -- 97
					return -- 97
				end -- 97
				local name, enter, targets = Map.getRoute("Station", "right") -- 98
				if name then -- 98
					local _with_1 = body.entity -- 99
					_with_1.moveFromRight = false -- 100
					_with_1.moveRouteName = name -- 101
					_with_1.moveEnter = enter -- 102
					_with_1.moveTargets = Array(targets) -- 103
					return _with_1 -- 99
				end -- 98
			end) -- 96
			_with_0:slot("BodyLeave", function(body, sensorTag) -- 104
				if not (sensorTag == AcademyExitSensor and body.entity and body.entity.player) then -- 105
					return -- 105
				end -- 105
				local _with_1 = body.entity -- 106
				_with_1.moveFromRight = nil -- 107
				_with_1.moveRouteName = nil -- 108
				_with_1.moveEnter = nil -- 109
				_with_1.moveTargets = nil -- 110
				return _with_1 -- 106
			end) -- 104
		end -- 93
		self._zoom = 1.0 -- 112
		self:gslot("AppChange", function(settingName) -- 113
			if settingName == "Size" then -- 113
				return self:updateZoom() -- 113
			end -- 113
		end) -- 113
		return self:updateZoom() -- 114
	end, -- 77
	loadAsync = function(_self) -- 116
		Cache:loadAsync("spine:station") -- 117
		return Cache:loadAsync("spine:ninilite") -- 118
	end -- 116
}) -- 42
return _module_0 -- 1
