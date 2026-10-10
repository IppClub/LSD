-- Local wall and floor damage, using the academy's original steel palette.
-- Presentation only: no collision, story flags, or interaction sensors.
local D=require('Dora')
local Art={texture='Image/Story/academy-damage-v1.png',cell=627}
function Art.create(world)
 local root=D.Node();root.order=-2;root:addTo(world)
 local width,y=world.sceneWidth,world.offset
 local dim=D.DrawNode();dim.order=-1;dim:addTo(root)
 dim:drawPolygon({D.Vec2(0,y),D.Vec2(width,y),D.Vec2(width,y+1800),D.Vec2(0,y+1800)},D.Color(0x770c1420))
 local function part(index,x,height,scale,mirror)
  local sprite=assert(D.Sprite(Art.texture),'Academy damage atlas missing')
  local cell=Art.cell
  sprite.textureRect=D.Rect((index%2)*cell,math.floor(index/2)*cell,cell,cell)
  sprite.size=D.Size(cell,cell)
  -- The painted ground edge is inside the transparent cell, not at its bottom.
  sprite.anchor=D.Vec2(.5,index==2 and 156/cell or index==3 and 166/cell or .5)
  sprite.scaleX=scale*(mirror and -1 or 1);sprite.scaleY=scale
  sprite.position=D.Vec2(x,y+height);sprite:addTo(root)
  return sprite
 end
 for _,p in ipairs({{0,.12,580,.38},{1,.31,440,.32},{0,.54,690,.30},{1,.73,520,.39},{0,.90,390,.27}})do
  local rest=world.tag=='RestRoom'
  local height=rest and 95 or p[3]
  part(p[1],width*p[2],height,rest and .18 or p[4],p[2]>.5)
 end
 for i,p in ipairs({{2,.08,.25},{3,.23,.30},{2,.43,.20},{3,.63,.24},{2,.79,.29},{3,.94,.20}})do
  part(p[1],width*p[2],3,p[3],i%2==0)
 end
 return root
end
function Art.createDust(world)
 local root=D.Node();root.order=-1;root:addTo(world)
 local particles={}
 for i=1,3 do
  local sprite=assert(D.Sprite('Image/Story/academy-dust-source.png'))
  sprite.color=D.Color(0xff888d99);sprite.opacity=0;sprite:addTo(root)
  particles[i]=sprite
 end
 local elapsed=0
 root:schedule(function(dt)
  elapsed=elapsed+dt
  for i,sprite in ipairs(particles)do
   local age=(elapsed/18+(i-1)/3)%1
   local size=.24+age*.10
   sprite.scaleX=size*(i%2==0 and -1 or 1);sprite.scaleY=size
   sprite.opacity=math.sin(age*math.pi)^2*.13
   sprite.position=D.Vec2(world.sceneWidth*(.18+(i-1)*.31)+math.sin(elapsed*.2+i)*28,world.offset+28+age*170)
  end
  return false
 end)
 return root
end
return Art
