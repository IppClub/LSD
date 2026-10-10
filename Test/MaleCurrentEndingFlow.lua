local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/male-current-ending-flow-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/male-current-final-betrayal-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-male%-current%-final%-betrayal%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-male-current-ending-flow-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local untilTime=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<untilTime,'Ending flow timeout');D.sleep(.02)end end
  local Hub=require('Ending.Hub');require('Start');wait(function()return Hub.current and Hub.current.view end)
  local h=Hub.current;assert(h.mode=='records'and not D.Platformer.Data.store.world);local store=assert(require('Ending.Store').open());local views=assert(store:load());assert(not views.ending and not views.credits)
  h.view.close:emit('Tapped');wait(function()return Hub.current~=h end);h=Hub.current;assert(h.mode=='title');assert(not store:load().ending)
  h.continue:emit('Tapped');wait(function()return Hub.current~=h and Hub.current.view end);h=Hub.current;local view=h.view
  for _=1,3 do local before=view.page;view.next:emit('Tapped');wait(function()return view.page==before+1 end)end
  views=assert(store:load());assert(views.ending and not views.credits)
  while view.page<#view.pages do local before=view.page;view.next:emit('Tapped');wait(function()return view.page==before+1 end)end
  view.next:emit('Tapped');wait(function()return Hub.current~=h end);h=Hub.current;assert(h.mode=='title'and store:load().credits)
  h.explore:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w and w.finalGate end);local w=D.Platformer.Data.store.world;assert(w.tag=='RDRoom')
  local roster=assert(require('Story.AcademyLossRecords').current());local found=false;for _,r in ipairs(roster)do if r.role=='vika'then assert(r.status=='rescued');found=true end end;assert(found)
  h=assert(Hub.openAsync('title'));h.replay:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w and w.finalBetrayal end);local c=D.Platformer.Data.store.world.finalBetrayal
  local f=assert(c:request());local deadline=D.App.runningTime+60
  while f.phase~='complete'do assert(D.App.runningTime<deadline);if f.view.visible and not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.12)end
  assert(c.ending.visible);c.ending:emit('Tapped');wait(function()return c.endingView end);assert(c.world.data.journalOpen)
  c.back:emit('Tapped');D.sleep(.1);assert(not c.closed and c.world==D.Platformer.Data.store.world,'Underlying scene exited through ending modal')
  c.endingView.close:emit('Tapped');wait(function()return Hub.current~=h end);assert(Hub.current.mode=='title')
  local stamps=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0EndingViews ORDER BY kind'),false,true)
  package.loaded.Start=nil;require('Start');h=Hub.current;wait(function()return Hub.current~=h and Hub.current.view end);assert(Hub.current.mode=='records')
  assert(stamps==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0EndingViews ORDER BY kind'),false,true))
  for name,value in pairs(snapshots)do if name~='Game0EndingViews'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  D.sleep(.3);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-ending-records.tga'))
  result.oldTablesPreserved=true;result.partialViewNotMarked=true;result.saveFaultInjected=false;result.finalSceneEntry=true;result.sameProcessResume=true;result.replayNoAward=true;result.status='PASS'
  D.Content:save(D.Path(root,'Test/male-current-ending-resume-fixture.txt'),db)
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
