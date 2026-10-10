local D=require('Dora');local G=require('Factory.ControlPodGeometry');local Art={}
Art.file='Image/Factory/ControlPod/architecture-v1.png'
Art.parts={wall={14,17,357,474},tread={382,345,440,132},column={845,26,167,466},balcony={1031,287,500,190},frame={0,540,420,423},door={440,563,375,375},passage={859,563,383,383},console={1338,619,159,336}}
function Art.sprite(name,parent,x,y,w,h,order)
 local rect=assert(Art.parts[name]);local s=assert(D.Sprite(Art.file));s.textureRect=D.Rect(table.unpack(rect));s.size=D.Size(rect[3],rect[4]);s.scaleX=w/rect[3];s.scaleY=(h or w*rect[4]/rect[3])/rect[4];s.position=D.Vec2(x,y);s.order=order or 0;s:addTo(parent);return s
end
function Art.build(world)
 local backdrop=D.DrawNode();backdrop.order=-100;backdrop:drawPolygon({D.Vec2(0,0),D.Vec2(4000,0),D.Vec2(4000,4700),D.Vec2(0,4700)},D.Color(0xff18272c));backdrop:addTo(world)
 for f=1,7 do
  local y=G.floorY(f)
  for c=0,(f==7 and 8 or 4) do local wall=Art.sprite('wall',world,220+c*440,y+270,480,660,-90);wall.opacity=.7 end
  Art.sprite('column',world,G.center,y+280,180,650,0)
  local landing=Art.sprite('balcony',world,440,y,650,220,-25);landing.anchor=D.Vec2(.5,.47)
  local label=D.Label('SourceHanSansCN-Regular',44);label.text=string.format('%02d',f);label.position=D.Vec2(210,y+200);label.color=D.Color(0xff6cd5d8);label.order=-30;label:addTo(world)
 end
 local terrain=D.BodyDef();terrain.type='Static'
 for f=1,7 do terrain:attachPolygon(D.Vec2(f==7 and 2070 or 440,G.floorY(f)-8),f==7 and 3620 or 650,16,0,1,1,0)end
 for i=0,6*G.steps-1 do
  local x,y,depth=G.point(i/G.steps)
  local nx,ny=G.point((i+1)/G.steps)
  local support=D.DrawNode();support.order=depth>0 and 9 or -21;support:addTo(world)
  support:drawSegment(D.Vec2(x,y-36),D.Vec2(nx,ny-36),12,D.Color(0xff28373d));support:drawSegment(D.Vec2(x,y-30),D.Vec2(nx,ny-30),3,D.Color(0xff81959a))
  local t=Art.sprite('tread',world,x,y,175,53,depth>0 and 10 or -20);t.anchor=D.Vec2(.5,.78)
  t.color=D.Color(depth>0 and 0xffffffff or 0xff96a4a8)
  terrain:attachPolygon(D.Vec2(x,y-8),175,16,0,1,1,0)
 end
 for x=900,3600,450 do local landing=Art.sprite('balcony',world,x,G.floorY(7),550,220,-25);landing.anchor=D.Vec2(.5,.47)end
 local floorBody=D.Body(terrain,world,D.Vec2.zero);floorBody.group=D.Platformer.Data.groupTerrain;floorBody.tag='control-pod-stairs';floorBody:addTo(world)
 local y=G.floorY(7)+205
 Art.sprite('passage',world,G.doorX,y,430,430,-35)
 local door=Art.sprite('door',world,G.doorX+218,y,436,436,-34);door.anchor=D.Vec2(1,.5)
 Art.sprite('frame',world,G.doorX,y,500,500,-33)
 Art.sprite('console',world,G.doorX-340,G.floorY(7)+115,110,230,-32)
 return {door=door,floorBody=floorBody}
end
return Art
