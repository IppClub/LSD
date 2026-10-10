local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/reconnection-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/roof-aftermath-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-roof%-aftermath%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-reconnection-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Resume timeout');D.sleep(.03)end end
  require('Data.Config'):loadAsync()
  local service=assert(require('Story.Service').open());local nav=require('Academy.Navigation')
  assert(not service:canRead('network-warning','RDRoom'));assert(not service:canRead('return-online','Factory'))
  local function arrive(name)
   local w=nav.returnToRoomAsync(name);local c=assert(w.reconnection);local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end))
   assert(not w.commandAssembly)
   assert(not require('Story.Flow').openAsync(c.id,w),'Remote discovery accepted')
   local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
   hud.move:emit('Left',true);wait(function()return p.unit.x<c.marker.x+30 end,15);hud.move:emit('Left',false);D.sleep(.3)
   wait(function()return c.menu.menu.enabled end,15);return w,c,p
  end
  local function advance(f)
   wait(function()return f.view.visible end,20)
   local deadline=D.App.runningTime+60
   while f.phase=='dialogue'or f.phase=='saving'do assert(D.App.runningTime<deadline);if not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.07)end
  end
  local w,c,p=arrive('OperationRoom');assert(not D.Group({'name','unit'}):find(function(e)return e.name=='wuyun'and e.unit.world==w end))
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/reconnection-terminal.tga'))
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_reconnection BEFORE INSERT ON Game0StoryNodes WHEN NEW.id='return-online' BEGIN SELECT RAISE(FAIL,'QA reconnection'); END")>=0)
  c.menu:emit('Tapped',1);wait(function()return w.storyFlow~=nil end,20);local f=w.storyFlow;advance(f)
  assert(f.phase=='save-error'and #f.view._reviews==16 and not service:summary().completed['return-online']and not service:summary().unlocks['yulingling-reconnected'])
  assert(D.DB:exec('DROP TRIGGER lsd.fail_reconnection')>=0);f.retryButton:emit('Tapped');wait(function()return f.phase=='complete'end,20);report.saveRetry=true
  w,c,p=arrive('RDRoom');c.menu:emit('Tapped',1);wait(function()return w.storyFlow~=nil end,20);f=w.storyFlow;advance(f);assert(f.phase=='complete'and #f.view._reviews==6);report.rows={16,6}
  local recorded=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryNodes ORDER BY id'),false,true)
  local replay=assert(require('Story.Flow').openAsync('return-online',w,nil,true));advance(replay);assert(replay.phase=='complete'and #replay.view._reviews==16 and recorded==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryNodes ORDER BY id'),false,true));report.replay=true
  local journal=assert(require('Story.Journal').openAsync(w,99));assert(journal.recordIds[1]or journal.recordIds[2]);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/reconnection-journal.tga'));journal.view.closeButton:emit('Tapped')
  w=nav.returnToOperationAsync();assert(w.reconnection and not w.commandAssembly and not w.storyFlow);report.restored=true
  for name,value in pairs(snapshot)do if name~='Game0StoryNodes'and name~='Game0StoryUnlocks'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  report.priorTablesPreserved=true;report.status='PASS';D.Content:save(D.Path(root,'Test/reconnection-resume-fixture.txt'),db)
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
