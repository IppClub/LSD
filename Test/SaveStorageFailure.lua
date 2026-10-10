-- Use a disposable fixture prepared with directory mode 0555. Never changes permissions.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local f=D.json.decode(assert(D.Content:load(D.Path(root,'Test/storage-failure-fixture.json'))))
assert(D.Path:getFilename(f.directory):match('^lsd%-storage%-readonly%-qa%-%d+$'))
assert(not D.DB:existDB('lsd'),'Must launch in a clean game session')
local store=require('Save.Slots').new(f.directory)
local report={status='WAITING_FOR_FAILURE_CLICK',runId=f.runId,directory=f.directory,osInput=false,fixtureMode=f.permission}
local out=D.Path(root,'Docs/evidence/2026-10-04/save-storage-readonly-native.json')
local original=assert(D.Content:load(D.Path(f.directory,'lsd.db')))
local c=require('Save.Title').open({store=store,onOpen=function(name)report.opened=name end})
package.loaded['Test.SaveStorageFailureState']={controller=c,report=report}
D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local deadline=D.App.runningTime+180
  while not c.error do assert(D.App.runningTime<deadline,'Expected native Continue click');D.sleep(.05)end
  assert(c.error=='BACKUP_FAILED',c.error)
  assert(c.phase=='ready' and not report.opened and not D.DB:existDB('lsd'))
  assert(c.label.text:find('存储空间',1,true) and c.label.text:find('写入权限',1,true))
  assert(#store:backups('lsd.db')==0 and store:current()=='lsd.db')
  assert(D.Content:load(D.Path(f.directory,'lsd.db'))==original)
  assert(D.Content:load(D.Path(f.directory,'lsd-current-save.txt'))=='lsd.db')
  report.failure=c.error;report.originalPreserved=true;report.selectionPreserved=true;report.status='WAITING_FOR_PERMISSION_RESTORE_AND_RETRY'
  D.Content:save(out,D.json.encode(report))
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/save-storage-readonly-error.tga'))
  deadline=D.App.runningTime+180
  while not report.opened do assert(D.App.runningTime<deadline,'Restore fixture permissions then native Continue click');D.sleep(.05)end
  assert(report.opened=='lsd.db'and D.DB:existDB('lsd') and #store:backups('lsd.db')==1)
  assert(store:current()=='lsd.db' and D.Content:load(D.Path(f.directory,'lsd.db'))==original)
  D.DB:exec('DETACH DATABASE lsd')
  report.retrySucceeded=true;report.osInput=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
