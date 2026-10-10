local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-target-review-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local previous=assert(D.json.decode(D.Content:load(root..'/Test/flower-target-demo-result.json'),32));assert(previous.status=='PASS')
  local source=previous.database;assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-target%-demo%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-target-review-'..os.time()..'.db';assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local rows=assert(require('Training.FlowerTrialStore').history('ninilite'));assert(#rows>=3)
  for _,row in ipairs(rows)do assert(require('Training.FlowerTrialStore').validate(row));assert(row.episode.versions.aim==1 and row.setup.bossScale==1)end
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',nil,nil,nil,'field');assert(c.candidate.actionSetVersion==5 and #c.candidate.sourceEpisodes==1)
  local history=assert(require('Training.FlowerPracticeStore').history('ninilite'));assert(#history==3 and c.candidate.sourceEpisodes[1]==history[#history].episode)
  local comparison=assert(c.comparison);assert(comparison.basic.aimedShots~=nil and comparison.candidate.aimedShots~=nil)
  local text=require('Training.FlowerComparison').text(comparison);assert(text:find('正确部位') and text:find('0/0'))
  for _,record in ipairs(rows)do
   local aim=record.evaluation.aim.actors.ninilite
   assert(aim.emitted==aim.aimed+aim.unknownIntent+aim.redirected+aim.unresolved)
   assert(aim.aimed==aim.correct+aim.wrongPart+aim.otherEnemy+aim.friendly+aim.missOrBlocked)
  end
  D.App.winSize=D.Size(1000,750);D.sleep(1)
  assert(c.label.text:find('未学到攻击') and c.label.text:find('候选动作：后退') and c.label.text:find('正确部位') and not c.hud.visible and c.learnLatestButton.visible)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-target-review.tga');D.sleep(.2)
  r.learnedActions=require('Training.FlowerPolicy').learnedActionsText(c.candidate);r.comparison=comparison;r.countsReconciled=true;r.readback=true;r.humanInputHidden=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
