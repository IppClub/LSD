local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-assessment-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-q-four-source-evaluation-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-q%-four%-source%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-generalization-review-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local candidate=assert(require('Training.ResourceQStore').loadLatestAsync());local records=assert(require('Training.ResourceQTrials').loadAsync(candidate.id));assert(#records==6)
  local panel=require('Training.FlowerQPanel').openAsync(function()end,candidate.bundle.baseModels)
  panel.resourceReviewButton:emit('Tapped');local deadline=D.App.totalTime+10
  while not panel.resourceReviewView do assert(D.App.totalTime<deadline,panel.message);D.sleep(.02)end
  local view=panel.resourceReviewView;assert(#view.groups==3 and view.next.visible and view.previous.visible)
  local seen={}
  for i=1,3 do
   local g=view.groups[view.index];seen[g.key.profile]=true
   if g.key.profile=='reproduction'then assert(view.label.text:find('没有直接训练来源',1,true))else assert(view.label.text:find('当前场景已有来源',1,true))end
   assert(g.basic.count==1 and g.evaluate.count==1 and view.label.text==require('Training.ResourceQReview').text(g))
   for _,trial in ipairs(prior.trials)do if trial.profile==g.key.profile then assert(g[trial.mode].cost==trial.cost and g[trial.mode].wins==(trial.status=='won'and 1 or 0))end end
   view.area:scrollToPosY(-10000,0);D.sleep(.1);view.next:emit('Tapped')
  end
  assert(seen.reproduction and seen.near and seen.far and view.index==1);view.previous:emit('Tapped');assert(view.index==3)
  assert(#view.assessment.regressions==2 and #view.assessment.missing==2 and #view.assessment.sparse==3)
  view.summaryButton:emit('Tapped');assert(view.label.text:find('当前存在退步',1,true)and view.label.text:find('高 173.0',1,true))
  view.area:scrollToPosY(-10000,0);D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/resource-assessment.tga');D.sleep(.2)
  view.next:emit('Tapped');assert(not view.showAssessment and view.label.text==require('Training.ResourceQReview').text(view.groups[view.index]))
  view.back:emit('Tapped');assert(panel.node.visible and not panel.resourceReviewView and not panel.busy)
  r.checks={'six saved evaluations rebuilt','three scenarios separated','next wraps and previous works','costs and wins match saved records','return restores training'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
