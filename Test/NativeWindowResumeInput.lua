-- Held virtual-pad setup + actual macOS hide/show; no database or combat injection.
local entry,qaResultName=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(entry))
local out=root..'/Test/'..(qaResultName or'native-window-resume-input-result.json')
local r={status='RUNNING',osInput=true,scope='actual-window-hide-show; held-vpad-setup-engine-event',events={},samples={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local directory=assert(os.getenv('LSD_QA_OS_OBSERVATION_DIRECTORY'))
  assert(directory:match('^/private/tmp/lsd%-os%-window%-resume%-'))
  local parent=D.Node();parent:addTo(D.Director.ui3D)
  local hud=require('UI.HUDControl')({});hud:addTo(parent);hud.move.visible=true;hud.weapon.visible=true
  local left,right=false,false
  hud.move.onMove=function(key,down)if key=='keyLeft'then left=down else right=down end end
  parent:gslot('AppEvent',function(event)r.events[#r.events+1]={event=event,at=D.App.runningTime,left=left,right=right};save()end)
  r.stage='WAIT_FOR_OS_FOCUS';save()
  assert(D.Content:save(directory..'/ready.json',D.json.encode({status='WAIT_FOR_FOCUS'},false,true)))
  local armDeadline=D.App.runningTime+90
  while not D.Content:exist(directory..'/arm.json')do assert(D.App.runningTime<armDeadline,'OS focus/arm driver missing');D.sleep(.02)end
  D.sleep(.1);hud.move:emit('Right',true);D.sleep(.1);assert(right,'Held vpad setup not active after initial focus')
  r.stage='READY_FOR_OS_HIDE';r.before={right=right,left=left};save()
  assert(D.Content:save(directory..'/armed.json',D.json.encode({status='READY'},false,true)))
  local deadline=D.App.runningTime+120
  while not D.Content:exist(directory..'/done.json')do
   assert(D.App.runningTime<deadline,'OS hide/show driver missing')
   r.samples[#r.samples+1]={at=D.App.runningTime,left=left,right=right,keyA=D.Keyboard:isKeyPressed('A'),keyD=D.Keyboard:isKeyPressed('D')};D.sleep(.02)
  end
  D.sleep(.2);r.after={left=left,right=right};save()
  assert(not right and not left,'Held virtual-pad state survived actual window hide/show')
  local seen={};for _,event in ipairs(r.events)do seen[event.event]=true end
  assert(seen.WindowHidden and seen.WindowShown and seen.WindowFocusLost and seen.WindowFocusGained,'Missing actual desktop lifecycle events')
  r.desktopEventsVerified=true
  hud.move:emit('Left',true);D.sleep(.05);assert(left,'Fresh input rejected after resume');hud.move:emit('Left',false);D.sleep(.05);assert(not left)
  r.freshInputVerified=true;r.stage='RESUME_VERIFIED'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
