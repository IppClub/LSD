-- Real PatrolLevel/HUD and native event dispatch; controlled idle models and
-- virtual supplies, with an optional actual desktop focus phase. Skill probes
-- use engine UI events; this does not prove physical gameplay or mission billing.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/patrol-input-availability-result.json'
local r={status='RUNNING',osInput=false,controlledFixture=true,naturalVictory=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local c=require('Factory.PatrolLevel').openAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},function()return true end,{battleFactory=function(models)
   local supply=assert(require('Economy.CombatSession').virtual('input-availability',{{actor='mentor',item='kinetic',quantity=40},{actor='ninilite',item='emp',quantity=40},{actor='wuyun',item='emp',quantity=40}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supply,{virtual=true,physicalSupport=true})
   b.bossCombat.boss.guard.update=function()end
   return b
  end,presentation={title='战斗技能失焦专项'}})
  local b=c.battle;local requests={};r.requests=requests;local command=b.command
  b.command=function(self,name)
   if name~='stop'then requests[#requests+1]={name=name,at=D.App.runningTime}end
   return command(self,name)
  end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 8);while not fn()do assert(D.App.runningTime<deadline,'Input fixture stalled');D.sleep(.01)end end
  wait(function()return b.mentor.onSurface and b.arena.student.onSurface and b.wuyun.student.onSurface end)
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  local ui=c.controls
  local function inputs()
   ui:emit('KeyDown','F');ui:emit('KeyDown','R');ui:emit('KeyDown','G')
   c.fire:emit('TapBegan');c.wind:emit('TapBegan');c.gather:emit('TapBegan')
  end
  local function silence(name,fn)
   local before=#requests;fn();D.sleep(.75)
   assert(#requests==before,name..' submitted inactive commands')
   r.cases[#r.cases+1]={name=name,requests=0};save()
  end
  -- Pending key skills and an already started G gesture must be discarded on
  -- loss. The already issued short gather order may continue normally.
  ui:emit('KeyDown','F');ui:emit('KeyDown','R');ui:emit('KeyDown','G')
  assert(requests[#requests].name=='gather')
  local issuedPlan,issuedUntil=b.gatherPlan,b.gatherUntil
  D.emit('AppEvent','WindowFocusLost')
  assert(b.gatherPlan==issuedPlan and b.gatherUntil==issuedUntil,'Focus loss cancelled an already issued order')
  r.issuedOrderPreserved=true
  silence('focus-loss-cancels-pending-and-long-hold',inputs)
  D.emit('AppEvent','WindowHidden');D.emit('AppEvent','WindowFocusGained')
  silence('focus-gain-keeps-hidden-inactive',inputs)
  D.emit('AppEvent','WindowShown');silence('return-does-not-replay',function()end)
  D.emit('AppEvent','WillEnterBackground');D.emit('AppEvent','WindowFocusLost');D.emit('AppEvent','WindowFocusGained')
  silence('focus-gain-keeps-background-inactive',inputs)
  D.emit('AppEvent','DidEnterForeground');silence('foreground-does-not-replay',function()end)
  ui.visible=false;silence('hidden-controls-reject',inputs)
  ui.visible=true;silence('controls-reshown-do-not-replay',function()end)
  D.emit('Story.Display',true);silence('hidden-story-hud-rejects',inputs)
  D.emit('Story.Display',false);silence('story-return-does-not-replay',function()end)
  local beforeMedicine=#requests
  D.emit('AppEvent','WindowFocusLost')
  local accepted,reason=c.commandInput('medicine')
  assert(not accepted and reason=='INPUT_INACTIVE'and #requests==beforeMedicine,'Chapter-specific command bypassed focus guard')
  D.emit('AppEvent','WindowFocusGained');c.commandInput('medicine')
  assert(#requests==beforeMedicine+1 and requests[#requests].name=='medicine','Fresh chapter-specific command unavailable')
  r.chapterCommandGuard=true
  local before=#requests;ui:emit('KeyDown','F');ui:emit('KeyDown','R');D.sleep(.05)
  assert(#requests==before+2 and requests[before+1].name=='fire'and requests[before+2].name=='wind','Fresh keyboard skills unavailable')
  before=#requests;c.fire:emit('TapBegan');c.wind:emit('TapBegan')
  assert(#requests==before+2,'Fresh touch skills unavailable')
  before=#requests;ui:emit('KeyDown','G');D.sleep(.7);ui:emit('KeyUp','G');D.sleep(.05)
  assert(#requests==before+2 and requests[before+1].name=='gather'and requests[before+2].name=='recover-gather','Fresh G gesture unavailable')
  before=#requests;local continuing=b.gatherMode=='recover'and b:gatherActive()
  c.gather:emit('TapBegan');D.sleep(.7);c.gather:emit('TapEnded');D.sleep(.05)
  assert(#requests==before+(continuing and 1 or 2)and requests[#requests].name=='recover-gather','Fresh touch hold unavailable')
  r.requests=requests;r.freshKeyboardSkills=true;r.freshTouchSkills=true;r.freshKeyboardAndTouchHold=true
  local directory=os.getenv('LSD_QA_PATROL_ACTUAL_FOCUS_DIRECTORY')
  if directory then
   assert(directory:match('^/private/tmp/lsd%-os%-patrol%-focus%-'))
   -- This phase emits no AppEvent. Focus must come from the actual desktop.
   -- Skill probes use engine UI events, so they are not physical gameplay QA.
   r.actualLifecycleEvents={};local lost,gained=0,0
   ui:gslot('AppEvent',function(event)
    r.actualLifecycleEvents[#r.actualLifecycleEvents+1]={event=event,at=D.App.runningTime}
    if event=='WindowFocusLost'then lost=lost+1 elseif event=='WindowFocusGained'then gained=gained+1 end
    save()
   end)
   r.stage='WAIT_FOR_ACTUAL_OS_FOCUS';save()
   assert(D.Content:save(directory..'/ready.json',D.json.encode({status=r.stage},false,true)))
   wait(function()return D.Content:exist(directory..'/arm.json')end,120)
   local startLost=lost;r.stage='WAIT_FOR_ACTUAL_OS_FOCUS_LOSS';save()
   assert(D.Content:save(directory..'/armed.json',D.json.encode({status=r.stage},false,true)))
   wait(function()return lost>startLost end,120)
   local returnGained=gained;local requestsBefore=#requests
   inputs();local accepted,reason=c.commandInput('medicine')
   assert(not accepted and reason=='INPUT_INACTIVE','Actual focus loss allowed chapter command')
   D.sleep(.75);assert(gained==returnGained,'Desktop returned before inactive probe completed')
   assert(#requests==requestsBefore,'Actual focus loss allowed skill/long-hold requests')
   r.stage='ACTUAL_FOCUS_PROBE_COMPLETE';r.actualFocusBlockedRequests=true;save()
   assert(D.Content:save(directory..'/probe-complete.json',D.json.encode({status=r.stage},false,true)))
   wait(function()return gained>returnGained end,120)
   D.sleep(.15);assert(#requests==requestsBefore,'Actual focus return replayed queued commands')
   c.fire:emit('TapBegan');assert(#requests==requestsBefore+1 and requests[#requests].name=='fire','Actual focus return rejected fresh input')
   r.actualFocusFreshInput=true;r.actualOSLifecycle=true;r.actualGameplayKeys=false
  end
  b:finish('aborted','Controlled input availability complete')
  r.scope='Actual production native controls and simulated lifecycle/visibility events; controlled idle models, disabled Boss attacks and virtual supplies; not formal battle, costs or victory'
  r.scope=r.scope..(r.actualOSLifecycle and '; additional actual macOS focus loss/gain phase verified with engine UI skill probes, not physical gameplay keys'or '; actual OS focus not exercised')
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
