-- Native attribution regression, not a natural victory or OS-input test.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/mentor-input-provenance-result.json'
local r={status='RUNNING',shots={},scope='native HUD events; scripted enemy suspension; no formal mission or OS claim'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local parent=D.json.decode(D.Content:load('/private/tmp/lsd-font-input-public-clearance-20261008/result.json'),32)
  assert(parent.status=='PASS' and not D.DB:existDB('lsd'))
  local dest=D.Content.writablePath..'/mentor-input-provenance-'..os.time()..'.db'
  assert(D.Content:copyAsync(parent.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  require('Data.Config'):loadAsync();local models=assert(require('Training.FlowerPractice').models())
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0SupplyWallet')},32)end
  local before=snapshot();local b=require('Enemy.BigYingzhaoBattle').createAsync(models,nil,{virtual=true})
  local hud=require('UI.HUDControl')({weaponIcon='kineticgun'});hud.weapon.visible=true;hud:addTo(D.Director.ui3D);require('Ground.Mentor').bindAim(hud,b)
  assert(b:start());b.enemies[1].guard.nextAttack=math.huge
  for _,a in ipairs(b.learners)do a.nextDecision=math.huge end
  local function wait(f)local endAt=D.App.runningTime+8;while not f()do assert(D.App.runningTime<endAt,'Provenance timeout');D.sleep(.01)end end
  local function ready()wait(function()return b.phase=='playing' and b.mentorAim.canStart() and not b.mentorAim.shot end)end
  local function emitted(expected)
   wait(function()local s=b.bossTrace.steps[#b.bossTrace.steps];return s and s.actor=='mentor' and s.emitted==1 end)
   local s=b.bossTrace.steps[#b.bossTrace.steps];r.shots[#r.shots+1]={origin=s.origin,emitted=s.emitted,started=s.started};save();assert(s.origin==expected,'Wrong input origin: '..tostring(s.origin)..' expected '..expected)
   wait(function()return not b.mentor:isDoing('groundMentorShot') and not b.mentorAim.shot end)
  end
  for _,prior in ipairs({'unset','scripted','mentor-assistance'})do
   ready();if prior=='unset'then b.mentorActionOrigin=nil else b.mentorActionOrigin=prior end
   local original=b.mentorActionOrigin
   D.emit('Skill.Began');D.sleep(.04);D.emit('Skill.Ended',false)
   assert(b.mentorActionOrigin==original,'Manual release leaked provenance');emitted('player')
   local count=#b.bossTrace.steps;D.emit('Skill.Ended',false);D.sleep(.04)
   assert(#b.bossTrace.steps==count and b.mentorActionOrigin==original,'Duplicate release fired or leaked')
  end
  ready();b.mentorActionOrigin='mentor-assistance';assert(b.mentorAim:fireAt(0,true));emitted('mentor-assistance')
  ready();b.mentorActionOrigin=nil;assert(b:command('shoot'));emitted('scripted')
  ready();b.mentorActionOrigin='mentor-assistance';local count=#b.bossTrace.steps
  D.emit('Skill.Began');D.sleep(.04);D.emit('Skill.Ended',true);D.sleep(.04)
  assert(not b.mentorAim.held and #b.bossTrace.steps==count and b.mentorActionOrigin=='mentor-assistance')
  r.cancelPreserved=true;r.duplicatePreserved=true;r.modelsAndWalletUnchanged=snapshot()==before;assert(r.modelsAndWalletUnchanged)
  b.phase='aborted';hud:removeFromParent();b.world:removeFromParent();r.scope='3 manual HUD releases player; assisted fireAt mentor-assistance; direct command scripted; cancellation/duplicate preserve original; no actual OS/natural win claim'
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
