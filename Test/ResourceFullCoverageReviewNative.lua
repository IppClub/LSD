local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-full-coverage-review-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-q-full-coverage-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-q%-full%-coverage%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-full-coverage-review-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local candidate=assert(require('Training.ResourceQStore').loadLatestAsync());local records=assert(require('Training.ResourceQTrials').loadAsync(candidate.id));assert(#records==10)
  r.costDiagnostics={}
  for _,entry in ipairs(records)do
   if entry.record.mode=='evaluate'then
    local d={empCost=0,fallbackEmpCost=0,zeroProgressEmpCost=0,qDecisions=0,fallbackDecisions=0}
    for _,actor in ipairs({'ninilite','wuyun'})do
     local a=assert(entry.facts.telemetry.actors[actor])
     for _,key in ipairs({'empCost','fallbackEmpCost','zeroProgressEmpCost'})do d[key]=d[key]+assert(a[key])end
     d.qDecisions=d.qDecisions+a.q;d.fallbackDecisions=d.fallbackDecisions+a.fallback
    end
    r.costDiagnostics[entry.record.profile]=d
   end
  end
  local panel=require('Training.FlowerQPanel').openAsync(function()end,candidate.bundle.baseModels)
  panel.resourceReviewButton:emit('Tapped');local deadline=D.App.totalTime+10
  while not panel.resourceReviewView do assert(D.App.totalTime<deadline,panel.message);D.sleep(.02)end
  local view=panel.resourceReviewView;assert(#view.groups==5 and view.next.visible and view.previous.visible)
  local seen={}
  for i=1,5 do
   local g=view.groups[view.index];seen[g.key.profile]=true
   if (g.key.profile=='reproduction' or g.key.profile=='field')then assert(view.label.text:find('没有直接训练来源',1,true))else assert(view.label.text:find('当前场景已有来源',1,true))end
   if g.key.profile=='reproduction'then assert(g.evaluate.qDecisions==0 and g.evaluate.fallbackDecisions==60 and view.label.text:find('没有执行候选决策',1,true))end
   assert(g.basic.count==1 and g.evaluate.count==1 and view.label.text==require('Training.ResourceQReview').text(g))
   for _,trial in ipairs(prior.trials)do if trial.profile==g.key.profile then assert(g[trial.mode].cost==trial.cost and g[trial.mode].wins==(trial.status=='won'and 1 or 0))end end
   view.area:scrollToPosY(-10000,0);D.sleep(.1);view.next:emit('Tapped')
  end
  assert(seen.reproduction and seen.near and seen.far and seen.field and seen.exposed and view.index==1);view.previous:emit('Tapped');assert(view.index==5)
  assert(#view.assessment.regressions>=2 and #view.assessment.missing==0 and #view.assessment.sparse==5)
  view.summaryButton:emit('Tapped');assert(view.label.text:find('当前存在退步',1,true)and view.label.text:find('高 173.0',1,true))
  view.area:scrollToPosY(-10000,0);D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/resource-full-coverage-review.tga');D.sleep(.2)
  view.next:emit('Tapped');assert(not view.showAssessment and view.label.text==require('Training.ResourceQReview').text(view.groups[view.index]))
  view.back:emit('Tapped');assert(panel.node.visible and not panel.resourceReviewView and not panel.busy)
  r.checks={'ten saved evaluations rebuilt','five scenarios separated','assessment has no missing scenarios and five sparse comparisons','next wraps and previous works','costs and wins match saved records','zero Q decisions explained without attributing fallback savings to learning','return restores training'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
