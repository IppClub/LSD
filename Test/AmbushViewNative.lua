local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.Content:save(root..'/Test/ambush-view-result.json','{"status":"RUNNING"}')
D.thread(function()
 local ok,err=xpcall(function()
  D.App.winSize=D.Size(683,384)
  local c=require('Ruins.PursuitLevel').openAsync({finishAsync=function()return true end},{mission='c0-m06'});local b=c.battle
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  D.sleep(.4);local e=b.enemies[1];assert(b:enemyStrike(e,require('Ruins.Pursuit').attackSpecs.dashanxiao[4]))
  local strike=e.strikes[#e.strikes]
  D.sleep(.4);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/ambush-enter.tga')
  while #strike.stages<2 do D.sleep(.01)end
  D.sleep(.18);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/ambush-drop.tga')
  while e.busy do D.sleep(.01)end
  assert(strike.completed);D.sleep(.1);b:finish('aborted','QA')
 end,debug.traceback)
 D.Content:save(root..'/Test/ambush-view-result.json',D.json.encode({status=ok and 'PASS' or 'FAIL',error=not ok and err or nil}))
end)
