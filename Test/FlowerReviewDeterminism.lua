local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-review-determinism-result.json'
D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={diffs={}};local ok,err=xpcall(function()
  local src=D.Content.writablePath..'/flower-wuyun-deployment-1791163208.db';local dest=D.Content.writablePath..'/flower-review-determinism-'..os.time()..'.db'
  assert(D.Content:copyAsync(src,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local row=assert(D.DB:query("SELECT payload FROM lsd.Game0FlowerAdoptions WHERE learner='wuyun' ORDER BY id DESC LIMIT 1"))[1]
  local saved=assert(D.json.decode(row[1],32));local review=assert(require('Training.FlowerAdoptionReview').assess(saved.bundle))
  local function diff(a,b,path)
   if type(a)~='table' or type(b)~='table'then if a~=b then r.diffs[#r.diffs+1]={path=path,saved=a,recomputed=b}end;return end
   for k,v in pairs(a)do diff(v,b[k],path..'.'..tostring(k))end
   for k,v in pairs(b)do if a[k]==nil then r.diffs[#r.diffs+1]={path=path..'.'..tostring(k),recomputed=v}end end
  end
  diff(saved.review,review,'review');r.exact=require('Training.FlowerIdentity').equal(saved.review,review)
  local R=require('Training.FlowerAdoptionReview');assert(R.sameAssessment(saved.review,review))
  local Store=require('Training.FlowerAdoptionStore');local active=assert(Store.inspect('wuyun'));r.archiveReadable=true
  local mutated=D.json.decode(row[1],32);mutated.review.pairs.reproduction.delta.teamHealing=mutated.review.pairs.reproduction.delta.teamHealing+.01
  assert(not R.sameAssessment(mutated.review,review))
  assert(D.DB:exec('UPDATE lsd.Game0FlowerAdoptions SET payload=? WHERE id=?',{D.json.encode(mutated,false,true),active.id})>=0)
  local invalid,why=Store.inspect('wuyun');assert(not invalid and why=='INVALID_ADOPTION_REVIEW')
  assert(D.DB:exec('UPDATE lsd.Game0FlowerAdoptions SET payload=? WHERE id=?',{row[1],active.id})>=0)
  assert(Store.inspect('wuyun'));r.tamperingRejected=true
  mutated=D.json.decode(D.json.encode(review),32);mutated.required=mutated.required+1e-10;assert(not R.sameAssessment(mutated,review))
  mutated=D.json.decode(D.json.encode(review),32);mutated.readyForDecision=false;assert(not R.sameAssessment(mutated,review))
  r.gatesExact=true

 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
