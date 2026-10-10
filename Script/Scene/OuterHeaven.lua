-- [yue]: Script/Scene/OuterHeaven.yue
local _module_0 = nil -- 1
local _ENV = Dora(Dora.Platformer) -- 1
local Vec2 <const> = Vec2 -- 2
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
local Cache <const> = Cache -- 2
local W <const> = 11520 -- 4
local HW <const> = W / 2 -- 5
local H <const> = 1080 -- 6
local HH <const> = H / 2 -- 7
local Offset <const> = 150 -- 8
local PathOffset <const> = Vec2(-50, -30) -- 9
local MaxPath <const> = 2 -- 10
local DefaultZoom <const> = 1.0 -- 11
local layerDefs = { -- 20
	{ -- 20
		look = "front", -- 20
		order = 100, -- 20
		ratio = Vec2(-0.2, 0) -- 20
	}, -- 20
	{ -- 21
		look = "bushshadow", -- 21
		order = -100, -- 21
		y = -70, -- 21
		z = 283 -- 21
	}, -- 21
	{ -- 22
		look = "road", -- 22
		order = -101, -- 22
		angleX = 45, -- 22
		scale = 1.22 -- 22
	}, -- 22
	{ -- 23
		look = "bush", -- 23
		order = -102, -- 23
		y = -70, -- 23
		z = 283 -- 23
	}, -- 23
	{ -- 24
		look = "light", -- 24
		order = -103, -- 24
		ratio = Vec2(1, 0) -- 24
	}, -- 24
	{ -- 25
		look = "cloud5", -- 25
		order = -104, -- 25
		ratio = Vec2(0.8, 0), -- 25
		z = 250, -- 25
		handle = function(self) -- 25
			self.speed = 1 / 10 -- 26
			self:play("cloud", true) -- 27
			return self -- 25
		end -- 25
	}, -- 25
	{ -- 28
		look = "cloud4", -- 28
		order = -105, -- 28
		ratio = Vec2(0.82, 0), -- 28
		z = 250, -- 28
		handle = function(self) -- 28
			self.speed = 1 / 30 -- 29
			self:play("cloud", true) -- 30
			return self -- 28
		end -- 28
	}, -- 28
	{ -- 31
		look = "cloud3", -- 31
		order = -106, -- 31
		ratio = Vec2(0.84, 0), -- 31
		z = 250, -- 31
		handle = function(self) -- 31
			self.speed = 1 / 50 -- 32
			self:play("cloud", true) -- 33
			return self -- 31
		end -- 31
	}, -- 31
	{ -- 34
		look = "cloud2", -- 34
		order = -107, -- 34
		ratio = Vec2(0.86, 0), -- 34
		z = 250, -- 34
		handle = function(self) -- 34
			self.speed = 1 / 70 -- 35
			self:play("cloud", true) -- 36
			return self -- 34
		end -- 34
	}, -- 34
	{ -- 37
		look = "fog", -- 37
		order = -108, -- 37
		ratio = Vec2(0.9, 0), -- 37
		y = -100, -- 37
		z = 250, -- 37
		handle = function(self) -- 37
			self.speed = 1 / 30 -- 38
			self:play("fogout") -- 39
			return self -- 37
		end -- 37
	}, -- 37
	{ -- 40
		look = "valley", -- 40
		order = -109, -- 40
		ratio = Vec2(0.8, -0.2), -- 40
		angleX = 45, -- 40
		scale = 1.2, -- 40
		x = -400 -- 40
	}, -- 40
	{ -- 41
		look = "mountain", -- 41
		order = -110, -- 41
		ratio = Vec2(0.86, 0), -- 41
		y = -200, -- 41
		z = 250 -- 41
	}, -- 41
	{ -- 42
		look = "cloud1", -- 42
		order = -111, -- 42
		ratio = Vec2(0.8, 0), -- 42
		z = 250, -- 42
		handle = function(self) -- 42
			self.speed = 1 / 90 -- 43
			self:play("cloud", true) -- 44
			return self -- 42
		end -- 42
	}, -- 42
	{ -- 45
		look = "back", -- 45
		order = -112, -- 45
		ratio = Vec2(1, 0) -- 45
	} -- 45
} -- 19
local addLayer -- 47
addLayer = function(world, def) -- 47
	local layer -- 48
	do -- 48
		local _with_0 = Spine("outerHeaven") -- 48
		_with_0.look = def.look -- 49
		_with_0.order = def.order -- 50
		_with_0.scaleX = def.scale or 1.0 -- 51
		_with_0.scaleY = def.scale or 1.0 -- 52
		_with_0.x = def.x or 0 -- 53
		_with_0.y = def.y or 0 -- 54
		_with_0.z = def.z or 0 -- 55
		_with_0.angleX = def.angleX or 0 -- 56
		_with_0.angleY = def.angleY or 0 -- 57
		layer = _with_0 -- 48
	end -- 48
	if def.ratio then -- 58
		world:setLayerRatio(def.order, def.ratio) -- 59
	end -- 58
	world:addChild(layer) -- 60
	if def.handle then -- 61
		def.handle(layer) -- 61
	end -- 61
	return layer -- 62
