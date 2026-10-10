local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/ending-resume-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/ending-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-ending%-flow%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-ending-resume-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local before={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do before[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  require('Start');local deadline=D.App.runningTime+30;local Hub=require('Ending.Hub')
  while not(Hub.current and Hub.current.view)do assert(D.App.runningTime<deadline,'Ending restore timeout');D.sleep(.02)end
  assert(Hub.current.mode=='records'and Hub.current.view.page==1 and not D.Platformer.Data.store.world)
  local views=assert(assert(require('Ending.Store').open()):load());assert(views.ending and views.credits)
  for name,v in pairs(before)do assert(v==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  result.allTablesPreserved=true;result.noAutoReplay=true;result.defaultRecords=true;result.views=views;result.status='PASS'
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
