-- Development-only entry: runs the real game with an isolated QA database.
-- Existing player data in writablePath/lsd.db must never be used by this entry.
local Dora = require("Dora")
local root = Dora.Path:getPath(Dora.Path:getScriptPath(...))
assert(root, "Game0Baseline must be loaded as a project entry")
for _, path in ipairs({root, Dora.Path(root, "Script"), Dora.Path(root, "Spine"), Dora.Path(root, "Image"), Dora.Path(root, "Font")}) do
	Dora.Content:insertSearchPath(1, path)
end
assert(not Dora.DB:existDB("lsd"), "Another LSD session is already using the database schema")
local database = Dora.Path(Dora.Content.writablePath, "lsd-game0-baseline-qa.db")
assert(Dora.DB:exec("ATTACH DATABASE '" .. database:gsub("'", "''") .. "' AS lsd"), "Cannot attach isolated QA database")
print("LSD_QA_DATABASE=" .. database)
print("LSD_QA_ENGINE=" .. Dora.App.version)
require("Start")
