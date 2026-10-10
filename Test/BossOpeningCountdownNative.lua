-- Visible completed-opening timing and arena geometry; controlled native label.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/boss-opening-countdown-result.json';local r={status='RUNNING',controlledFixture=true,osInput=false,naturalVictory=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local M=require('Ground.BigYingzhaoLevel');local S=require('Ground.LifeSupport').new(45,'defence');S.machineHP=30
  local bossUnit={x=3300,y=300,faceRight=true,playable={current='idle'}}
  local guard={unit=bossUnit,waves={},busy=false,strike={skill='massive',completed=D.App.runningTime-.1,recoveryDuration=4},nextAttack=D.App.runningTime+3.9}
  local machine={x=3590,y=300,unitDef={size={width=140,height=160}}}
  local visible=true;local boss={enemy=bossUnit,enemyHP=1000,guard=guard}
  local b={phase='playing',support=S,machine=machine,minX=200,maxX=3640,bossCombat={boss=boss,armor={available=function()return visible end}}}
  local controls=D.Node();controls.size=D.App.bufferSize;controls:addTo(D.Director.ui3D)
  local label=D.Label('SourceHanSansCN-Regular',22);label.alignment='Left';label.textWidth=480;label.anchor=D.Vec2(0,1);label:addTo(controls)
  local function check(name,fragment,timer)
   local before=D.json.encode(S,false,true);local text,red=M.supportWarningText(b)
   assert(text:find(fragment,1,true),name..': '..text)
   assert((text:match('%d+%.%ds')~=nil)==timer,name..' timer')
   assert(red and text:find('机体危急',1,true),'Critical state lost')
   assert(before==D.json.encode(S,false,true),'Opening cue mutated support')
   label.text=text;label.color3=D.Color3(red and 0xff756d or 0xffcf72);D.sleep(.03);assert(label.height<=88,'Opening cue escaped four-line area')
   r.cases[#r.cases+1]={name=name,text=text,height=label.height};save()
  end
  guard.nextAttack=D.App.runningTime+3.9;check('right-edge','向左整队换位',true)
  guard.nextAttack=D.App.runningTime+1.2;check('finite-countdown','1.2s',true)
  bossUnit.x=500;bossUnit.faceRight=false;machine.x=250;guard.nextAttack=D.App.runningTime+3.9;check('left-edge','向右整队换位',true)
  bossUnit.x=1000;bossUnit.faceRight=true;machine.x=1400;check('room-available','瞄准已破甲部位',true)
  guard.nextAttack=D.App.runningTime-.1;check('expired-no-opening','Boss正面',false)
  guard.nextAttack=D.App.runningTime+3.9;guard.busy=true;check('busy-no-countdown','Boss正面',false);guard.busy=false
  guard.reacting=D.App.runningTime;check('reacting-no-countdown','Boss正面',false);guard.reacting=nil
  visible=false;check('hidden-no-countdown','机体危急',false);visible=true
  boss.enemyHP=0;check('defeated-no-countdown','机体危急',false);boss.enemyHP=1000
  guard.waves={{active=true,x=1100,travel=100,direction=1,visual={parent=true,visible=true}}};check('live-wave-priority','波技能路径',false);guard.waves={}
  b.phase='ready';check('ready-no-countdown','Boss正面',false);b.phase='playing'
  machine.x=3590;bossUnit.x=3300;S.gold=1;check('low-energy-critical','向左整队换位',true)
  r.screenshots={};local size=D.App.winSize
  for _,v in ipairs({{960,540,'1920'},{683,384,'1366'}})do
   D.App.winSize=D.Size(v[1],v[2]);D.sleep(.1);controls.size=D.App.bufferSize;label.position=D.Vec2(D.App.bufferSize.width-510,D.App.bufferSize.height-255)
   guard.nextAttack=D.App.runningTime+3.9;check('layout-'..v[3],'向左整队换位',true)
   local p=D.Path(D.Content.writablePath,'opening-countdown-'..v[3]..'.tga');D.App:saveScreenshot(p);D.sleep(.05)
   r.screenshots[#r.screenshots+1]={path=p,width=D.App.bufferSize.width,height=D.App.bufferSize.height,labelHeight=label.height,text=label.text}
  end
  D.App.winSize=size;controls:removeFromParent();r.scope='Read-only opening timing/arena-side cue and native label layout; controlled state, not formal Boss victory or whole UI acceptance'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
