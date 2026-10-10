local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-small-target-review-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-small-target-fallback-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-small%-target%-fallback%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-small-target-review-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local candidate=assert(require('Training.ResourceQStore').loadLatestAsync());local records=assert(require('Training.ResourceQTrials').loadAsync(candidate.id));assert(#records==18)
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
  local view=panel.resourceReviewView;assert(#view.groups==9 and view.next.visible and view.previous.visible)
  local seen={};local revised=0
  for i=1,9 do
   local g=view.groups[view.index];if g.key.setup.resourceFallback==3 then revised=revised+1;assert(view.label.text:find('基础回退：对花苞、小花妖及已知全破甲Boss保留EMP',1,true))end;seen[g.key.profile]=true
   if (g.key.profile=='reproduction' or g.key.profile=='field')then assert(view.label.text:find('没有直接训练来源',1,true))else assert(view.label.text:find('当前场景已有来源',1,true))end
   if g.key.profile=='reproduction'then assert(g.evaluate.qDecisions==0 and g.evaluate.fallbackDecisions==60 and view.label.text:find('没有执行候选决策',1,true))end
   assert(g.basic.count==1 and g.evaluate.count==1 and view.label.text==require('Training.ResourceQReview').text(g))
   for _,trial in ipairs(prior.trials)do if trial.profile==g.key.profile and g.key.setup.resourceFallback==3 then assert(g[trial.mode].cost==trial.cost and g[trial.mode].wins==(trial.status=='won'and 1 or 0))end end
   view.area:scrollToPosY(-10000,0);D.sleep(.1);view.next:emit('Tapped')
  end
  assert(revised==2)
  assert(seen.reproduction and seen.near and seen.far and seen.field and seen.exposed and view.index==1);view.previous:emit('Tapped');assert(view.index==9)
  assert(#view.assessment.missing==3 and #view.assessment.sparse==2 and view.assessment.outdated==7)
  view.summaryButton:emit('Tapped');assert(view.label.text:find('另有7组旧回退规则记录',1,true)and view.label.text:find('缺少完整基础/候选对照',1,true))
  view.area:scrollToPosY(-10000,0);D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/resource-small-target-review.tga');D.sleep(.2)
  view.next:emit('Tapped');assert(not view.showAssessment and view.label.text==require('Training.ResourceQReview').text(view.groups[view.index]))
  view.back:emit('Tapped');assert(panel.node.visible and not panel.resourceReviewView and not panel.busy)
  r.checks={'eighteen saved evaluations rebuilt','old and resource-aware fallback groups separated','assessment excludes old-rule coverage and reports three missing scenarios','next wraps and previous works','costs and wins match saved records','zero Q decisions explained without attributing fallback savings to learning','return restores training'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
