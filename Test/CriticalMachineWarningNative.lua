-- Controlled warning geometry and real native text layout; no gameplay completion.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/critical-machine-warning-result.json'
local r={status='RUNNING',scope='critical-support-warning-with-visible-risk',osInput=false,cases={}};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local S=require('Ground.LifeSupport').new(45,'defence');local M=require('Ground.BigYingzhaoLevel');local visible=true
  local u={x=1000,y=300,faceRight=true,playable={current='idle'}};local machine={x=1500,y=300,unitDef={size={width=140,height=160}}}
  local boss={enemy=u,enemyHP=1000};local b={support=S,machine=machine,bossCombat={boss=boss,armor={available=function()return visible end}}}
  local label=D.Label('SourceHanSansCN-Regular',22);label.alignment='Left';label.textWidth=480;label.position=D.Vec2(500,400);label:addTo(D.Director.ui3D)
  local function check(name,risk,critical,danger)
   local before=D.json.encode(S,false,true);local text,red=M.supportWarningText(b);label.text=text;D.sleep(.03)
   local found=risk and text:find(risk,1,true)~=nil or not risk and not text:find('Boss',1,true) and not text:find('波技能路径',1,true)
   local hasCritical=text:find('机体危急',1,true)~=nil
   local clean=before==D.json.encode(S,false,true)
   local energyVisible=not risk or S.gold~=1 or text:find('金粉将尽',1,true)~=nil
   local passed=not not(found and hasCritical==critical and red==danger and clean and energyVisible and label.height<=88)
   r.cases[#r.cases+1]={name=name,text=text,danger=red,height=label.height,width=label.width,risk=risk,critical=critical,supportUnchanged=clean,passed=passed};save()
  end
  check('ordinary-visible-front','Boss正面',false,false)
  S.machineHP=30;check('critical-visible-front','Boss正面',true,true)
  S.gold=1;check('critical-low-energy-visible-front','Boss正面',true,true)
  S.machineHP=100;check('low-energy-visible-front','Boss正面',false,false)
  S.machineHP=30;S.gold=45;machine.x=1900;u.playable.current='wave';boss.guard={unit=u,direction=1,waves={}}
  check('critical-visible-wave','波技能路径',true,true)
  visible=false;check('hidden-boss-does-not-reveal',nil,true,true);visible=true
  machine.x=2500;u.playable.current='idle';boss.guard=nil;check('critical-outside-no-false-risk',nil,true,true)
  machine.x=1500;S.machineHP=0;check('destroyed-stays-terminal',nil,false,true)
  S.machineHP=30;S.gold=0;check('unpowered-stays-withdrawal',nil,false,true)
  S.gold=45;S.machineHP=100;machine.x=1200;u.playable.current='punch'
  local guard={unit=u,direction=1,waves={}};boss.guard=guard
  local function pose(skill,stage,elapsed,duration)
   guard.strike={skill=skill};guard.sequence={status='playing',index=stage,started=D.App.runningTime-elapsed,duration=duration};u.playable.current=skill
  end
  for _,state in ipairs({{name='ordinary',hp=100,gold=45},{name='critical',hp=30,gold=45},{name='critical-low-energy',hp=30,gold=1},{name='low-energy',hp=100,gold=1}})do
   S.machineHP=state.hp;S.gold=state.gold
   pose('punch',1,1.3,2.0666666)
   check(state.name..'-visible-recovery','收招，整队仍在正面',state.hp<=30,state.hp<=30)
   pose('hero',2,.7,2);u.playable.current='hero2'
   check(state.name..'-visible-follow-up','连招尚未结束',state.hp<=30,true)
  end
  b.mentor={x=1500,y=300};b.mentorHP=100;b.world={offset=230};S.x=1200
  b.physicalShield=require('Ground.PhysicalShield').new(S,D.App.runningTime)
  S.machineHP=30;S.gold=1;pose('punch',1,.5,2.0666666)
  check('mentor-outside-critical-low-energy-punch','拳击前摇',true,true)
  assert(r.cases[#r.cases].text:find('导师在护盾外',1,true))
  b.mentor.x=1440;check('mentor-on-inclusive-shield-edge','拳击前摇',true,true)
  assert(not r.cases[#r.cases].text:find('导师在护盾外',1,true))
  label:removeFromParent();assert(#r.cases==19)
  for _,c in ipairs(r.cases)do assert(c.passed,'Warning requirement failed: '..c.name)end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
