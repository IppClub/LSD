local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
require('Test.YingzhaoDodgeMatrixFlow')(root,'yingzhao-dodge-matrix-result.json',{'punch','massive'},{250,500})
