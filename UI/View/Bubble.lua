-- [xml]: UI/View/Bubble.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node = Node() -- 2
node.anchor = Vec2(node.anchor.x,0) -- 2
node.x = x or 0 -- 2
node.y = y or 200 -- 2
node.scaleX = 0.5 -- 2
node.scaleY = 0.5 -- 2
node.size = Size(524,112) -- 2
local back1 = Grid("button.clip|prompt_chat_1_1", 1, 3) -- 3
back1.x = node.width*0.5 -- 3
back1.y = node.height*0.5 -- 3
node:addChild(back1) -- 3
local back2 = Sprite("button.clip|prompt_chat_1_2") -- 4
back2.anchor = Vec2(back2.anchor.x,1) -- 4
back2.x = node.width*0.5 -- 4
back2.y = 0 -- 4
node:addChild(back2) -- 4
local lb = Label("SourceHanSansCN-Regular",30) -- 5
lb.anchor = Vec2(0,lb.anchor.y) -- 5
lb.x = 20 -- 5
lb.y = node.height*0.5 -- 5
lb.color3 = Color3(0xffffff) -- 5
lb.alignment = "Left" -- 5
lb.textWidth = 490 -- 5
lb.lineGap = 5 -- 5
lb.text = text or '' -- 5
node:addChild(lb) -- 5
do -- 8
	local height = lb.height + 40 -- 10
	if height > 112 then -- 11
		local yOffset = height - 112 -- 12
		local offset = Vec2(0, yOffset) -- 13
		back1.y = height / 2 + yOffset / 2 -- 14
		lb.y = height / 2 -- 15
		node.height = height -- 16
		local _list_0 = { -- 18
			{ -- 18
				1, -- 18
				3 -- 18
			}, -- 18
			{ -- 19
				2, -- 19
				3 -- 19
			}, -- 19
			{ -- 20
				1, -- 20
				4 -- 20
			}, -- 20
			{ -- 21
				2, -- 21
				4 -- 21
			} -- 21
		} -- 17
		for _index_0 = 1, #_list_0 do -- 22
			local _des_0 = _list_0[_index_0] -- 17
			local x, y = _des_0[1], _des_0[2] -- 17
			back1:setPos(x, y, back1:getPos(x, y) - offset) -- 23
		end -- 23
	end -- 11
end -- 23
return node -- 9
end