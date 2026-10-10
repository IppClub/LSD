local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local p=require('Training.PartPractice').createAsync('ninilite');D.sleep(.2)
  local a=p.arena;local target=p.partCombat.target;a.enemy.playable.speed=0
  local y=target.model.y;target:sample();local original=target.regions
  local v=original[1].vertices[1];local point={x=v.x,y=v.y}
  local expected=assert(require('Combat.HitGeometry').nearest({x=point.x,y=point.y-1000},{x=point.x,y=point.y+1000},original))
  target.model.y=y+1000;target:sample();local previous=target.regions
  target.model.y=y-1000;target:sample()
  assert(not target:probe(point,{x=point.x+.0001,y=point.y}))
  local hit=assert(target:probeMoving(point,point,previous))
  assert(hit.part==expected.part and math.abs(hit.t-expected.t)<1e-5)
  r.part=hit.part;r.t=hit.t;r.expected=expected.t;r.actualSpine=true
  target.model.y=y;p:close()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil
 D.Content:save(root..'/Test/part-moving-result.json',D.json.encode(r))
end)
