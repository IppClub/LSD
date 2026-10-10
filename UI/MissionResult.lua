-- [xml]: UI/MissionResult.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local placeholder = Node() -- 2
placeholder:cleanup(); args = args or {}; args.missionMode = true; do return require("UI.Settlement")(args) end -- 3
return placeholder -- 3
end