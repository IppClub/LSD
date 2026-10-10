-- Interactive carriage preview in the earned QA profile; no automated input.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local db=assert(D.Content:load(D.Path(root,"Test","train-resume-fixture.txt")))
assert(D.Path:getPath(db)==D.Content.writablePath and D.Path:getFilename(db):match("^lsd%-train%-route%-qa%-%d+%.db$"))
assert(not D.DB:existDB("lsd") and D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
D.thread(function()
 local config=require("Data.Config"); config:loadAsync()
 D.Cache:loadAsync("spine:"..config.char); D.Cache:loadAsync("spine:ninilite")
 require("Academy.Navigation").returnToRoomAsync("TrainA")
end)
