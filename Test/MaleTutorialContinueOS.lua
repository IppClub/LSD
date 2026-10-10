-- Continue an earned tutorial save copy through native title input.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local evidence=D.json.decode(assert(D.Content:load(D.Path(root,'Docs/evidence/2026-10-04/opening-male-os-initial.json'))))
 local source=D.Path(evidence.directory,evidence.selected)
 assert(source:match('lsd%-opening%-os%-qa%-%d+/lsd%-journey%-%d+%-%d+%.db$') and not D.DB:existDB('lsd'))
 local directory=D.Path(D.Content.writablePath,'lsd-male-tutorial-continue-os-'..os.time());assert(not D.Content:exist(directory)and D.Content:mkdir(directory))
 local filename='lsd-journey-'..os.time()..'-1.db';assert(D.Content:copyAsync(source,D.Path(directory,filename)))
 local title=require('Save.Title').open({store=require('Save.Slots').new(directory)})
 package.loaded['Test.MaleTutorialContinueOSState']={title=title,source=source,directory=directory,filename=filename}
end)
