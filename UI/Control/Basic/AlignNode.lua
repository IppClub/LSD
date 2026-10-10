-- [yue]: UI/Control/Basic/AlignNode.yue
local _module_0 = nil -- 1
local _ENV = Dora -- 9
local Class <const> = Class -- 10
local Node <const> = Node -- 10
local Vec2 <const> = Vec2 -- 10
local App <const> = App -- 10
local View <const> = View -- 10
local load <const> = load -- 10
local tostring <const> = tostring -- 10
local alignFuncCache = { } -- 12
local alignFunc <const> = function(src) -- 13
	local cached = alignFuncCache[src] -- 14
	if not cached then -- 15
		cached = load("local _ENV = " .. "Dora(...)\nreturn " .. tostring(src)) -- 16
		alignFuncCache[src] = cached -- 17
	end -- 15
	return cached -- 18
end -- 12
_module_0 = Class(Node, { -- 13
	__init = function(self, args) -- 13
		local isRoot, inUI, hAlign, vAlign, alignOffset, alignWidth, alignHeight -- 14
		do -- 14
			local _obj_0 = args or { } -- 22
			isRoot, inUI, hAlign, vAlign, alignOffset, alignWidth, alignHeight = _obj_0.isRoot, _obj_0.inUI, _obj_0.hAlign, _obj_0.vAlign, _obj_0.alignOffset, _obj_0.alignWidth, _obj_0.alignHeight -- 14
			if isRoot == nil then -- 15
				isRoot = false -- 15
			end -- 15
			if inUI == nil then -- 16
				inUI = true -- 16
			end -- 16
			if hAlign == nil then -- 17
				hAlign = "Center" -- 17
			end -- 17
			if vAlign == nil then -- 18
				vAlign = "Center" -- 18
			end -- 18
			if alignOffset == nil then -- 19
				alignOffset = Vec2.zero -- 19
			end -- 19
		end -- 14
		self.inUI = inUI -- 23
		self._isRoot = isRoot -- 24
		if self._isRoot then -- 25
			local viewSize = inUI and App.bufferSize or View.size -- 26
			self.size = viewSize -- 27
			self._viewSize = viewSize -- 28
			self:gslot("AppChange", function(settingName) -- 29
				if settingName == "Size" then -- 29
					viewSize = self.inUI and App.bufferSize or View.size -- 30
					if self._viewSize ~= viewSize then -- 31
						self._viewSize = viewSize -- 32
						self.size = viewSize -- 33
						local width, height = viewSize.width, viewSize.height -- 34
						self:emit("AlignLayout", width, height) -- 35
						return self:eachChild(function(child) -- 36
							return child:emit("AlignLayout", width, height) -- 37
						end) -- 36
					end -- 31
				end -- 29
			end) -- 29
			return self:slot("Enter", function() -- 38
				local width, height -- 39
				do -- 39
					local _obj_0 = self.inUI and App.bufferSize or View.size -- 39
					width, height = _obj_0.width, _obj_0.height -- 39
				end -- 39
				self:emit("AlignLayout", width, height) -- 40
				return self:eachChild(function(child) -- 41
					return child:emit("AlignLayout", width, height) -- 42
				end) -- 41
			end) -- 38
		else -- 44
			self.hAlign = hAlign -- 44
			self.vAlign = vAlign -- 45
			self.alignOffset = alignOffset -- 46
			self.alignWidth = alignWidth -- 47
			self.alignHeight = alignHeight -- 48
			return self:slot("AlignLayout", function(w, h) -- 49
				local env = { -- 50
					w = w, -- 50
					h = h -- 50
				} -- 50
				local oldSize = self.size -- 51
				if self.alignWidth then -- 52
					local widthFunc = alignFunc(self.alignWidth) -- 53
					self.width = widthFunc(env) -- 54
				end -- 52
				if self.alignHeight then -- 55
					local heightFunc = alignFunc(self.alignHeight) -- 56
					self.height = heightFunc(env) -- 57
				end -- 55
				do -- 58
					local _exp_0 = self.hAlign -- 58
					if "Left" == _exp_0 then -- 59
						self.x = self.width / 2 + self.alignOffset.x -- 59
					elseif "Center" == _exp_0 then -- 60
						self.x = w / 2 + self.alignOffset.x -- 60
					elseif "Right" == _exp_0 then -- 61
						self.x = w - self.width / 2 - self.alignOffset.x -- 61
					end -- 58
				end -- 58
				do -- 62
					local _exp_0 = self.vAlign -- 62
					if "Bottom" == _exp_0 then -- 63
						self.y = self.height / 2 + self.alignOffset.y -- 63
					elseif "Center" == _exp_0 then -- 64
						self.y = h / 2 + self.alignOffset.y -- 64
					elseif "Top" == _exp_0 then -- 65
						self.y = h - self.height / 2 - self.alignOffset.y -- 65
					end -- 62
				end -- 62
				local newSize = self.size -- 66
				if oldSize ~= newSize then -- 67
					local width, height = newSize.width, newSize.height -- 68
					return self:eachChild(function(child) -- 69
						return child:emit("AlignLayout", width, height) -- 70
					end) -- 69
				end -- 67
			end) -- 49
		end -- 25
	end, -- 13
	alignLayout = function(self) -- 72
		if self._isRoot then -- 73
			local width, height -- 74
			do -- 74
				local _obj_0 = self.inUI and App.bufferSize or View.size -- 74
				width, height = _obj_0.width, _obj_0.height -- 74
			end -- 74
			self:emit("AlignLayout", width, height) -- 75
			return self:eachChild(function(child) -- 76
				return child:emit("AlignLayout", width, height) -- 77
			end) -- 76
		else -- 79
			local width, height -- 79
			do -- 79
				local _obj_0 = self.size -- 79
				width, height = _obj_0.width, _obj_0.height -- 79
			end -- 79
			return self:eachChild(function(child) -- 80
				return child:emit("AlignLayout", width, height) -- 81
			end) -- 80
		end -- 73
	end -- 72
}) -- 12
return _module_0 -- 1
