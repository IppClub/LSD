-- Shared HUD guard: hidden ancestors must not leave a live input surface.
local D=require('Dora');local I={}
function I.bind(node,clear)
 local background,unfocused,hidden=false,false,false
 node:gslot('AppEvent',function(event)
  if event=='WillEnterBackground'or event=='DidEnterBackground'then background=true;clear()
  elseif event=='DidEnterForeground'then background=false;clear()
  elseif event=='WindowFocusLost'then unfocused=true;clear()
  elseif event=='WindowFocusGained'then unfocused=false;clear()
  elseif event=='WindowHidden'then hidden=true;clear()
  elseif event=='WindowShown'then hidden=false;clear()end
 end)
 return function()
  if background or unfocused or hidden then return false end
  local current=node
  while current do if not current.visible then return false end;current=current.parent end
  return true
 end
end
return I
