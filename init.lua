local _ENV = Dora
local Path <const> = Path
local Content <const> = Content
local require <const> = require
local scriptPath = Path:getScriptPath(...)
if scriptPath then
	local _list_0 = {
		scriptPath,
		Path(scriptPath, "Script"),
		Path(scriptPath, "Spine"),
		Path(scriptPath, "Image"),
		Path(scriptPath, "Font")
	}
	for _index_0 = 1, #_list_0 do
		local path = _list_0[_index_0]
		Content:insertSearchPath(1, path)
	end
	return require("Save.Title").open()
end
