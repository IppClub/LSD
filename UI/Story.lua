local _module_0 = nil
local _ENV = Dora
local require <const> = require
local type <const> = type
local Class <const> = Class
local property <const> = property
local print <const> = print
local thread <const> = thread
local Cache <const> = Cache
local sleep <const> = sleep
local table <const> = table
local View <const> = View
local Pass <const> = Pass
local SpriteEffect <const> = SpriteEffect
local emit <const> = emit
local collectgarbage <const> = collectgarbage
local Story = require("UI.View.Story")
local StoryPortrait = require("UI.StoryPortrait")
local Answer = require("UI.Answer")
local Struct = require("Utils").Struct
local YarnRunner = require("YarnRunner")
local Config = require("Data.Config")
local Command = require("System.Command")
local Dialog = Struct.Story.Dialog("character", "name", "text")
local getCharName
getCharName = function(current)
	if current.marks then
		local _list_0 = current.marks
		for _index_0 = 1, #_list_0 do
			local mark = _list_0[_index_0]
			local _type_0 = type(mark)
			local _tab_0 = "table" == _type_0 or "userdata" == _type_0
			if _tab_0 then
				local attr = mark.name
				local name
				do
					local _obj_0 = mark.attrs
					local _type_1 = type(_obj_0)
					if "table" == _type_1 or "userdata" == _type_1 then
						name = _obj_0.name
					end
				end
				local id
				do
					local _obj_0 = mark.attrs
					local _type_1 = type(_obj_0)
					if "table" == _type_1 or "userdata" == _type_1 then
						id = _obj_0.id
					end
				end
				if name == nil then
					name = ''
				end
				if id == nil then
					id = ''
				end
				if attr ~= nil then
					if ("char" == attr or "Character" == attr) then
						if id == "char" then
							id = Config.char
						end
						return name, id
					end
				end
			end
		end
	end
	return '', ''
