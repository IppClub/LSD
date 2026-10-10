local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-comparison-review-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/yingzhao-q-comparison-result.json'),32);assert(prior.status=='PASS')
  local report=prior.report;assert(require('Training.YingzhaoComparisonStore').validate(report))
  local text=require('Training.YingzhaoComparison').text(report)
  assert(text:find('本轮候选未执行动作',1,true))
  local view=require('UI.DisarmComparison')({title='大英招 · 自主训练对照',summary=text,saved=prior.saved,closed=function()end});view:addTo(D.Director.ui3D);view:alignLayout()
  D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/yingzhao-q-comparison-coverage.tga');D.sleep(.2)
  r.summary=text;r.coverageVisible=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
