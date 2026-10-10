local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-wait-native-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-medical-visit-qa-1791007987.db';local dest=D.Content.writablePath..'/flower-wait-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite');D.sleep(.3);c.startButton:emit('Tapped');D.sleep(.2)
  for _,e in ipairs(c.battle.roots)do e.enemyCombat:close()end
  local function count()local n=0;for _,s in ipairs(c.battle.partCombat.journal.steps)do if s.action.actor=='ninilite' and s.action.name=='idle'then n=n+1 end end;return n end
  local before=count();c.wait:emit('TapBegan');D.sleep(.1);assert(count()==before+1)
  for i=1,20 do c.hud.move.onMove('keyLeft',false);c.hud.move.onMove('keyRight',false);c.wait:emit('TapBegan');D.sleep(.05)end
  assert(count()==before+1 and c.arena.student:isDoing(c.arena.physical.idle),'Neutral/repeated wait split an ongoing action')
  c.hud.move:emit('Right',true);D.sleep(.2);c.hud.move:emit('Right',false);D.sleep(.1)
  assert(not c.arena.student:isDoing(c.arena.physical.fmove) and not c.arena.student:isDoing(c.arena.physical.bmove))
  c.finishButton:emit('Tapped');local endAt=D.App.totalTime+8;while not c.result do assert(D.App.totalTime<endAt);D.sleep(.02)end
  for _,s in ipairs(c.result.episode.steps)do if s.action.actor=='ninilite' and s.action.name=='idle'then assert(s.sealed and s.finished-s.started>=1);r.waitSeconds=s.finished-s.started end end
  local candidateBefore=c.candidate;local history=assert(require('Training.FlowerPracticeStore').history('ninilite'))
  local built,why=c:learnAsync('latest');assert(not built and why=='TOO_FEW_SAMPLES' and c.candidate==candidateBefore)
  assert(#assert(require('Training.FlowerPracticeStore').history('ninilite'))==#history)
  local bad,reason=c:learnAsync('unknown');assert(not bad and reason=='INVALID_LEARNING_SCOPE')
  r.continuousWait=true;r.movementRelease=true;r.shortLatestPreservesCandidate=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
