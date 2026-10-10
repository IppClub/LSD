local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local out=D.Path(root,'Test/save-continue-result.json');local report={status='RUNNING',runId=os.time(),osInput=false};D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local previous=D.json.decode(assert(D.Content:load(D.Path(root,'Test/save-slots-result.json'))));assert(previous.status=='PASS'and previous.directory:match('lsd%-slots%-qa%-%d+$'))
  local store=require('Save.Slots').new(previous.directory);assert(store:attach('lsd.db'))
  local before={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do before[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  D.DB:exec('DETACH DATABASE lsd')
  local c=require('Save.Title').open({store=store});c.continue:emit('Tapped')
  local deadline=D.App.runningTime+40;while not(require('Ending.Hub').current and require('Ending.Hub').current.view)do assert(D.App.runningTime<deadline);D.sleep(.03)end
  assert(c.selected=='lsd.db'and require('Ending.Hub').current.mode=='records')
  for name,value in pairs(before)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  report.originalJourneyLoaded=true;report.allTablesPreserved=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
