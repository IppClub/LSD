local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/ending-view-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/final-betrayal-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-final%-betrayal%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-ending-view-qa-'..run..'.db');result.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync()
  local c=assert(require('Ending.View').openAsync());D.Director.ui3D.endingPreview=c
  result.pages=#c.pages;result.status='READY';D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))end
end)
