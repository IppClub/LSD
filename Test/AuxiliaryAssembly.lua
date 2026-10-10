-- Artist's completed assembly beside original-part native reconstruction.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff23313f));bg:addTo(ui)
local manifest=D.json.decode(D.Content:load('Image/Auxiliary/manifest.json'))
local c={models={},buttons={}};ui.assembly=c;D.Platformer.Data.store.auxiliaryAssembly=ui
local function label(text,x,y,size) local n=D.Label('SourceHanSansCN-Regular',size or 24);n.text=text;n.position=D.Vec2(x,y);n:addTo(ui);return n end
label('原稿 · 装备机挡板展开',ui.width*.25,ui.height-40);label('游戏模型 · 装备机默认闭合',ui.width*.72,ui.height-40)
for i,kind in ipairs({'defence','cargo','mobility'}) do
 local v=manifest.variants[kind];local rect=v.reference.rect;local origin=v.reference.origin
 local scale=math.min(ui.width*.40/rect[3],(ui.height-160)/3/math.max(rect[4],kind=='defence' and 400 or 0));local y=ui.height-85-i*(ui.height-160)/3
 local ref=D.Sprite('Image/Auxiliary/'..v.source);ref.textureRect=D.Rect(table.unpack(rect));ref.size=D.Size(rect[3],rect[4]);ref.anchor=D.Vec2((origin[1]-rect[1])/rect[3],1-(origin[2]-rect[2])/rect[4]);ref.scaleX=scale;ref.scaleY=scale;ref.position=D.Vec2(ui.width*.25,y);ref:addTo(ui)
 if type(v.reference.maskRuns)=="table" then
  local stencil=D.DrawNode()
  for _,r in ipairs(v.reference.maskRuns) do local x=r[1]-rect[3]*ref.anchor.x;local yy=rect[4]-r[2]-rect[4]*ref.anchor.y
   stencil:drawPolygon({D.Vec2(x,yy),D.Vec2(x+r[3],yy),D.Vec2(x+r[3],yy-r[4]),D.Vec2(x,yy-r[4])},D.Color(0xffffffff))
  end
  local clip=D.ClipNode(stencil);clip.alphaThreshold=.1;clip.position=ref.position;clip.scaleX=scale;clip.scaleY=scale;clip:addTo(ui)
  ref:removeFromParent(false);ref.position=D.Vec2.zero;ref.scaleX=1;ref.scaleY=1;ref:addTo(clip)
 end
 D.Cache:unload('Image/Auxiliary/'..kind..'.model');D.Cache:unload('Image/Auxiliary/'..kind..'.clip')
 local m=require('Ground.AuxiliaryModel').create(kind);m.scaleX=scale;m.scaleY=scale;m.position=D.Vec2(ui.width*.72,y);m:addTo(ui);c.models[i]=m
 local line=D.DrawNode();line:drawSegment(D.Vec2(ui.width*.06,y),D.Vec2(ui.width*.94,y),1,D.Color(0x4453e1d7));line:addTo(ui)
end
local function button(text,x)
 local holder=D.Node();holder.scaleX=.5;holder.scaleY=.5;holder.position=D.Vec2(x,20);holder:addTo(ui)
 local b=require('UI.InputButton')({text=text,textBG=''});b:addTo(holder);return b
end
local slow=button('慢放',ui.width*.84)
slow:slot('Tapped',function() if c.busy then return end;c.slow=not c.slow;for _,m in ipairs(c.models) do m.speed=c.slow and .25 or 1 end end)
local tracks={{'整机','idle'},{'移动','move'},{'采集','collect'},{'装备舱','carry'}}
for i,track in ipairs(tracks) do
 local b=button(track[1],ui.width*.20+(i-1)*ui.width*.16);c.buttons[track[2]]=b
 b:slot('Tapped',function() if c.busy then return end;c.busy=true;D.thread(function()
  local t=0;for _,m in ipairs(c.models) do t=math.max(t,m:play(track[2],false)) end
  D.sleep(t+.05);for _,m in ipairs(c.models) do m:play('idle',true) end;c.busy=false
 end) end)
end
D.thread(function() D.sleep(.5);for _,m in ipairs(c.models) do m:play('idle',true) end end)
