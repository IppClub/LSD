local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-budget-review-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-restraint-matrix-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-restraint%-matrix%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-budget-review-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local rows=assert(require('Training.ResourceC45Trials').history('ninilite'));assert(#rows==8)
  local models=rows[1].setup.models;local policy=assert(require('Training.ResourcePolicyStore').loadAsync('ninilite'))
  local M=require('Training.ResourceBudgetReview');local review=M.build(policy,models,rows);assert(#review.groups==3 and not review.adoptionEligible)
  local total=0;for _,g in ipairs(review.groups)do total=total+#g.pairs;if g.quote.total==50 then assert(g.jointWins==0 and g.candidateWins==0 and g.basicWins==0)elseif g.quote.total==160 then assert(#g.pairs==2 and g.basicWinningCost==210 and g.candidateWinningCost==164)end end;assert(total==4)
  for _,g in ipairs(review.groups)do assert(g.basicFacts.known==0 and g.basicFacts.unknown==#g.pairs and g.candidateFacts.known==0)end
  -- Synthetic copies exercise reporting only; never save them as battle evidence.
  local fixture=D.json.decode(D.json.encode(rows,false,true),32)
  for _,row in ipairs(fixture)do
   row.episode.versions.outcome=1
   row.episode.outcome={version=1,enemiesRemaining=0,partyAlive=true,niniliteHit=true,wuyunHit=true,confusionCleared=true,injury=true}
   if row.episode.resources.quote.total==50 then
    if row.controller=='candidate'then row.episode.outcome.niniliteHit=false else row.episode.outcome.enemiesRemaining=2 end
   end
  end
  local f=M.build(policy,models,fixture);assert(#f.groups==3)
  for _,g in ipairs(f.groups)do if g.quote.total==50 then assert(g.basicFacts.cleared==0 and g.candidateFacts.cleared==1 and g.candidateFacts.storyMissing==1 and g.jointWins==0)end end
  local mixed={};for _,row in ipairs(rows)do mixed[#mixed+1]=row end
  for _,row in ipairs(fixture)do row.episode.episode=row.episode.episode..'-fixture';mixed[#mixed+1]=row end
  assert(#M.build(policy,models,mixed).groups==6,'Old and new measurement versions merged')
  local duplicate={};for _,row in ipairs(rows)do duplicate[#duplicate+1]=row;duplicate[#duplicate+1]=row end
  local again=M.build(policy,models,duplicate);local pairs=0;for _,g in ipairs(again.groups)do pairs=pairs+#g.pairs end;assert(pairs==4,'Repeated episodes counted twice')
  local oneBasic={};local kept=false
  for _,row in ipairs(rows)do if row.episode.resources.quote.total==160 then if row.controller=='candidate'or not kept then oneBasic[#oneBasic+1]=row end;if row.controller=='basic'then kept=true end end end
  local limited=M.build(policy,models,oneBasic);assert(#limited.groups==1 and #limited.groups[1].pairs==1,'Baseline reused')
  assert(#M.build({},models,rows).groups==0)
  local values={};for _,line in ipairs(rows[1].episode.resources.quote.lines)do values[#values+1]={actor=line.actor,item=line.item,quantity=line.quantity}end
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',nil,models,nil,nil,nil,values);D.sleep(.3)
  assert(c.resourceBudgetReview and #c.resourceBudgetReview.groups==3 and c.label.text:find('预算50：任务完成0/1 / 0/1',1,true))
  r.text=M.text(review);r.checks={'eight saved trials rebuilt','separate three budgets','disjoint pairs only','duplicates ignored','no cost benefit from failed pairs','player UI displayed'}
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/resource-budget-review.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
