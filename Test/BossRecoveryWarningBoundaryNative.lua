-- Controlled visible-state warning boundaries; no natural victory claim.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/boss-recovery-warning-boundary-result.json'
local r={status='RUNNING',controlledFixture=true,naturalVictory=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local T=require('Training.YingzhaoTiming');local M=require('Ground.BigYingzhaoLevel')
  local support=require('Ground.LifeSupport').new(45,'defence')
  local u={x=1000,y=300,faceRight=true,playable={current='punch'}}
  local machine={x=1200,y=300,unitDef={size={width=140,height=160}}}
  local actor={x=1300,y=300,visible=true,opacity=1,unitDef={size={width=80,height=200}}}
  local visible=true;local hp=100
  local guard={unit=u,direction=1,waves={}}
  local boss={enemy=u,enemyHP=1000,guard=guard}
  local b={support=support,machine=machine,bossCombat={boss=boss,armor={available=function()return visible end}},targets=function()return {{unit=actor,hp=function()return hp end}}end}
  local function pose(skill,stage,elapsed,duration)
   guard.strike={skill=skill};guard.sequence={status='playing',index=stage,started=D.App.runningTime-elapsed,duration=duration};u.playable.current=skill
  end
  local function expect(name,fragment,red)
   local before=D.json.encode(support,false,true);local text,danger=M.supportWarningText(b)
   assert(fragment==''and text==''or fragment~=''and text:find(fragment,1,true),name..': '..text);assert(danger==red,name..' severity')
   assert(D.json.encode(support,false,true)==before,'Warning changed support state')
   r.cases[#r.cases+1]={name=name,text=text,danger=danger}
  end
  pose('punch',1,.5,2.0666666);expect('punch-front-windup','拳击前摇',true)
  pose('punch',1,1.3,2.0666666);expect('punch-recovery-not-safe-promise','收招，整队仍在正面',false)
  pose('massive',1,.6,2.9333333);expect('massive-more-impacts','连斩正在推进',true)
  pose('massive',1,1.75,2.9333333);expect('massive-last-impact-recovery','收招，整队仍在正面',false)
  pose('hero',2,.7,2);u.playable.current='hero2';expect('hero-intermediate-recovery','连招尚未结束',true)
  pose('hero',4,.7,2);u.playable.current='hero2';expect('hero-before-finisher','连招尚未结束',true)
  pose('hero',5,.7,2);u.playable.current='hero3';expect('hero-final-tail','收招，整队仍在正面',false)
  pose('wave',1,2.6,4);expect('machine-wave-priority','机体处于波技能路径',true)
  u.playable.current='idle';machine.x=800;guard.waves={{active=true,x=1100,travel=100,direction=1,visual={parent=true,visible=true}}}
  expect('party-live-wave-after-clip','队员处于波技能路径',true)
  guard.waves[1].visual.visible=false;pose('punch',1,.5,2.0666666);expect('hidden-wave-only-visible-punch','拳击前摇',true)
  guard.waves[1].visual.visible=true;actor.visible=false;guard.sequence.status='complete';expect('hidden-party-not-revealed','',false)
  actor.visible=true;hp=0;expect('dead-party-not-revealed','',false)
  hp=100;guard.waves[1].active=false;pose('punch',1,.5,2.0666666);expect('ended-wave-punch-only','拳击前摇',true)
  actor.x=1500;expect('punch-outside-hit-reach','队员处于Boss正面',false)
  actor.y=630.01;expect('party-outside-vertical','',false)
  actor.y=300;actor.x=1300;visible=false;expect('hidden-boss','',false)
  visible=true;support.machineHP=30;expect('critical-machine-first','机体',true)
  support.machineHP=100;support.gold=0;expect('no-energy-first','停机',true)
  support.gold=45;boss.enemyHP=0;expect('defeated-boss','',false)
  support.gold=45;support.machineHP=100;boss.enemyHP=1000;visible=true;hp=100;actor.visible=true;actor.x=1300;actor.y=300;machine.x=800;guard.waves={};u.playable.current='idle'
  b.phase='playing';guard.sequence.status='complete';guard.strike={skill='massive',completed=D.App.runningTime-.1,recoveryDuration=4};guard.nextAttack=D.App.runningTime+3.9
  expect('completed-heavy-opening','收招停顿',false)
  guard.busy=true;expect('busy-not-post-attack','队员处于Boss正面',false);guard.busy=false
  guard.reacting=D.App.runningTime;expect('hit-not-post-attack','队员处于Boss正面',false);guard.reacting=nil
  guard.nextAttack=D.App.runningTime-.01;expect('expired-opening','队员处于Boss正面',false);guard.nextAttack=D.App.runningTime+3.9
  visible=false;expect('hidden-opening-not-revealed','',false);visible=true
  support.machineHP=30;expect('critical-machine-over-opening','机体',true);support.machineHP=100
  support.gold=0;expect('energy-over-opening','停机',true);support.gold=45
  guard.waves={{active=true,x=1100,travel=100,direction=1,visual={parent=true,visible=true}}};expect('live-party-wave-over-opening','队员处于波技能路径',true);guard.waves={}
  b.phase='ready';expect('ready-not-opening','队员处于Boss正面',false);b.phase='playing'
  boss.enemyHP=0;expect('defeated-not-opening','',false);boss.enemyHP=1000
  local raw={skill='hero',stage=2,started=0,duration=2}
  local tail,kind=T.recoveryTail(raw,.7);assert(not tail and kind=='follow-up')
  raw.stage=5;tail,kind=T.recoveryTail(raw,.7);assert(math.abs(tail-1.3)<.001 and kind=='recovery')
  raw={skill='massive',stage=1,started=0,duration=2.9333333}
  assert(not T.recoveryTail(raw,1.6));tail=T.recoveryTail(raw,1.8);assert(tail and tail>1)
  assert(not T.recoveryTail(raw,3));assert(not T.recoveryTail({skill='bad',stage=1,started=0,duration=2},1))
  assert(not T.recoveryTail({skill='punch',stage=1,started=2,duration=2},1))
  assert(T.project({skill='hero',stage=2,started=0,duration=2},.7)=='recovery','Existing stage observation changed')
  r.timingContractUnchanged=true;r.wholeSkillTailValidated=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
