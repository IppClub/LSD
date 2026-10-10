local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-candidate-cold-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/yingzhao-candidate-store-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-candidates%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-candidate-cold-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local store=require('Training.YingzhaoPolicyStore');local candidate=assert(store.loadLatestAsync('ninilite'));assert(candidate.id==prior.id and candidate.model.sampleCount==6)
  local payload=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoCandidates WHERE id=?',{candidate.id})[1][1]
  local altered=D.json.decode(payload,32);altered.records[1].demonstrator='wuyun'
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoCandidates SET payload=? WHERE id=?',{D.json.encode(altered),candidate.id})>=0)
  assert(not store.loadLatestAsync('ninilite'),'Altered source accepted')
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoCandidates SET payload=? WHERE id=?',{payload,candidate.id})>=0)
  candidate=assert(store.loadLatestAsync('ninilite'))
  local tables=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
  for _,row in ipairs(tables)do assert(row[1]=='Game0YingzhaoObservations'or row[1]=='Game0YingzhaoCandidates','Unexpected adoption or wallet table')end
  r.id=candidate.id;r.samples=candidate.model.sampleCount;r.coldRebuild=true;r.noAdoption=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
