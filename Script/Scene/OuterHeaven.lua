-- [yue]: Script/Scene/OuterHeaven.yue
local Vec2 = Dora.Vec2 -- 1
local Spine = Dora.Spine -- 1
local Class = Dora.Class -- 1
local property = Dora.property -- 1
local Sprite = Dora.Sprite -- 1
local View = Dora.View -- 1
local math = _G.math -- 1
local _module_0 = Dora.Platformer -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local Rect = Dora.Rect -- 1
local BodyDef = Dora.BodyDef -- 1
local Body = Dora.Body -- 1
local Data = _module_0.Data -- 1
local Cache = Dora.Cache -- 1
local _module_0 = nil -- 1
local W <const> = 11520 -- 3
local HW <const> = W / 2 -- 4
local H <const> = 1080 -- 5
local HH <const> = H / 2 -- 6
local Offset <const> = 150 -- 7
local PathOffset <const> = Vec2(-50, -30) -- 8
local MaxPath <const> = 2 -- 9
local DefaultZoom <const> = 1.0 -- 10
local layerDefs = { -- 19
	{ -- 19
		look = "front", -- 19
		order = 100, -- 19
		ratio = Vec2(-0.2, 0) -- 19
	}, -- 19
	{ -- 20
		look = "bushshadow", -- 20
		order = -100, -- 20
		y = -70, -- 20
		z = 283 -- 20
	}, -- 20
	{ -- 21
		look = "road", -- 21
		order = -101, -- 21
		angleX = 45, -- 21
		scale = 1.22 -- 21
	}, -- 21
	{ -- 22
		look = "bush", -- 22
		order = -102, -- 22
		y = -70, -- 22
		z = 283 -- 22
	}, -- 22
	{ -- 23
		look = "light", -- 23
		order = -103, -- 23
		ratio = Vec2(1, 0) -- 23
	}, -- 23
	{ -- 24
		look = "cloud5", -- 24
		order = -104, -- 24
		ratio = Vec2(0.8, 0), -- 24
		z = 250, -- 24
		handle = function(self) -- 24
			self.speed = 1 / 10 -- 25
			self:play("cloud", true) -- 26
			return self -- 24
		end -- 24
	}, -- 24
	{ -- 27
		look = "cloud4", -- 27
		order = -105, -- 27
		ratio = Vec2(0.82, 0), -- 27
		z = 250, -- 27
		handle = function(self) -- 27
			self.speed = 1 / 30 -- 28
			self:play("cloud", true) -- 29
			return self -- 27
		end -- 27
	}, -- 27
	{ -- 30
		look = "cloud3", -- 30
		order = -106, -- 30
		ratio = Vec2(0.84, 0), -- 30
		z = 250, -- 30
		handle = function(self) -- 30
			self.speed = 1 / 50 -- 31
			self:play("cloud", true) -- 32
			return self -- 30
		end -- 30
	}, -- 30
	{ -- 33
		look = "cloud2", -- 33
		order = -107, -- 33
		ratio = Vec2(0.86, 0), -- 33
		z = 250, -- 33
		handle = function(self) -- 33
			self.speed = 1 / 70 -- 34
			self:play("cloud", true) -- 35
			return self -- 33
		end -- 33
	}, -- 33
	{ -- 36
		look = "fog", -- 36
		order = -108, -- 36
		ratio = Vec2(0.9, 0), -- 36
		y = -100, -- 36
		z = 250, -- 36
		handle = function(self) -- 36
			self.speed = 1 / 30 -- 37
			self:play("fogout") -- 38
			return self -- 36
		end -- 36
	}, -- 36
	{ -- 39
		look = "valley", -- 39
		order = -109, -- 39
		ratio = Vec2(0.8, -0.2), -- 39
		angleX = 45, -- 39
		scale = 1.2, -- 39
		x = -400 -- 39
	}, -- 39
	{ -- 40
		look = "mountain", -- 40
		order = -110, -- 40
		ratio = Vec2(0.86, 0), -- 40
		y = -200, -- 40
		z = 250 -- 40
	}, -- 40
	{ -- 41
		look = "cloud1", -- 41
		order = -111, -- 41
		ratio = Vec2(0.8, 0), -- 41
		z = 250, -- 41
		handle = function(self) -- 41
			self.speed = 1 / 90 -- 42
			self:play("cloud", true) -- 43
			return self -- 41
		end -- 41
	}, -- 41
	{ -- 44
		look = "back", -- 44
		order = -112, -- 44
		ratio = Vec2(1, 0) -- 44
	} -- 44
} -- 18
local addLayer -- 46
addLayer = function(world, def) -- 46
	local layer -- 47
	do -- 47
		local _with_0 = Spine("outerHeaven") -- 47
		_with_0.look = def.look -- 48
		_with_0.order = def.order -- 49
		_with_0.scaleX = def.scale or 1.0 -- 50
		_with_0.scaleY = def.scale or 1.0 -- 51
		_with_0.x = def.x or 0 -- 52
		_with_0.y = def.y or 0 -- 53
		_with_0.z = def.z or 0 -- 54
		_with_0.angleX = def.angleX or 0 -- 55
		_with_0.angleY = def.angleY or 0 -- 56
		layer = _with_0 -- 47
	end -- 47
	if def.ratio then -- 57
		world:setLayerRatio(def.order, def.ratio) -- 58
	end -- 57
	world:addChild(layer) -- 59
	if def.handle then -- 60
		def.handle(layer) -- 60
	end -- 60
	return layer -- 61