end -- 47
_module_0 = Class({ -- 65
	width = property(function() -- 65
		return W -- 65
	end), -- 65
	sceneWidth = property(function() return W end),
	offset = property(function() -- 66
		return Offset -- 66
	end), -- 66
	addShadowTo = function(self, unit) -- 68
		local _with_0 = Sprite("Image/shadow.png") -- 69
		_with_0.order = -1 -- 70
		_with_0:schedule(function() -- 71
			_with_0.y = self.offset - unit.y -- 71
		end) -- 71
		_with_0:addTo(unit) -- 72
		return _with_0 -- 69
	end, -- 68
	zoom = property(function(self) -- 74
		return self._zoom -- 74
	end, function(self, value) -- 75
		self._zoom = value -- 76
		return self:updateZoom() -- 77
	end), -- 74
	updateZoom = function(self) -- 79
		local scale = View.scale -- 80
		local width, height -- 81
		do -- 81
			local _obj_0 = View.size * Vec2(scale, scale) -- 81
			width, height = _obj_0.width, _obj_0.height -- 81
		end -- 81
		local zoom = self._zoom / DefaultZoom -- 82
		zoom = math.max(width / W / zoom, height / H / zoom) -- 83
		local realWidth = math.min(W / zoom, W) -- 84
		local realHeight = math.min(H / zoom, H) -- 85
		zoom = math.max(W / realWidth, H / realHeight) -- 86
		self.camera.zoom = zoom / scale -- 87
	end, -- 79
	__partial = function(_) -- 89
		local _with_0 = PlatformWorld() -- 90
		do -- 91
			local _with_1 = _with_0.camera -- 91
			_with_1.boundary = Rect(0, 0, W, H) -- 92
			_with_1.followRatio = Vec2(0.03, 0.03) -- 93
		end -- 91
		_with_0.tag = "OuterHeaven" -- 94
		return _with_0 -- 90
	end, -- 89
	__init = function(self) -- 96
		for i = -MaxPath, MaxPath do -- 97
			self:setLayerOffset(i, PathOffset * i) -- 98
			self:getLayer(i).z = -50 * i -- 99
		end -- 97
		for _index_0 = 1, #layerDefs do -- 101
			local def = layerDefs[_index_0] -- 101
			addLayer(self, def) -- 102
		end -- 101
		local terrainDef -- 104
		do -- 104
			local _with_0 = BodyDef() -- 104
			_with_0.type = "Static" -- 105
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 106
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 107
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 108
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 109
			_with_0.position = Vec2(0, Offset) -- 110
			terrainDef = _with_0 -- 104
		end -- 104
		do -- 112
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 112
			_with_0.group = Data.groupTerrain -- 113
			_with_0:addTo(self) -- 114
		end -- 112
		self._zoom = 1.0 -- 116
		self:gslot("AppChange", function(settingName) -- 117
			if settingName == "Size" then -- 117
				return self:updateZoom() -- 117
			end -- 117
		end) -- 117
		return self:updateZoom() -- 118
	end, -- 96
	loadAsync = function(_) -- 120
		return Cache:loadAsync("spine:outerHeaven") -- 120
	end -- 120
}) -- 64
return _module_0 -- 1
