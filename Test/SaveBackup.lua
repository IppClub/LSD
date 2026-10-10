local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local out=D.Path(root,'Test/save-backup-result.json');local report={status='RUNNING',runId=run,osInput=false};D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local directory=D.Path(D.Content.writablePath,'lsd-backup-qa-'..run);assert(not D.Content:exist(directory)and D.Content:mkdir(directory));report.directory=directory
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-ending-resume-fixture.txt')));assert(D.Path:getFilename(source):match('^lsd%-fresh%-ending%-flow%-qa%-%d+%.db$'))
  local legacy=D.Path(directory,'lsd.db');assert(D.Content:copyAsync(source,legacy));local original=D.Content:load(legacy)
  local store=require('Save.Slots').new(directory);assert(store:attach('lsd.db'));local backups=store:backups('lsd.db');assert(#backups==1)
  local tables={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do tables[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  D.DB:exec('DETACH DATABASE lsd');assert(D.Content:load(legacy)==original)
  assert(D.Content:save(legacy,'QA damaged primary'));assert(not store:attach('lsd.db'));assert(#store:backups('lsd.db')==1)
  assert(D.Content:save(D.Path(directory,'lsd.db.backup-9999999999-1.db'),'QA damaged newer backup'))
  local c=require('Save.Title').open({store=store,onOpen=function(name)report.restored=name end});c.saves:emit('Tapped');assert(c.restore)
  report.awaitingMouse=true;D.Content:save(out,D.json.encode(report))
  local deadline=D.App.runningTime+120;while not report.restored do assert(D.App.runningTime<deadline,'Mouse restore required');D.sleep(.05)end
  assert(report.restored~='lsd.db'and store:current()==report.restored)
  for name,value in pairs(tables)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  D.DB:exec('DETACH DATABASE lsd');assert(D.Content:load(legacy)=='QA damaged primary')
  assert(D.Content:load(D.Path(directory,backups[1]))~=nil)
  report.allTablesRestored=true;report.damagedOriginalPreserved=true;report.corruptNewerBackupSkipped=true;report.osInput=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
