-- [xml]: UI/Answer.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node = Node() -- 2
node.size = Size(827,114) -- 2
node.touchEnabled = true -- 2
local back1 = Grid("button.clip|prompt_chat_answer_1", 1, 2) -- 3
back1.x = node.width*0.5 -- 3
back1.y = node.height*0.5 -- 3
node:addChild(back1) -- 3
local back2 = Grid("button.clip|prompt_chat_answer_2", 1, 2) -- 4
back2.x = node.width*0.5 -- 4
back2.y = node.height*0.5 -- 4
back2.visible = false -- 4
node:addChild(back2) -- 4
local lb = Label("SourceHanSansCN-Regular",50) -- 5
lb.anchor = Vec2(0,lb.anchor.y) -- 5
lb.x = 55 -- 5
lb.y = node.height*0.5 -- 5
lb.color3 = Color3(0xffffff) -- 5
lb.alignment = "Left" -- 5
lb.textWidth = 717 -- 5
lb.text = text or '' -- 5
node:addChild(lb) -- 5
local scaleAction = Action(Sequence(Scale(0.08,1,0.8),Scale(0.3,0.8,1,Ease.OutBack))) -- 10
local show = Action(Spawn(Show(),Opacity(0,0.6,0.6))) -- 14
node.show = show -- 14
local hide = Action(Sequence(Show(),Opacity(0.8,0.6,0),Hide())) -- 18
node.hide = hide -- 18
node:slot("Tapped",function() -- 24
node:perform(scaleAction) -- 24
end) -- 24
node:slot("TapBegan",function() -- 25
back2:perform(show) -- 25
end) -- 25
node:slot("TapEnded",function() -- 26
back2:perform(hide) -- 26
end) -- 26
do -- 26
	local height = lb.height + 40 -- 28
	if height > 114 then -- 29
		local yOffset = height - 114 -- 30
		local offset = Vec2(0, yOffset) -- 31
		back1.y = height / 2 + yOffset / 2 -- 32
		back2.y = height / 2 + yOffset / 2 -- 33
		lb.y = height / 2 -- 34
		node.height = height -- 35
		local _list_0 = { -- 37
			{ -- 37
				1, -- 37
				2 -- 37
			}, -- 37
			{ -- 38
				2, -- 38
				2 -- 38
			}, -- 38
			{ -- 39
				1, -- 39
				3 -- 39
			}, -- 39
			{ -- 40
				2, -- 40
				3 -- 40
			} -- 40
		} -- 36
		for _index_0 = 1, #_list_0 do -- 41
			local _des_0 = _list_0[_index_0] -- 36
			local x, y = _des_0[1], _des_0[2] -- 36
			back1:setPos(x, y, back1:getPos(x, y) - offset) -- 42
			back2:setPos(x, y, back2:getPos(x, y) - offset) -- 43
		end -- 43
	end -- 29
end -- 43
return node -- 27
end