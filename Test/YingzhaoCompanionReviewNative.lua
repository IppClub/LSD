local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-companion-review-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-companion-readback-20261006/result.json'),32);assert(source.status=='PASS'and source.companionReadback)
  local report=source.report;assert(require('Training.YingzhaoComparisonStore').validate(report))
  local C=require('Training.YingzhaoComparison');local text=C.text(report);r.counts={}
  for _,round in ipairs(report.rounds)do
   local missing=0;for _,d in ipairs(round.companionDecisions)do if d.reason=='NO_MATCH'then missing=missing+1 end end
   r.counts[#r.counts+1]={mode=round.mode,decisions=#round.companionDecisions,missing=missing}
  end
  assert(text:find('原策略场次中的队友乌云：',1,true)and text:find('候选场次中的队友乌云：',1,true))
  local legacy=D.json.decode(D.json.encode(report),32);for _,round in ipairs(legacy.rounds)do round.companionDecisions=nil end
  assert(not C.text(legacy):find('中的队友乌云：',1,true),'Legacy observations invented')
  local returned=false;local view=require('UI.DisarmComparison')({title='大英招 · 队友决策复盘',summary=text,saved=source.saved,closed=function()returned=true end});view:addTo(D.Director.ui3D);view:alignLayout()
  D.sleep(.2);view.area:scrollTo(D.Vec2(0,view.area.viewSize.height-460));D.sleep(.3)
  D.App:saveScreenshot(root..'/Test/yingzhao-companion-review.tga');D.sleep(.2)
  view.backButton:emit('Tapped');assert(returned);r.returned=true;r.legacyHonest=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
