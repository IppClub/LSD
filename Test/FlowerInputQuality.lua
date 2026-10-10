-- Input lifecycle fixtures and diagnostics on an archived QA demonstration.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-input-quality-result.json'
D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-committed-combat-result.json'),32))
  assert(prior.status=='PASS' and D.Path:getFilename(prior.database):match('^flower%-committed%-combat%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-input-quality-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local P=require('Training.FlowerPolicy');local history=assert(require('Training.FlowerPracticeStore').history('ninilite'));local latest=history[#history]
  local report=assert(P.inspect({latest},'ninilite'));assert(report.coverage.total==52 and report.coverage.knownUnarmoredShots==2)
  assert(P.coverageText(report.coverage):find('已知无甲部位仍发射EMP：2次',1,true));r.coverage=report.coverage
  local unknown=D.json.decode(D.json.encode(latest),32)
  for _,step in ipairs(unknown.steps)do for key in pairs(require('Training.FlowerFeatures').parts)do step.observation['part_'..key]='unknown' end end
  local changed=assert(P.inspect({unknown},'ninilite'));assert(changed.coverage.knownUnarmoredShots==0 and changed.coverage.total==report.coverage.total)
  r.noOutcomeBackfill=true
  D.App.winSize=D.Size(1000,750)
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite');D.sleep(.5)
  assert(c.label.text:find('已知无甲部位仍发射EMP',1,true))
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-input-quality.tga');D.sleep(.2)
  c.startButton:emit('Tapped')
  local b=c.battle;local a=c.arena
  for _,e in ipairs(b.roots)do e.enemyCombat:close()end
  for _,learner in ipairs(b.learners)do learner.nextDecision=math.huge end
  local command=b.command;b.command=function(self,action)if action=='shoot'then return false end;return command(self,action)end
  D.sleep(.1)
  c.hud.move:emit('Right',true);D.sleep(.1);assert(a.student:isDoing(a.physical.fmove) or a.student:isDoing(a.physical.bmove))
  local function count()local n=0;for _,step in ipairs(b.partCombat.journal.steps)do if step.action.actor=='ninilite'then n=n+1 end end;return n end
  -- Keep the actual mentor attack animation in progress after fixture enemies
  -- disappear, reproducing the interval that previously generated frame samples.
  local deadline=D.App.totalTime+5
  while b.mentor:isDoing('groundMentorShot')do assert(D.App.totalTime<deadline);D.sleep(.01)end
  assert(command(b,'shoot'))
  for _,enemy in ipairs(b.enemies)do enemy.enemyHP=0;enemy.enemy.position=enemy.enemy.position+D.Vec2(0,3000) end
  D.sleep(.04);assert(b.phase=='playing' and b.mentor:isDoing('groundMentorShot'))
  local before=count();assert(a.enemyHP==0 and not a:available('fmove') and not a:available('idle') and not a:available('laser'))
  for i=1,8 do
   c.hud.move.onMove('keyRight',true);c.wait:emit('TapBegan');c.hud.weapon:emit('TapBegan');c.hud.weapon:emit('TapEnded');D.sleep(.016)
  end
  assert(count()==before,'Cleared encounter accepted frame-length demonstrations');assert(not c.aim.held)
  c.hud.move:emit('Right',false);r.noPostClearActions=true
  while not c.result do assert(D.App.totalTime<deadline,tostring(b.phase)..':'..tostring(b.saveError));D.sleep(.02)end
  local valid,reason=require('Training.CombatStore').validate(c.result.episode);assert(valid,reason);r.resolved=b.phase
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
