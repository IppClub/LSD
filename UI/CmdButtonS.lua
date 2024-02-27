-- [xml]: UI/CmdButtonS.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.x = x or 0 -- 2
node1.y = y or 0 -- 2
node1.size = Size(263,92) -- 2
local sprite1 = Sprite("button.clip|lsdar_btn_bg_3") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 -- 3
sprite1.visible = not selected -- 3
node1:addChild(sprite1) -- 3
local sprite2 = Sprite("button.clip|lsdar_btn_bg_4") -- 5
sprite2.x = node1.width*0.5 -- 5
sprite2.y = node1.height*0.5 -- 5
sprite2.visible = selected -- 5
node1:addChild(sprite2) -- 5
do -- 5
	local validAction -- 7
	do -- 7
		local _exp_0 = action -- 7
		if "cover" == _exp_0 or "fight" == _exp_0 or "follow" == _exp_0 or "move" == _exp_0 or "retreat" == _exp_0 or "assemble" == _exp_0 then -- 8
			validAction = true -- 8
		elseif nil == _exp_0 then -- 9
			validAction = true -- 9
		else -- 10
			validAction = false -- 10
		end -- 10
	end -- 10
	if not validAction then -- 11
		error("invalid cmd button type: " .. tostring(action)) -- 11
	end -- 11
end -- 11
if action then -- 13
local sprite3 = Sprite('button.clip|lsdar_btn_' .. action .. '_1') -- 14
sprite3.x = 55 -- 14
sprite3.y = node1.height*0.5 -- 14
sprite3.opacity = selected and 1.0 or 0.5 -- 14
node1:addChild(sprite3) -- 14
local label1 = Label("SourceHanSansCN-Regular",45) -- 15
label1.anchor = Vec2(0,label1.anchor.y) -- 15
label1.x = 110 -- 15
label1.y = node1.height*0.5 -- 15
label1.color3 = Color3(0xffffff) -- 15
label1.opacity = selected and 1.0 or 0.5 -- 15
label1.alignment = "Left" -- 15
label1.spacing = 5 -- 15
label1.text = text or '' -- 15
node1:addChild(label1) -- 15
else -- 19
local label2 = Label("SourceHanSansCN-Regular",45) -- 20
label2.x = node1.width*0.5 -- 20
label2.y = node1.height*0.5 -- 20
label2.color3 = Color3(0xffffff) -- 20
label2.opacity = selected and 1.0 or 0.5 -- 20
label2.alignment = "Center" -- 20
label2.spacing = 5 -- 20
label2.text = text or '' -- 20
node1:addChild(label2) -- 20
end -- 24
return node1 -- 24
end