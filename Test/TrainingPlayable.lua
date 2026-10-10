-- Temporary playable entry; the production academy entry also opens this level.
local D = require("Dora")
local root = D.Path:getPath(D.Path:getScriptPath(...))
for _,path in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,path) end
assert(not D.DB:existDB("lsd"), "Another LSD session owns the schema")
local database = D.Path(D.Content.writablePath,"lsd-game0-baseline-qa.db")
assert(D.DB:exec("ATTACH DATABASE '"..database:gsub("'","''").."' AS lsd"))
D.Director.entry:slot("Cleanup",function() D.DB:exec("DETACH DATABASE lsd") end)
D.thread(function()
	local config = require("Data.Config")
	config:loadAsync()
	if not config.char then config.char = "charM" end
	require("Training.Level")()
end)