end
_module_0 = Class(Story, {
	reviewVisible = property(function(self)
		return self._reviewVisible
	end, function(self, value)
		self._reviewVisible = value
		self.reviewMask.visible = value
		self.topCenter.visible = value
		self.reviewBack.visible = value
		self.reviewArea.visible = value
	end),
	advance = function(self, option)
		local action, result = self._runner:advance(option)
		if "Text" == action then
			if result.optionsFollowed then
				local _
				_, self._options = self._runner:advance()
			else
				self._options = nil
			end
			self._current = result
			return true
		elseif "Command" == action then
			self._current = nil
			self._options = nil
			self.answerList:removeAllChildren()
			self.continueIcon.visible = true
			self._advancing = true
			do
				local _type_0 = type(result)
				local _tab_0 = "table" == _type_0 or "userdata" == _type_0
				if _tab_0 then
					local preload = result.preload
					if preload ~= nil then
						self._preload = preload
						return self:advance()
					end
				end
			end
			return true
		elseif "Error" == action then
			print(result)
			return false
		else
			return false
		end
	end,
	__init = function(self, dialogFile)
		self._runner = YarnRunner(dialogFile, "Start", Config, Command)
		self:advance()
		self.reviewVisible = false
		self._advancing = self._current == nil
		local nextSentence
		nextSentence = function()
			if self._advancing then
				return
			end
			if self._options then
				return
			end
			if self:advance() then
				if not self._current then
					return
				end
				self._advancing = true
				return thread(function()
					self._advancing = false
					return self:updateDialogAsync()
				end)
			else
				return self:hide()
			end
		end
		self:gslot("Story.Advance", function()
			self._advancing = false
			return nextSentence()
		end)
		self.confirm:slot("Tapped", nextSentence)
		local pressed = { }
		self.keyboardEnabled = true
		self:slot("KeyDown", function(key)
			if not (key == "Return" or key == "Space") then
				return
			end
			if pressed[key] then
				return
			end
			pressed[key] = true
			if not (self.visible and not self.reviewVisible) then
				return
			end
			return nextSentence()
		end)
		self:slot("KeyUp", function(key)
			pressed[key] = nil
		end)
		self.textArea:slot("NoneScrollTapped", nextSentence)
		self.reviewButton:slot("Tapped", function()
			if self._advancing then
				return
			end
			self.reviewVisible = true
			return self:alignLayout()
		end)
		self.reviewBack:slot("Tapped", function()
			self.reviewVisible = false
		end)
		self.reviewArea:slot("NoneScrollTapped", function()
			self.reviewVisible = false
		end)
		do
			local _with_0 = Dialog()
			_with_0.__modified = function(key, value)
				if "character" == key then
					self.figure:removeAllChildren()
					if (value ~= nil) and value ~= "" then
						return self.figure:addChild(StoryPortrait({
							char = value
						}))
					end
				elseif "name" == key then
					if (value ~= nil) then
						self.name.text = value
					end
				elseif "text" == key then
					if (value ~= nil) then
						self.text.text = value
					end
				end
			end
			_with_0.__updated = function()
				return self:alignLayout()
			end
			self._dialog = _with_0
		end
		self._reviews = { }
		self._reviewRevision = 0
		self.visible = false
	end,
	-- 回顾列表按句全量重建，封顶避免超长对话的内存与重建成本无界增长。
	pushReview = function(self, name, text)
		self._reviewRevision = (self._reviewRevision or 0) + 1
		do
			local _obj_0 = self._reviews
			_obj_0[#_obj_0 + 1] = {
				name = name,
				text = text
			}
		end
		if #self._reviews > 150 then
			table.remove(self._reviews, 1)
		end
	end,
	updateDialogAsync = function(self)
		if self._preload then
			local _list_0 = self._preload
			for _index_0 = 1, #_list_0 do
				local item = _list_0[_index_0]
				local figureFile = StoryPortrait.asset(item)
				if figureFile then
					Cache:loadAsync(figureFile)
				end
			end
			self._preload = nil
		end
		if not self._current then
			return
		end
		if self._advancing then
			return
		end
		self._advancing = true
		local name, characterId = getCharName(self._current)
		local figureFile = StoryPortrait.asset(characterId)
		if figureFile then
			Cache:loadAsync(figureFile)
		end
		local text = self._current.text
		self:pushReview(name, text)
		self._dialog.character = characterId
		self._dialog.name = name
		self._dialog.text = text
		self.answerList:removeAllChildren()
		if self._options then
			self.continueIcon.visible = false
			local count = #self._options
			for i = 1, count do
				local option = self._options[i]
				local optionName = getCharName(option)
				local optionText = option.text
				self.answerList:addChild((function()
					local _with_0 = Answer({
						text = optionText
					})
					_with_0:slot("Tapped", function()
						_with_0.touchEnabled = false
						return thread(function()
							sleep(0.3)
							self:pushReview(optionName, optionText)
							if self:advance(i) then
								return thread(function()
									return self:updateDialogAsync()
								end)
							else
								return self:hide()
							end
						end)
					end)
					return _with_0
				end)())
			end
			local size = self.answerList:alignItems(40)
			self.answerList.size = size
			self.answerList:alignItems(40)
		else
			self.continueIcon.visible = true
		end
		self._advancing = false
	end,
	showAsync = function(self)
		self:updateDialogAsync()
		self.visible = true
		self._viewScale = View.scale
		self._viewEffect = View.postEffect
		View.scale = 4 * self._viewScale
		local size = View.size
		local blurH
		do
			local _with_0 = Pass("builtin:vs_sprite", "builtin:fs_spriteblurh")
			_with_0.grabPass = true
			_with_0:set("u_radius", size.width)
			blurH = _with_0
		end
		local blurV
		do
			local _with_0 = Pass("builtin:vs_sprite", "builtin:fs_spriteblurv")
			_with_0.grabPass = true
			_with_0:set("u_radius", size.height)
			blurV = _with_0
		end
		do
			local _with_0 = SpriteEffect()
			for _ = 1, 3 do
				_with_0:add(blurH)
				_with_0:add(blurV)
			end
			View.postEffect = _with_0
		end
		self:gslot("AppChange", function(settingName)
			if settingName == "Size" then
				local width, height
				do
					local _obj_0 = View.size
					width, height = _obj_0.width, _obj_0.height
				end
				blurH:set("u_radius", width)
				return blurV:set("u_radius", height)
			end
		end)
		return emit("Story.Display", true)
	end,
	hide = function(self)
		self:gslot("AppChange", nil)
		self:emit("Ended")
		self:removeFromParent()
		local viewScale = self._viewScale
		local viewEffect = self._viewEffect
		return thread(function()
			collectgarbage()
			Cache:removeUnused()
			emit("Story.Display", false)
			View.scale = viewScale
			sleep()
			View.postEffect = viewEffect
		end)
	end
})
return _module_0
