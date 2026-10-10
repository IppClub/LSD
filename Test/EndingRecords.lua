local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/ending-records-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/final-betrayal-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-final%-betrayal%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-ending-records-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local before={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do before[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local Records=require('Ending.Records');local Store=require('Ending.Store');local store=assert(Store.open());local views=assert(store:load());assert(not views.ending and not views.credits)
  local p=assert(Records.read());assert(p.finalModel.sampleCount==p.evacuation.learner.samples and p.currentRevision>=1)
  local roster={};for _,person in ipairs(p.roster)do roster[person.role]=person.status end
  assert(roster.vika=='rescued'and roster.vivi=='rescued'and roster.sunborn=='betrayed'and roster.wuyun=='departed'and roster.ayan=='previously-deceased')
  for _,id in ipairs({'liyena','moling','moyu','villywan','dahuli','yuzijiang'})do assert(roster[id]=='deceased',id)end
  local rejected,err=store:markAsync('credits');assert(not rejected and err=='ENDING_VIEW_REQUIRED');assert(not store:markAsync('unknown'))
  -- Lock and malformed source tests affect only this disposable earned QA copy.
  local unlock=assert(D.DB:query("SELECT id,node FROM lsd.Game0StoryUnlocks WHERE id='final-story-complete'")[1]);assert(D.DB:exec("DELETE FROM lsd.Game0StoryUnlocks WHERE id='final-story-complete'")>=0)
  local denied,why=Records.read();assert(not denied and why=='ENDING_LOCKED');assert(not store:markAsync('ending'));assert(D.DB:exec('INSERT INTO lsd.Game0StoryUnlocks VALUES(?,?)',unlock)>=0)
  local original=assert(D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='final-betrayal'")[1][1]);assert(D.DB:exec("UPDATE lsd.Game0StoryPerformances SET report='{}' WHERE node='final-betrayal'")>=0)
  assert(not Records.read());assert(D.DB:exec("UPDATE lsd.Game0StoryPerformances SET report=? WHERE node='final-betrayal'",{original})>=0)
  local originalModel=D.DB:query("SELECT payload FROM lsd.Game0Training WHERE slot='main'")[1][1];local changed=D.json.decode(originalModel,32);changed.revision=changed.revision+1;changed.adopted.sampleCount=changed.adopted.sampleCount+1
  assert(D.DB:exec("UPDATE lsd.Game0Training SET payload=? WHERE slot='main'",{D.json.encode(changed)})>=0)
  local newer=assert(Records.read());assert(newer.currentRevision==p.currentRevision+1 and newer.currentModel.sampleCount==p.currentModel.sampleCount+1 and newer.finalModel.sampleCount==p.finalModel.sampleCount)
  assert(D.DB:exec("UPDATE lsd.Game0Training SET payload=? WHERE slot='main'",{originalModel})>=0);result.historicalModelPreserved=true
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_ending BEFORE INSERT ON Game0EndingViews BEGIN SELECT RAISE(FAIL,'qa ending'); END")>=0)
  local saved,why=store:markAsync('ending');assert(not saved and why=='WRITE_FAILED');views=assert(store:load());assert(not views.ending and not views.credits)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_ending')>=0);assert(store:markAsync('ending'));views=assert(store:load());assert(views.ending and not views.credits)
  assert(store:markAsync('credits'));local stamped=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0EndingViews ORDER BY kind'),false,true)
  assert(store:markAsync('ending')and store:markAsync('credits'));assert(stamped==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0EndingViews ORDER BY kind'),false,true))
  assert(D.DB:exec("UPDATE lsd.Game0EndingViews SET schemaVersion=99 WHERE kind='ending'")>=0);assert(not store:load()and not store:markAsync('ending'));assert(D.DB:exec("UPDATE lsd.Game0EndingViews SET schemaVersion=1 WHERE kind='ending'")>=0)
  views=assert(assert(Store.open()):load());assert(views.ending and views.credits)
  for name,value in pairs(before)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  result.missions=p.missions;result.roster=roster;result.finalSamples=p.finalModel.sampleCount;result.currentSamples=p.currentModel.sampleCount;result.currentRevision=p.currentRevision;result.finalAttempt=p.finalAttempt;result.oldTablesPreserved=true;result.saveRetry=true;result.viewsIndependent=true;result.status='PASS'
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
