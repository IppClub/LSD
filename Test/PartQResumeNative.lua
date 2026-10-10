local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/part-q-resume-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  assert(not D.DB:existDB('lsd'));assert(D.DB:exec("ATTACH DATABASE '"..D.Content.writablePath.."/resume-q.db' AS lsd")>=0)
  require('Data.Config'):loadAsync()
  local p=assert(require('Training.PartPractice').openAsync(nil,'ninilite'))
  assert(p.adopted.q.updates==36 and p.savedTrace.qTraining.updates==36)
  D.App.winSize=D.Size(683,384);D.sleep(.5)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/part-q-report-denominators.tga');D.sleep(.1)
  local previous=p.adopted
  local report,why=p:trainPartQAsync(4242);assert(report,why)
  assert(report.initialModel.updates==36 and report.updates==36 and report.model.updates==72)
  assert(require('Training.PartQTrace').validate(report,report.model))
  assert(p.adopted==previous and previous.q.updates==36 and p.candidate.q.updates==72)
  assert(not p:adoptAsync(),'Resume bypassed comparison')
  assert(p.store:load().adopted.q.updates==36)
  r.newUpdates=report.updates;r.totalUpdates=report.model.updates;r.privateResume=true;r.replayed=true;r.adoptionNeedsComparison=true
  p:close()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
