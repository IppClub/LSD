-- Native visual/input QA only; reopens the isolated completed StoryUI profile.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local db=assert(D.Content:load(D.Path(root,"Test","story-resume-fixture.txt")))
assert(D.Path:getPath(db)==D.Content.writablePath and D.Path:getFilename(db):match("^lsd%-story%-ui%-qa%-%d+%.db$"))
assert(not D.DB:existDB("lsd") and D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
D.thread(function()
 require("Data.Config"):loadAsync()
 D.Cache:loadAsync({"spine:charF","spine:ninilite"})
 require("Academy.Navigation").returnToRoomAsync("LibraryRoom")
end)
