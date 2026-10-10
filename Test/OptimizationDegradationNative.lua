-- Fault injection into actual native animation completion notifications.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/optimization-degradation-result.json'
local baseline=os.getenv('LSD_QA_DEGRADATION_BASELINE')=='1'
local r={status='RUNNING',controlledFixture=true,osInput=false,baseline=baseline,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local A=require('Training.Arena');local Animation=require('CombatAnimation')
  local a=A.createAsync({scene='VRTraining',manualUpdate=true,actionPrefix='degradationNi_'})
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 12);while not fn()do assert(D.App.runningTime<deadline,'Native degradation fixture stalled');D.sleep(.01)end end
  wait(function()return a.student.onSurface end)
  local records={}
  a.beginCombatAction=function()records[#records+1]={started=D.App.runningTime};return #records end
  a.finishCombatAction=function(id,owner,source,status)local v=assert(records[id]);v.notifications=(v.notifications or 0)+1;v.ended=D.App.runningTime;v.status=status end
  assert(a.student:start(a.physical.laser));wait(function()return records[1] and records[1].ended end)
  assert(records[1].status=='completed' and records[1].notifications==1,'Normal animation closure changed')
  wait(function()return not a.student:isDoing(a.physical.laser) and D.App.runningTime>=a.nextShot end)
  a.student.playable:slot('AnimationEnd'):clear()
  assert(a.student:start(a.physical.laser));wait(function()return records[2] and records[2].ended end)
  assert(records[2].notifications==1,'Fault animation closed multiple times')
  assert(records[2].status==(baseline and 'completed' or 'interrupted'),'Missing end notification incorrectly counted as complete')
  assert(records[2].ended-records[2].started<6,'Missing end notification locked attack')
  D.sleep(.1);assert(a.student.playable.current==a.student.data.combatRest,'Missing callback did not recover rest')
  r.cases=records;r.missingEnd=a.student.data.combatAnimationFailure
  if not baseline then
   assert(r.missingEnd=='ANIMATION_END_TIMEOUT')
   Animation.configure(a.student,a.character.id)
   assert(a.student:start(a.physical.laser));wait(function()return records[3] and records[3].ended end)
   assert(records[3].status=='completed' and records[3].notifications==1,'Action did not recover after notification restored')
   local at=D.App.runningTime;local duration,completed=Animation.playOnceAsync(a.student,'qa_missing_animation')
   assert(duration==0 and completed==false and D.App.runningTime-at<.5,'Missing clip threw or stalled caller')
   assert(a.student.data.combatAnimationFailure=='MISSING_ANIMATION')
   Animation.rest(a.student);r.missingClipRecovered=true;r.normalActionAfterFault=true
   local wu=A.createAsync({world=a.world,manualUpdate=true,characterId='wuyun',actionPrefix='degradationWu_'})
   wait(function()return wu.student.onSurface end)
   local released=0;local song=require('Factory.Song').new(wu,{states={},song=function()released=released+1;return 1 end})
   wu.mode='trial';wu.student.playable:slot('AnimationEnd'):clear();assert(song:request())
   wait(function()return not wu.student:isDoing(song.action) end)
   local log=assert(song.logs[1]);assert(not log.completedAt and not log.releaseAt and released==0,'Unconfirmed chant released its effect')
   assert(log.interruptedReason=='ANIMATION_END_TIMEOUT' and log.interruptedAt,'Unconfirmed chant missing failure reason')
   assert(wu.student.playable.current==wu.student.data.combatRest);r.chant=log
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
