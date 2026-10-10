local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-contribution-review-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-close-aim-natural-20261006/result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-mentor%-trace%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-contribution-review-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local report=assert(require('Training.YingzhaoComparisonStore').load(prior.saved));assert(require('Training.FlowerIdentity').equal(report,prior.report));r.coldReadback=true
  local C=require('Training.YingzhaoContributions');local I=require('Training.FlowerIdentity');local before=D.json.decode(D.json.encode(report),32)
  local expected={{80,172.5,48,14},{75,94.5,40,14}};r.contributions={}
  for i,round in ipairs(report.rounds)do
   local summary=C.summarize(round.trace);local mentor=summary.actors.mentor;local e=expected[i]
   assert(mentor.summonDamage==e[1]and mentor.bossDamage==e[2]and mentor.cost==e[3]and mentor.noDamageCost==e[4])
   local sum=0;for _,a in pairs(summary.actors)do sum=sum+a.cost;assert(a.noDamageCost<=a.cost)end
   assert(sum+summary.deployment==round.cost);r.contributions[#r.contributions+1]=summary
  end
  local old=D.json.decode(D.json.encode(report.rounds[1].trace),32);old.vitals=nil
  assert(C.text(old):find('承伤未记录',1,true),'Missing old vitals displayed as zero')
  assert(I.equal(report,before),'Read-only review mutated report')
  local text=require('Training.YingzhaoComparison').text(report)
  assert(text:find('援军伤害',1,true)and text:find('未造成伤害或破甲',1,true))
  for _,round in ipairs(report.rounds)do
   local accepted=0;for _,d in ipairs(round.decisions)do if d.accepted then accepted=accepted+1 end end
   assert(text:find((round.mode=='baseline'and'原策略'or'候选')..'动作执行 '..accepted..' 次',1,true))
  end
  local closed=false;local view=require('UI.DisarmComparison')({title='大英招 · 乌云技能对照',summary=text,saved=prior.saved,closed=function()closed=true end});view:addTo(D.Director.ui3D);view:alignLayout();D.sleep(.3)
  D.App:saveScreenshot(root..'/Test/yingzhao-contribution-review-top.tga');D.sleep(.2);view.area:scrollTo(D.Vec2(0,550));D.sleep(.2);D.App:saveScreenshot(root..'/Test/yingzhao-contribution-review.tga');D.sleep(.2);view.area:scrollTo(D.Vec2(0,view.area.viewSize.height-460));D.sleep(.2)
  view.backButton:emit('Tapped');assert(closed);r.returned=true;r.text=text
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
