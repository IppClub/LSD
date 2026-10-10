-- Run only after the long soak is terminal. Real native C4.5; no builder replacement.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={runId=os.time(),status='RUNNING',osInput=false,syntheticDemonstrations=true,cases={}}
local out=D.Path(root,'Test/training-build-exit-result.json')
D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-cooperation-resume-fixture.txt')))
  assert(D.Path:getFilename(source):match('^lsd%-fresh%-cooperation%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-training-build-exit-qa-'..report.runId..'.db')
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);report.database=db
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),false,true)
  local Arena=require('Training.Arena');local Model=require('Training.Model')
  for _,character in ipairs({'ninilite','wuyun'})do
   local profile=require('Training.Progress').forCharacter(character);assert(profile.load())
   local old=Arena.createAsync({characterId=character,adopted=profile.adopted,previous=profile.previous,scene='VRTraining'})
   for i=1,1500 do
    local distance=50+(i*37)%900
    assert(old.recorder:record({distance=distance,facing='yes',enemyAction='idle',attackReady='yes'},distance<330 and 'laser' or 'fmove',true))
   end
   local returned,result,reason=false
   local build=coroutine.create(function()result,reason=old:finishDemoAsync();returned=true end)
   local resumed,why=coroutine.resume(build);assert(resumed,why)
   assert(old.mode=='building' and not returned,'Did not reach native asynchronous build suspension')
   -- Remove the actual native scene before allowing the waiting Lua caller to resume.
   old.world:removeFromParent();local closeDeadline=D.App.runningTime+1
   while not old.closed do assert(D.App.runningTime<closeDeadline,'Cleanup did not close the old arena');D.sleep(.01)end
   local fresh=Arena.createAsync({characterId=character,adopted=profile.adopted,previous=profile.previous,scene='VRTraining'})
   local adopted=fresh.adopted;local limit=D.App.runningTime+30
   while coroutine.status(build)~='dead' do
    assert(D.App.runningTime<limit,'Native build did not finish after exit')
    D.sleep(.02);local step,message=coroutine.resume(build);assert(step,message)
   end
   assert(returned and not result and reason=='CLOSED','Closed arena published a model')
   assert(not old.candidate and fresh.mode=='demo' and not fresh.candidate and #fresh.recorder.samples==0 and fresh.adopted==adopted,'Old build mutated the new session')
   for i=1,12 do
    local distance=50+i*65
    assert(fresh.recorder:record({distance=distance,facing='yes',enemyAction='idle',attackReady='yes'},distance<330 and 'laser' or 'fmove',true))
   end
   local candidate,buildError=fresh:finishDemoAsync();assert(candidate,buildError)
   assert(Model.validate(candidate,character,fresh.character.legal))
   assert(candidate.sampleCount==12 and fresh.adopted==adopted)
   report.cases[#report.cases+1]={character=character,oldSamples=1500,newSamples=12,closedResult=reason,newBuildPassed=true}
  end
  assert(before==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),false,true),'Exit changed adopted training records')
  report.adoptedDataUnchanged=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
