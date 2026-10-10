-- Actual earned model copy, physical guard projectiles, and authored three-person skills.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','patrol-music-result.txt');D.Content:save(out,'LSD_PATROL_MUSIC_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','command-assembly-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-command%-assembly%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-patrol-music-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local snapshot={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")) do snapshot[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true) end
  local progress=require('Training.Progress');assert(progress.load());local wp=progress.forCharacter('wuyun');assert(wp.load());local models={ninilite=assert(progress.adopted),wuyun=assert(wp.adopted)}
  local music=require('System.Music')
  local c=require('Factory.PatrolLevel').openAsync(models)
  D.sleep(.8);assert(music.inspect().playing and music.inspect().path=='Music/战斗准备.mp3')
  c.start:emit('Tapped');D.sleep(.8)
  assert(c.battle.phase=='playing' and music.inspect().path=='Music/战斗2.mp3' and music.inspect().playing)
  c.withdraw:emit('Tapped');D.sleep(1)
  assert(c.battle.phase=='aborted' and c.result and not music.inspect().playing)
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  return {ready='战斗准备',playing='战斗2',abortedStops=true,allTablesUnchanged=true,database=db}
 end,debug.traceback)
 D.Content:save(out,D.json.encode({status=ok and 'PASS'or'FAIL',runId=id,result=ok and result or nil,error=not ok and result or nil,audibleReview=false}));print(D.Content:load(out))
end)
