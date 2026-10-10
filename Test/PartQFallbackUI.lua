local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={};local ok,err=xpcall(function()
  require('Data.Config'):loadAsync()
  local p=assert(require('Training.PartPractice').openAsync(nil,'ninilite'))
  local prior=D.json.decode(D.Content:load(root..'/Test/part-q-fallback-result.json'),64)
  assert(prior.status=='PASS');p.evaluation={groups=prior.comparison}
  D.App.winSize=D.Size(683,384);D.sleep(.5)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/part-q-fallback-report.tga');D.sleep(.2)
  p:close()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil
 D.Content:save(root..'/Test/part-q-fallback-ui-result.json',D.json.encode(r))
end)
