-- A child schedule keeps the original HUD input and unit movement schedules.
local D=require('Dora');local H={}
function H.attach(hud,read)
 assert(not hud.aimHint,'Aim hint already attached')
 local node=D.Node();node.tag='aim-hint';node:addTo(hud)
 local bg=D.DrawNode();bg:drawPolygon({D.Vec2(-155,-40),D.Vec2(155,-40),D.Vec2(155,40),D.Vec2(-155,40)},D.Color(0xc9101b28));bg:addTo(node)
 local label=D.Label('SourceHanSansCN-Regular',32);label.textWidth=300;label.alignment='Center';label:addTo(node)
 local state={node=node,label=label,phase='idle'};hud.aimHint=state
 node:schedule(function()
  -- Keep the hint flat; the skill area has a perspective rotation.
  local scale=D.App.bufferSize.height/1563
  node.scaleX=scale;node.scaleY=scale
  local point=hud:convertToNodeSpace(hud.weapon:convertToWorldSpace(D.Vec2(hud.weapon.width/2,hud.weapon.height+100)))
  local margin=155*scale+14;local vertical=40*scale+14
  node.position=D.Vec2(math.max(margin,math.min(hud.width-margin,point.x)),math.max(vertical,math.min(hud.height-vertical,point.y)))
  node.visible=hud.visible and hud.weapon.visible
  local held,precision,available=read()
  state.phase=held and (precision and 'precision'or'aiming')or available==false and 'unavailable'or'idle'
  local text=state.phase=='precision'and'精瞄中\n松开发射'or state.phase=='aiming'and'正在瞄准\n继续按住可精瞄'or state.phase=='unavailable'and'暂时无法射击'or'轻点射击\n长按可精瞄'
  -- Native Label.setText rebuilds glyph layout, even for identical text.
  if label.text~=text then label.text=text end
  label.color=D.Color(state.phase=='precision'and 0xffffd482 or 0xfff2f5fa)
  return false
 end)
 return state
end
return H
