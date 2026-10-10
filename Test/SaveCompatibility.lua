local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={status='RUNNING',runId=os.time(),osInput=false};local out=D.Path(root,'Test/save-compatibility-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local dir=D.Path(D.Content.writablePath,'lsd-compatibility-qa-'..report.runId);assert(not D.Content:exist(dir)and D.Content:mkdir(dir));report.directory=dir
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-ending-resume-fixture.txt')));assert(D.Path:getFilename(source):match('^lsd%-fresh%-ending%-flow%-qa%-%d+%.db$'))
  local path=D.Path(dir,'lsd.db');assert(D.Content:copyAsync(source,path))
  local slots=require('Save.Slots').new(dir)
  local function sql(statement)
   assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS qa_source")>=0)
   assert(D.DB:exec(statement)>=0);assert(D.DB:exec('DETACH DATABASE qa_source')>=0)
  end
  local original=D.Content:load(path);assert(slots:attach('lsd.db'));D.DB:exec('DETACH DATABASE lsd')
  assert(D.Content:load(path)==original);report.currentSaveUnchanged=true
  local current=assert(slots:create());D.DB:exec('DETACH DATABASE lsd')
  sql('UPDATE qa_source.Game0StoryMeta SET schemaVersion=999 WHERE id=1')
  local future=D.Content:load(path);local backups=#slots:backups('lsd.db')
  local title=require('Save.Title').open({store=slots,onOpen=function()error('Incompatible save launched')end})
  title.saves:emit('Tapped');while slots:list()[title.page]~='lsd.db'do title.next:emit('Tapped')end
  title.load:emit('Tapped');assert(title.phase=='ready'and title.error=='SAVE_NEWER_VERSION')
  assert(title.label.text:find('较新版本',1,true));assert(not D.DB:existDB('lsd'))
  assert(D.Content:load(path)==future and slots:current()==current and #slots:backups('lsd.db')==backups)
  report.futureRejectedBeforeWrites=true;report.titleExplained=true;title.node:removeFromParent()
  -- Newer incompatible backup must not hide a healthy earlier snapshot.
  assert(D.Content:copyAsync(path,D.Path(dir,'lsd.db.backup-'..report.runId..'-99.db')))
  local restored=assert(slots:restore('lsd.db'));assert(restored~='lsd.db')
  assert(D.DB:query('SELECT schemaVersion FROM lsd.Game0StoryMeta WHERE id=1')[1][1]==1)
  D.DB:exec('DETACH DATABASE lsd');assert(D.Content:load(path)==future);report.compatibleBackupRecovered=true
  sql('UPDATE qa_source.Game0StoryMeta SET schemaVersion=1 WHERE id=1')
  sql('CREATE TABLE qa_source.Game0FutureFeature(schemaVersion INTEGER NOT NULL)')
  local loaded,err=slots:attach('lsd.db');assert(not loaded and err=='SAVE_NEWER_VERSION'and not D.DB:existDB('lsd'))
  sql('DROP TABLE qa_source.Game0FutureFeature');sql('UPDATE qa_source.Game0StoryMeta SET schemaVersion=0 WHERE id=1')
  loaded,err=slots:attach('lsd.db');assert(not loaded and err=='SAVE_SCHEMA_UNSUPPORTED')
  report.unknownModuleRejected=true;report.unsupportedVersionRejected=true
  local legacy=D.Path(dir,'legacy');assert(D.Content:mkdir(legacy))
  local legacyStore=require('Save.Slots').new(legacy);assert(legacyStore:create())
  assert(D.DB:exec('CREATE TABLE lsd.Config(name TEXT,value TEXT)')>=0);assert(D.DB:exec("INSERT INTO lsd.Config VALUES('name','LegacyQA')")>=0)
  local legacyName=legacyStore:current();D.DB:exec('DETACH DATABASE lsd');assert(legacyStore:attach(legacyName))
  assert(D.DB:query('SELECT value FROM lsd.Config')[1][1]=='LegacyQA');D.DB:exec('DETACH DATABASE lsd')
  report.legacyConfigAccepted=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
