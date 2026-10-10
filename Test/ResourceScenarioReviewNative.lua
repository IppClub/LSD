local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-scenario-review-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-scenario-trials-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-scenario%-trials%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-scenario-review-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local rows=assert(require('Training.ResourceC45Trials').history('ninilite'));assert(#rows==4)
  local models=rows[1].setup.models;local policy=assert(require('Training.ResourcePolicyStore').loadAsync('ninilite'))
  local M=require('Training.ResourceBudgetReview');local review=M.build(policy,models,rows);assert(#review.groups==2)
  for _,g in ipairs(review.groups)do assert(g.quote.total==160 and #g.pairs==1)end
  local S=require('Training.ResourceDemoStore');local demos=assert(S.history('ninilite'));local bad=D.json.decode(D.json.encode(demos[1],false,true),32);bad.episode=bad.episode..'-evaluation';bad.practiceProfile='exposed'
  local yes,why=S.saveAsync('ninilite','aborted',bad);assert(not yes and why=='INVALID_RESOURCE_DEMO')
  assert(require('Training.ResourcePolicy').inspect({bad},'ninilite').coverage.total==0)
  assert(#assert(S.history('ninilite'))==#demos)
  local loadout={};for _,line in ipairs(rows[1].episode.resources.quote.lines)do loadout[#loadout+1]={actor=line.actor,item=line.item,quantity=line.quantity}end
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',nil,models,nil,'exposed',nil,loadout);D.sleep(.2)
  assert(c.label.text:find('已知全身破甲 · 预算160',1,true)and c.label.text:find('近距完整护甲 · 预算160',1,true))
  r.text=M.text(review);r.finalHP={};for _,row in ipairs(rows)do r.finalHP[#r.finalHP+1]={scenario=row.setup.profile.id,controller=row.controller,hp=row.finalHP,status=row.status}end
  r.checks={'evaluation source cannot become demonstration','classifier excludes evaluation-profile demos','two same-budget scenarios remain separate','player scenario review displayed'}
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/resource-scenario-review.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
