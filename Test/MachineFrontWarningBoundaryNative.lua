-- Controlled geometry/priority fixture only, not a playable Boss completion.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/machine-front-warning-boundary-result.json'
local r={status='RUNNING',scope='controlled-warning-geometry-and-priority',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local S=require('Ground.LifeSupport').new(45,'defence');local M=require('Ground.BigYingzhaoLevel')
  local visible=true;local u={x=1000,y=300,faceRight=false};local machine={x=500,y=300}
  local boss={enemy=u,enemyHP=1000};local b={support=S,machine=machine,bossCombat={boss=boss,armor={available=function()return visible end}}}
  local function expect(name,risk,danger)
   local before=D.json.encode(S,false,true);local text,red=M.supportWarningText(b)
   assert((text:find('Boss正面',1,true)~=nil)==risk,name..' warning mismatch');assert(red==danger,name..' severity mismatch')
   assert(before==D.json.encode(S,false,true),'Warning mutated life support');r.cases[#r.cases+1]={name=name,text=text,danger=red}
  end
  expect('visible-front-500',true,false)
  machine.x=160;expect('authored-advance-840',true,false)
  machine.x=159.99;expect('outside-840',false,false)
  machine.x=1000.01;expect('behind-left-facing',false,false)
  u.faceRight=true;machine.x=1840;expect('right-facing-840',true,false)
  machine.x=1840.01;expect('right-outside',false,false)
  machine.x=1500;machine.y=630;expect('vertical-330',true,false)
  machine.y=630.01;expect('vertical-outside',false,false)
  machine.y=300;visible=false;expect('hidden-no-revealed-risk',false,false)
  visible=true;boss.enemyHP=0;expect('defeated-no-risk',false,false)
  boss.enemyHP=1000;S.machineHP=30;expect('critical-machine-with-front',true,true)
  S.machineHP=100;S.gold=1;expect('low-energy-with-front',true,false)
  S.gold=0;expect('stopped-field-priority',false,true)
  S.gold=45;S.machineHP=0;expect('destroyed-machine-priority',false,true)
  assert(#r.cases==14)
  S.machineHP=100;S.gold=45;machine.y=300;machine.unitDef={size={width=140,height=160}}
  u.playable={current='wave'};u.faceRight=true
  boss.guard={unit=u,direction=1,waves={}}
  local function waveCase(name,wanted)
   local before=D.json.encode(S,false,true);local text,red=M.supportWarningText(b)
   assert((text:find('波技能路径',1,true)~=nil)==wanted,name..' wave warning mismatch')
   if wanted then assert(red,'Wave exposure must be urgent')end
   assert(before==D.json.encode(S,false,true),'Wave warning changed support')
   r.cases[#r.cases+1]={name=name,text=text,danger=red}
  end
  machine.x=1900;waveCase('wave-beyond-melee-advance',true)
  machine.x=2250;waveCase('wave-outside-finite-range',false)
  machine.x=800;waveCase('wave-behind-boss',false)
  boss.guard.direction=-1;u.faceRight=false;machine.x=100;waveCase('wave-left-telegraph',true)
  visible=false;waveCase('hidden-boss-no-telegraph-reveal',false);visible=true
  u.playable.current='idle';machine.x=1300
  local visual={parent=true,visible=true}
  boss.guard.waves={{active=true,visual=visual,x=1100,travel=100,direction=1}}
  waveCase('live-front-after-animation',true)
  visual.visible=false;waveCase('hidden-wave-no-reveal',false);visual.visible=true
  machine.x=1050;waveCase('body-overlap-front',true)
  machine.x=900;waveCase('already-behind-live-front',false)
  machine.x=1400;boss.guard.waves[1].active=false;waveCase('ended-wave-no-alert',false)
  boss.guard.waves[1].active=true;S.machineHP=30;waveCase('critical-machine-with-wave',true)
  S.machineHP=100;boss.enemyHP=0;waveCase('defeated-boss-no-wave-alert',false)
  assert(#r.cases==26)
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
