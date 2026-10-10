local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','command-assembly-resume-result.txt');D.Content:save(out,'LSD_COMMAND_RESUME_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','command-assembly-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-command%-assembly%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-command-resume-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function wait(f,t,message) local deadline=D.App.runningTime+(t or 20);while not f() do assert(D.App.runningTime<deadline,message or 'Command resume stalled');D.sleep(.03) end end
  local snapshot={};for _,name in ipairs({'Game0StoryAssignments','Game0StoryUnlocks','Game0FoxTrail','Game0StorySupplies','Game0Training','Game0Training_wuyun'}) do
   snapshot[name]=D.json.encode(assert(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1')),false,true)
  end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.commandAssembly and w.commandAssembly.phase=='ready' end,40)
  local w=D.Platformer.Data.store.world;local c=w.commandAssembly;local service=assert(require('Story.Service').open());assert(service:summary().completed['command-assembly'] and service:summary().objective:find('主攻',1,true))
  for _,role in ipairs(require('Story.CommandAssembly').roles) do assert(c.actors[role.id] and c.labels[role.id].text:find(role.duty,1,true)) end
  local panel=assert(c:openAssignments());panel.stationButton:emit('Tapped');assert(panel.detail.text:find('妮妮莉特',1,true) and panel.detail.text:find('乌云',1,true));panel.closeButton:emit('Tapped')
  local navigation=require('Academy.Navigation');navigation.returnToRoomAsync('RestRoom');w=D.Platformer.Data.store.world
  local journal=assert(require('Story.Journal').openAsync(w,12));journal.view.archiveButton:emit('Tapped');wait(function()return w.storyFlow and w.storyFlow.id=='command-assembly' and w.storyFlow.view.visible end,35)
  local f=w.storyFlow;local deadline=D.App.runningTime+40;while f.phase=='dialogue' or f.phase=='saving' do assert(D.App.runningTime<deadline);if not f.view._advancing then f.view.confirm:emit('Tapped') end;D.sleep(.08) end
  assert(f.phase=='complete' and #f.view._reviews==28);wait(function()return w.storyJournal.phase=='journal' end);w.storyJournal.view.closeButton:emit('Tapped')
  navigation.returnToRoomAsync('OperationRoom');wait(function()local n=D.Platformer.Data.store.world;return n and n.commandAssembly and n.commandAssembly.phase=='ready' end,30);w=D.Platformer.Data.store.world;c=w.commandAssembly
  for _,role in ipairs(require('Story.CommandAssembly').roles) do
   local count=0;D.Group({'name','unit'}):each(function(e)if e.name==role.id and e.unit.world==w then count=count+1 end end);assert(count==1,'Repeated role '..role.id)
  end
  assert(c.fox and w.foxParty,'Ordinary room navigation lost fox');assert(c.fox.companionForm=='nine-tail-chibi' and c.fox.sourceArt=='Image/Companion/Q-huli.png','Boss form used as companion')
  D.DB:exec('UPDATE lsd.Game0StoryMeta SET schemaVersion=99 WHERE id=1')
  local rows,err=service:assignments();assert(not rows and err=='INCOMPATIBLE_STORY_SAVE')
  local can,why=service:canRead('command-assembly','OperationRoom',true);assert(not can and why=='INCOMPATIBLE_STORY_SAVE')
  local saved,reason=service:completeAsync('command-assembly','OperationRoom',true);assert(not saved and reason=='INCOMPATIBLE_STORY_SAVE','Cached service mutated future save')
  D.DB:exec('UPDATE lsd.Game0StoryMeta SET schemaVersion=1 WHERE id=1')
  for name,value in pairs(snapshot) do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Resume/replay changed '..name) end
  return 'PASS earnedAssemblyCopy=true actualStartOperationRoom=true nineOriginalActorsAndFoxRestored=true dutiesRestored=true originalPhoneAssignmentPanel=true publicJournalOtherRoomReplay28=true ordinaryNavigationRestoresAssembly=true noDuplicateActors=true cachedFutureSaveReadWriteRejected=true modelsFoodMedicineAssignmentsAndUnlocksRetained=true'
 end,debug.traceback)
 local report='LSD_COMMAND_RESUME_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
