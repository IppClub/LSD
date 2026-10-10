-- Reopen the exact completed evaluation database and verify current UI/history.
local script,source=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script))
local out=root..'/Test/flower-heldout-reload-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-heldout%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-heldout-reload-'..os.time()..'.db';assert(not D.Content:exist(dest) and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  require('Data.Config'):loadAsync()
  local Store=require('Training.FlowerTrialStore');local old=Store.history;local reads=0;Store.history=function(...)reads=reads+1;return old(...)end
  local P=require('Training.FlowerPractice');local c=P.openAsync(nil,'ninilite');assert(reads==1,'Repeated history reads on entry')
  assert(c.generalization and c.generalization.completed==3 and c.generalization.required==3 and not c.generalization.adoptionEligible)
  for _,id in ipairs(require('Training.FlowerScenarios').ids)do
   local pair=c.generalization.pairs[id];assert(pair and pair.profile==id and pair.basicEpisode~=pair.candidateEpisode)
  end
  local wu=P.openAsync(nil,'wuyun');assert(wu.generalization and wu.generalization.completed==0,'Cross-learner evidence leaked')
  local c=P.openAsync(nil,'ninilite',nil,nil,nil,'reproduction')
  assert(c.profile.id=='reproduction' and c.battle.roots[3].enemyCombat.bossPhase==2 and c.battle.partCombat.target.damage.parts['flower-core'].ap==0)
  D.App.winSize=D.Size(683,384);D.sleep(.5);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-heldout-reloaded.tga');D.sleep(.2)
  local accepted,why=c:start();assert(not accepted and why=='EVALUATION_ONLY')
  r.singleReadOnEntry=true;r.fullCoverageReloaded=true;r.characterIsolation=true;r.profileReloaded=true;r.generalization=c.generalization
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
