-- Candidate eye patches leave the original ears, hair and face outline intact.
local D=require('Dora')
local Face={}
function Face.attach(model)
 local head=assert(model:getNodeByName('head'))
 local state={phase='open',cycles=0,elapsed=0,interval=2.7,events={}}
 local sprites={}
 for _,phase in ipairs({'half','closed'})do
  local s=assert(D.Sprite('Image/Companion/fox-chibi-blink-'..phase..'-atlas-v1.clip|eyes'))
  s.anchor=D.Vec2.zero;s.position=D.Vec2(70,116);s.visible=false;s:addTo(head,10)
  sprites[phase]=s
 end
 local function show(phase)
  if state.phase~=phase then state.events[#state.events+1]={phase=phase,time=state.elapsed}end
  state.phase=phase
  for name,s in pairs(sprites)do s.visible=name==phase end
 end
 function state.hold(phase)assert(phase=='open'or sprites[phase]);state.manual=true;show(phase)end
 function state.release()state.manual=false;state.clock=0;show('open')end
 state.clock=0
 local tick=D.Node();tick:addTo(model)
 tick:schedule(function(dt)
  state.elapsed=state.elapsed+dt
  if not state.manual then
   state.clock=state.clock+dt
   local t=state.clock-state.interval
   if t<0 then show('open')
   elseif t<.025 then show('half')
   elseif t<.075 then show('closed')
   elseif t<.1 then show('half')
   else state.cycles=state.cycles+1;state.clock=state.clock-state.interval-.1;show('open')end
  end
  return false
 end)
 model.face=state;return state
end
return Face
