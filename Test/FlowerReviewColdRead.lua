local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-review-cold-read-result.json'
D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/flower-wuyun-deployment-1791163371.db';local dest=D.Content.writablePath..'/flower-review-cold-read-'..os.time()..'.db'
  assert(D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local R=require('Training.FlowerAdoptionReview');local rows=assert(D.DB:query('SELECT id,payload FROM lsd.Game0FlowerAdoptions ORDER BY id'));assert(#rows==3)
  for _,row in ipairs(rows)do
   local saved=assert(D.json.decode(row[2],32));local review=assert(R.assess(saved.bundle))
   assert(R.sameAssessment(saved.review,review),'Cold process rejected archive '..row[1])
   if row[1]==3 then assert(require('Training.FlowerIdentity').equal(saved.review,review),'New deterministic totals changed across processes');r.newExact=true end
  end
  assert(not require('Training.FlowerAdoptionStore').inspect('wuyun'));r.archives=#rows;r.noImplicitAdoption=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
