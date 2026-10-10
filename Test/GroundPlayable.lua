-- Native preview of the earned ground profile; route coverage is in GroundRoute.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
D.thread(function()
 local db=assert(D.Content:load(D.Path(root,"Test","ground-resume-fixture.txt")))
 assert(D.Path:getPath(db)==D.Content.writablePath and D.Path:getFilename(db):match("^lsd%-ground%-route%-qa%-%d+%.db$"))
 assert(not D.DB:existDB("lsd") and D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
 D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
 require("Data.Config"):loadAsync(); assert(require("Training.Progress").load())
 assert(require("Story.Service").open():summary().completed["ground-contact"])
 require("Academy.Navigation").returnToRoomAsync("AbandonedCity")
 print("LSD_GROUND_PLAYABLE_READY earnedGroundProfile=true")
end)
