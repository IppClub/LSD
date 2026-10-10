-- Held virtual-pad setup + actual macOS hide/show; no database or combat injection.
local entry,qaResultName=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(entry))
local out=root..'/Test/'..(qaResultName or'native-window-resume-keyboard-result.json')
local r={status='RUNNING',osInput=true,scope='actual-window-hide-show and sustained fresh OS A input; initial held-vpad priming uses an engine event',events={},samples={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local directory=assert(os.getenv('LSD_QA_OS_OBSERVATION_DIRECTORY'))
  assert(directory:match('^/private/tmp/lsd%-os%-window%-resume%-'))
  local parent=D.Node();parent.keyboardEnabled=true;parent:addTo(D.Director.ui3D)
  local hud=require('UI.HUDControl')({});hud:addTo(parent);hud.move.visible=true;hud.weapon.visible=true
  local left,right=false,false
  hud.move.onMove=function(key,down)if key=='keyLeft'then left=down else right=down end end
  parent:gslot('AppEvent',function(event)r.events[#r.events+1]={event=event,at=D.App.runningTime,totalTime=D.App.totalTime,left=left,right=right};save()end)
  r.keyboardEvents={}
  for _,event in ipairs({'KeyDown','KeyUp'})do parent:slot(event,function(key)if key=='A'then r.keyboardEvents[#r.keyboardEvents+1]={event=event,key=key,at=D.App.totalTime};save()end end)end
  r.stage='WAIT_FOR_OS_FOCUS';save()
  assert(D.Content:save(directory..'/ready.json',D.json.encode({status='WAIT_FOR_FOCUS'},false,true)))
  local armDeadline=D.App.runningTime+90
  while not D.Content:exist(directory..'/arm.json')do assert(D.App.runningTime<armDeadline,'OS focus/arm driver missing');D.sleep(.02)end
  local focused=false;for _,e in ipairs(r.events)do if e.event=='WindowFocusGained'then focused=true elseif e.event=='WindowFocusLost'then focused=false end end;assert(focused,'Initial actual OS focus not verified before held setup');r.initialFocusVerified=true
  D.sleep(.1);hud.move:emit('Right',true);D.sleep(.1);assert(right,'Held vpad setup not active after initial focus');r.heldSetupEventCount=#r.events;r.heldSetupAt=D.App.totalTime
  r.stage='READY_FOR_OS_HIDE';r.before={right=right,left=left};save()
  assert(D.Content:save(directory..'/armed.json',D.json.encode({status='READY'},false,true)))
  local deadline=D.App.runningTime+120
  while not D.Content:exist(directory..'/done.json')do
   assert(D.App.runningTime<deadline,'OS hide/show driver missing')
   r.samples[#r.samples+1]={at=D.App.runningTime,totalTime=D.App.totalTime,left=left,right=right,keyA=D.Keyboard:isKeyPressed('A'),keyD=D.Keyboard:isKeyPressed('D')};D.sleep(.02)
  end
  D.sleep(.2);r.after={left=left,right=right};save()
  assert(not right and not left,'Held virtual-pad state survived actual window hide/show')
  local hidden,shown,lost,gained
  for i,event in ipairs(r.events)do
   if event.event=='WindowHidden'then hidden=i elseif event.event=='WindowShown'then shown=i elseif event.event=='WindowFocusLost'then lost=i elseif event.event=='WindowFocusGained'then gained=i end
  end
  assert(hidden and shown and lost and gained and shown>hidden and gained>lost,'Missing actual renewed shown/focus events in the proper order')
  local cancel=r.events[r.heldSetupEventCount+1];assert(cancel and (cancel.event=='WindowHidden'or cancel.event=='WindowFocusLost'),'Held setup cleared by activation before actual hide/loss');assert(not cancel.right and not cancel.left,'Held input not cleared on actual hide/loss');r.heldCancelledBy=cancel.event
  r.lifecycleIndices={hidden=hidden,shown=shown,focusLost=lost,focusGained=gained}
  r.desktopEventsVerified=true
  r.stage='READY_FOR_FRESH_OS_INPUT';r.keyboardEvents={};r.freshSamples={};save()
  assert(D.Content:save(directory..'/fresh-ready.json',D.json.encode({status='READY_FOR_FRESH_OS_INPUT'},false,true)))
  local freshDeadline=D.App.totalTime+60
  while not D.Content:exist(directory..'/fresh-done.json')do
   assert(D.App.totalTime<freshDeadline,'Fresh OS keyboard driver missing')
   r.freshSamples[#r.freshSamples+1]={at=D.App.totalTime,left=left,right=right,keyA=D.Keyboard:isKeyPressed('A')};D.sleep(.02)
  end
  D.sleep(.2);local down,up
  for _,event in ipairs(r.keyboardEvents)do if event.event=='KeyDown'and not down then down=event elseif event.event=='KeyUp'and down then up=event;break end end
  assert(down and up and up.at-down.at>=1.5,'No sustained fresh OS A press/release after resume')
  local held=0;for _,sample in ipairs(r.freshSamples)do if sample.left and sample.keyA and not sample.right then held=held+1 end end
  assert(held>=50 and not left and not right and not D.Keyboard:isKeyPressed('A'),'Fresh OS input failed to drive or release HUD after resume')
  r.physicalKeyboardHoldSeconds=up.at-down.at;r.physicalHeldSamples=held;r.freshInputVerified=true;r.freshInputUsesOSKeyboard=true;r.stage='RESUME_VERIFIED'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
