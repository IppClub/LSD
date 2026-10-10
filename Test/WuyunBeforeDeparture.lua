local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/wuyun-before-departure-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/roof-battle-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-roof%-battle%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-wuyun-before-departure-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Resume timeout');D.sleep(.03)end end
  assert(require('Story.Availability').canDeploy('wuyun'))
  local service=assert(require('Mission.Service').open());assert(service:saveFormationAsync({mentor=true,learner='ninilite',wuyun=true}));assert(service:formation().wuyun)
  local p=require('Training.Progress');assert(p.load());local wu=p.forCharacter('wuyun');assert(wu.load())
  local attempt,e=service:beginAsync('c0-m03',{ninilite=p.adopted,wuyun=wu.adopted},service:formation());assert(attempt,e)
  assert(service:finishAsync(attempt,'aborted',{reason='pre-departure regression'}));report.missionAccepted=true
  local w=require('Academy.Navigation').returnToRoomAsync('RestRoom');D.sleep(.6)
  assert(D.Group({'name','unit'}):find(function(e)return e.name=='wuyun'and e.unit.world==w end));report.actorPresent=true
  for _,name in ipairs({'Game0Training','Game0Training_wuyun','Game0StoryNodes'})do assert(snapshot[name]==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true))end
  report.trainingAndStoryPreserved=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
