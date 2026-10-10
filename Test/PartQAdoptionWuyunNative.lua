local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
assert(load(D.Content:load(root..'/Test/PartQAdoptionNative.lua'),'@'..root..'/Test/PartQAdoptionNative.lua'))(root..'/Test/PartQAdoptionNative','wuyun')
