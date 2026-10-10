-- Screen-space identification stays visible when an enemy covers the player.
-- Use the original life bar; the marker never changes a unit or handles input.
local D=require('Dora');local M={}
function M.attach(b,controls)
 local owner=b.mentor
 local node=D.Node();node.tag='combat-player-marker';node.order=30;node.visible=false;node:addTo(controls.controls)
 local marker={node=node,owner=owner,closed=false,pending=false};controls.playerMarker=marker
 local bg=D.DrawNode();bg:drawPolygon({D.Vec2(-47,0),D.Vec2(-47,30),D.Vec2(47,30),D.Vec2(47,0),D.Vec2(7,0),D.Vec2(0,-8),D.Vec2(-7,0)},D.Color(0xec101b28));bg:addTo(node)
 local label=D.Label('SourceHanSansCN-Regular',18);label.text='导师';label.color3=D.Color3(0x9eeeff);label.position=D.Vec2(0,18);label:addTo(node);marker.label=label
 local bar,hp=require('UI.View.StatusBar').default(1,0,0x9eeeff,false);bar.scaleX=.8;bar.scaleY=.4;bar.position=D.Vec2(0,3);bar:addTo(node);marker.hpBar=hp
 node:slot('Cleanup',function()marker.closed=true;marker.pending=false end)
 node:schedule(function()
  if marker.closed or b.arena.closed then return true end
  local active=(b.phase=='ready'or b.phase=='playing')and controls.controls.visible
  if not active then node.visible=false;return false end
  local fraction=math.max(0,math.min(1,b.mentorHP/100));if hp.scaleX~=fraction then hp.scaleX=fraction end
  if marker.pending then return false end
  marker.pending=true
  -- Point to the actual controlled body center, rather than estimating a
  -- head height from collision dimensions or another character's artwork.
  owner:convertToWindowSpace(D.Vec2.zero,function(point)
   marker.pending=false
   if marker.closed or b.arena.closed then return end
   local buffer,window=D.App.bufferSize,D.App.winSize
   local x=point.x*buffer.width/window.width;local y=buffer.height-point.y*buffer.height/window.height
   node.visible=(b.phase=='ready'or b.phase=='playing')and controls.controls.visible and x>=47 and x<=buffer.width-47 and y>=8 and y<=buffer.height-30
   if node.visible then node.position=D.Vec2(x,y)end
   marker.projection={at=D.App.runningTime,x=x,y=y,ownerX=owner.x,ownerY=owner.y}
  end)
  return false
 end)
 return marker
end
return M
