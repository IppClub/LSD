-- Continue an earned tutorial save copy through native title input.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local evidence=D.json.decode(assert(D.Content:load(D.Path(root,'Docs/evidence/2026-10-04/tutorial-hybrid-academy.json'))))
 local source;for _,row in ipairs(evidence.database)do if row[2]=='lsd'then source=row[3]end end
 assert(source and source:match('lsd%-game0%-tutorial%-left%-os%-qa%-%d+%.db$') and not D.DB:existDB('lsd'))
 local directory=D.Path(D.Content.writablePath,'lsd-tutorial-continue-os-'..os.time());assert(not D.Content:exist(directory)and D.Content:mkdir(directory))
 local filename='lsd-journey-'..os.time()..'-1.db';assert(D.Content:copyAsync(source,D.Path(directory,filename)))
 local title=require('Save.Title').open({store=require('Save.Slots').new(directory)})
 package.loaded['Test.TutorialContinueOSState']={title=title,source=source,directory=directory,filename=filename}
end)
