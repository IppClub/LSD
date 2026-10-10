local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-cost-breakdown-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-attack-compare-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-attack%-compare%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-cost-breakdown-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local Compare=require('Training.DisarmCompare');local Store=require('Training.DisarmComparisonStore');r.actors={}
  for _,actor in ipairs({'ninilite','wuyun'})do
   local saved=assert(Store.load(prior.actors[actor].archive));local costs=assert(Compare.costBreakdown(saved.record));r.actors[actor]=costs
   for _,controller in ipairs({'baseline','candidate'})do
    local stock={};for _,run in ipairs(saved.record.runs)do if run.controller==controller then for key,line in pairs(run.trace.resources.stock)do local item=stock[key]or{units=0,cost=0};stock[key]=item;item.units=item.units+line.used;item.cost=item.cost+line.used*line.unit end end end
    local total=costs[controller].deployment
    for key,item in pairs(stock)do local report=costs[controller].items[key]or{units=0,cost=0};assert(report.units==item.units and report.cost==item.cost,'Consumption disagrees with final stock');total=total+report.cost end
    assert(total==saved.review.cost[controller],'Breakdown differs from settlement')
   end
   D.Director.ui3D:removeAllChildren();local v=require('UI.DisarmComparison')({record=saved.record,saved=saved.id});v:addTo(D.Director.ui3D);v:alignLayout()
   assert(v.label.text:find('费用构成',1,true)and v.label.text:find('乌云近战',1,true))
   assert(v.area.viewSize.height>v.area.height);v.area:scrollToPosY(-10000,0);D.sleep(.2)
   r.screenshot=D.Content.writablePath..'/cost-breakdown.tga';D.App:saveScreenshot(r.screenshot);D.sleep(.2)
  end
  assert(not Compare.costBreakdown({}));r.stockReconciled=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
