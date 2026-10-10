-- Fresh QA profile for name-entry regression, never the user's lsd.db.
local Dora = require("Dora")
local root = Dora.Path:getPath(Dora.Path:getScriptPath(...))
for _, path in ipairs({root, Dora.Path(root, "Script"), Dora.Path(root, "Spine"), Dora.Path(root, "Image"), Dora.Path(root, "Font")}) do
	Dora.Content:insertSearchPath(1, path)
end
assert(not Dora.DB:existDB("lsd"), "Another LSD session is already using the schema")
local database = Dora.Path(Dora.Content.writablePath, "lsd-game0-new-profile-qa-" .. os.time() .. ".db")
assert(not Dora.Content:exist(database), "Fresh profile QA database already exists")
assert(Dora.DB:exec("ATTACH DATABASE '" .. database:gsub("'", "''") .. "' AS lsd"))
print("LSD_FRESH_QA_DATABASE=" .. database)
require("Start")
