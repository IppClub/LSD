local D=require('Dora')
local Art={file='Image/Factory/Roof/architecture-v1.png'}
Art.parts={domeRear={10,90,538,370},cannon={548,8,440,498},domeFront={990,92,535,364},climbWall={52,490,327,523},catwalk={403,711,642,125},stairs={1012,556,495,420}}
function Art.sprite(name,parent,x,y,w,h,order)
 if name=='stairs' then
  -- Two texture rectangles exclude the neighboring catwalk in this atlas.
  -- Preserve the complete stair silhouette without editing generated pixels.
  local r=Art.parts.stairs;local node=D.Node();node.position=D.Vec2(x,y);node.order=order or 0;node:addTo(parent)
  local sy=(h or w*r[4]/r[3])/r[4];local sx=w/r[3]
  for _,tile in ipairs({{1048,556,459,282},{1012,838,495,138}})do
   local s=assert(D.Sprite(Art.file));s.textureRect=D.Rect(table.unpack(tile));s.size=D.Size(tile[3],tile[4]);s.anchor=D.Vec2(0,0)
   s.scaleX=sx;s.scaleY=sy;s.position=D.Vec2((tile[1]-r[1]-r[3]/2)*sx,(r[2]+r[4]-tile[2]-tile[4])*sy);s:addTo(node)
  end
  return node
 end
 local r=assert(Art.parts[name]);local s=assert(D.Sprite(Art.file))
 s.textureRect=D.Rect(table.unpack(r));s.size=D.Size(r[3],r[4]);s.anchor=D.Vec2(.5,0)
 s.scaleX=w/r[3];s.scaleY=(h or w*r[4]/r[3])/r[4]
 s.position=D.Vec2(x,y);s.order=order or 0;s:addTo(parent);return s
end
-- Keep the glass foreground distinct so actors and cannon occupy its interior.
function Art.dome(parent,x,y,width)
 local height=width*370/538
 local rear=Art.sprite('domeRear',parent,x,y,width,height,-20)
 local cannon=Art.sprite('cannon',parent,x,y+10,width*.38,height*.83,0)
 local front=Art.sprite('domeFront',parent,x,y,width,height,30)
 return {rear=rear,cannon=cannon,front=front}
end
return Art
