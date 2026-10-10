local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local out=D.Path(root,'Test/save-recovery-edges-result.json');local report={status='RUNNING',runId=run,osInput=false};D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local dir=D.Path(D.Content.writablePath,'lsd-save-edges-qa-'..run);assert(not D.Content:exist(dir)and D.Content:mkdir(dir));report.directory=dir
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-ending-resume-fixture.txt')));assert(D.Path:getFilename(source):match('^lsd%-fresh%-ending%-flow%-qa%-%d+%.db$'))
  for _,i in ipairs({9,10})do
   local path=D.Path(dir,'lsd.db.backup-100-'..i..'.db');assert(D.Content:copyAsync(source,path));assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS edge")>=0)
   assert(D.DB:exec('CREATE TABLE edge.QASnapshot(version INTEGER)')>=0);assert(D.DB:exec('INSERT INTO edge.QASnapshot VALUES(?)',{i})>=0);D.DB:exec('DETACH DATABASE edge')
  end
  local store=require('Save.Slots').new(dir);assert(#store:list()==1 and store:list()[1]=='lsd.db'and not store:current())
  assert(store:backups('lsd.db')[1]=='lsd.db.backup-100-10.db')
  local c=require('Save.Title').open({store=store,onOpen=function()end});c.saves:emit('Tapped');assert(c.restore and not c.load and c.label.text:find('原文件缺失',1,true));c.node:removeFromParent()
  local fresh=assert(store:restore('lsd.db'));assert(D.DB:query('SELECT version FROM lsd.QASnapshot')[1][1]==10);D.DB:exec('DETACH DATABASE lsd');assert(not D.Content:exist(D.Path(dir,'lsd.db')))
  local pointer=D.Content:load(D.Path(dir,'lsd-current-save.txt'));local old=D.Content:load(D.Path(dir,fresh));local backup=store.backup
  store.backup=function()return nil,'BACKUP_FAILED'end
  local failed,reason=store:attach(fresh);assert(not failed and reason=='BACKUP_FAILED'and not D.DB:existDB('lsd'));store.backup=backup
  assert(D.Content:load(D.Path(dir,'lsd-current-save.txt'))==pointer and D.Content:load(D.Path(dir,fresh))==old)
  assert(store:attach(fresh));D.DB:exec('DETACH DATABASE lsd')
  report.orphanBackupVisible=true;report.sameSecondNumericOrder=true;report.backupFailureBlocksLoad=true;report.originalAndPointerPreserved=true;report.retryWorks=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
