local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local robot=require('Rescue.BuddhaPrototype').create();robot:addTo(D.Director.ui3D)
D.thread(function()D.sleep(2);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/buddha-prototype-idle.tga'));D.sleep(.2);robot:emit('Guard',true);D.sleep(2);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/buddha-prototype-guard.tga'));print('Buddha prototype rendered, review required')end)
