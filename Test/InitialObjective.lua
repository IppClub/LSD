-- Objective branches use a fresh QA DB and an existing earned training profile.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={status='RUNNING',runId=os.time(),osInput=false};local out=D.Path(root,'Docs/evidence/2026-10-04/initial-objective-native.json')
D.thread(function()
 local ok,why=xpcall(function()
  local db=D.Path(D.Content.writablePath,'lsd-initial-objective-qa-'..report.runId..'.db');assert(not D.Content:exist(db) and not D.DB:existDB('lsd'))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);report.database=db
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local service=assert(require('Story.Service').open())
  local first=assert(service:summary());assert(first.objective:find('B区右门',1,true) and first.objective:find('三场试战',1,true));report.untrained=first.objective
  local source=assert(D.Content:load(D.Path(root,'Test/wuyun-training-resume-fixture.txt')));assert(D.Path:getFilename(source):match('^lsd%-wuyun%-training%-qa%-%d+%.db$'))
  assert(D.DB:exec("ATTACH DATABASE '"..source.."' AS objective_source")>=0)
  assert(D.DB:exec('INSERT OR REPLACE INTO lsd.Game0Training SELECT * FROM objective_source.Game0Training')>=0);D.DB:exec('DETACH DATABASE objective_source')
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),false,true)
  local trained=assert(service:summary());assert(trained.objective:find('训练成果已采用',1,true) and trained.objective:find('C区右门',1,true));report.trained=trained.objective
  assert(before==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),false,true))
  assert(not next(trained.completed) and not next(trained.mission.unlocks));report.noStoryOrMissionReward=true;report.modelUnchanged=true
  local c=require('Data.Config');c:loadAsync();c.char='charF';c.charName='ObjectiveQA';c.skipOP=1;c.tutorialCompleted=1
  require('Academy.Navigation').returnToRoomAsync('PreparationRoom')
  local w=D.Platformer.Data.store.world;local journal=assert(require('Story.Journal').openAsync(w));assert(journal.phase=='journal')
  report.status='PASS';D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/initial-objective-journal.tga'))
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
