local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Spine'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={status='RUNNING',runId=os.time(),osInput=false};local out=D.Path(root,'Test/hud-input-availability-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local parent=D.Node();parent:addTo(D.Director.ui3D)
  local hud=require('UI.HUDControl')({});hud:addTo(parent);hud.move.visible=true;hud.weapon.visible=true
  local left,right=false,false;hud.move.onMove=function(key,down)if key=='keyLeft'then left=down else right=down end end
  local shots,ends=0,0;parent:gslot('Skill.Began',function()shots=shots+1 end);parent:gslot('Skill.Ended',function()ends=ends+1 end)
  D.sleep(.2);hud.move:emit('Right',true);D.sleep(.05);assert(right)
  parent.visible=false;hud:emit('KeyDown','J');D.sleep(.05);assert(not right and shots==0)
  hud.move:emit('Right',true);parent.visible=true;D.sleep(.05);assert(not right and shots==0)
  hud.move:emit('Left',true);D.sleep(.05);assert(left)
  D.emit('AppEvent','WillEnterBackground');assert(not left);local oldShots=shots
  hud:emit('KeyDown','J');hud.move:emit('Right',true);D.sleep(.05);assert(shots==oldShots and not right)
  D.emit('AppEvent','DidEnterForeground');D.sleep(.05);assert(not left and not right and shots==oldShots)
  hud:emit('KeyDown','J');D.sleep(.05);assert(shots==oldShots+1)
  D.emit('Story.Display',true);D.sleep(.05);local endCount=ends;assert(not hud.visible)
  D.emit('Story.Display',false);D.sleep(.05);assert(shots==oldShots+1)
  -- Desktop focus and hidden state are independent of mobile background state.
  hud.move:emit('Right',true);D.sleep(.05);assert(right)
  D.emit('AppEvent','WindowFocusLost');assert(not right)
  hud:emit('KeyDown','J');hud.move:emit('Right',true);D.sleep(.05);assert(not right and shots==oldShots+1)
  D.emit('AppEvent','WindowHidden');D.emit('AppEvent','WindowFocusGained')
  hud.move:emit('Right',true);D.sleep(.05);assert(not right,'Focus gain reactivated hidden HUD')
  D.emit('AppEvent','WindowShown');D.sleep(.05);assert(not right)
  hud.move:emit('Left',true);D.sleep(.05);assert(left)
  D.emit('AppEvent','WillEnterBackground');D.emit('AppEvent','WindowFocusLost');D.emit('AppEvent','WindowFocusGained')
  hud.move:emit('Right',true);D.sleep(.05);assert(not left and not right,'Focus gain reactivated background HUD')
  D.emit('AppEvent','DidEnterForeground');D.sleep(.05);assert(not right)
  -- A pending press followed by loss must never become a queued shot on return.
  hud:emit('KeyDown','J');D.emit('AppEvent','WindowFocusLost');hud:emit('KeyUp','J')
  D.emit('AppEvent','WindowFocusGained');D.sleep(.05);assert(shots==oldShots+1,'Focus resume emitted a queued shot')
  report.desktopIndependentState=true;report.desktopPendingShotCancelled=true
  hud.move:emit('Right',true);D.sleep(.05);assert(right)
  hud:removeFromParent();D.sleep(.05);assert(not right and ends>=endCount)
  report.hiddenAncestorClears=true;report.backgroundClears=true;report.noQueuedShot=true;report.foregroundFreshInput=true;report.cleanupClears=true;report.shots=shots;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
