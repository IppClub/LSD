-- Isolated, unseeded new game. All progression is operated through native UI.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local directory=D.Path(D.Content.writablePath,'lsd-opening-os-qa-'..id)
assert(not D.DB:existDB('lsd') and not D.Content:exist(directory) and D.Content:mkdir(directory))
local title=require('Save.Title').open({store=require('Save.Slots').new(directory)})
package.loaded['Test.OpeningOSState']={title=title,directory=directory,runId=id}
D.Content:save(D.Path(root,'Test/opening-os-session.json'),D.json.encode({runId=id,directory=directory,unseeded=true,osInputRequired=true}))
