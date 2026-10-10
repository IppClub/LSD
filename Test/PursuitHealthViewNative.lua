local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.Content:save(root..'/Test/pursuit-health-view-result.json','{"status":"RUNNING"}')
D.thread(function()
 local ok,err=xpcall(function()
  D.App.winSize=D.Size(683,384)
  local c=require('Ruins.PursuitLevel').openAsync({finishAsync=function()return true end},{mission='c0-m06'});local b=c.battle
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge;e.unit.position=D.Vec2(10000,b.world.offset+155)end
  b.mentor.position=D.Vec2(6850,b.world.offset+155)
  for i,e in ipairs(b.escorts)do e.unit.position=D.Vec2(7100+(i-1)*220,b.world.offset+155);assert(b:damageFriendly(e.unit,i*20))end
  D.sleep(.3);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/pursuit-health-bars.tga');D.sleep(.2);b:finish('aborted','QA')
 end,debug.traceback)
 D.Content:save(root..'/Test/pursuit-health-view-result.json',D.json.encode({status=ok and 'PASS' or 'FAIL',error=not ok and err or nil}))
end)
