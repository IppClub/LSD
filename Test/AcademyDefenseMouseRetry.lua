-- Native battle integration against an earned model; no story victory is inserted.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/academy-defense-mouse-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/academy-defense-mouse-retry-source.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-academy%-defense%-mouse%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-academy-defense-mouse-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true)end
  require('Data.Config'):loadAsync();require('Academy.Navigation').returnToRoomAsync('PassageA')
  result.status='WAITING_FOR_OS';result.actualInputOnly=true;result.osInput=true;result.keys={};result.failedAttempts={}
  local keys=D.Node();keys.keyboardEnabled=true;keys:addTo(D.Director.ui)
  keys:slot('KeyDown',function(key)result.keys[key]=(result.keys[key]or 0)+1 end)
  D.Content:save(out,D.json.encode(result));local deadline=D.App.runningTime+600;local lastLevel
  while true do
   assert(D.App.runningTime<deadline,'Actual-input defense session timed out')
   local w=D.Platformer.Data.store.world;local level=w and w.patrolLevel
   if level then
    local b=level.battle
    if level~=lastLevel then lastLevel=level;result.attempt=level.attempt and level.attempt.id end
    result.phase=b.phase;result.stage=b.stage;result.mentorHP=b.mentorHP;result.learnerHP=b.arena.studentHP;result.powerHP=b.powerHP;result.beaconHP=b.beaconHP;result.mentorX=b.mentor.x;result.beaconX=b.objective.x
    if level.phase=='result'and b.phase=='won'then
     assert(require('Mission.Service').open():summary().unlocks['academy-defense-complete'],'Victory not saved')
     assert(require('Academy.DefenseProof').validate(b.report,b.arena.trialModel));result.combat=b.report
     assert((result.keys.J or 0)>0,'No actual keyboard firing observed')
     assert(b.objectiveView.beacon and b.objectiveView.beacon.completed.move)
     D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/academy-defense-os-won.tga'))
     result.status='PASS';result.beaconAnimations=b.objectiveView.beacon.completed;break
    elseif level.phase=='result'and b.phase~='won'and not level.osFailureRecorded then
     level.osFailureRecorded=true;result.failedAttempts[#result.failedAttempts+1]={status=b.phase,report=b.report};result.status='RETRY_AVAILABLE'
    elseif level.phase=='save-error'then result.status='SAVE_RETRY_REQUIRED'
    elseif b.phase=='playing'then result.status='PLAYING'end
   end
   D.Content:save(out,D.json.encode(result));D.sleep(.1)
  end
  keys:removeFromParent()
  local allowed={Game0MissionMeta=true,Game0MissionAttempts=true,Game0MissionUnlocks=true,Game0StorySupplies=true}
  for name,snapshot in pairs(snapshots)do if not allowed[name]then assert(snapshot==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  result.priorTablesPreserved=true;D.Content:save(D.Path(root,'Test/academy-defense-mouse-fixture.txt'),db)
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
