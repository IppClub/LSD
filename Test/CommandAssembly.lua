local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','command-assembly-result.txt');D.Content:save(out,'LSD_COMMAND_ASSEMBLY_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','fox-trail-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fox%-trail%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-command-assembly-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function wait(f,t,message) local deadline=D.App.runningTime+(t or 20);while not f() do assert(D.App.runningTime<deadline,message or 'Command assembly stalled');D.sleep(.03) end end
  local before={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")) do
   if row[1]~='Game0StoryNodes' and row[1]~='Game0StoryUnlocks' and row[1]~='Game0StoryAssignments' then before[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true) end
  end
  require('Start');wait(function() local w=D.Platformer.Data.store.world;return w and w.commandAssembly and w.commandAssembly.phase=='ready' end,40)
  local w=D.Platformer.Data.store.world;local c=w.commandAssembly;assert(w.tag=='OperationRoom' and c.fox and w.foxParty)
  local story=assert(require('Story.Service').open());assert(not story:summary().completed['command-assembly'] and not next(assert(story:assignments())))
  assert(not story:canRead('command-assembly','Factory'),'Wrong room accepted')
  local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end))
  local count=0;for _,role in ipairs(require('Story.CommandAssembly').roles) do local e=c.actors[role.id];assert(e and e.unit.world==w and e.unit.visible and e.storyCompanion,'Missing original actor '..role.id);count=count+1 end;assert(count==9)
  assert(not require('Story.Flow').openAsync('command-assembly',w),'Remote first meeting accepted')
  wait(function() p.keyLeft=p.unit.x>c.center+20;p.keyRight=p.unit.x<c.center-20;return math.abs(p.unit.x-c.center)<25 end,15);p.keyLeft=false;p.keyRight=false;p.unit:stop();p.unit.velocityX=0
  wait(function() return c.menu.menu.enabled end)
  c.menu:emit('Tapped',2);assert(c.error=='REPORT_REQUIRED' and not c.assignmentPanel,'Assignments granted before report')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_command_assignment BEFORE INSERT ON Game0StoryAssignments WHEN NEW.role='wuyun' BEGIN SELECT RAISE(ABORT,'QA command assignment'); END")>=0)
  c.menu:emit('Tapped',1);wait(function()return w.storyFlow and w.storyFlow.id=='command-assembly' and w.storyFlow.view.visible end,30);local f=w.storyFlow
  local deadline=D.App.runningTime+50;while f.phase=='dialogue' or f.phase=='saving' do assert(D.App.runningTime<deadline,'28-line meeting stalled');if not f.view._advancing then f.view.confirm:emit('Tapped') end;D.sleep(.08) end
  assert(f.phase=='save-error' and #f.view._reviews==28 and p.busy,'Original dialogue/rollback missing')
  assert(not story:summary().completed['command-assembly'] and not story:summary().unlocks['network-offensive-briefed'] and not next(story:assignments()),'Partial assignments committed')
  assert(f.view._reviews[7].name=='狐狸' and f.view._reviews[13].name=='烛参' and f.view._reviews[16].name=='烛商' and f.view._reviews[18].name=='半夏' and f.view._reviews[21].name=='李叶娜' and f.view._reviews[28].name=='众人','Original speaker names lost')
  D.DB:exec('DROP TRIGGER lsd.fail_command_assignment');f.retryButton:emit('Tapped');wait(function()return f.phase=='complete' and c.phase=='ready' and not p.busy end)
  assert(story:summary().completed['command-assembly'] and story:summary().unlocks['network-offensive-briefed'])
  local assignments=assert(story:assignments());local assigned=0;for _,entry in pairs(assignments) do assert(entry.node=='command-assembly');assigned=assigned+1 end;assert(assigned==10)
  assert(assignments.dahuli.duty=='recon' and assignments.villywan.duty=='computing' and assignments.vika.duty=='energy-research' and assignments.vivi.duty=='energy-research' and assignments.moyu.duty=='medical' and assignments.moling.duty=='medical' and assignments.liyena.duty=='flank' and assignments.mentor.duty=='assault' and assignments.ninilite.duty=='assault' and assignments.wuyun.duty=='assault')
  wait(function()return c.menu.menu.enabled end);c.menu:emit('Tapped',2);assert(c.assignmentPanel and w.data.journalOpen and p.busy)
  for _,button in ipairs({c.assignmentPanel.mailButton,c.assignmentPanel.researchButton,c.assignmentPanel.archiveButton,c.assignmentPanel.stationButton}) do button:emit('Tapped');assert(#c.assignmentPanel.detail.text>30) end
  c.assignmentPanel.closeButton:emit('Tapped');assert(not w.data.journalOpen and not p.busy)
  local recorded=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryAssignments ORDER BY role'),false,true)
  local j=assert(require('Story.Journal').openAsync(w,12));assert(j.recordIds[3]=='command-assembly');j.view.archiveButton:emit('Tapped');wait(function()return w.storyFlow~=f and w.storyFlow.view.visible end,30);f=w.storyFlow
  deadline=D.App.runningTime+50;while f.phase=='dialogue' or f.phase=='saving' do assert(D.App.runningTime<deadline);if not f.view._advancing then f.view.confirm:emit('Tapped') end;D.sleep(.08) end
  assert(f.phase=='complete' and #f.view._reviews==28 and recorded==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryAssignments ORDER BY role'),false,true))
  wait(function()return w.storyJournal.phase=='journal' end);w.storyJournal.view.closeButton:emit('Tapped')
  wait(function()return c.menu.menu.enabled end);c.menu:emit('Tapped',3)
  wait(function()return w.missionBriefing and w.missionBriefing.phase=='briefing' end,30)
  assert(w.missionBriefing.view.tag=='mission-briefing' and w.missionBriefing.view.startButton and w.missionBriefing.view.backButton,'Original formation access missing')
  w.missionBriefing.view.backButton:emit('Tapped')
  wait(function()local n=D.Platformer.Data.store.world;return n~=w and n.commandAssembly and n.commandAssembly.phase=='ready' end,30)
  w=D.Platformer.Data.store.world;c=w.commandAssembly
  for name,value in pairs(before) do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Reunion changed '..name) end
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='network-offensive-briefed'")==1)
  D.Content:save(D.Path(root,'Test','command-assembly-resume-fixture.txt'),db)
  return 'PASS earnedFoxTrailCopy=true actualStartOperationRoom=true originalNineActorsAndFox=true physicalCenter=true originalDialogue28=true originalSpeakerNames=true noAssignmentBeforeReport=true tenDutiesAtomicWithStory=true saveFaultRollbackRetry=true originalPhoneFourDutyGroups=true publicJournalPage12=true replayIdempotent=true legacyFormationAndReturn=true modelsMedicineFoodAndMissionUnchanged=true'
 end,debug.traceback)
 local report='LSD_COMMAND_ASSEMBLY_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
