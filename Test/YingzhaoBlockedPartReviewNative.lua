-- Render an actual archived failure report; no synthetic combat or adoption.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-blocked-part-review-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-schema5-actor-sources-natural-20261006/result.json'),32);assert(prior.status=='PASS')
  local report=prior.report;assert(require('Training.YingzhaoComparisonStore').validate(report))
  local C=require('Training.YingzhaoComparison');local summary=C.text(report)
  assert(summary:find('瞄准受阻部位：侧腹 12 次、手臂 1 次。',1,true))
  local matched={};r.ruleAudit={}
  for _,d in ipairs(report.rounds[2].decisions)do
   for action,why in pairs(d.blockedActions or {})do if why=='PART_UNREACHABLE'then
    for index,rule in ipairs(report.candidate.rules)do
     local match=true;for _,c in ipairs(rule.conditions)do if d.observation[c.name]~=c.value then match=false;break end end
     if match then
      assert(rule.action==action);local item=matched[index]or{rule=index,action=action,count=0,conditions=rule.conditions};matched[index]=item;item.count=item.count+1;break
     end
    end
   end end
  end
  for _,item in pairs(matched)do r.ruleAudit[#r.ruleAudit+1]=item end
  table.sort(r.ruleAudit,function(a,b)return a.rule<b.rule end)
  local legacy=D.json.decode(D.json.encode(report),32)
  for _,round in ipairs(legacy.rounds)do for _,d in ipairs(round.decisions or {})do d.blockedActions=nil end end
  assert(not C.text(legacy):find('瞄准受阻部位',1,true),'Old records invented missing detail')
  local returned=false
  local view=require('UI.DisarmComparison')({title='大英招 · 部位受阻复盘',summary=summary,saved=prior.saved,closed=function()returned=true end});view:addTo(D.Director.ui3D);view:alignLayout()
  D.sleep(.2);view.area:scrollTo(D.Vec2(0,(view.area.viewSize.height-460)*.5));D.sleep(.3)
  D.App:saveScreenshot(root..'/Test/yingzhao-blocked-part-review.tga');D.sleep(.2)
  view.backButton:emit('Tapped');assert(returned)
  r.summary=summary;r.legacyHonest=true;r.returnButton=true;r.sourceUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
