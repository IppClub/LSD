-- [yue]: UI/MessageBox.yue
local Class = Dora.Class -- 1
local Size = Dora.Size -- 1
local _module_0 = nil -- 1
local MessageBox = require("UI.View.MessageBox") -- 2
local Message = require("UI.Message") -- 3
local Struct = require("Utils").Struct -- 4
local Item = Struct.MessageBox.Item("title", "special", "text") -- 6
local Array = Struct.Array() -- 7
_module_0 = Class(MessageBox, { -- 10
	__init = function(self) -- 10
		do -- 11
			local _with_0 = Array() -- 11
			_with_0.__added = function(index, item) -- 12
				return self.view:addChild(Message(item), index) -- 13
			end -- 12
			_with_0.__updated = function() -- 14
				self.area:adjustSizeWithAlign("Auto", 0, Size(700, 204)) -- 15
				return self.area:scrollToPosY(0) -- 16
			end -- 14
			self._messages = _with_0 -- 11
		end -- 11
		return self:gslot("MessageBox.Add", function(item) -- 17
			return self._messages:insert(Item({ -- 19
				title = item.title, -- 19
				special = item.special, -- 20
				text = item.text -- 21
			})) -- 21
		end) -- 21
	end -- 10
}) -- 9
return _module_0 -- 21
