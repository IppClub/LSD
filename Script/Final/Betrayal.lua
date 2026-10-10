-- Story-only aftermath of an already committed evacuation victory.
local D=require('Dora');local Stage={}
function Stage.openAsync(replay)
 local service,why=require('Story.Service').open();if not service then return nil,why end
 local allowed,why=service:canRead('final-betrayal','PassageA',replay or false);if not allowed then return nil,why end
 local facts=assert(service:summary());local done=facts.completed['final-betrayal']
 local config=require('Data.Config');local mentorAsset=config.char=='charF'and 'charF'or 'charM'
 local cinematic='Spine/Final/'..mentorAsset..'.json|Spine/'..mentorAsset..'.atlas'
 local Scene=require('Scene.PassageA');Scene:loadAsync()
 for _,asset in ipairs({'sunborn','ninilite','coldweapon',cinematic})do D.Cache:loadAsync('spine:'..asset)end
 D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear()
 local world=Scene();world:addTo(D.Director.entry);D.Platformer.Data.store.world=world;require('Story.AcademyLoss').damageWorld(world)
 local c={world=world,phase='ready',mentorAsset=mentorAsset,report={version=1},clock=0,closed=false,commands={}};world.finalBetrayal=c
 local function actor(asset,x)
  local m=assert(D.Spine(asset));m.position=D.Vec2(x,world.offset);m.recovery=.2;m:play('idle',true);m:addTo(world);return m
 end
 c.mentor=actor(cinematic,1940);c.nini=actor('ninilite',2280);c.nini.fliped=true;c.lin=actor('sunborn',1450)
 local blade=assert(D.Spine('coldweapon'));blade.look='sword';blade.scaleX=.2;blade.scaleY=.2;c.lin:setSlot('melee',blade)
 world.camera.zoom=1;world.camera.position=D.Vec2(1810,330)
 local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D);ui.order=200;c.ui=ui
 local bg=D.DrawNode();bg:addTo(ui)
 local label=D.Label('SourceHanSansCN-Regular',25,true);label.outlineWidth=.16;label.outlineColor=D.Color(0xff101b28);label.anchor=D.Vec2(0,1);label.alignment='Left';label:addTo(ui);c.label=label
 local function button(text)
  local h=D.Node();h.scaleX=.5;h.scaleY=.5;h:addTo(ui);local b=require('UI.InputButton')({text=text,textBG=''});b:slot('Tapped'):clear();b:addTo(h);return b,h
 end
 local call,callHolder=button(done and '重看终章交谈'or '呼叫羽凌灵');c.call=call
 local back,backHolder=button('返回受损学院');c.back=back
 local ending,endingHolder=button('旅程回顾与署名');ending.visible=false;c.ending=ending
 ending:slot('Tapped',function()D.thread(function()local view,why=require('Ending.View').openAsync(world,function()D.thread(function()require('Ending.Hub').openAsync('title')end)end);c.endingView=view;if not view then label.text='旅程记录暂不可用，请重试。';c.error=why end end)end)
 local function layout()
  ui.size=D.App.bufferSize;label.position=D.Vec2(30,ui.height-25);label.textWidth=ui.width-350
  backHolder.position=D.Vec2(ui.width-205,ui.height-65);callHolder.position=D.Vec2(ui.width-205,ui.height-145);endingHolder.position=callHolder.position
  bg:clear();bg:drawPolygon({D.Vec2(0,ui.height-120),D.Vec2(ui.width,ui.height-120),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xdd101b28))
 end
 layout();ui:gslot('AppChange',function(n)if n=='Size'then layout()end end)
 local originalScale,originalEffect
 local function dispose()
  c.closed=true
  for name,e in pairs(c.commands)do if require('System.Command')[name]==e.fn then require('System.Command')[name]=e.previous end end
  if originalScale then D.View.scale=originalScale;D.View.postEffect=originalEffect end
  if ui.parent then ui:removeFromParent()end
 end
 world:slot('Cleanup',dispose)
 back:slot('Tapped',function()
  if c.phase=='saving'or (c.flow and (c.flow.phase=='saving'or c.flow.phase=='save-error'))then label.text='终章记录尚未保存，请先重试保存。';return end
  if c.closed or world.data.journalOpen then return end;c.closed=true
  D.thread(function()require('Academy.Navigation').returnToRoomAsync('RDRoom')end)
 end)
 local function install(name,action)
  local commands=require('System.Command');local e={previous=rawget(commands,name)};c.commands[name]=e
  e.fn=function()
   D.thread(function()
    local view=world.storyFlow.view;local scale,effect=D.View.scale,D.View.postEffect
    view.visible=false;D.View.scale=view._viewScale or scale;D.View.postEffect=view._viewEffect
    action()
    if not c.closed then view.visible=true;D.View.scale=scale;D.View.postEffect=effect;D.emit('Story.Advance')end
   end)
   coroutine.yield('Command')
  end;commands[name]=e.fn
 end
 function c:request()
  if self.phase~='ready'or self.closed then return nil,'BUSY'end
  originalScale,originalEffect=D.View.scale,D.View.postEffect;self.phase='dialogue';call.visible=false
  install('finalFreezeClock',function()
   self.frozenClock=self.clock;self.report.clockBefore=self.clock;self.report.freezeStarted=D.App.runningTime
   D.sleep(.7);self.report.clockAfter=self.clock;self.report.freezeObserved=D.App.runningTime
  end)
  install('finalBetrayalStrike',function()
   self.phase='action';local p=require('Final.BetrayalAction').playAsync(self);if self.closed then return end
   self.report.action=p;self.phase='dialogue'
  end)
  local flow,why=require('Story.Flow').openAsync('final-betrayal',world,function()
   self.phase='complete';self.report.clockEnd=self.clock;ending.visible=true
   label.text='仍有回应\n妮妮莉特：那就回应我。';call.visible=false
  end,done or false)
  self.flow=flow;if not flow then self.phase='ready';call.visible=true end;return flow,why
 end
 call:slot('Tapped',function()D.thread(function()c:request()end)end)
 ui:schedule(function(dt)
  if not c.frozenClock then c.clock=c.clock+dt end
  if c.phase~='complete'then label.text=string.format('撤离终端 · %s\n通讯计时 %05.1f · %s',done and '终章回看'or'等待回应',c.clock,c.frozenClock and '信道无回应'or'正在呼叫羽凌灵')end
  return false
 end)
 return c
end
return Stage
