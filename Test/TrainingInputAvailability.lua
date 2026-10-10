local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={status='RUNNING',runId=os.time(),osInput=false,characters={}};local out=D.Path(root,'Test/training-input-availability-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-cooperation-resume-fixture.txt')));assert(D.Path:getFilename(source):match('^lsd%-fresh%-cooperation%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-training-input-qa-'..report.runId..'.db');report.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync()
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),false,true)
  local function wait(fn)local deadline=D.App.runningTime+30;while not fn()do assert(D.App.runningTime<deadline,'Training input wait');D.sleep(.03)end end
  for _,character in ipairs({'ninilite','wuyun'})do
   local old=D.Director.ui3D:getChildByTag('training-controls');require('Training.Level')(nil,character)
   wait(function()local u=D.Director.ui3D:getChildByTag('training-controls');return u and u~=old end)
   local ui=D.Director.ui3D:getChildByTag('training-controls');local a=ui.arena;local hud=D.Director.ui3D:getChildByTag('trainingHUD')
   wait(function()return a:available('fmove')end)
   hud.move:emit('Right',true);D.sleep(.15);assert(#a.recorder.samples>0)
   D.emit('Story.Display',true);D.sleep(.1);local count=#a.recorder.samples;local rejected=a.recorder.rejected
   local accepted,err=a:request('laser','demo');assert(not accepted and err=='INPUT_SUSPENDED')
   D.emit('Skill.Began');hud.move:emit('Right',true);D.sleep(.2)
   assert(#a.recorder.samples==count and a.recorder.rejected==rejected and a.student.velocityX==0)
   D.emit('Story.Display',false);D.sleep(.1);assert(#a.recorder.samples==count)
   D.emit('AppEvent','WillEnterBackground');accepted,err=a:request('idle','demo');assert(not accepted and err=='INPUT_SUSPENDED')
   D.emit('Skill.Began');D.sleep(.1);assert(#a.recorder.samples==count and a.recorder.rejected==rejected)
   D.emit('AppEvent','DidEnterForeground');wait(function()return a:available('idle')end)
   hud.skillArea:getChildByTag('training-wait'):emit('TapBegan');D.sleep(.05);assert(#a.recorder.samples==count+1)
   report.characters[character]={before=count,after=#a.recorder.samples,rejectedUnchanged=true,noHiddenSamples=true,noBackgroundSamples=true,resumed=true}
  end
  assert(before==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),false,true));report.adoptedDataUnchanged=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
