-- Launch a fresh isolated journey. All gameplay advancement is OS input.
local D=require('Dora');local sourceRoot=D.Path:getPath(D.Path:getScriptPath(...))
assert(not D.DB:existDB('lsd'))
local run=os.time();local directory='/private/tmp/lsd-os-journey-'..run
assert(not D.Content:exist(directory)and D.Content:mkdir(directory))
local oldPaths,oldWritable=D.Content.searchPaths,D.Content.writablePath
local stage='/private/tmp/lsd-game0-stage-f-20261004'
local manifest=assert(D.json.decode(D.Content:load(D.Path(stage,'runtime-manifest.json')),128))
D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Cache:unload()
for _,item in ipairs(manifest.files)do
 if item.path:sub(-4)=='.lua'then local name=item.path:sub(1,-5):gsub('/','.');package.loaded[name]=nil;if name:sub(1,7)=='Script.'then package.loaded[name:sub(8)]=nil end end
end
D.Content.writablePath=directory
D.Content.searchPaths={stage,D.Path(stage,'Script'),D.Path(stage,'Spine'),D.Path(stage,'Image'),D.Path(stage,'Font'),D.Path(D.Content.assetPath,'Script'),D.Path(D.Content.assetPath,'Script/Lib')}
D.Director.entry:slot('Cleanup',function()
 if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end
 D.Content.searchPaths=oldPaths;D.Content.writablePath=oldWritable
end)
local report={status='READY_FOR_OS_INPUT',runId=run,directory=directory,stage=stage,progressInjected=false}
D.Content:save(D.Path(sourceRoot,'Test/os-journey-current.json'),D.json.encode(report))
assert(load(D.Content:load(D.Path(stage,'init.lua')),'@'..D.Path(stage,'init.lua')))(D.Path(stage,'init'))
