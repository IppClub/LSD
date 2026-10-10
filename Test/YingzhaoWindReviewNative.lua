local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-wind-review-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-wind-natural-20261006/result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-wind%-natural%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-wind-review-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local report=assert(require('Training.YingzhaoComparisonStore').load(prior.saved));assert(require('Training.FlowerIdentity').equal(report,prior.report));r.coldReadback=true
  local text=require('Training.YingzhaoComparison').text(report)
  for _,round in ipairs(report.rounds)do
   local accepted=0;for _,d in ipairs(round.decisions)do if d.accepted then accepted=accepted+1 end end
   assert(text:find((round.mode=='baseline'and'原策略'or'候选')..'动作执行 '..accepted..' 次',1,true))
  end
  local closed=false;local view=require('UI.DisarmComparison')({title='大英招 · 乌云技能对照',summary=text,saved=prior.saved,closed=function()closed=true end});view:addTo(D.Director.ui3D);view:alignLayout();D.sleep(.3)
  D.App:saveScreenshot(root..'/Test/yingzhao-wind-review.tga');D.sleep(.2);view.area:scrollTo(D.Vec2(0,view.area.viewSize.height-460));D.sleep(.2)
  view.backButton:emit('Tapped');assert(closed);r.returned=true;r.text=text
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
