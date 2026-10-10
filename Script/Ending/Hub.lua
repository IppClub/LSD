-- Post-story navigation never resets the save or revives the academy.
local D=require('Dora');local Hub={}
function Hub.openAsync(mode)
 if mode~='title'and mode~='records'then return nil,'INVALID_ENDING_DESTINATION'end
 if mode=='title'then require('System.Music').stop(.4);D.Audio:stopStream(.4)end
 local records,why=require('Ending.Records').read();if not records then return nil,why end
 local store,why=require('Ending.Store').open();if not store then return nil,why end
 local watched,why=store:load();if not watched then return nil,why end
 D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear()
 D.View.scale=1;D.View.postEffect=nil
 local c={mode=mode,phase='ready',watched=watched};Hub.current=c
 local root=D.Node();root.tag='game0-ending-'..mode;root.size=D.App.bufferSize;root.order=300;root:addTo(D.Director.ui3D);c.node=root
 root:slot('Cleanup',function()if Hub.current==c then Hub.current=nil end end)
 local panel=D.Node();panel.size=D.Size(1440,900);panel.anchor=D.Vec2(0,0);panel:addTo(root)
 local bg=D.DrawNode();bg:drawPolygon({D.Vec2(0,0),D.Vec2(1440,0),D.Vec2(1440,900),D.Vec2(0,900)},D.Color(0xff101b2a));bg:addTo(panel)
 local banner=assert(D.Sprite('Image/banner.jpg'));local scale=math.min(1080/banner.width,300/banner.height);banner.scaleX=scale;banner.scaleY=scale;banner.position=D.Vec2(720,650);banner:addTo(panel)
 local label=D.Label('SourceHanSansCN-Regular',30,true);label.alignment='Center';label.textWidth=1240;label.position=D.Vec2(720,440);label.text='GAME 0 · 仍有回应\n旅程已记录';label:addTo(panel);c.label=label
 local function layout()root.size=D.App.bufferSize;local s=math.min(root.width/1440,root.height/900);panel.scaleX=s;panel.scaleY=s;panel.position=D.Vec2((root.width-1440*s)/2,(root.height-900*s)/2)end
 layout();root:gslot('AppChange',function(n)if n=='Size'then layout()end end)
 local function button(text,y,action)
  local b=require('UI.InputButton')({text=text,textBG=''});b.scaleX=.65;b.scaleY=.65;b.position=D.Vec2(720,y);b:slot('Tapped'):clear();b:addTo(panel)
  b:slot('Tapped',function()
   if c.phase~='ready'then return end;c.phase='opening'
   D.thread(function()
    local ok,why=action()
    if not ok and root.parent then c.phase='ready';c.error=why;label.text='暂时无法读取旅程，请重试。'end
   end)
  end);return b
 end
 c.continue=button('继续旅程',305,function()return Hub.openAsync('records')end)
 c.replay=button('重看终章',220,function()return require('Final.Betrayal').openAsync(true)end)
 c.explore=button('受损学院',135,function()require('Academy.Navigation').returnToRoomAsync('RDRoom');return true end)
 if mode=='records'then
  c.phase='reading'
  c.view,why=require('Ending.View').openAsync(nil,function()D.thread(function()Hub.openAsync('title')end)end)
  if not c.view then c.phase='ready';return nil,why end
 end
 return c
end
return Hub
