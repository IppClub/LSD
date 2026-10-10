local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-threat-review-result.json';local r={status='RUNNING',rounds={}}
D.Content:save(out,D.json.encode(r,false,true));D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-edge-varied-natural-20261006/result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-edge%-varied%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/threat-review.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local report=assert(require('Training.YingzhaoComparisonStore').load(prior.saved));local I=require('Training.FlowerIdentity');assert(I.equal(report,prior.report));local before=D.json.decode(D.json.encode(report),32)
  local C=require('Training.YingzhaoThreatReview');local totals={232,250}
  for i,round in ipairs(report.rounds)do
   local s=assert(C.build(round.trace));local total=0;for _,row in ipairs(s.damage)do total=total+row.total end;assert(total==totals[i])
   if i==2 then assert(s.windCooldownHits==4 and s.windCooldownDamage==48 and #s.groups>0)end
   r.rounds[#r.rounds+1]=s
  end
  assert(C.build({})==nil and C.text({}):find('缺少受击明细',1,true));assert(I.equal(report,before))
  local text=require('Training.YingzhaoComparison').text(report);assert(text:find('损失 48 生命',1,true))
  assert(text:find('拳击补练',1,true)and text:find('连斩补练',1,true))
  local closed=false;local view=require('UI.DisarmComparison')({title='大英招 · 队伍受击复盘',summary=text,saved=prior.saved,closed=function()closed=true end});view:addTo(D.Director.ui3D);view:alignLayout();D.sleep(.3)
  view.area:scrollTo(D.Vec2(0,view.area.viewSize.height-460));D.sleep(.2);D.App:saveScreenshot(root..'/Test/yingzhao-threat-review.tga');D.sleep(.2)
  view.backButton:emit('Tapped');assert(closed);r.returned=true;r.text=text;r.coldReadback=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