end -- 46
_module_0 = Class({ -- 64
	width = property(function() -- 64
		return W -- 64
	end), -- 64
	offset = property(function() -- 65
		return Offset -- 65
	end), -- 65
	addShadowTo = function(self, unit) -- 67
		local _with_0 = Sprite("Image/shadow.png") -- 68
		_with_0.order = -1 -- 69
		_with_0:schedule(function() -- 70
			_with_0.y = self.offset - unit.y -- 70
		end) -- 70
		_with_0:addTo(unit) -- 71
		return _with_0 -- 68
	end, -- 67
	zoom = property(function(self) -- 73
		return self._zoom -- 73
	end, function(self, value) -- 74
		self._zoom = value -- 75
		return self:updateZoom() -- 76
	end), -- 73
	updateZoom = function(self) -- 78
		local scale = View.scale -- 79
		local width, height -- 80
		do -- 80
			local _obj_0 = View.size * Vec2(scale, scale) -- 80
			width, height = _obj_0.width, _obj_0.height -- 80
		end -- 80
		local zoom = self._zoom / DefaultZoom -- 81
		zoom = math.max(width / W / zoom, height / H / zoom) -- 82
		local realWidth = math.min(W / zoom, W) -- 83
		local realHeight = math.min(H / zoom, H) -- 84
		zoom = math.max(W / realWidth, H / realHeight) -- 85
		self.camera.zoom = zoom / scale -- 86
	end, -- 78
	__partial = function(_) -- 88
		local _with_0 = PlatformWorld() -- 89
		do -- 90
			local _with_1 = _with_0.camera -- 90
			_with_1.boundary = Rect(0, 0, W, H) -- 91
			_with_1.followRatio = Vec2(0.03, 0.03) -- 92
		end -- 90
		_with_0.tag = "OuterHeaven" -- 93
		return _with_0 -- 89
	end, -- 88
	__init = function(self) -- 95
		for i = -MaxPath, MaxPath do -- 96
			self:setLayerOffset(i, PathOffset * i) -- 97
			self:getLayer(i).z = -50 * i -- 98
		end -- 98
		for _index_0 = 1, #layerDefs do -- 100
			local def = layerDefs[_index_0] -- 100
			addLayer(self, def) -- 101
		end -- 101
		local terrainDef -- 103
		do -- 103
			local _with_0 = BodyDef() -- 103
			_with_0.type = "Static" -- 104
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 105
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 106
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 107
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 108
			_with_0.position = Vec2(0, Offset) -- 109
			terrainDef = _with_0 -- 103
		end -- 103
		do -- 111
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 111
			_with_0.group = Data.groupTerrain -- 112
			_with_0:addTo(self) -- 113
		end -- 111
		self._zoom = 1.0 -- 115
		self:gslot("AppChange", function(settingName) -- 116
			if settingName == "Size" then -- 116
				return self:updateZoom() -- 116
			end -- 116
		end) -- 116
		return self:updateZoom() -- 117
	end, -- 95
	loadAsync = function(_) -- 119
		return Cache:loadAsync("spine:outerHeaven") -- 119
	end -- 119
}) -- 63
return _module_0 -- 119
