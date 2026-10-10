local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-boundary-movement-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local A=require('Training.YingzhaoActions')
  for _,actor in ipairs({'ninilite','wuyun'})do
   local a=require('Training.Arena').createAsync({characterId=actor,manualUpdate=true});local b={phase='playing'}
   D.sleep(.3)
   for _,side in ipairs({-1,1})do
    for _,outward in ipairs({false,true})do
     a.student:stop();a.student.velocityX=0;a.student.x=side<0 and a.minX or a.maxX
     a.targetFacingForAction=function()return outward and side>0 or not outward and side<0 end
     local blocked=outward and 'fmove'or'bmove';local allowed=outward and 'bmove'or'fmove'
     local ok,why=A.available(b,a,blocked);assert(not ok and why=='ARENA_BOUNDARY')
     ok,why=A.request(b,a,blocked,'scripted');assert(not ok and why=='ARENA_BOUNDARY');assert(a.student.velocityX==0)
     assert(A.available(b,a,allowed));local x=a.student.x;assert(A.request(b,a,allowed,'scripted'));D.sleep(.2)
     assert((a.student.x-x)*side< -5,'Inward movement failed')
     a.student:stop();assert(A.available(b,a,blocked),'Movement rejected away from boundary')
     r.cases[#r.cases+1]={actor=actor,side=side,blocked=blocked,allowed=allowed,travel=a.student.x-x};save()
    end
   end
  end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
