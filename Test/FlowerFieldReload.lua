local script,source=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script));local out=root..'/Test/flower-field-reload-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-field%-evaluation%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-field-reload-'..os.time()..'.db';assert(D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  D.App.winSize=D.Size(960,540)
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',nil,nil,nil,'field');D.sleep(1)
  assert(c.comparison.profile=='field' and c.label.text:find('默认补给') and c.label.text:find('基础失败 / 候选失败') and not c.hud.visible)
  assert(not c.arena.closed and c.battle.phase=='ready')
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-field-comparison.tga');D.sleep(.1)
  c.scenarioButton:emit('Tapped');local deadline=D.App.totalTime+5
  repeat D.sleep(.05);local ui=D.Director.ui3D:getChildByTag('flower-practice-controls');if ui and ui~=c.ui then c=ui.practice;break end;assert(D.App.totalTime<deadline)until false
  D.sleep(.1);assert(not c.scenario and c.battle.support.gold==90)
  r.readback=true;r.failedPairVisible=true;r.fieldHUDHidden=true;r.standardRestored=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
